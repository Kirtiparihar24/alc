class Wfm::NotesController < WfmApplicationController
  before_filter :authenticate_user!
  before_filter :update_notifications, :only=>[:edit,:show]
  before_filter :lock_the_note, :only=>[:edit]
  before_filter :get_default_data, :except => [:get_matters_contacts,:get_contact_of_matter,:get_matter_of_contact]
  before_filter :get_note, :only => [:edit, :update, :complete_note, :do_complete_note, :assign_note_form, :assign_this_note, :assign_note]
  before_filter :get_worktypes_and_work_subtypes, :only => [:new,:edit,:complete_note,:get_lawfirm_and_lawyers]
  before_filter :get_notes_and_tasks_count, :only=>[:new,:create,:edit,:update,:show]
  before_filter :assigned_lawyers, :only =>[:edit,:assign_note_form]
  before_filter :get_user_notifications, :only=> [:index, :new, :create, :edit, :update, :show]
  
  #  before_filter :do_transaction, :only => [:create, :update]
  layout 'wfm'

  # if front office manager render those notes that are of the lawyers from clusters assigned to him (that is belonging to current user's lawyer) and created by same type of livia
  # for back office and common pool manager notes created by and assigned to their respective cluster livians
  # if secretary only see notes assigned to him and created by him.
  # notes filtered by searching attributes
  def index
    create_sessions(current_user.role.name,current_user) if session[:sp_session].nil?
    secretary = is_secretary?
    lawyer_user_ids = get_lawyer_user_ids
    livian_user_ids = @user_ids
    created_by_user_ids = lawyer_user_ids
    created_by_user_ids << current_user.id if secretary
    @notes = Communication.get_notes(params,created_by_user_ids,secretary,current_user,livian_user_ids)
    @notes_count = Communication.get_notes_count(lawyer_user_ids, livian_user_ids, secretary, current_user)
    @tasks_count,@overdue_task_count,@upcoming_task_count,@todays_task_count = UserTask.get_task_count(lawyer_user_ids,livian_user_ids,secretary,current_user)
    filtered_list
  end

  # To generate new Note
  # it retrieve all front office worktypes, i.e. worktypes without complexity.
  # in users array,
  # get all lawyers that are belonged to current user

  def new
    @note = Communication.new
    @time_zone = current_user.time_zone
    @livian_users =[]
    set_lawfirm_and_lawyers_val
  end

  # assign note option only for manager
  # note assign current user by default

  def create
    params[:note].merge!(:created_by_user_id=>current_user.id, :assigned_to_user_id => params[:note][:assigned_to_user_id].blank? ? current_user.id : params[:note][:assigned_to_user_id])
    unless params[:note][:assigned_by_employee_user_id] == ""
      employee_user = User.find(params[:note][:assigned_by_employee_user_id])
      params[:note].merge!(:company_id=>employee_user.company_id)
    end
    note = Communication.new(params[:note])
    @document_home = DocumentHome.new()
    errors = note.validate_note_docs(params)
    errors += UserTask.check_validations(params,current_user).join("<br>") unless params[:generate_task].blank?
    responds_to_parent do
      if errors.blank?
        Communication.transaction do
          note.save
          upload_multiple_documents(note,params)
          create_task(note,params)
        end
        render :update do |page|
          page.redirect_to wfm_notes_path
          flash[:notice] = "Note #{note.status == 'complete'? 'completed' : 'created'} successfully"
        end
      else
        render :update do |page|
          page << "show_error_full_msg('altnotice','#{errors}','message_error_div');"
          page << "enableAllSubmitButtons('buttons_to_disable','Save');"
        end
      end
    end
  end
  # all fields are editable if that note is created by current user
  # other wise only note's comment, Priority, Attachment editable

  def edit
    @time_zone = @note.receiver.time_zone
    note_receiver = @note.receiver
    @time_zone = note_receiver.time_zone
    @contacts = Contact.find_all_by_company_id(note_receiver.company_id,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc").collect{|contact|[ contact.full_name, contact.id ]}
    matter_peoples = MatterPeople.find_matter_people(note_receiver.id)
    @matters = Matter.find_matter_peoples_matters(matter_peoples).collect{|matter|[matter.clipped_name, matter.id]}
    set_lawfirm_and_lawyers_val
  end

  def update
    errors = @note.validate_note_docs(params)
    errors += UserTask.check_validations(params,current_user).join("<br>") unless params[:generate_task].blank?
    responds_to_parent do
      if errors.blank?
        Communication.transaction do
          @note.update_attributes(params[:note].merge(:updated_by_user_id => current_user.id))
          upload_multiple_documents(@note,params)
          create_task(@note,params)
        end
        render :update do |page|
          page.redirect_to wfm_notes_path
          flash[:notice] = "Note Updated successfully"
        end
      else
        render :update do |page|
          if params[:task].present?
            page << "show_error_full_msg('altnotice','#{errors}','message_error_div');"
          else
            page << "show_error_full_msg('assign_to_errors','#{errors}','message_error_div');"
          end
          page << "enableAllSubmitButtons('buttons_to_disable','Update');"
        end
      end
    end
  end

  def get_document
    @document = Document.find(:id)
    send_file  @document.data.path, :type => @document.data_content_type, :length=> @document.data_file_size, :disposition => 'attachment'.freeze
  end

  # render contact and users that belong to matter
  def get_matters_contacts_and_users
    user = User.find(params[:user_id])
    contacts = Contact.find_all_by_company_id(user.company_id,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    matter_peoples = MatterPeople.find_matter_people(params[:user_id])
    matters = Matter.find_matter_peoples_matters(matter_peoples)
    @livian_users = User.all_cluster_livian(user.clusters)
    time_zone = user.time_zone
    render :update do |page|
      page.hide "notes_lwayers_list"
      if @livian_users.blank?
        page << "show_error_msg('modal_new_task_errors','No livians are assigned to this lawyer','message_error_div');disableAllSubmitButtons('buttons_to_disable');"
      else
        page << "enableAllSubmitButtons('buttons_to_disable','Save');"
        page.replace_html 'matter_contact_select', :partial=>'matters_contacts_select', :locals=>{:matters=>matters,:contacts=>contacts}
        page.replace_html 'users_select', :partial=>'users_select' unless params[:back_office_task] && params[:back_office_task].eql?('back_office_task')
        page.replace_html 'tasks_0_time_zone', :partial=>'wfm/user_tasks/time_zone', :locals=>{:index=>'0',:time_zone=>"#{time_zone}"}
        page << "update_datepicker_min_date('0')"
      end
    end
  end

  def complete_note
    render :layout => false
  end

  def do_complete_note
    respond_to do |format|
      if params[:complete_comment] != ""
        @note.complete_note(params,current_user.id)
        format.html{
          render :update do |page|
            page << 'tb_remove();'
            page.redirect_to wfm_notes_path
            flash[:notice] = "Note completed successfully"
          end
        }
      else
        format.js{
          render :update do |page|
            page << "jQuery('#TB_ajaxContent').animate({scrollTop: 0}, 1000);show_error_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
          end
        }
      end
    end
  end

  # returns the perticular contact related to the matter
  def get_contact_of_matter
    @selected_contact_id = ""
    unless params[:matter_id] == ""
      matter = Matter.find(params[:matter_id])
      @contacts = [matter.contact]
      @contacts.compact
      @selected_contact_id = matter.contact.id if matter.contact
    else
      user = User.find(params[:lawyer_user_id])
      @contacts = Contact.find_all_by_company_id(user.company_id,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    end
    render :update do |page|
      page.replace_html 'contact_select', :partial=> 'contacts_of_matter', :locals=>{:contacts=>@contacts,:selected_contact_id=>@selected_contact_id}
    end
  end

  #render contacts that is belongin to particular matter.

  def get_matter_of_contact
    unless params[:contact_id] == ""
      contact = Contact.find(params[:contact_id])
      @matters = contact.matters
    else
      user = User.find(params[:lawyer_user_id])
      matter_peoples = MatterPeople.find_matter_people(params[:lawyer_user_id])
      @matters = Matter.find_matter_peoples_matters(matter_peoples)
      @contacts = Contact.find_all_by_company_id(user.company_id,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    end
    render :update do |page|
      page.replace_html 'matter_select', :partial=> 'matters_of_contact', :locals=>{:matters=>@matters}
      if params[:contact_id] == ""
        page.replace_html 'contact_select', :partial=> 'contacts_of_matter', :locals=>{:contacts=>@contacts,:selected_contact_id=>@selected_contact_id}
      end
    end
  end

  #render lawyers that is belonging to particular company.

  def get_assigend_lawyers_of_company
    @lawyer_users = get_company_lawyers(current_user,params[:company_id], params[:model_name])
    render :update do |page|
      page.replace_html 'lawyer_filter_option', :partial=>'wfm/shared/lawyer_filter_select'
    end
  end

  #assign the Note to any livia that is belonging to clusters of note's receiver
  def assign_note_form
    render :layout => false
  end

  #assign the Note to any livia that is belonging to clusters of note's receiver
  def assign_note
    if params[:assign_comment].blank?
      render :update do |page|
        page << "show_error_full_msg('assign_to_errors','Comment can not be blank','message_error_div');"
      end
    else
      @note.update_attributes(:assigned_to_user_id => params[:note][:assigned_to_user_id], :updated_by_user_id => current_user.id)
      create_comment(@note,params[:comment])
      render :update do |page|
        flash[:notice] = 'Note assigned successfully'
        page << 'tb_remove();'
        page.redirect_to wfm_notes_path
      end
    end
  end

  def update_assign_note_user_select
    users_type = params[:users_type]
    note_ids = params[:note_id].split(',')
    @notes=[]
    for note_id in note_ids
      @notes << Communication.find(note_id)
    end
    livian_users = []
    @livian_users = []
    case users_type
    when 'back_office_user'
      livian_users += Cluster.get_back_office_cluster_livians
    when 'cpa'
      livian_users += Cluster.get_common_pool_livian_users
    when 'cluster_users'
      if params[:lawyer_id].blank?
        common_clusters = notes_tasks_common_clusters(@notes)
        livian_users = User.all_cluster_livian(common_clusters)
      else
        lawyer = User.find(params[:lawyer_id])
        livian_users = User.all_cluster_livian(lawyer.clusters)
      end
    end
    livian_users.uniq!
    @livian_users = sort_by_first_name_and_last_name(livian_users) unless livian_users.blank?
    render :update do |page|
      page.replace_html 'users_select', :partial=>'users_select'
    end
  end

  # render Users that is belonging to more than one notes of commman clusters

  def assign_multiple_notes_form
    @note_ids = params[:note_ids].split(',')
    @notes=[]
    for note_id in @note_ids
      @notes << Communication.find(note_id)
    end
    @common_clusters = notes_tasks_common_clusters(@notes)
    @valid = !@common_clusters.blank? && !@common_clusters.class.eql?(String)
    if @valid
      livian_users = User.all_cluster_livian(@common_clusters)
      @livian_users = livian_users.blank? ? "" : livian_users.collect{|user|[user.full_name,user.id]}
    end
    render :layout => false
  end

  # assign multiple notes to one user

  def assign_multiple_notes
    if params[:comment].blank?
      render :update do |page|
        page << "show_error_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
      end
    else
      note_ids = params[:note_ids].split(',')
      notes = Communication.find(note_ids)
      Communication.update_all({:assigned_to_user_id => params[:note][:assigned_to_user_id], :updated_by_user_id => current_user.id},['id in (?)', note_ids])
      for note in notes
        create_comment(note,params[:comment])
      end
      render :update do |page|
        flash[:notice] = 'Note assigned successfully'
        page << 'tb_remove();'
        page.redirect_to wfm_notes_path
      end
    end
  end

  ## autocomplete search for lawfirm and lawyer
  def get_lawfirm_and_lawyers
    if params[:q]
      if current_user.belongs_to_common_pool || current_user.belongs_to_back_office
        lawfirms = Company.search_by_name(params[:q].strip).uniq
      else
        law_value= @assigned_lawfirm_users.map(&:company_id).uniq!
        lawfirms=Company.search_company_name(params[:q],law_value)
      end
      render :partial=>"lawfirm_listings",:locals=>{:lawfirms=>lawfirms}  
    else
      if params[:company_id].blank?
        lawfirm_users = @lawyers.collect{|u| [ u.full_name, u.id ]} if @lawyers
      else
        assigned_lawyers= @lawyers.select{|lawyer| lawyer.company_id == params[:company_id].to_i}
        lawfirm_users = assigned_lawyers.collect{|u| [ u.full_name, u.id ]} if assigned_lawyers
      end
      render :update do |page|
        page.replace_html "lawyers_select", :partial=>"lawyers_select", :locals=>{:lawfirm_users=>lawfirm_users}
        page.show "notes_lwayers_list" unless params[:company_id].blank?
      end
    end
  end

  #### Lock & Unlock the note by Livian
  def allow_lock
    if params[:checked] == "1"
      if !params[:current_user_id].blank?
        locks = Communication.find(params[:note_id]).update_attributes(:lock_by_user_id => "#{params[:current_user_id]}")
      end
    else
      locks = Communication.find(params[:note_id]).update_attributes(:lock_by_user_id => "")
    end
    render :update do |page|
      if params[:checked] == "1"
        flash[:notice] = "Succesfuly locked"
        page.redirect_to wfm_notes_path
      else
        flash[:notice] = "Succesfuly Unlocked"
        page.redirect_to wfm_notes_path
      end
    end
  end
  
  private

  # Find user(livian) from all the clusters which is associated with loggedin user.
  # Return user_ids
  def get_lawyer_user_ids
    @assigned_lawfirm_users.map(&:id)
  end

  # save document that is belonging to note.
  def upload_multiple_documents(note,params)
    if params[:document_home].present?
      document=params[:document_home][:document_attributes]
      Document.upload_multiple_docs_for_task_or_note(document,note,current_user.id,params)
    end
  end

  # getting the unique lawyers, work subtypes, assigned to users and clusters list from tasks for filter options
  def filtered_list
    if !(current_user.belongs_to_common_pool || current_user.belongs_to_back_office)
      @lawfirms = []
      @assigned_lawfirm_users.each do |lawyer|
        @lawfirms << lawyer.company if lawyer.company
      end
      @lawfirms.uniq!
      @logged_by_users = [["----livians----",""]]
      @logged_by_users += @cluster_livian_users.collect{|livian|[livian.full_name,livian.id]}
      @logged_by_users << ["----lawyers----",""]
      @logged_by_users += @assigned_lawfirm_users.collect{|lowyer|[lowyer.full_name,lowyer.id]}
      @lawyers = (params[:search].present? && params[:search][:company_id].present?) ? get_company_lawyers(current_user,params[:search][:company_id],"communications") : @assigned_lawfirm_users
    else
      filtere_list_for_cp_or_bo
    end
  end

  def get_note
    @note = Communication.find(params[:id])
  end

  # This method is to carry out all the actions when data is saved via modal windows
  # Options:
  # option => it is used to display appropriate flash msg in case of edit or create
  # from => if 'iframe' is passed , then 'responds_to_parent' is used, else its not used for normal modal windows

  def action_if_note_created_or_updated(option,from)
    msg = option == 'update' ? "updated" : "created"
    if from.eql?('iframe')
      responds_to_parent do
        render :update do |page|
          page << "enableAllSubmitButtons('buttons_to_disable');tb_remove();window.location.reload();"
          flash[:notice] = "Note "+msg+" successfully"
        end
      end
    elsif from.eql?('assign')
      render :update do |page|
        page << "enableAllSubmitButtons('buttons_to_disable');tb_remove();window.location.reload();"
        flash[:notice] = "Note "+msg+" successfully"
      end
    end
  end

  # This method is to display the error messages in modal windows
  # Options:
  # errors => pass the errors from the calling method
  # from => if 'iframe' is passed , then 'responds_to_parent' is used, else its not used for normal modal windows
  def action_if_note_not_created_or_updated(errors,from)
    if from.eql?('iframe')
      responds_to_parent do
        render :update do |page|
          page << "enableAllSubmitButtons('buttons_to_disable');jQuery('#TB_ajaxContent').animate({scrollTop: 0}, 1000);show_error_msg('modal_new_task_errors','#{escape_javascript(errors.to_s)}','message_error_div');"
        end
      end
    elsif from.eql?('assign')
      render :update do |page|
        page << "enableAllSubmitButtons('buttons_to_disable');jQuery('#TB_ajaxContent').animate({scrollTop: 0}, 1000);show_error_msg('modal_new_task_errors','#{escape_javascript(errors.to_s)}','message_error_div');"
      end
    end
  end

  def create_task(note,params)
    if !params[:complete].blank?
      if !params[:complete_comment].blank?
        work_subtype = WorkSubtype.find(params[:task][:work_subtype_id])
        params[:task].merge!(:work_subtype_complexity_id=> work_subtype.work_subtype_complexities.first.id) if params[:task][:work_subtype_complexity_id].blank?
        category_id = work_subtype.work_type.category.id
        params[:task].merge!(:created_by_user_id =>current_user.id,:assigned_by_employee_user_id =>note.assigned_by_employee_user_id,
          :company_id=>note.company_id,:note_id=>note.id,:status=>"complete",:name=>note.description,:assigned_to_user_id=>current_user.id,
          :completed_by_user_id=>current_user.id,:assigned_by_user_id=>current_user.id,:completed_at=>Time.now,:category_id=>category_id)
        task = UserTask.new(params[:task])
        Notification.create_notification_for_task(task,"Task Completed.",current_user,task.share_with_client) if task.save && task.status == 'complete'
        note.update_attribute(:status,'complete')
        Document.assign_documents(task,note,current_user.id)
        Comment.create(:commentable_type=>"UserTask",:commentable_id=>task.id,:created_by_user_id=>current_user.id,
          :comment=>params[:complete_comment],:company_id=>task.company_id,:title=>"UserTask")
      end
    elsif !params[:generate_task].blank?
      task = UserTask.create_tasks(params,note,current_user.id)
      @errors = task[1]
      note.update_attribute(:status,'complete') if task[0] == params[:tasks].count
    end
  end

  # Save comment of note.
  def create_comment(note,comment_text)
    Comment.create(:commentable_type=>note.class.name,:commentable_id=>note.id,:created_by_user_id=>current_user.id,
      :comment=>comment_text,:company_id=>note.company_id,:title=>note.class.name)
  end

  #assign note to livia.
  def assign_this_note
    if !params[:assign].blank? && !params[:assign_comment].blank?
      @note.update_attributes(:assigned_to_user_id => params[:assigned_to_user_id], :updated_by_user_id => current_user.id)
      create_comment(@note,params[:comment])
    end
  end

  # getting the unique lawyers, work subtypes, assigned to users and clusters list from tasks for filter options
  def filtere_list_for_cp_or_bo
    @lawyers,@lawfirms=[],[]
    if is_secretary?
      created_by_user_ids=@assigned_lawfirm_users.map(&:id)
      created_by_user_ids << current_user.id
      notes = Communication.notes_for_secretary(created_by_user_ids,current_user.id)
    else
      livian_ids = @cluster_livian_users.map(&:id)
      livian_ids = [0] if livian_ids.blank?
      lawyer_ids = @assigned_lawfirm_users.map(&:id)
      lawyer_ids = [0] if lawyer_ids.blank?
      notes = Communication.notes_for_manager(lawyer_ids,livian_ids)
    end
    company_ids  = notes.map(&:company_id).uniq
    @lawfirms = Company.find(company_ids)
    if params[:search].present? && params[:search][:company_id].present?
      @lawyers = get_company_lawyers(current_user,params[:search][:company_id],"communications")
    else
      user_ids = notes.map(&:assigned_by_employee_user_id).uniq
      @lawyers = User.find(user_ids)
    end
    
    if is_team_manager
      @logged_by_users = [["----livians----",""]]
      @logged_by_users += @cluster_livian_users.collect{|livian|[livian.full_name,livian.id]}
      @logged_by_users << ["----lawyers----",""]
      @logged_by_users += @lawyers.collect{|lowyer|[lowyer.full_name,lowyer.id]}
    end
  end

  def get_worktypes_and_work_subtypes
    if belongs_to_back_office?
      @back_office_user = true
      @work_types = WorkType.back_office_work_types
      @lawyers = Employee.get_all_employee_users
    else
      @back_office_user = false
      @work_types = WorkType.livian_work_types
      @lawyers = belongs_to_front_office? ? @assigned_lawfirm_users : Employee.get_all_employee_users
    end
    @lawyers.uniq!
  end

  def assigned_lawyers
    @livian_users = User.all_cluster_livian(@note.clusters).map{|u| [u.full_name, u.id]}
  end

  def  set_lawfirm_and_lawyers_val
    @lawfirms ={}
    if current_user.belongs_to_common_pool || current_user.belongs_to_back_office
      lawfirms = Company.find(:all,:order=>"name ASC")
      lawfirms.each do |lawfirm_user|
        @lawfirms["#{lawfirm_user.id}"]=lawfirm_user.name
      end
    else
      @assigned_lawfirm_users.each do |lawfirm_user|
        @lawfirms["#{lawfirm_user.company.id}"]=lawfirm_user.company.name
      end
    end
  end
end