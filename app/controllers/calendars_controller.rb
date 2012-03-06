class CalendarsController < ApplicationController
  before_filter :authenticate_user!  
  helper_method :get_employee_id
  before_filter :get_base_data
  before_filter :get_all_parent_matter_activities
  before_filter :get_user, :only => [:calendar_by_matter]

  def calendar_month
    @pagenumber=206
    add_breadcrumb "Calendar Month View", calendar_month_calendars_path
    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year.to_i, @month.to_i, 1), :month)
    enddate = @calendar.enddt.to_date
    #FIXME following line is not a proper solution, it is just added for show appointments in calendar month view
    params[:start_date], params[:end_date] = @calendar.startdt.to_date, @calendar.enddt.to_date
    @appointments =[]    
    zimbra_personal = ZimbraActivity.zimbra_appt_date_range("appointment", @company.id, enddate, params[:people], nil, nil, current_user.email, params[:status])
    if  can? :manage, MatterTask
      condition = (params[:matters].blank? && in_matter_people)
    else
      condition = !(can? :manage, MatterTask) || (params[:matters].blank? && in_matter_people)
    end
    if  condition
      @appointments = zimbra_personal
    else
      @appointments =  MatterTask.matter_tasks_date_range("appointment", @company.id, enddate, enddate, params, current_user.email)      
      @appointments << zimbra_personal
      @appointments.flatten!      
    end
  end
  
  def index
    @pagenumber=120
    @appointments =[]
    @week = params[:cal_week].present? ? params[:cal_week].to_i : Time.zone.now.to_date.cweek
    week = @week
    @week_start = Date.commercial(@year, week, 1)
    @week_end = Date.commercial(@year, week, 7)
    @pre_week = (week==1 ? 52 : week-1)
    @nxt_week = (week==52 ? 1 : week+1)
    params[:date_start] = @week_start
    params[:date_end] = @week_end
    fetch_tasks_and_appointments(@week_end)    
    add_breadcrumb "Calendar", :calendars_path
  end

  def calendar_day
    @pagenumber=205
    add_breadcrumb "Calendar Day View", calendar_day_calendars_path  
    params[:start_date], params[:end_date] = @cal_date, @cal_date
    fetch_tasks_and_appointments(@cal_date)    
  end

  def search_matter_people
    if params[:mode_type]=="matter"
      for mpl in @mtrpeople
        @people_result.push(mpl.employee_user_id)
      end
    else    
      @result = []
      @matters = []
      present_matters = []
      params[:people].each do |person|
        user = User.find(person)       
        user.matters.unexpired_team_matters(user.id, user.company.id, Time.zone.now.to_date).uniq.each do |matter|
          if params[:matters].include?(matter.id)
            unless present_matters.include?(matter.id)
              @result.push(matter.id)
              @matters << matter
              present_matters << matter.id
            end            
          end
        end        
      end      
    end
  end

  # before filter for fetching base data
  def get_base_data
    # ===================================================== Base Data
    @company=@company || current_company
    check_frm_param
    @commonparams = {:matters => params[:matters], :people => params[:people], :frm => params[:frm], :mattertid => params[:mattertid], :opmtr=>params[:opmtr], :oppeople=>params[:oppeople], :mttrsel=>params[:mttrsel]}    
    # ===================================================== Duration calculation
    @year = params[:cal_year].present? ? params[:cal_year].to_i : Time.zone.now.to_date.year
    @month = params[:cal_month].present? ? params[:cal_month].to_i : Time.zone.now.to_date.month
    @cal_date = params[:cal_date].present? ? params[:cal_date].to_date : Time.zone.now.to_date.to_date
    # ===================================================== Fetch Base Data
    # for users list in the law firm
    @userid = get_employee_user_id    
    @matters = Matter.unexpired_team_matters(@userid, @company.id, Time.zone.now.to_date).uniq
    allmtrs = @matters.collect{|mtr| mtr.id}
    # following condition is to handle a search if not selected from dropdown returns a "" blank string in array
    check_matters = (params[:matters].present? && !params[:matters].blank?)
    params[:matters] = check_matters ? (params[:matters]==[""] ? nil : params[:matters]) : allmtrs
    mt = params[:matters].collect{|m| m.to_i}
    params[:mttrsel] = params[:mttrsel]=="true" ? true : false
    mtrs = (params[:mttrsel].present? && params[:mttrsel]) ? [] : mt
    if params[:action]=="calendar_by_people"
      @mtrpeople = MatterPeople.lawteam_members.find_all_by_matter_id(allmtrs)
    else
      @mtrpeople = MatterPeople.lawteam_members.find_all_by_matter_id((params[:mttrsel].present? && params[:mttrsel]) ? allmtrs : mt)
    end
    params[:matters] = mtrs
    usrs, urs = [], []
    @mtrpeople.group_by(&:employee_user_id).each do |label, people|
      urs.push(label)
    end
    usrs = User.find_with_deleted(urs)
    @distinct_matter_userid = usrs.sort_by(&:full_name).collect{|usr| [usr.full_name, usr.id]}
    # ===================================================== Assigning next pre
    # == if month is dec then add 1 in @month/ @year and if jan then minus 1 ==
    mnth = @month
    yr = @year
    @pre_month = (mnth==1 ? 12 : (mnth-1))
    @nxt_month = (mnth==12 ? 1 : (mnth+1))
    @pre_year = (mnth==1 ? yr-1 : yr)
    @nxt_year = (mnth==12 ? yr+1 : yr)
    @result = []
    @people_result = []
    # ===================================================== Selected indexes
    # for selected records in list view for matters and matter people
    @result = mtrs
    if params[:people].blank?
      params[:people] = [@userid]
    end
    if params[:status].blank?
      params[:status] = "Open"
    end
    peoplearray = params[:people].present? ? params[:people] : (@distinct_matter_userid.collect{|user| user[1]})
    @mple = MatterPeople.lawteam_members.find_all_by_employee_user_id(peoplearray)
    params[:matter_people] = @mple.collect{|mtr| mtr.id}
    @mple.group_by(&:employee_user_id).each do |label, people|
      @people_result.push(label)
    end
    # handling start date and end date parameters for search
    startdate = params[:start_date]
    enddate = params[:end_date]
    if startdate.blank? && !enddate.blank?
      params[:start_date] = enddate.to_date > Time.zone.now.to_date ? enddate : Time.zone.now.to_date
    elsif enddate.blank? && !startdate.blank?
      params[:end_date] = startdate.to_date > Time.zone.now.to_date ? startdate : Time.zone.now.to_date
    elsif !startdate.blank? && !enddate.blank?
      params[:end_date] = startdate.to_date > enddate.to_date ? startdate : enddate
    end
    opmtr = params[:opmtr] ? (params[:opmtr]=="true" ? true : false) : false 
    oppeople = params[:oppeople] ? (params[:oppeople]=="true" ? true : false) : false
    params[:opmtr] = opmtr
    params[:oppeople] = oppeople
    params[:opsearch] = params[:opsearch]=="true" ? true : false
    cout = 0
    @userclass = []
    @distinct_matter_userid.each do |user|
      cout += 1
      @userclass.push([user[1], cout])
    end
  end

  def calendar_by_matter
    authorize!(:index,@user) unless @user.has_access?(:Activities)
    @week = params[:cal_week].present? ? params[:cal_week].to_i : Time.zone.now.to_date.cweek
    params[:start_date] = params[:start_date].blank? ? Time.zone.now.to_date : params[:start_date]
    params[:end_date] = params[:end_date].blank? ? Time.zone.now.to_date+7 : params[:end_date]
    add_breadcrumb "Calendar By Matter", calendar_by_matter_calendars_path
    params[:matters] = params[:matters].blank? ? @matters.collect{|mttr| mttr.id} : params[:matters]
    @result = params[:matters]
    @task_todos = MatterTask.matter_tasks_date_range("todo", @company.id, @cal_date, @cal_date, params, current_user.email)
    @appointments =  MatterTask.matter_tasks_date_range("appointment", @company.id, @cal_date, @cal_date, params, current_user.email)
    @pagenumber=121
  end

  def calendar_by_people
    @week = params[:cal_week].present? ? params[:cal_week].to_i : Time.zone.now.to_date.cweek
    params[:start_date] = params[:start_date].blank? ? Time.zone.now.to_date : params[:start_date]
    params[:end_date] = params[:end_date].blank? ? Time.zone.now.to_date+7 : params[:end_date]
    if can? :manage, MatterTask
      params[:matters] = params[:matters].blank? ? @matters.collect{|mttr| mttr.id} : params[:matters]
      @matters = @company.matters.find(params[:matters])
      @result = params[:matters]
      @task_todos = MatterTask.matter_tasks_date_range("todo", @company.id, @cal_date, @cal_date, params, current_user.email)
      @appointments =  MatterTask.matter_tasks_date_range("appointment", @company.id, @cal_date, @cal_date, params, current_user.email)
    end
    add_breadcrumb "Calendar By People", calendar_by_people_calendars_path
    @pagenumber=122
  end

  def fetch_tasks_and_appointments(enddate)
    # === calendar day and week
    @appointments, @task_todos =[], []
    @appointments = ZimbraActivity.zimbra_appt_date_range("appointment", @company.id, enddate, params[:people], nil, nil, current_user.email, params[:status])
    @task_todos = ZimbraActivity.zimbra_appt_date_range("todo", @company.id, enddate, params[:people], nil, nil, nil, params[:status])
    if can? :manage, MatterTask
      if params[:matters] && !params[:matters].blank?
        @task_todos << MatterTask.matter_tasks_date_range("todo", @company.id, enddate, enddate, params, nil).flatten
        @appointments <<  MatterTask.matter_tasks_date_range("appointment", @company.id, enddate, enddate, params, current_user.email).flatten
        @appointments.flatten!
        @task_todos.flatten!
      end
    end
    @appointments = @appointments.reject{|appointment| appointment.all_day_event}
    all_activities = @task_todos + @appointments
    get_task_and_appointment_series(all_activities)
  end

  def get_user_classes(appointments)
    users = []
    cou = 0
    @userclass = []    
    appointments.each do |appointment|
      userid = get_employee_id(appointment)

      if users.blank? || !users.include?(userid)
        cou += 1
        users.push(userid)
        @userclass.push([userid, cou])
      end
    end
  end

  def get_employee_id(appointment)
    if appointment.attribute_present?("matter_id")
      MatterPeople.find(appointment.assigned_to_matter_people_id).employee_user_id
    else
      appointment.assigned_to_user_id
    end
  end

  def edit_matter_activity
    authorize!(:edit_matter_activity,current_user) unless current_user.has_access?(:Matters)
    @matter_task = MatterTask.find(params[:id])
    @matter = @matter_task.matter
    @other_matter_tasks = @matter.matter_tasks - [@matter_task]
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    @category_types = @matter_task.get_category_types(current_company)
    @attnds = MatterPeople.get_name_and_email(@matter)
    @attnds = @attnds.delete_if{ |att| @matter_task.attendees_emails.include?(att[1]) unless (att.blank? or att[1].blank?)} unless @matter_task.attendees_emails.blank?
    render :partial => "form_activity", :locals =>{:controller => "matter_tasks", :action => "update", :id => @matter_task.id}, :layout => false
  end

  def search_assignees
    data = params
    mattrppl = MatterPeople.find(data[:assgnd_id]) unless data[:assgnd_id].blank?
    if !mattrppl.blank?
      @mtrppl = MatterPeople.find_by_sql("select * from matter_peoples where deleted_at is null and matter_id = #{mattrppl.matter_id} and id != #{mattrppl.id}")
    elsif !params[:matter_id].blank?
      @mtrppl = MatterPeople.find_by_sql("select * from matter_peoples where deleted_at is null and matter_id = #{params[:matter_id]}")
    end
    @mtrppl.delete_if{|mp| data[:attnd_emails].include?(mp.get_email)} unless data[:attnd_emails].blank? unless @mtrppl.blank?
  end

  def create_activity
    if params[:matterid]
      redirect_to create_matter_activity_path
    else
      @zimbra_activity = ZimbraActivity.new
      render :layout => false
    end
  end

  def create_matter_activity
    authorize!(:create_matter_activity,current_user) unless current_user.has_access?(:Matters)
    @matter = Matter.find(params[:matterid])
    @other_matter_tasks = @matter.matter_tasks
    params[:matter_task] ||= {}
    params[:matter_task][:category] ||= "todo"
    @matter_task = @matter.matter_tasks.new(params[:matter_task])
    @matter_task.category = "appointment" if params[:is_appointment]=="true"
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    @attnds = MatterPeople.get_name_and_email(@matter)
    render :partial => "form_activity", :locals =>{:controller => "matter_tasks", :action => "create", :id => nil}, :layout => false
  end

  def edit_activity
    @zimbra_activity = ZimbraActivity.find(params[:id])
    if params[:home].eql?('true')
      respond_to do |format|
        format.js{
          render :file => 'calendars/edit_activity.js'
        }
      end
    else
      render :partial => "personal_activity", :locals => {:controller => "zimbra_activities", :action => "update", :id => @zimbra_activity.id}, :layout => false
    end
  end

  def edit_zimbra_instance
    data = params
    @zimbra_activity = ZimbraActivity.find(data[:id])    
    lawyer_email = current_user.email
    @zimbra_activity.start_date = ZimbraActivity.set_date_time(data[:instance_start_date], @zimbra_activity.start_date.strftime("%H:%M:%S"), lawyer_email)
    @zimbra_activity.end_date = ZimbraActivity.set_date_time(data[:instance_end_date], @zimbra_activity.end_date.strftime("%H:%M:%S"), lawyer_email)
    @zimbra_activity.exception_start_date = ZimbraActivity.set_date_time(data[:instance_start_date], data[:ex_start_time], lawyer_email)
    render :partial => "calendars/personal_activity", :locals =>{:controller => "calendars", :action => "create_zimbra_instance", :id => @zimbra_activity.id} ,:layout => false
  end

  def create_zimbra_instance
    data = params
    if data[:deleted_at]
      @zimbra_activity = ZimbraActivity.find(data[:id])
      if @zimbra_activity
        lawyer_email = current_user.email
        @new_zimbra_activity = @zimbra_activity.clone
        @new_zimbra_activity.start_date = Date.parse(data[:instance_start_date])
        @new_zimbra_activity.end_date = Date.parse(data[:instance_end_date])
        @new_zimbra_activity.exception_start_date = ZimbraActivity.set_date_time(data[:instance_start_date], data[:ex_start_time], lawyer_email)
        @new_zimbra_activity.task_id = @zimbra_activity.id
        @new_zimbra_activity.zimbra_status = true
        @new_zimbra_activity.exception_status = true       
        if @new_zimbra_activity.save
          @new_zimbra_activity.destroy
          respond_to do |format|
            flash[:notice] = "Activity instance was deleted successfully"
            if params[:height]
              format.js{
                render :update do |page|
                  page << "tb_remove();"
                  page << "window.location.reload();"
                end
              }
            else
              format.html {
                unless params[:frm_cal].eql?("calendars")
                  redirect_to :action => "index", :cat=> 'appointment'
                else
                  redirect_to :back
                end
              }
            end
          end
        else          
          format.js{
            render :update do |page|
              errs = "<ul>" + @new_zimbra_activity.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('activities_errors','#{errs}','message_error_div');"
            end
          }
        end
      end
    else
      main_task = ZimbraActivity.find(data[:id])
      @zimbra_activity = ZimbraActivity.new(data[:zimbra_activity].merge!({:assigned_to_user_id => current_user.id, :company_id => current_company.id}))
      @zimbra_activity.task_id = main_task.id
      @zimbra_activity.repeat = nil
      @zimbra_activity.occurrence_type = nil
      unless main_task.occurrence_type.blank?
        if main_task.occurrence_type == "count"
          @zimbra_activity.count = main_task.count
        else
          @zimbra_activity.until = main_task.until
        end
      end
      @zimbra_activity.category = "appointment"
      @zimbra_activity.zimbra_status = true
      @zimbra_activity.exception_status = true
      sd = Time.zone.parse(data[:zimbra_activity][:start_date_appointment] + ' ' + data[:zimbra_activity][:start_time]).getutc
      ed = Time.zone.parse(data[:zimbra_activity][:end_date_appointment] + ' ' + data[:zimbra_activity][:end_time]).getutc
      @zimbra_activity.start_date_appointment = sd
      @zimbra_activity.end_date_appointment = ed      
      respond_to do |format|
        if @zimbra_activity.save
          flash[:notice] = "#{t(:text_zimbra_activity)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          format.js{
            render :update do |page|
              page << "tb_remove();"
              page << "window.location.reload();"
            end
          }
        else          
          format.js{
            render :update do |page|
              format_ajax_errors(@zimbra_activity, page, 'zimbra_activities_errors');              
            end
          }
        end
      end
    end
  end

  def instance_series
    if params[:matter]
      @appointment = MatterTask.find(params[:appointment_id])
    else
      @appointment = ZimbraActivity.find(params[:appointment_id])
    end
    render :layout => false
  end

  def mark_as_done
    data = params
    @zimbra_activity = ZimbraActivity.find(params[:id])
    unless data[:zimbra_activity].blank?
      respond_to do|format|
        format.js {
          render :update do|page|
            if @zimbra_activity.update_attributes(:completed_at => data[:zimbra_activity][:completed_at], :progress => 'COMP', :progress_percentage => '100')
              page.call("parent.tb_remove")
              page.call("window.location.reload")
            else
              format_ajax_errors(@zimbra_activity, page, "modal_complete_task_errors")
            end
          end
        }
      end
    else
      render :layout => false
    end
  end
  
  def check_frm_param   
    frm = request.referer.to_s
    if (params[:frm] && params[:frm].eql?("m")) || (frm.include?("/matters") && !frm.include?("matter_tasks") && params[:mattertid].blank?)
      params[:frm] = "m" if params[:frm].blank?
      add_breadcrumb "Matters", :matters_path
    elsif (params[:frm] && params[:frm].eql?("ma")) || frm.include?("matter_tasks")
      if params[:frm].blank?
        params[:mattertid] = params[:matters]
        params[:frm] = "ma"
      end
      if params[:mattertid].present?
        add_breadcrumb "Matters", :matters_path
        add_breadcrumb "Matter Activities", {:controller => "matter_tasks", :action => "index", :matter_id => params[:mattertid]}
      end
    end
    add_breadcrumb "Calendar", :calendars_path unless params[:action].eql?("index")
  end

  def synchronize_appointments
    Resque.enqueue(SyncZimbraAppointment, get_employee_user_id)
    flash[:notice] = "The zimbra appointments are being synced in the background. You can continue to use the LIVIA Portal. This will not impact the sync process. A notification email will be sent on your registered email id once the process is completed."
    redirect_to :back
  end

end
