# Matter related tasks are handled in this controller.
# The functionality for adding comments and documents to matter tasks, is done
# here. Also the linkage of matter tasks and matter issues is handled here.
# This controller preloads a matter, and is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterTasksController < ApplicationController
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  
  layout 'left_with_tabs'
  
  before_filter :authenticate_user!
  before_filter :get_matter, :except => [:comment_form,:create_task_home]
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :check_access_to_matter, :except => [:comment_form,:create_task_home]
  before_filter :get_all_parent_matter_activities, :only => [:index]
  before_filter :get_user, :only => [:index,:edit,:update,:create,:new,:new_from_home,:create_matter_task_form,:create_task_home]
  rescue_from ActionController::UnknownAction, :with => :no_action_handled_tasks
  rescue_from ActiveRecord::RecordNotFound, :with => :show_action_error_handled_tasks
  add_breadcrumb I18n.t(:text_matters), :matters_path

  # Renders partial for t&e entry in task edit.
  def time_expense_entry
    @time_entry = current_company.time_entries.new
    @matter_task = @matter.matter_tasks.find(params[:id])
    if(@matter)
			@matter = Matter.find(params[:matter_id], :conditions => ["company_id = ?", current_company.id])
			if(@matter && !MatterPeople.is_part_of_matter_and_matter_people?(@matter.id, get_employee_user_id))
        @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ["matter_peoples.matter_id=? AND matter_peoples.employee_user_id !=? AND ((matter_peoples.end_date >= '#{Date.today}' AND matter_peoples.start_date <= '#{Date.today}') or (matter_peoples.start_date <= '#{Date.today}' and matter_peoples.end_date is null))", @matter.id, get_employee_user_id] )
      else
        @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ['matter_peoples.matter_id=?', @matter.id] )
			end
    else
      @lawyers = User.all(:joins => "inner join employees on employees.user_id = users.id", :conditions => [condition_str])
		end
    @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
    render :partial => "time_expense_entry", :layout => false
  end

  def get_assignees
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    @def_assignee = @assignees.find {|e| e.id == params[:assignee_id].to_i}
    render :partial => "assignees"
  end

  # Return matter tasks scoped by current Matter.
  def index
    authorize!(:index,@user) unless @user.has_access?(:Activities)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    data = params
    sort_column_order
    params[:order] = @ord.nil? ? 'matter_tasks.created_at ASC' : @ord
    data[:cat] = (data[:cat]=="todo"||data[:cat].blank?) ? "todo" : "appointment"
    data[:per_page] = data[:per_page].blank? ? 25 : data[:per_page]
    @mode_type     = data[:mode_type].eql?("ALL") ? 'ALL' : 'MY'
    @task_status = data[:task_status] || "all"
    if(is_access_matter? && @matter.employee_matter_people_id(get_employee_user_id) ==nil)
      @mode_type = "ALL"
      params[:mode_type]= "ALL"
      # Find with deleted is used here to fetch the deleted exception of appointments.
      all_matter_tasks = data[:letter].blank?  ? @matter.matter_tasks.with_order(data[:order]).find_with_deleted(:all) : @matter.matter_tasks.with_order(data[:order]).find_with_deleted(:all, :conditions => ["upper(substr(matter_tasks.name, 1, 1)) = '#{data[:letter]}'"])
    else
      all_matter_tasks  = @mode_type.eql?("MY") ? @matter.my_matter_tasks(get_employee_user_id, data[:order], data[:letter]) : (data[:letter].blank? ? @matter.matter_tasks.with_order(data[:order]).find_with_deleted(:all) : @matter.matter_tasks.with_order(data[:order]).find_with_deleted(:all, :conditions => ["upper(substr(matter_tasks.name, 1, 1)) = '#{data[:letter]}'"]))
    end
    params.merge!(:mode_type=>@mode_type) if params[:mode_type] == nil
    all_matter_tasks = all_matter_tasks.find_all {|e| e.check_task_status(@task_status)}
    matter_tasks, exceptions_id = [], []
    all_matter_tasks.each do |task|
      if task.category.eql?(data[:cat])
        if data[:cat].eql?('appointment')
          matter_tasks << task ####if task.task_id.nil? # Added condition for Bug 7614
        else
          # Filter the deleted tasks.
          if task.deleted_at.nil?
            matter_tasks << task if task.assoc_as == '0' or task.assoc_as == nil
          end
        end
      end
    end
    params[:column_name] = params[:col]    
    get_task_and_appointment_series(matter_tasks, true) unless matter_tasks.blank?
    @matter_tasks = data[:cat].eql?('appointment') ? @task_appt : @task_todo
    @parents = @matter.matter_tasks.find_all_by_category_and_assoc_as('todo', '1', :select => :parent_id).collect{|task| task.parent_id}.uniq
    if params[:cat].eql?("appointment")
      @pagenumber = 175
    else
      @pagenumber = 142
    end
    data[:cat].eql?('appointment') ? @dates = {:date_start=>params[:date_start],:date_end=>params[:date_end]} : @dates = {}
    add_breadcrumb t(:text_activities), matter_matter_tasks_path(@matter)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matter_tasks }
    end
  end

  def new_from_home
    authorize!(:new_from_home,@user) unless @user.has_access?(:Activities)
    @matter = Matter.find(params[:matter][:id], :include => [:employee_document_homes, :client_document_homes])
    params[:matter_id] = @matter.id
    params[:matter_task] ||= {}
    params[:matter_task][:category] ||= "todo"
    @matter_task = @matter.matter_tasks.new(params[:matter_task])
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
    @has_children = false
    @assignees = MatterPeople.current_lawteam_members(@matter.id) 
    @attnds = MatterPeople.get_name_and_email(@matter)
    add_breadcrumb "New Matter Activities", new_matter_matter_task_path(@matter)
    respond_to do |format|
      format.html { render "new_edit" }
      format.js  { render "new_edit" }
      format.xml  { render :xml => @matter_task }
    end
  end

  def new
    authorize!(:new,@user) unless @user.has_access?(:Activities)
    params[:matter_task] ||= {}
    params[:matter_task][:category] ||= "todo"
    @matter_task = @matter.matter_tasks.new(params[:matter_task])
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @assignees = MatterPeople.current_lawteam_members(@matter.id) #@matter.matter_peoples.find(:all,:conditions=> ["people_type='client'"])
    @attnds = MatterPeople.get_name_and_email(@matter)
    @has_children = false
    @pagenumber = 40   
    @other_matter_tasks = @matter.matter_tasks
    add_breadcrumb "Matter Activities", matter_matter_tasks_path(@matter)
    add_breadcrumb "New Matter Activities", new_matter_matter_task_path(@matter)
    @note_name = StickyNote.find_by_note_id_and_assigned_to_user_id(params[:note_id],assigned_user) unless params[:note_id].blank?
    params[:request_from].present?? @request_from = params[:request_from] : @request_from = nil
    respond_to do |format|      
      format.html {
        if request.xhr?
          render :partial => "modal_new"
        else
          render "new_edit"
        end
      }
      format.js {
        render :partial => "modal_new"
      }
      format.xml  { render :xml => @matter_task }
    end
  end

  def edit
    authorize!(:edit,@user) unless @user.has_access?(:Activities)
    @matter_peoples=@matter.matter_peoples.find(:all,:conditions=>"people_type='client'")
    @matter_task = @matter.matter_tasks.find(params[:id])
    @category_types = @matter_task.get_category_types(current_company)
    if is_access_matter? || is_lead_lawyer?
      @notes = @matter_task.comments
    else
      #TODO: This is very expensive way the code written it need to be optimize
      @notes = @matter_task.comments.find_all {|e| e.lawyer_can_see?(get_employee_user_id,@matter_task.matter.id, @matter_task, get_company_id)}
    end
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @pagenumber=178
    unless @matter_task.is_appointment?
      children = @matter_task.get_all_children.flatten
      @other_matter_tasks = @other_matter_tasks - [@matter_task] - children
      @has_children = !children.blank?
    else
      @has_children = false
    end    
    @assignees = MatterPeople.current_lawteam_members(@matter.id) #@matter.matter_peoples.find(:all,:conditions=> ["people_type='client'"])
    assignee_id = @matter_task.assigned_to_matter_people_id
    assignee=@assignees.select{|assigne| assigne.id==assignee_id}
    if assignee.count==0
      @assignees << MatterPeople.find_with_deleted(assignee_id)
    end
    @attnds = MatterPeople.get_name_and_email(@matter)
    @attnds = @attnds.delete_if{ |att| @matter_task.attendees_emails.include?(att[1]) unless (att.blank? or att[1].blank?)} unless @matter_task.attendees_emails.blank?
    documents = @matter_task.document_homes.all(:conditions => ["sub_type IS NULL AND wip_doc IS NULL AND ((access_rights = 1 AND owner_user_id = #{get_employee_user_id}) OR access_rights != 1)"])
    @lawyer_documents = documents.find_all {|e| e.upload_stage!=2}
    @client_documents = []
    me = @matter.matter_peoples.lawteam_members.find_by_employee_user_id(get_employee_user_id)
    
    # Show client document ONLY IF:
    # User is lead lawyer Or law firm manager
    # Or
    # The matter task is assigned to the user
    # Or
    # User has been delegated the access to view client docs
    if is_access_matter? || @matter_task.assigned_to_matter_people_id == me.id || me.can_view_client_docs? || is_lead_lawyer?
      @client_documents = documents.find_all {|e| e.upload_stage==2}
    end

    params[:request_from].present?? @request_from = params[:request_from] : @request_from = nil
    add_breadcrumb "Matter Activities", matter_matter_tasks_path(@matter)
    add_breadcrumb "Edit Matter Activities", edit_matter_matter_task_path(@matter, @matter_task)
    respond_to do |format|
      format.html { render "new_edit" }
      format.xml  { render :xml => @matter_task }
    end
  end

  def edit_instance
    data = params
    @matter_task = @matter.matter_tasks.find(data[:id])
    lawyer_email = current_user.email
    @matter_task.start_date = ZimbraActivity.set_date_time(data[:instance_start_date], @matter_task.start_date.strftime("%H:%M:%S"), lawyer_email)
    @matter_task.end_date = ZimbraActivity.set_date_time(data[:instance_end_date], @matter_task.end_date.strftime("%H:%M:%S"), lawyer_email)
    @matter_task.exception_start_date = Date.parse(data[:instance_start_date])
    @matter_task.exception_start_time = Time.parse(data[:ex_start_time]).strftime("%I:%M %p")
    @notes = @matter_task.comments
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @has_children = false
    @lawyer_documents = @matter_task.document_homes.find_all {|e| e.upload_stage!=2}
    @client_documents = @matter_task.document_homes.find_all {|e| e.upload_stage==2}
    add_breadcrumb "Matter Activities", matter_matter_tasks_path(@matter)
    add_breadcrumb "Edit Matter Activities", edit_matter_matter_task_path(@matter, @matter_task)
    @category_types = @matter_task.get_category_types(current_company)
    @attnds = MatterPeople.get_name_and_email(@matter)
    @attnds = @attnds.delete_if{ |att| @matter_task.attendees_emails.include?(att[1]) unless (att.blank? or att[1].blank?)} unless @matter_task.attendees_emails.blank?
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    assignee_id = @matter_task.assigned_to_matter_people_id
    assignee=@assignees.select{|assigne| assigne.id==assignee_id}
    if assignee.count==0
      @assignees << MatterPeople.find_with_deleted(assignee_id)
    end
    if params[:height]
      render :partial => "calendars/form_activity", :locals =>{:controller => "matter_tasks", :action => "create_instance", :id => @matter_task.id} ,:layout => false
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?(:Activities)
    data = params
    if data[:matter_task] [:category].eql?('todo')
      data[:matter_task][:start_time]=Time.zone.now.strftime("%I:%M %p")
      data[:matter_task][:end_time]=Time.zone.now.strftime("%I:%M %p")
    end
    data[:matter_task][:start_time] = Time.zone.parse(data[:matter_task][:start_time]).strftime("%I:%M %p")
    data[:matter_task][:end_time] = Time.zone.parse(data[:matter_task][:end_time]).strftime("%I:%M %p")
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @has_children = false
    @pagenumber=40
    @assignees = MatterPeople.current_lawteam_members(@matter.id) #@matter.matter_peoples.find(:all,:conditions=> ["people_type='client'"])
    @matter_task = @matter.matter_tasks.new(data[:matter_task].merge!({:created_by_user_id => current_user.id, :company_id => @company.id}))
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(@company)
    @attnds = MatterPeople.get_name_and_email(@matter)
    data[:request_from].present?? @request_from = data[:request_from] : @request_from = nil
    data[:matter_task][:attendees_emails] = @matter_task.add_people_attendees(data[:people_attendees_emails], data[:matter_task][:attendees_emails]) unless data[:people_attendees_emails].blank?
    if data[:matter_task][:start_date_appointment].present?
      sd = Time.zone.parse(data[:matter_task][:start_date_appointment] + ' ' + data[:matter_task][:start_time]).getutc
      ed = Time.zone.parse(data[:matter_task][:end_date_appointment] + ' ' + data[:matter_task][:end_time]).getutc
      @matter_task.start_date_appointment = sd
      @matter_task.end_date_appointment = ed
    end
    if data[:matter_task] [:category].eql?('todo')
      @matter_task.start_date_todo =Time.zone.parse(data[:matter_task][:start_date_todo] + ' 12:00 PM') if !data[:matter_task][:start_date_todo].blank?
      @matter_task.end_date_todo =Time.zone.parse(data[:matter_task][:end_date_todo] + ' 12:00 PM') if !data[:matter_task][:end_date_todo].blank?
    else
      @matter_task.assoc_as = '0'
      data[:matter_task].delete(:parent_id)
      data[:matter_task].delete(:assoc_as)
    end
    respond_to do |format|
      if @matter_task.errors.blank? and @matter_task.save
        flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          redirect_if(data[:button_pressed].eql?("save"), edit_matter_matter_task_path(@matter, @matter_task, :request_from => @request_from))
          redirect_if(@request_from && data[:button_pressed].eql?("save_exit"), root_url)
          redirect_if(data[:button_pressed].eql?("save_exit") && @request_from.blank?, matter_matter_tasks_path(@matter, :cat => @matter_task.is_appointment? ? 'appointment' : ''))
        }
        format.xml  { render :xml => @matter_task, :status => :created, :location => @matter_task }
        format.js {
          render :update do|page|
            page << "tb_remove()"
            if params[:note_id].present?
              page.call "deleteStickyNote",params[:note_id]
            end
            page.call("parent.location.reload")
          end
        }
      else
        format.html { render "new_edit" }
        format.xml  { render :xml => @matter_task.errors, :status => :unprocessable_entity }
        format.js {
          render :update do|page|
            unless params[:cal_action]
              errors = "<ul>" + @matter_task.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('modal_new_task_errors','#{escape_javascript(errors)}','message_error_div');"
              page << "jQuery('#save_task').val('Save');"
              page << "jQuery('#save_task').attr('disabled','');"
              page << "jQuery('#loader').hide();"
              if params[:note_id].present?
                page.call "deleteStickyNote",params[:note_id]
              end
            else
              format_ajax_errors(@matter_task, page, 'calendar_activities_errors')
              page << "jQuery('#loadingimg').hide();"
            end
          end
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :index
  end

  def create_instance
    data = params
    if data[:deleted_at]
      @matter_task = @matter.matter_tasks.find(data[:id])
      if @matter_task
        @new_matter_task = @matter_task.clone
        @new_matter_task.exception_start_date = Date.parse(data[:instance_start_date])
        @new_matter_task.exception_start_time = Time.zone.parse(data[:ex_start_time]).strftime("%H:%M:%S")
        @new_matter_task.task_id = @matter_task.id
        @new_matter_task.zimbra_task_status = true
        @new_matter_task.exception_status = true
        @new_matter_task.updated_by_user_id = current_user.id
        @new_matter_task.skip_on_create_instance = true
        if @new_matter_task.save
          @new_matter_task.destroy          
          respond_to do |format|
            flash[:notice] = "Activity instance was deleted successfully"
            if params[:height] or request.xhr?
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
              format.xml  { render :xml => @matter_task, :status => :created, :location => @matter_task }
            end
          end
        else
          if params[:height]
            format.js{
              render :update do |page|
                errs = "<ul>" + @new_matter_task.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                page << "show_error_msg('activities_errors','#{errs}','message_error_div');"
              end
            }
          else
            flash[:error] = @new_matter_task.errors
            redirect_to :action => "index"
          end
        end
      end
    else      
      @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
      @has_children = false
      @assignees = MatterPeople.current_lawteam_members(@matter.id) 
      @matter_task = @matter.matter_tasks.new(data[:matter_task].merge!({:created_by_user_id => current_user.id, :company_id => current_company.id}))
      @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
      @matter_task.task_id =data[:id]
      @matter_task.category = "appointment"
      @category_types = @matter_task.get_category_types(current_company)
      @matter_task.zimbra_task_status = true
      @matter_task.exception_status = true
      sd = Time.zone.parse(data[:matter_task][:start_date_appointment] + ' ' + data[:matter_task][:start_time]).getutc
      ed = Time.zone.parse(data[:matter_task][:end_date_appointment] + ' ' + data[:matter_task][:end_time]).getutc
      @matter_task.start_date_appointment = sd
      @matter_task.end_date_appointment = ed
      data[:matter_task][:attendees_emails] = @matter_task.add_people_attendees(data[:people_attendees_emails], data[:matter_task][:attendees_emails])
      @attnds = MatterPeople.get_name_and_email(@matter)
      @attnds = @attnds.delete_if{ |att| @matter_task.attendees_emails.include?(att[1]) unless (att.blank? or att[1].blank?)} unless @matter_task.attendees_emails.blank?
      respond_to do |format|
        @matter_task.updated_by_user_id = current_user.id
        if @matter_task.save
          flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          if params[:height]
            format.js{
              render :update do |page|
                page << "tb_remove();"
                page << "window.location.reload();"
              end
            }
          else
            format.html {
              redirect_if(data[:save], edit_matter_matter_task_path(@matter, @matter_task))
              redirect_if(data[:save_exit], matter_matter_tasks_path(@matter, :cat => 'appointment'))
            }
            format.xml  { render :xml => @matter_task, :status => :created, :location => @matter_task }
          end
        else
          if params[:height]
            format.js{
              render :update do |page|
                errs = "<ul>" + @matter_task.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                page << "show_error_msg('activities_errors','#{errs}','message_error_div');"
              end
            }
          else
            format.html { render "new_edit" }
            format.xml  { render :xml => @matter_task.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
  end


  def update
    authorize!(:update,@user) unless @user.has_access?(:Activities)
    data = params
    @assignees = MatterPeople.current_lawteam_members(@matter.id)
    @matter_task = @matter.matter_tasks.find(data[:id])
    @notes = @matter_task.comments
    @lawyer_documents= @matter_task.document_homes.find_all {|e| e.upload_stage!=2}
    @client_documents= @matter_task.document_homes.find_all {|e| e.upload_stage==2}
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @category_types = @matter_task.get_category_types(current_company)
    unless @matter_task.is_appointment?
      children = @matter_task.get_all_children.flatten
      @other_matter_tasks = @other_matter_tasks - [@matter_task] - children
      @has_children = !children.blank?
    else
      @has_children = false
    end
    @attnds = MatterPeople.get_name_and_email(@matter)
    @attnds = @attnds.delete_if{ |att| @matter_task.attendees_emails.include?(att[1]) unless (att.blank? or att[1].blank?)} unless @matter_task.attendees_emails.blank?
    data[:matter_task][:start_time] = Time.zone.parse(data[:matter_task][:start_time]).strftime("%I:%M %p")
    data[:matter_task][:end_time] = Time.zone.parse(data[:matter_task][:end_time]).strftime("%I:%M %p")
    if data[:matter_task][:start_date_appointment].present?
      data[:matter_task][:start_date_appointment] = Time.zone.parse(data[:matter_task][:start_date_appointment] + ' ' + data[:matter_task][:start_time])
      data[:matter_task][:end_date_appointment] = Time.zone.parse(data[:matter_task][:end_date_appointment] + ' ' + data[:matter_task][:end_time])
    end
    if @matter_task.category.eql?('todo') #data[:matter_task] [:category].eql?('todo')
      data[:matter_task][:start_date_todo] =Time.zone.parse(data[:matter_task][:start_date_todo] + ' 12:00 PM')
      data[:matter_task][:end_date_todo] =Time.zone.parse(data[:matter_task][:end_date_todo] + ' 12:00 PM')
    else
      data[:matter_task].delete(:parent_id)
      data[:matter_task].delete(:assoc_as)
    end
    data[:request_from].present?? @request_from = data[:request_from] : @request_from = nil
    if @matter_task.zimbra_task_id && @matter_task.assigned_to_matter_people_id !=  data[:matter_task][:assigned_to_matter_people_id].to_i
      @matter_task.destroy_zimbra_matter_task
      instance_matter = MatterTask.find_with_deleted(:all, :conditions => ["task_id = ?", @matter_task.id])
      instance_matter.each {|m| m.destroy! }
    end
    data[:matter_task][:attendees_emails] = @matter_task.add_people_attendees(data[:people_attendees_emails], data[:matter_task][:attendees_emails]) unless data[:people_attendees_emails].blank?
    respond_to do |format|
      if @matter_task.update_attributes(data[:matter_task].merge!({:updated_by_user_id => current_user.id, :zimbra_task_status => true}))
        flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        unless data[:cal_action]
          format.html {
            redirect_if(data[:button_pressed].eql?("save"), edit_matter_matter_task_path(@matter, @matter_task))
            redirect_if(@request_from && data[:button_pressed].eql?("save_exit"), root_url)
            redirect_if(data[:button_pressed].eql?("save_exit") && @request_from.blank?, matter_matter_tasks_path(@matter,  :cat => @matter_task.is_appointment? ? 'appointment' : '' ))
          }
          format.xml  { head :ok }
        else
          if request.xhr?
            format.js {
              render :update do |page|
                page.call("tb_remove")
                page.call("parent.location.reload")
              end
            }
          end
        end
      else
        unless data[:cal_action]
          format.html { render "new_edit" }
          format.xml  { render :xml => @matter_task.errors, :status => :unprocessable_entity }
        else
          format.js {
            render :update do |page|
              format_ajax_errors(@matter_task, page, 'calendar_activities_errors')
              page << "jQuery('#loadingimg').hide();"
            end
          }
        end
      end
    end
  end
  
  def destroy
    require 'uri'
    data = params
    @matter_task = @matter.matter_tasks.find(data[:id])
    @matter_task.updated_by_user_id = current_user.id
    @matter_task.destroy
    flash[:notice] = "Matter Activity was deleted successfully."
    respond_to do |format|
      if params[:_method].eql?('delete')
        format.html{redirect_to :back} #moved format.html above format.js to resolve Bug 9648, to avoid the IE security validation popup
      else
        format.js{
          render :update do |page|
            page << "tb_remove();"
            page << "window.location.reload();"
          end
        }
      end
      format.xml  { head :ok }
    end
  end

  # Send the comment form for matter task Comment. Sets the required
  # variables. Called from facebox.
  def comment_form
    data = params
    @comment_user_id = current_user.id
    @comment_commentable_id = data[:id]
    @comment_commentable_type = 'MatterTask'
    @comment_title = data[:comment_title] || 'Comment'
    @matter_id = data[:matter_id]
    respond_to do |format|
      format.html { render :partial => "matters/comment_form" }
    end
  end

  # Returns list of linked issues with the current task, rendered in facebox.
  # For showing (using facebox) issues linked to this risk.
  ###Modified for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  ##render common partial and values for respective instance variable on the basis of format_type
  def show_task_matter_issues
    @task_matter_issues = []
    @task_matter_facts = []
    @task_matter_risks = []
    @task_matter_researches = []
    if params[:format_type]=="issues"
      @task_matter_issues = @matter.matter_tasks.find(params[:id]).matter_issues
    end
    if params[:format_type]=="facts"
      @task_matter_facts =@matter.matter_tasks.find(params[:id]).matter_facts
    end
    if params[:format_type]=="risks"
      @task_matter_risks = @matter.matter_tasks.find(params[:id]).matter_risks
    end
    if params[:format_type]=="researches"
      @task_matter_researches = @matter.matter_tasks.find(params[:id]).matter_researches
    end
    respond_to do |format|
      format.js { render :partial => "common/linked_matter_all", :locals => { :matter_risks =>@task_matter_risks,:matter_issues => @task_matter_issues, :matter_facts => @task_matter_facts, :matter_researches => @task_matter_researches, :format_type => params[:format_type] } }
    end
  end

  def complete_task
    data = params
    data[:selected_records] ||= []
    data[:completed_at] ||= []
    i = 0
    j = 0
    msg = ''
    msg1 = ''
    rec = data[:selected_records].length
    if data[:selected_records].length>0
      data[:completed_at].each_with_index do |date,k|
        unless date.blank?
          unless data[:activity][k].eql?('true')
            task = MatterTask.find(data[:selected_records][i])
            task.completed_at = date
            task.completed = true
            task.completed_date_cannot_be_future
            task.zimbra_task_status = true
          else
            task = ZimbraActivity.find(data[:selected_records][i])
            task.completed_at = date
            task.progress = 'COMP'
            task.progress_percentage = '100'
            task.zimbra_status = true
          end
          task.save(false)
          if task.errors.count > 0
            j += 1
          else
            i += 1
          end
        end
      end
      msg = "#{i} Selected tasks marked completed successfully. " if i > 0
      msg1= "#{j} Completion date can't be greater thant todays date."  if j > 0
      respond_to do |format|
        format.js{
          render :update do |page|
            if msg1.blank?
              page << "tb_remove();"
              flash[:notice]= msg + msg1
              page << "window.location.reload();"
            else
              page << "jQuery('#loader').hide();"
              page << "show_error_msg('modal_complete_task_errors','#{escape_javascript(msg + msg1)}','message_error_div');"
            end
          end
        }
      end
    end
  end

  def mark_as_done_form
    @matter_task = MatterTask.find(params[:id])
    render :partial => "mark_as_done_form"
  end

  def mark_as_done
    data = params
    @matter_task = MatterTask.find(data[:id])
    respond_to do|format|
      format.js {
        unless data[:matter_task].blank?
          @matter_task.completed_at = data[:matter_task][:completed_at]
          @matter_task.completed = true
          @matter_task.zimbra_task_status = true
          render :update do|page|
            if @matter_task.save
              page.call("parent.tb_remove")
              page.call("window.location.reload")
              flash[:notice] = "Task marked completed successfully."
            else
              format_ajax_errors(@matter_task, page, "modal_complete_task_errors")
            end
          end
        end
      }
    end
  end

  def create_matter_task_form
    authorize!(:create_matter_task_form,@user) unless @user.has_access?(:Activities)
    @matter = Matter.find(params[:matter_id], :include => [:employee_document_homes, :client_document_homes])
    params[:matter_task] ||= {}
    params[:matter_task][:matter_id] = @matter.id
    params[:matter_task][:category] ||= "todo"
    params[:from] = "notes"
    @matter_task = @matter.matter_tasks.new(params[:matter_task])
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
    @has_children = false
    @assignees = MatterPeople.current_lawteam_members(@matter.id) 
    @attnds = MatterPeople.get_name_and_email(@matter)
    @note_name = StickyNote.find(params[:note_id], :conditions => {:assigned_to_user_id => assigned_user}) unless params[:note_id].blank?
    unless @note_name.nil?
      params[:note_id] = @note_name.id
    end
    respond_to do |format|
      format.js {
        render :file => 'matter_tasks/create_matter_task.js'          
      }
    end
  end

  def create_task_home
    authorize!(:create_task_home,@user) unless @user.has_access?(:Activities)
    data = params
    @matter = Matter.find(data[:matter_id])
    @other_matter_tasks = @matter.matter_tasks.find_all_by_category('todo')
    @assignees = MatterPeople.current_lawteam_members(@matter.id) #@matter.matter_peoples.find(:all,:conditions=> ["people_type='client'"])
    @matter_task = @matter.matter_tasks.new(data[:matter_task].merge!({:created_by_user_id => current_user.id, :company_id => current_company.id}))
    data[:request_from].present?? @request_from = data[:request_from] : @request_from = nil
    @task_category_types, @appointment_category_types= @matter_task.get_category_types(current_company)
    @has_children = false
    if data[:matter_task][:start_date_appointment].present?
      #Time.zone = current_user.time_zone
      sd = Time.zone.parse(data[:matter_task][:start_date_appointment] + ' ' + data[:matter_task][:start_time]).getutc unless data[:matter_task][:start_date_appointment].blank?
      ed = Time.zone.parse(data[:matter_task][:end_date_appointment] + ' ' + data[:matter_task][:end_time]).getutc unless data[:matter_task][:end_date_appointment].blank?
      @matter_task.start_date_appointment = sd
      #data[:matter_task][:start_date_appointment] = sd
      @matter_task.end_date_appointment = ed
    end
    if data[:matter_task] [:category].eql?('todo')
      @matter_task.start_date_todo =Time.zone.parse(data[:matter_task][:start_date_todo] + ' 12:00 PM') unless data[:matter_task][:start_date_todo].blank?
      @matter_task.end_date_todo =Time.zone.parse(data[:matter_task][:end_date_todo] + ' 12:00 PM') unless data[:matter_task][:start_date_todo].blank?
    else
      data[:matter_task].delete(:parent_id)
      data[:matter_task].delete(:assoc_as)
    end
    data[:matter_task][:attendees_emails] = @matter_task.add_people_attendees(data[:people_attendees_emails], data[:matter_task][:attendees_emails])
    if params[:matter_task][:start_date_appointment]==params[:matter_task][:end_date_appointment] and params[:matter_task][:start_time]==params[:matter_task][:end_time]
      @matter_task.errors.add('Start date','- End date And Start Time - End Time cannot be same')
    end
    respond_to do |format|
      if @matter_task.errors.blank? and @matter_task.save
        flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.js {
          render :update do|page|
            divid="#my#{params[:note_id]}Div"            
            page << "parent.tb_remove();"
            page<<"jQuery('#{divid}').fadeOut('slow');"
            page<<"jQuery('#{divid}').remove();"
            page<<"refreshIfHomePage('#{physical_clientservices_home_index_path}')"
            if data[:note_id]
              page.call "deleteStickyNote",params[:note_id]
            end
          end
        }
      else
        format.js {
          render :update do|page|
            page << "hide_loader()"
            format_ajax_errors(@matter_task, page, "modal_new_task_errors");
            page << "jQuery('#task_home_save').val('Save');"
            page << "jQuery('#task_home_save').attr('disabled','');"
            page << "jQuery('#loader').hide();"
          end
        }
      end
    end
  end

  ##Following two methods "get_issues_facts_risks_researches" and "assign_issues_facts_risks_researches"
  ###added for the Feature #7512 - Link task risk issue fact - all to all
  ###Added by Shripad
  ##These two methods will link risks,facts, researches,issues from the action pad
  def get_issues_facts_risks_researches
    sort_column_order
    @ord = @ord.nil? ? 'name ASC':@ord
    @matter_task = @matter.matter_tasks.find(params[:id])
    @col = @matter.send(params[:col_type]).find(:all, :order => @ord)
    @col_ids = @matter_task.send(params[:col_type_ids])
    @label = params[:label]
    render :layout => false
  end

  def assign_issues_facts_risks_researches
    @matter_task = @matter.matter_tasks.find(params[:id])
    unless params[:matter_task]
      eval("@matter_task.#{params[:dynamic_ids]}=nil")
      @matter_task.save false
    else
      @matter_task.update_attributes(params[:matter_task])
    end
    redirect_to matter_matter_tasks_path(@matter)
  end
  
  def no_action_handled_tasks
    redirect_to :action => "index"
  end

  def show_action_error_handled_tasks
    flash[:error] = "Record does not exists"
    redirect_to :action => "index"
  end

end
