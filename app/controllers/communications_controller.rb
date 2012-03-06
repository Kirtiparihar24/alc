class CommunicationsController < ApplicationController
  load_and_authorize_resource :except=>[:edit_task, :update_task,:get_call_recording,:view_within_date_range]
  verify :method => :post , :only => [:create, :update_task]
  verify :method => :put , :only => [:update]
  before_filter :authenticate_user!,:except=>[:get_call_recording]
  before_filter :get_service_session , :only => ['new','named_views_secretarys_task','create',:view_within_date_range]
  skip_before_filter :check_if_changed_password
  helper :sort
  include SortHelper
  # Below code is used in manager portal page for assignning and unassigning the skill to secretaries
  def eligible_secretaries
    comm = Communication.find(params[:commID].to_i, :include => [:receiver => [:service_provider_employee_mappings => [:skills, :service_provider]]])    
    providers = []
    comm.receiver.service_provider_employee_mappings.each do|p|
      p.skills.each do|s|
        if s.skill_type_id == params[:skillID].to_i
          providers << p.service_provider
          break
        end
      end
    end
    @eligible_secretaries = providers
    render :partial => "eligible_secretaries"
  end

  # Below code is before_filter  only for ['new','create','named_views_secretarys_task']
  def get_service_session
    @sp_session = current_service_session
  end

  # Below code execute on clcik of add button while creating session notes entry.
  def add_new_record
    @com_notes_entry= Communication.new
    @index = params[:index].to_i
    matter_contact_records
    render :partial => 'communications/field',:locals=>{:emp_id=>params[:emp_id]}
  end

  # Below code is before_filter  only for ['add_new_record','new']
  def matter_contact_records
    get_comp_id = get_company_id
    @contacts = Contact.get_contact_records(current_company,get_comp_id)   
    @matters = Matter.get_matter_records(get_comp_id, get_employee_user_id)
  end

  # Below code create new notes.
  def new
    # Below code is use to create 4 array object of Communication
    @com_notes_entries= Array.new(4){Communication.new}
    assignmentuser_id = @sp_session.assignment.nil? ? @sp_session.user.id : @sp_session.assignment.user.id
    lawfirm_user = User.find assignmentuser_id
    matter_contact_records
    @salutations = CompanyLookup.get_salutations(lawfirm_user)
    @employee = User.find(assignmentuser_id).employee
    @designations = Designation.get_companys_designation(lawfirm_user.company.id)
    params[:to_date]=(Date.today+1.week).to_s
    @outstanding_tasks = UserTask.get_outstanding_tasks(assignmentuser_id,is_secretary_or_team_manager?,params[:to_date])
    @task_completed = UserTask.get_task_completed_to_secretary(assignmentuser_id,is_secretary_or_team_manager?)
    @my_instructions = Communication.get_my_instructions( lawfirm_user.company.id,assignmentuser_id)
   
    respond_to do |format|
      format.html
      format.js
    end
  end

  # Below code save new notes.
  def create
  
    begin
      UserTask.transaction do
        # Below code is use to append created_by_user_id,performed_by,:user_id,assigned_to to the @com_notes_entries array object.
        com_notes_entries = params[:com_notes_entries].values.collect { |com_notes_entries| Communication.new(com_notes_entries.merge!(:created_by_user_id =>current_user.id,:assigned_to_user_id=>current_user.id,:assigned_by_employee_user_id =>get_employee_user_id,:company_id=>get_company_id))}
        # below code is use to count the number of notes saved.
        cnt=0
        # Below mention transaction block basically revert Task entry and even revert the Communication "status: field to update.
        # Added by Ajay Arsud Date:09 Sept 2010   
        com_notes_entries.each do |com_notes_entries|
          unless com_notes_entries.description.blank?
            com_notes_entries.note_priority = com_notes_entries.note_priority == 0?  1 : 2
            cnt =cnt+1 if com_notes_entries.save!
            if com_notes_entries.is_actionable.eql?(false)
              task = UserTask.new(:name=>com_notes_entries.description,:created_by_user_id=>@current_user.id,:tasktype=>6,:note_id=>com_notes_entries.id,:assigned_by_employee_user_id=>com_notes_entries.assigned_by_employee_user_id,:assigned_to_user_id=>@current_user.id,:status=>'complete',:completed_at =>Time.now,:completed_by_user_id => @current_user.id,:priority=>com_notes_entries.note_priority.to_i == 1? 1 : 2)
              com_notes_entries.update_attributes(:status =>'complete')
              task.save
            end
          end
        end    
        cnt >= 1? (cnt>1?flash[:notice] = "#{cnt} #{t(:text_notes_were)} successfully assigned." : flash[:notice] = "#{cnt} #{t(:text_note_was)} successfully assigned.") : (flash[:error]="Error while assigning the notes. Please enter all details.")
        redirect_to :action => 'new'
      end
    rescue
      redirect_to :action => 'new'
    end
  end

  # Below code is used to show the task detials to edit.
  def edit_task
    authorize!(:edit_task,current_user)unless current_user.role?(:secretary)
    data=params
    @task = UserTask.find(data[:id])
    @asset = @task.note_id if @task 
    @com_notes_entries = Communication.find(@asset, :include => [:receiver => :service_provider_employee_mappings]) #@com_notes_entries.receiver.service_provider_employee_mappings   
    @matters = Matter.team_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id) #FIXME: Is the company id right?
    lawyer_details(@com_notes_entries)    
    @contacts = Contact.all(:conditions => ["company_id = ?", @com_notes_entries.company_id], :order => 'first_name')
    @skill_list = Physical::Liviaservices::SkillType.all
    if data[:previous] =~ /(\d+)\z/
      @previous = UserTask.tracked_by(@current_user).find($1)
    end
    render :layout=> false
  rescue ActiveRecord::RecordNotFound
    @previous ||= $1.to_i
    respond_to_not_found(:js) unless @task
  end

  # Below code is used to update the task.
  def update_task
    authorize!(:update_task,current_user)unless current_user.role?(:secretary)
    data=params
    @note_priority =(data[:com_notes_entries][:note_priority] == 0 ||data[:com_notes_entries][:note_priority].eql?('0'))? 1 : 2
    @task = UserTask.find(data[:id].to_i)
    @com_notes_entries = Communication.find(data[:task][:note_id].to_i)
    if  data[:commit].eql?("Save & Exit")
      respond_to do |format|
        # Below mention transaction block basically revert Task entry and even revert the Communication to update.
        # Added by Ajay Arsud Date:09 Sept 2010
        UserTask.transaction do
          if @task.update_attributes(data[:task].merge!(:assigned_to_user_id => @current_user.id))
            @com_notes_entries.update_attributes(data[:com_notes_entries].merge!(:note_priority=>@note_priority))
            flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"
            format.html {redirect_to physical_liviaservices_livia_secretaries_url}
          else
            flash[:error] = t(:flash_task_error)
            format.html {redirect_to physical_liviaservices_livia_secretaries_url}
          end
        end
      end
    elsif data[:commit].eql?("Assign To")
      # Below mention transaction block basically revert Task entry and even revert the Communication to update.
      # Added by Ajay Arsud Date:09 Sept 2010
      UserTask.transaction do
        @task.update_attributes(data[:task])
        @task.update_attributes(:priority => @note_priority,:assigned_to_user_id => data[:task][:assigned_to_user_id])
        respond_to do |format|
          if @task.save
            data[:com_notes_entries][:note_priority] = @note_priority
            @com_notes_entries.update_attributes(data[:com_notes_entries])
            flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_assigned)}"
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          else
            flash[:error] = t(:flash_task_type)
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          end
        end
      end
    elsif data[:commit].eql?("Complete Task")
      # Below mention transaction block basically revert Task entry and even revert the Communication to update.
      # Added by Ajay Arsud Date:09 Sept 2010
      UserTask.transaction do
        @task.update_attributes(data[:task].merge!(:status => 'complete',:completed_at =>Time.now,:completed_by_user_id => @current_user.id,:assigned_to_user_id => @current_user.id))
        respond_to do |format|
          if @task.save
            if data[:com_notes_entries][:note_priority] == 0 ||data[:com_notes_entries][:note_priority].eql?('0')
              @note_priority = 1
            else
              @note_priority = 2
            end
            @com_notes_entries.update_attributes(data[:com_notes_entries].merge!(:note_priority=>@note_priority))
            flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_completed)}"
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          else
            flash[:error] = t(:flash_task_type)
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          end
        end
      end
    end  
  end

  # Below code is used to covert notes to task.
  def update    
    data=params
    employee = Employee.find(params[:id])
    if update_lawyer_preferences(employee)
      flash[:notice] = "Lawyer preferences updated successfully"
      redirect_to :back
      return true
    else
      flash[:error] = "<ul>" + employee.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
      redirect_to :back
      return false
    end
    @com_notes_entries = Communication.find(data["id"].to_i)
    @note_priority     = (data[:com_notes_entries][:note_priority] == 0 ||data[:com_notes_entries][:note_priority].eql?('0'))? 1 : 2  
    notes = data[:com_notes_entries][:description] if data[:com_notes_entries][:description]
    # Below code is common in "Complete Task" and "Assign To" logic.
    if data[:commit].eql?("Complete Task") || data[:commit].eql?("Assign To")
      notes_type = data[:task][:tasktype] unless data[:task][:tasktype].blank?
      task_details = {}
      task_details.merge!(data[:task])
      task_details.merge!(:name=>notes,:tasktype =>notes_type,:priority=>@note_priority)
    end
    if  data[:commit].eql?("Save & Exit")
      respond_to do |format|        
        if @com_notes_entries.update_attributes(:description=>notes,:more_action =>data[:com_notes_entries][:more_action], :matter_id =>data[:com_notes_entries][:matter_id], :contact_id=>data[:com_notes_entries][:contact_id],:note_priority=>@note_priority.to_i)
          flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"
          format.html {redirect_to physical_liviaservices_livia_secretaries_url}
        else
          format.html { render :action => "show" }
        end
      end
    elsif data[:commit].eql?("Complete Task")        
      task_details.merge!(data[:task])
      task_details.merge!(:assigned_to_user_id =>@current_user.id,:status=>'complete',:completed_at=>Time.now,:completed_by_user_id=>@current_user.id)
      @task= UserTask.new(task_details)
      respond_to do |format|
        # Below mention transaction block basically revert Task entry and even revert the Communication to update.
        # Added by Ajay Arsud Date:09 Sept 2010
        UserTask.transaction do
          if @task.save
            @com_notes_entries = Communication.find(data["id"].to_i)
            @task.update_attributes(:company_id=>@com_notes_entries.company_id)
            @com_notes_entries.update_attributes(:status => 'complete')
            flash[:notice]  = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_completed)}"
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          else
            flash[:error] = t(:flash_task_type)
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          end
        end
      end
    elsif data[:commit].eql?("Assign To")
      task_details.merge!(:assigned_to_user_id =>data[:task][:assigned_to_user_id])
      @task              = UserTask.new(task_details)
      respond_to do |format|
        # Below mention transaction block basically revert Task entry and even revert the Communication to update.
        # Added by Ajay Arsud Date:09 Sept 2010
        Communication.transaction do
          if @task.save
            @com_notes_entries = Communication.find(data["id"].to_i)
            @task.update_attributes(:company_id=>@com_notes_entries.company_id)            
            @com_notes_entries.update_attributes(:status => 'complete')
            flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_assigned)}"
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          else
            flash[:error] = t(:flash_task_type)
            format.html { redirect_to physical_liviaservices_livia_secretaries_url }
          end
        end
      end
    end   
  end

  # Below code is used to show the details of the notes before converting it to task.
  def show
    data=params
    #Below code is to find details for the notes.
    @com_notes_entries = Communication.find(data[:com_id].to_i) #@com_notes_entries.receiver.service_provider_employee_mappings
    @matters = Matter.team_matters(@com_notes_entries.assigned_by_employee_user_id, @com_notes_entries.company_id) #FIXME: Is the company id right?
    lawyer_details(@com_notes_entries) 
    company_id = CompanyLookup.find_by_lvalue_and_company_id("Rejected", @com_notes_entries.company_id).id  
    @contacts = Contact.all(:conditions => ["company_id = ? AND status_type != ?", company_id, @com_notes_entries.company_id], :order => 'first_name')
    @task = UserTask.new
    @skill_list = Physical::Liviaservices::SkillType.all
    if data[:related]
      model, id = data[:related].split("_")
      instance_variable_set("@asset", model.classify.constantize.find(id))
    end
    render :layout => false
  end

  #  # Below code is used when clicked on the "Secretarys Task" in left side bar on communication page.
  def named_views_secretarys_task
    @task_assigned = UserTask.all(:conditions => ["assigned_to_user_id = ? AND (status is null OR status != 'complete')", @sp_session.assignment.user.id], :order => "created_at DESC")
    @task_completed = UserTask.all(:conditions => ["completed_by_user_id = ? AND status like ? AND completed_at >= ?", @sp_session.assignment.user.id, "complete", 1.week.ago], :order => "created_at DESC")
    render :partial => 'named_views_secretarys_task'
  end
  
  # Below code is used in show and edit_task  to get lawyer details.
  def lawyer_details(notes)
    @allowed_ids=[]
    lawyer = Employee.find_by_user_id(notes.assigned_by_employee_user_id, :include => [:company => :employees])
    lawyer.company.employees.each do |employee|
      @allowed_ids << employee.user_id
    end
  end
  
  def get_call_recording
    begin
      Dir.foreach("/media/share")  do |folder|
        unless folder=="." or folder==".." or folder.include?(".rar")
          Dir.foreach("/media/share/#{folder}") do |file_name|
            begin
              if file_name.include?('OUT') && file_name.include?(params[:call_id])
                call_id = file_name.split('OUT').last.split(' ').first
                dd = file_name.slice(13,8)
                sp = dd.split("=")
                note = Communication.first(:conditions => ["call_id = ? AND assigned_to_user_id IN (?)", call_id, sp])
                if note
                  send_file "/media/share/#{folder}/#{file_name}", :type=>'audio/x-wav',:disposition =>'attachment'.freeze
                end
              end
            rescue Exception=>ex
              puts ex.message
            end
          end
        end
      end
    rescue
    end
  end
  
  def view_within_date_range
    template_name_hash = {'outstanding_task_details'=>'fragment-2','completed_action_details'=>"fragment-3"}
    from_date = params[:from_date]
    to_date = params[:to_date]
    option = params[:option]
    current_user_secretary = is_secretary_or_team_manager?
    assignmentuser_id = @sp_session.assignment.nil? ? @sp_session.user.id : @sp_session.assignment.user.id if current_user_secretary
    case option
    when "completed_action_details"
      if current_user_secretary
        if from_date && to_date
          @task_completed = UserTask.all(:select => 'id, share_with_client, created_at, name, completed_at, completed_by_user_id', :conditions => ["assigned_by_employee_user_id IN (?) AND status LIKE 'complete' AND date(completed_at) >= ? AND date(completed_at) <= ? ", assignmentuser_id, from_date, to_date], :order => "created_at DESC")
        else
          @task_completed = UserTask.all(:select => 'id, share_with_client, created_at, name, completed_at, completed_by_user_id', :conditions => ["assigned_by_employee_user_id IN (?) AND status LIKE 'complete' AND date(completed_at) >= ?", assignmentuser_id, 1.week.ago], :order => "created_at DESC")
        end
      else
        @task_completed = UserTask.get_task_completed_to_secretary(current_user.id,current_user_secretary,from_date,to_date)
      end
    when "outstanding_task_details"
      to_date ||= params[:to_date] = (Date.today + 1.week).to_s
      if current_user_secretary
        @outstanding_tasks = UserTask.get_outstanding_tasks(assignmentuser_id,current_user_secretary,to_date)
      else
        @outstanding_tasks = UserTask.get_outstanding_tasks(current_user.id,current_user_secretary,to_date)
      end
    end
    render :update do |page|
      page << "loader.remove();"
      if current_user_secretary
        page.replace_html "#{params[:option]}", :partial=>"/physical/clientservices/home/#{params[:option]}"
      else
        page.replace_html template_name_hash[params[:option]], :partial=>"/physical/clientservices/home/#{params[:option]}"
      end
      page << "livia_datepicker();"
    end
  end
  
  ##### added for search matter and contact for autocomplete
  def get_matter_details
    
    get_comp_id = get_company_id
    @matters =  Matter.search_results(get_company_id, get_employee_user_id, params["q"], true, nil, 'my_all').uniq
    @contacts = Contact.search_communication_contact(params[:q],current_company,get_comp_id)

    respond_to do |format|
      if params[:from] == "matters"
        format.js { render :partial=> 'comm_matter_auto_complete', :object => @matters,:locals=>{:from=>"matters"} }
        format.html { render :partial=> 'comm_matter_auto_complete',:object => @matters,:locals=>{:from=>"matters"} }
      else
        format.js { render :partial=> 'comm_matter_auto_complete', :object => @contacts,:locals=>{:from=>"contacts"}}
        format.html { render :partial=> 'comm_matter_auto_complete', :object => @contacts,:locals=>{:from=>"contacts"}}
      end
    end
  end

  def search_matters_contacts
    if params[:contact_id].present?
      @contacts=Contact.find(params[:contact_id])
      @matters=@contacts.matters.team_matters(get_employee_user_id, get_company_id).uniq
    end
    if params[:matter_id].present?
      @matters=Matter.find(params[:matter_id])
      @contacts=[@matters.contact]
    end
    if params[:contact_id].blank? &&  params[:matter_id].blank?
      @matters = Matter.team_matters(get_employee_user_id, get_company_id)
      @contacts = Contact.find(:all,
        :conditions=>["(company_id =? and status_type!=#{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id})", current_company.id],
        :order => 'first_name')
    end
    render :update do |page|
      if params[:matter_id].present?
        if params[:img_drop]=="drop"
          page.replace_html 'matter_drop_'+params[:formINDEX]+'_span', :partial=>'select_new_matters_contacts', :locals=>  {:from=>"mat",:matter_id=>@matters.id,:value=> params[:value],:formINDEX=>params[:formINDEX]}
        
        end
        page.replace_html 'comm_cnt_'+params[:formINDEX]+'_span', :partial=>'select_new_matters_contacts', :locals=> {:from=>"matters",:matter_id=>@matters.id,:formINDEX=>params[:formINDEX], :spanid=> params[:cnt_span_id]}
      else
        page.replace_html 'matter_drop_'+params[:formINDEX]+'_span', :partial=>'select_new_matters_contacts', :locals=> {:from=>"contacts",:contact_id => @contacts.id,:formINDEX=>params[:formINDEX], :spanid=> params[:cnt_span_id]}
        
      end
      #page << "SearchAutocomplete();"
    end

  end
  #for searchng matter and contact in communication index page by imagedrop
  def get_matter_info
    get_comp_id = get_company_id
    @contacts = Contact.get_contact_records(current_company,get_comp_id)
    @matters = Matter.get_matter_records(get_comp_id, get_employee_user_id)

    render :update do |page|
      if params[:comm_cnt_id].present?
        page.replace_html "contact_drop_#{params[:comm_cnt_id]}_span", :partial=>"verify_matter", :locals => { :contacts => @contacts,:com_id=>params[:comm_cnt_id],:from=>"contacts" }
      else
        page.replace_html "comm_mtr_#{params[:com_id]}_span", :partial=>"verify_matter", :locals => { :matters => @matters,:com_id=>params[:com_id],:from=>"matters" }
      end
    end
  end

  #####
  private
  def update_lawyer_preferences(employee)
    if employee.update_attributes(params[:employee])
      return true
    else
      return false
    end
  end
  
end
