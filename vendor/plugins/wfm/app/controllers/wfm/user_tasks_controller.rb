class Wfm::UserTasksController < WfmApplicationController
  
  before_filter :authenticate_user!
  before_filter :update_notifications, :only=>[:edit,:show]
  before_filter :get_default_data, :only=>[:new,:index,:create,:edit,:update,:show,:filter_lawyer,:filter_priority,:filter_work_subtype,:filter_assigned_to,:filter_cluster,:task_histroy,:import_task_by_file]
  before_filter :note_belongs_to_user, :only=>[:new]
  before_filter :lock_the_note, :only=>[:new,:create]
  before_filter :find_task_and_new_doc_home, :only=>[:new_documents,:upload_documents]
  before_filter :find_task, :only=>[:edit,:update,:show,:destroy,:complete_task,:reassign_task,:task_histroy,:open_recurring_task,:complete_this_task,:reassign_this_task,:check_for_parent_task]
  before_filter :set_index_and_action_param, :only=>[:get_work_types,:get_users,:get_complexities,:get_work_subtypes,:get_work_types_edit,:get_work_subtypes_edit,:get_complexities_edit]
  before_filter :get_notes_and_tasks_count, :only=>[:new,:create,:edit,:update,:show,:task_histroy,:import_task_by_file]
  before_filter :get_user_notifications, :only=>[:index, :new, :create, :edit, :update, :show, :task_histroy, :import_task_by_file]
  layout 'wfm'

  # render those tasks that are assigned to himself (if logged in user is secretary),else livians belonging to currrent user's clusters
  # return count of notes that are assigned by all lawyers of logged in user's clusters
  def index
    secretary = is_secretary?
    if secretary
      user_ids = [current_user.id]
      cluster_livian_user_ids = @cluster_livian_users.map(&:id)
    else
      cluster_livian_user_ids = @user_ids
      user_ids = get_user_ids
    end
    lawyer_ids = @assigned_lawfirm_users.map(&:id)
    livian_user_ids = @user_ids
    order = set_order_of_tasks(params)
    @tasks = UserTask.get_tasks(params,user_ids,secretary,current_user,cluster_livian_user_ids,lawyer_ids,order)
    filtered_list
    @notes_count = Communication.get_notes_count(lawyer_ids,livian_user_ids,secretary,current_user)
    @tasks_count,@overdue_task_count,@upcoming_task_count,@todays_task_count = UserTask.get_task_count(lawyer_ids,livian_user_ids,secretary,current_user,params)
  end

  # To generate new task from Note
  # it retrieve all front office worktypes, i.e. worktypes without complexity.
  # in users array,
  # 1. get clusters of lawyer for whom the note is created
  # 2. then retrieve all livians belonging to those clusters via for loop
  # thus the 'users' array contains all the livians that are associated with the lawyer's clusters
  # also diffenrentiating livian users based on skill sets(selected skill)
  def new
    @task = UserTask.new
    @time_zone = @note.receiver.time_zone
    if current_user.belongs_to_front_office
      @common_pool_user = false
      @back_office_user = false
    elsif current_user.belongs_to_common_pool
      @common_pool_user = true
      @back_office_user = false
    elsif current_user.belongs_to_back_office
      @common_pool_user = false
      @back_office_user = true
    end
    @work_types = @back_office_user ? WorkType.back_office_work_types : WorkType.livian_work_types
    @from_edit = 'false'
  end

  def edit
    @users_select = []
    @note = @task.communication
    @sub_tasks = UserTask.all_children(@task.id).select{ |task| !task.name.eql?(@task.name) }
    if @task.is_repeat_task?
      future_repeat_tasks = UserTask.open_future_repeat_tasks(@task)
      @doc_and_comment_total = UserTask.find_all_doc(future_repeat_tasks) + UserTask.find_all_comments( future_repeat_tasks) > 0 ? true : false
    end
    @is_parent_task = @sub_tasks.present?
    set_default_task_data(@task)
  end

  # assigning category to task from worksubtype
  # if work subtype complexity in not assigned to task, assigning the default one
  def create
    note = Communication.find(params[:user_task][:note_id])
    cnt,errors=UserTask.create_tasks(params,note,current_user.id)
    if errors.blank?
      note.update_attributes(:status =>'complete')
      cnt>1?flash[:notice] = "#{cnt} tasks successfully assigned." : flash[:notice] = "#{cnt} task successfully assigned."
      render :update do |page|
        page.redirect_to wfm_notes_path
      end
    else
      render :update do |page|
        page << "show_error_full_msg('altnotice','#{errors.join('<br>')}','message_error_div');"
      end
    end
  end

  def update
    parameters = params
    params1 = update_category_complexity_params(@task,parameters)
    params2 = update_stt_tat_params(@task,params1)
    params3 = update_copmleted_params(params2)
    params4 = update_repeat_params(params3)
    params  = update_user_params(params4)
    update_start_due_date_params(parameters, current_user)
    old_due_at = @task.due_at
    errors =[]
    errors << "Comment can not be blank !" if (params[:reassign_user] || params[:complete_task]) && params[:comment_text].blank?
    errors = UserTask.check_validations(params,current_user) if params[:tasks].present?
    is_repeat_before_update = @task.is_repeat_task?
    if errors.uniq.blank? && @task.update_attributes(params[:task].merge(:updated_by_user_id => current_user.id))
      UserTask.create_tasks(params,@task.communication,current_user.id,true) if params[:tasks].present?
      @task.update_due_at(params,old_due_at) if params[:special_handling].present?
      @task.update_repeat_instances if is_repeat_before_update || @task.is_repeat_task?
      Notification.create_notification_for_task(@task,"Task Completed.",current_user,@task.share_with_client) if @task.status == 'complete'
      create_comment(@task,params[:comment_text]) if (params[:reassign_user] || params[:complete_task]) && !params[:comment_text].blank?
      flash[:notice] ="Task updated successfully"
      render :update do |page|
        page.redirect_to :action => 'index'
      end
    else
      @task.errors.each { |e| errors.push(e[1])}
      render :update do |page|
        page << "show_error_full_msg('altnotice','#{errors.join('<br>')}','message_error_div');"
      end
    end
  end

  def destroy
    @task.destroy
    flash[:notice] ="Task deleted successfully"
    redirect_to :action => 'index'
  end

  def show
    @note = @task.communication
  end

  # updating work types select on new page
  def get_work_types
    @task_index = params[:task_index].blank? ? '' : params[:task_index]
    if params[:note_id].blank?
      @note = Communication.new(:assigned_by_employee_user_id=> params[:lawyer_id])
    else
      @note = Communication.find(params[:note_id])
    end
    get_work_types_subtypes_complexities(params)
    render :update do |page|
      page.replace_html 'task_'+@task_index+'_work_types', :partial=>'work_type_select'
      if @has_complexity
        page.show 'task_'+@task_index+'_complexity'
      else
        page.hide 'task_'+@task_index+'_complexity'
      end
    end
  end


  def get_work_types_edit
    get_work_types_subtypes_complexities(params)
    @note = Communication.find(params[:note_id])
    render :update do |page|
      page.replace_html 'task_'+params[:task_index]+'_work_types', :partial=>'work_type_select'
      if @has_complexity && !@work_subtypes.blank?
        page.show 'task_'+@task_index+'_complexity'
        page.replace_html 'task_'+@task_index+'_complexity_select', :partial=>'complexity_select'
      else
        page.hide 'task_'+@task_index+'_complexity'
      end
    end
  end

  # updating work subtypes select on new page
  def get_work_subtypes
    get_note_work_subtypes_complexities(params)
    render :update do |page|
      page.replace_html 'task_'+params[:task_index]+'_work_subtypes', :partial=>'work_subtype_select'
    end
  end

  # updating users select on new page
  def get_users
    work_subtype = WorkSubtype.find(params[:work_subtype_id]) unless params[:work_subtype_id] == "null" || params[:work_subtype_id].blank?
    users,complexity = [],nil
    if params[:user_category_type] == 'ClusterUsers'
      unless params[:task_type].eql?("LivianTask")
        if params[:complexity_id].present? && params[:complexity_id] != 'null'
          complexity = WorkSubtypeComplexity.find(params[:complexity_id])
        else
          complexity = work_subtype.work_subtype_complexities.first if work_subtype
        end
        users = Cluster.get_back_office_cluster_livians
      else
        employee_user = User.find(params[:employee_user_id])
        users =livian_users_of_lawyer(employee_user)
      end
      users.uniq!
    elsif params[:user_category_type] == 'CommonPoolAgent'
      if params[:task_type].eql?("Back Office") || params[:task_type].eql?("BackofficeTask")
        users = Cluster.get_back_office_cluster_livians
        if params[:complexity_id].present?
          complexity = WorkSubtypeComplexity.find(params[:complexity_id])
        else
          complexity = work_subtype.work_subtype_complexities.first if work_subtype
        end
      else
        users = Cluster.get_common_pool_livian_users
      end
    end
    if work_subtype
      differentiat_users_on_skills(users, work_subtype,complexity)
    else
      @users_select = [["no skilled user",""],["-------Other Users-------",""]]
      @users_select += users.collect {|u| [ u.full_name, u.id ]}
    end
    @has_complexity = params[:task_type] != 'LivianTask' && current_user.service_provider.has_back_office_access?
    render :update do |page|
      page.replace_html 'task_'+params[:task_index]+'_users', :partial=>'users_select'
      if @has_complexity
        page.show "tasks_#{params[:task_index]}_complexity_stt_tat_#{complexity.id}"
        page.replace_html "tasks_#{params[:task_index]}_complexity_stt_tat_#{complexity.id}", "<br>#{complexity.complexity_level} -stt: #{complexity.stt} tat: #{complexity.tat}"
      end
    end
  end

  # updating complexity select on new page
  def get_complexities
    work_subtype = WorkSubtype.find(params[:work_subtype_id])
    @complexities = work_subtype.work_subtype_complexities
    render :update do |page|
      page.show 'task_'+@task_index+'_complexity'
      page.replace_html 'task_'+@task_index+'_complexity_select', :partial=>'complexity_select'
    end
  end

  # updating complexity select on edit page
  def get_complexities_edit
    users = []
    work_subtype = WorkSubtype.find params[:work_subtype_id]
    @complexities = work_subtype.work_subtype_complexities
    if params[:reassign] == 'true'
      if params[:user_category_type] == 'ClusterUsers'
        @note = Communication.find(params[:note_id])
        if(params[:task_type]).blank?
          users = livian_users_of_lawyer(@note.receiver)
        else
          users = Cluster.get_back_office_cluster_livians
        end
      elsif params[:user_category_type] == 'CommonPoolAgent'
        if params[:task_type].eql?("Back Office")
          users = Cluster.get_back_office_cluster_livians
        else
          users = Cluster.get_common_pool_livian_users
        end
      end
      if ["CommonPoolAgent","ClusterUsers"].include?(params[:user_category_type])
        if work_subtype.blank?
          @users_select = [["no skilled user",""],["-------Other Users-------",""]]
          @users_select += users.collect {|u| [ u.full_name, u.id ]}
        else
          if params[:task_type].eql?("Back Office")
            differentiat_users_on_skills(users, work_subtype,work_subtype.work_subtype_complexities.first)
          else
            differentiat_users_on_skills(users, work_subtype)
          end
        end
      end
    else
      @complexities = work_subtype.work_subtype_complexities
    end
    render :update do |page|
      if params[:reassign] == 'true' && ["CommonPoolAgent","ClusterUsers"].include?(params[:user_category_type])
        if !current_user.service_provider.has_back_office_access?
          page.hide 'task_'+@task_index+'_complexity'
        else
          page.show 'task_'+@task_index+'_complexity'
          page.replace_html 'task_'+@task_index+'_complexity_select', :partial=>'complexity_select'
        end
        page.replace_html 'task_'+params[:task_index]+'_users', :partial=>'users_select'
      else
        page.show 'task_'+@task_index+'_complexity'
        page.replace_html 'task_'+@task_index+'_complexity_select', :partial=>'complexity_select'
      end
    end
  end

  # adding form for multiple tasks on new task page
  def add_new_task_form
    if params[:note_id].blank?
      @note = Communication.new(:assigned_by_employee_user_id=> params[:lawyer_id])
    else
      @note = Communication.find(params[:note_id])
    end
    @from_edit = params[:from_edit]
    @time_zone = @note.receiver.time_zone
    users = []
    if current_user.belongs_to_front_office
      users = User.all_cluster_livian(@note.clusters)
      @common_pool_user = false
      @back_office_user = false
    elsif current_user.belongs_to_common_pool
      users = Cluster.get_common_pool_livian_users
      @common_pool_user = true
      @back_office_user = false
    elsif current_user.belongs_to_back_office
      users = Cluster.get_back_office_cluster_livians
      @common_pool_user = false
      @back_office_user = true
    end
    @work_types = @back_office_user ? WorkType.back_office_work_types : WorkType.livian_work_types
    first_work_subtype = @work_types.first.work_subtypes.first
    @complexities = first_work_subtype.blank? ? [] : first_work_subtype.work_subtype_complexities
    get_work_subtypes_and_diffentiate_users(users,@work_types)
    render :update do |page|
      page.insert_html :bottom, :new_task_form, :partial=>'task_fields',:locals=>{:index=>params[:task_index]}
    end
  end

  # form for documents upload
  def new_documents
    @document= @document_home.documents.build
    render :layout=> false
  end

  def upload_documents
    if params[:document_home]
      document=params[:document_home][:document_attributes]
      total_size=0
      document[:data].each do |file|
        total_size+=file.size
      end
      if params[:document_home] && total_size < Document::Max_multi_file_upload_size && total_size !=0
        message = Document.upload_multiple_docs_for_task_or_note(document,@task,current_user.id,params)
        if message[:error] != ""
          flash[:error]=message[:error]
        else
          flash[:notice]=message[:notice]
        end
      else
        error = 'File size is not in the correct range [0.1- 50 Mb]'
      end
    else
      error = 'No File selected for upload'
    end
    responds_to_parent do
      render :update do |page|
        if error.blank?
          page.call("tb_remove")
          page.redirect_to  edit_wfm_user_task_path(@task.id)
        else
          page.hide 'loader1'
          error_message = "<ul><li>" + error + "</li></ul>"
          page << "show_error_msg('modal_new_document_errors','#{error_message}','message_error_div');"
          page << "jQuery('.MultiFile-applied').attr('disabled',false);"
          flash[:error] = nil
        end
      end
    end
  end

  # complete task form
  def complete_task
    @comment = Comment.new
    render :layout => false
  end

  # comleting task
  # since we are using ajax requests for edit task now, the format.html block is removed as its not needed.
  # params[:modal] is passed so when a child task is completed via modal window, it should redirect to its parent edit page
  # else if its completed directly from edit page(it doesnt have child tasks), it will redirect to task index
  def complete_this_task
    if params[:comment][:comment].blank?
      render :update do |page|
        page << "show_error_full_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
      end
    else
      @task.update_attributes(:completed_at=>Time.now, :status=>'complete', :completed_by_user_id=>current_user.id)
      create_comment(@task, params[:comment][:comment])
      Notification.create_notification_for_task(@task,"Completed Task.", current_user, @task.share_with_client) if @task.status == 'complete'
      render :update do |page|
        page << 'tb_remove();'
        if params[:modal].present?
          page.redirect_to edit_wfm_user_task_path(@task.parent_task)
        else
          page.redirect_to wfm_user_tasks_path
        end
        flash[:notice] = "Task completed successfully"
      end
    end
  end

  # displays history (activity log) of the document
  def document_history
    document_home = DocumentHome.find(params[:id])
    @documents = document_home.documents.find(:all ,:order =>'created_at desc')
    render :layout => false
  end

  def download_document
    document = Document.find(params[:id])
    send_file document.data.path, :type => document.data_content_type, :length=>document.data_file_size, :disposition => 'attachment'.freeze
  end

  # Document supercede form.
  def supercede_document
    @doc_home = DocumentHome.find(params[:id])
    @document_home=DocumentHome.new
    @document= @doc_home.latest_doc
    render :layout=> false
  end

  def supercede
    @doc_home = DocumentHome.find(params[:doc_id])
    if params[:document_home].present?
      params[:document_home][:created_by_user_id] = current_user.id
      params[:document_home][:employee_user_id] = @doc_home.employee_user_id
    end
    responds_to_parent do
      render :update do |page|
        if params[:document_home].present? && params[:document_home][:data].present? && params[:document_home][:data].size > 0  &&  params[:document_home][:data].size < 15728640 && @doc_home.superseed_document(params[:document_home], false)
          flash[:notice]="#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
          page << "tb_remove();"
          page.redirect_to  edit_wfm_user_task_path(@doc_home.mapable.id)
        else
          err = 'File size is not in the correct range [0.1- 15mb]'
          #flash[:error]="#{t(:text_document)} " "#{t(:flash_cannot_greaterthan_15mb)}"
          error_message = "<ul><li>" + err + "</li></ul>"
          page << "show_error_msg('modal_new_document_errors','#{error_message}','message_error_div');"
        end
      end
    end
  end

  # collecting the livians assigned to lawyer
  def reassign_task
    clusters = @task.receiver.clusters
    users = []
    set_default_task_data(@task)
    if @back_office_task
      users = Cluster.get_back_office_cluster_livians
    else
      users = User.all_cluster_livian(clusters)
    end
    if @task.work_subtype && @back_office_task
      differentiat_users_on_skills(users, @task.work_subtype, @task.work_subtype_complexity)
    elsif @task.work_subtype
      differentiat_users_on_skills(users, @task.work_subtype)
    else
      @users_select = [["no skilled user",""],["-------Other Users-------",""]]
      @users_select += users.collect {|u| [ u.full_name, u.id ]}
    end
    render :layout=> false
  end

  # assingn task from common pool to the logged in service provider
  def get_next_task
    sp = current_user.service_provider
    task = sp.get_next_task(belongs_to_common_pool?,belongs_to_back_office?,belongs_to_front_office?)
    if task
      task.update_attributes(:assigned_to_user_id=>sp.user.id,:assigned_by_user_id=>nil)
      flash[:notice] = t(:flash_new_task_from_queue)
    else
      flash[:error] = t(:warning_task_not_found)
    end
    redirect_to(:action => 'index')
  end

  def reassign_multiple_task_form
    set_task_ids_and_get_users(params)
    render :layout=> false
  end

  def get_users_for_multiple_task_reassign
    if params[:user_category_type] == "ClusterUsers"
      set_task_ids_and_get_users(params)
    elsif params[:user_category_type] == 'CommonPoolAgent'
      users = Cluster.get_common_pool_livian_users
      @users_select = users.collect {|u| [ u.full_name, u.id ]}
    end
    @from_edit = true
    render :update do |page|
      page.replace_html 'task_0_users', :partial=>'users_select'
    end
  end

  def reassign_multiple_tasks
    task_ids = params[:task_ids].split(',')
    tasks=[]
    for task_id in task_ids
      tasks << UserTask.find(task_id)
    end
    if params[:comment_text].present?
      for task in tasks
        assigned_to_user_id = params[:user_type] == 'CommonPool' ? nil : params[:task][:assigned_to_user_id]
        task.update_attributes(:assigned_by_user_id=>current_user.id,:assigned_to_user_id=>assigned_to_user_id)
        create_comment(task,params[:comment_text])
      end
      render :update do |page|
        page << 'tb_remove();'
        page.redirect_to wfm_user_tasks_path
        flash[:notice] = "Tasks reassigned successfully"
      end
    else
      render :update do |page|
        page << "show_error_full_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
      end
    end
  end

  def task_histroy
    @audits = @task.audits.find(:all, :order => 'created_at DESC')
    render :layout=> false
  end

  def check_for_parent_task
    sub_tasks = UserTask.all_children(params[:id]).select{ |task| !task.name.eql?(@task.name) }
    render :update do |page|
      page.replace_html 'sub_tasks_details_toggle_div', :partial=>"sub_task_details", :locals=>{:sub_tasks=>sub_tasks}
    end
  end

  def open_recurring_task
    render :layout=> false
  end

  def import_task_by_file
    @task = UserTask.new
    render :layout=> false
  end

  #create task which is info fetch by excel file.
  def create_import_task_by_file
    task_result = UserTask.import_task_by_excel(params,current_user.id)
    responds_to_parent do
      render :update do |page|
        if task_result[2].blank?
          flash[:notice] = "#{task_result[1]} tasks are successfully save in total tasks #{task_result[0]}"
          page.redirect_to wfm_user_tasks_path
        else
          page << "show_error_full_msg('error_messages','#{task_result[2].flatten.join('<br>')}','message_error_div');"
        end
      end
    end
  end

  def download_xls_format
    send_file RAILS_ROOT+'/public/sample_import_files/tasks_import_file.xls', :type => "application/xls"
  end
  
  # to reassign task via the 'reassign task' modal window or task edit page
  # since we are using ajax requests for edit task now, the format.html block is removed as its not needed.
  def reassign_this_task
    if params[:comment_text].blank?
      render :update do |page|
        page << "show_error_msg('modal_new_task_errors','Comment cannot be blank','message_error_div');"
      end
    else
      params[:task].merge!(:assigned_by_user_id=>current_user.id)
      @task.update_attributes(params[:task])
      create_comment(@task,params[:comment_text])
      render :update do |page|
        page << 'tb_remove();'
        page.redirect_to wfm_user_tasks_path
        flash[:notice] = "Task updated successfully"
      end
    end
  end

  # gives the description of lawyers through ajax
  def get_lawyer_info
     @lawfirm_user = User.find_by_id(params[:id])
     
      render :update do |page|
        #page << "toggle_lawyes_list('#{params[:id]}')"
        page.replace_html "verify_lawyer_div_#{params[:id]}", :partial=>"verify_lawyer", :locals => { :lawfirm_user => @lawfirm_user,:ids => params[:id] }
        #page << "jQuery('#side_bar_lwayers_list').scrollTo( jQuery('#verify_lawyer_div_#{params[:id]}'), 800 )"
        
      end   
     
  end  

  private

  # Find user(lawyer) from all the clusters which is associated with loggedin user.
  # Return user_ids
  def get_user_ids
    @assigned_lawfirm_users.map(&:id)
  end


  # check if the note from which task will be generated belongs to the user
  def note_belongs_to_user
    @note = Communication.find(params[:note_id])
    unless belongs_to_common_pool? || belongs_to_back_office?
      lawyer_ids = get_user_ids
    else
      lawyer_ids = Employee.get_all_employee_users.map(&:id)
    end
    if is_secretary?
      lawyer_ids << current_user.id
      condition = !(lawyer_ids.include? @note.created_by_user_id) && @note.assigned_to_user_id != current_user.id
    else
      condition = !(lawyer_ids.include? @note.assigned_by_employee_user_id or @note.assigned_to_user_id == current_user.id)
    end
    if condition
      flash[:error] = "Note doesn't belogns to logged in user."
      redirect_to :action => 'index'
    end
  end

  # setting the data for edit task
  # 1.Getting the work type from worksubtype assigned to the task
  # 2.Getting worksubtypes of the worktype for work subtype select
  # 3.Getting work subtype comlexities of work subtupe for complexity select
  # 4.Getting work types of the same category as the worktype of the work subtype assigned to task for work type select
  def set_default_task_data(task)
    @work_types = @work_subtypes = @complexities= []
    if task.work_subtype
      @work_subtype = task.work_subtype
      @work_type = @work_subtype.work_type
      @work_subtypes = @work_type.work_subtypes
      @complexities = @work_subtype.work_subtype_complexities
      category = @work_type.category
      @back_office_task = category.has_complexity
      categories = Category.find_with_complexity(category.has_complexity)
      for cat in categories
        @work_types += cat.work_types
      end
    else
      @back_office_task=false
      @work_types = WorkType.livian_work_types
      @work_subtypes = @work_types.first.work_subtypes
    end
    @work_types.uniq!
  end

  # Updating the stt and tat  based on conditions
  def update_stt_tat_params(task,params)
    if params[:task][:work_subtype_complexity_id].present? && params[:task][:work_subtype_complexity_id] != ""
      comp_id = params[:task][:work_subtype_complexity_id].to_i
      if task.work_subtype_complexity_id != comp_id
        complexity = WorkSubtypeComplexity.find(comp_id)
        params[:task][:stt],params[:task][:tat]=complexity.stt,complexity.tat unless params[:special_handling].present?
      end
    end
    params
  end

  # Updating the complexity based on conditions
  def update_category_complexity_params(task,params)
    if params[:task][:work_subtype_id].present? && params[:task][:work_subtype_id] != ""
      work_subtype = WorkSubtype.find(params[:task][:work_subtype_id])
      params[:task][:category_id] = work_subtype.work_type.category_id
      complexities = work_subtype.work_subtype_complexities
      if params[:task__radio_1].present? && params[:task__radio_1]=="LivianTask" && !complexities.blank?
        complexity = complexities.first
        params[:task][:work_subtype_complexity_id] = complexity.id

      elsif params[:task__radio_1].present? && params[:task__radio_1]=="BackofficeTask" && !complexities.blank?
        unless params[:task][:work_subtype_complexity_id].blank?
          complexity = WorkSubtypeComplexity.find(params[:task][:work_subtype_complexity_id])
        else
          complexity = complexities.first
          params[:task][:work_subtype_complexity_id] = complexity.id
        end
      end
      if !params[:special_handling].present? && params[:task][:work_subtype_complexity_id].to_i != task.work_subtype_complexity_id
        params[:task][:stt],params[:task][:tat]=complexity.stt,complexity.tat
      end
    end
    params
  end

  # updating asiigned to user id based on conditions
  def update_user_params(params)
    if params[:reassign_user].present?
      if (params[:user_type] == "CommonPoolAgent" or params[:user_type] == "ClusterUsers") and params[:task][:assigned_to_user_id] ==""
        params[:task].delete(:assigned_to_user_id)
      elsif (params[:user_type] == "CommonPool")
        params[:task].merge!(:assigned_to_user_id => "")
      end
      unless params[:task][:assigned_to_user_id].blank?
        params[:task][:assigned_by_user_id] = current_user.id
      end
    else
      params[:task].delete(:assigned_to_user_id)
    end
    params
  end

  # if complete task is checked while updating task adding appropriate params to complete task
  def update_copmleted_params(params)
    if params[:complete_task].present? && params[:complete_task] == "complete"
      params[:task][:completed_by_user_id] = current_user.id
      params[:task][:completed_at] = Time.now
      params[:task][:status] = 'complete'
    end
    params
  end

  def update_repeat_params(params)
    if params[:task][:repeat] == "WEE"
      wdays = params[:task].delete(:repeat_wday)
      if wdays.blank?
        params[:task][:repeat_wday] = 2
      else
        params[:task][:repeat_wday] = 0
        for val in wdays
          params[:task][:repeat_wday] |= val.to_i
        end
      end
    else
      params[:task][:repeat_wday] = nil
    end
    params
  end

  def create_comment(task,comment_text)
    task.comments.create(:created_by_user_id=>current_user.id, :comment=>comment_text, :company_id=>task.company_id, :title=>"UserTask")
  end

  # separator for user select for skilled users and other users
  def differentiat_users_on_skills(users, work_subtype, work_subtype_complexity = nil)
    skill_users,other_users=[],[]
    for user in users
      if work_subtype_complexity
        complexity = user.work_subtype_complexities.select{|c|c.work_subtype_id==work_subtype.id}.first
        if complexity && complexity.complexity_level >= work_subtype_complexity.complexity_level
          skill_users << user
        else
          other_users << user if user
        end
      elsif user && user.work_subtypes.include?(work_subtype)
        skill_users << user
      else
        other_users << user if user
      end
    end
    @users_select = [["-------Skilled Users-------",""]]
    @users_select += skill_users.collect {|u| [ u.full_name, u.id ]}
    @users_select << ["No skilled User",""] if skill_users.blank?
    @users_select << ["-------Other Users-------",""]
    @users_select += other_users.collect {|u| [ u.full_name, u.id ]}
  end

  def find_task_and_new_doc_home
    @task = UserTask.find(params[:task_id])
    @document_home=DocumentHome.new
  end

  def find_task()
    @task = UserTask.find(params[:id])
  end

  def set_index_and_action_param
    @task_index = params[:task_index]
    @from_edit = params[:from_action].present?
  end


  # getting the unique lawyers, work subtypes, assigned to users and clusters list from tasks for filter options
  def filtered_list
    if !(current_user.belongs_to_common_pool || current_user.belongs_to_back_office)
      @lawfirms = []
      company_ids = @assigned_lawfirm_users.map(&:company_id).uniq
      @lawfirms = Company.find(company_ids)
      @lawyers = (params[:search].present? && params[:search][:company_id].present?) ? get_company_lawyers(current_user,params[:search][:company_id],"user_tasks") : @assigned_lawfirm_users
    else
      filtered_list_for_cp_or_bo
    end
  end

  def livian_users_of_lawyer(employee_user)
    User.all_cluster_livian(employee_user.clusters)
  end

  def get_work_types_subtypes_complexities(params)
    if params[:category_type] == 'LivianTask'
      @work_types= WorkType.livian_work_types
    else
      @work_types= WorkType.back_office_work_types
    end
    @work_subtypes,@complexities=[],[]
    @has_complexity = params[:category_type] != 'LivianTask' && current_user.service_provider.has_back_office_access?
  end

  def get_note_work_subtypes_complexities(params)
    if params[:note_id].blank?
      @note = Communication.new(:assigned_by_employee_user_id=> params[:lawyer_id])
    else
      @note = Communication.find(params[:note_id])
    end
    work_type = WorkType.find(params[:work_type_id])
    @work_subtypes = work_type.work_subtypes
    @has_complexity = (params[:task_type] == "BackofficeTask" || params[:task_type] == "Back Office" ) && current_user.service_provider.has_back_office_access?
  end

  def get_work_subtypes_and_diffentiate_users(users,work_types)
    @work_subtypes = []
    first_work_type = work_types.first unless work_types.blank?
    if !work_types.blank? && first_work_type
      differentiat_users_on_skills(users, first_work_type.work_subtypes.first)
      @work_subtypes = first_work_type.work_subtypes
    else
      @users_select = users.collect {|u| [ u.full_name, u.id ]}
    end
  end

  def set_task_ids_and_get_users(params)
    @task_ids = params[:task_ids].split(',')
    @tasks,users=[],[]
    for task_id in @task_ids
      @tasks << UserTask.find(task_id)
    end
    @common_clusters = notes_tasks_common_clusters(@tasks)
    @no_clusters_assigned = @common_clusters.eql?('Lawyer is not assigned to any clusters.') ? @common_clusters : nil
    @valid = !@common_clusters.blank? && @no_clusters_assigned.blank?
    @same_category = tasks_common_category(@tasks)
    if @valid
      @back_office_tasks = @tasks.collect{|task| task.is_back_office_task?}.include?(false) ? false : true
      if @back_office_tasks
        users = Cluster.get_back_office_cluster_livians
      else
        users = User.all_cluster_livian(@common_clusters)
      end
      @users_select = users.collect {|u| [ u.full_name, u.id ]}
    end
  end

  def filtered_list_for_cp_or_bo
    @lawyers,@lawfirms=[],[]
    if is_secretary?
      tasks = UserTask.find(:all,:select=>'DISTINCT assigned_by_employee_user_id,company_id',:conditions=>"assigned_to_user_id = #{current_user.id}")
    else
      lawyer_ids = @assigned_lawfirm_users.map(&:id)
      lawyer_ids = [0] if lawyer_ids.blank?
      conditions= "assigned_by_employee_user_id in (#{lawyer_ids.join(',')})"
      if current_user.belongs_to_common_pool
        cp_livian = Cluster.get_common_pool_livian_users
        cp_livian_ids = cp_livian.map(&:id)
        cp_livian_ids = [0] if cp_livian_ids.blank?
        bo_work_subtypes = WorkSubtype.back_office_work_subtypes
        bo_work_subtype_ids = bo_work_subtypes.map(&:id)
        bo_work_subtype_ids = [0] if bo_work_subtype_ids.blank?
        conditions = "(" + conditions + " or assigned_to_user_id in (#{cp_livian_ids.join(',')}) or (assigned_to_user_id is null and work_subtype_id not in (#{bo_work_subtype_ids.join(',')})))"
      end
      if current_user.belongs_to_back_office
        skills_id = current_user.get_users_bo_skills.map(&:id)
        conditions = "(" + conditions + ")"  + " or " + "( work_subtype_id in (#{skills_id.join(',')}))" unless skills_id.blank?
      end
      tasks = UserTask.find(:all,:select=>'DISTINCT assigned_by_employee_user_id,company_id',:conditions=>conditions)
    end
    company_ids  = tasks.map(&:company_id).uniq
    @lawfirms = Company.find(company_ids)
    if params[:search].present? && params[:search][:company_id].present?
      @lawyers = get_company_lawyers(current_user,params[:search][:company_id],"user_tasks")
    else
      user_ids = tasks.map(&:assigned_by_employee_user_id).uniq
      @lawyers = User.find(user_ids)
    end
  end

  def get_work_subtype_users(work_subtype)
    users = []
    bo_users = User.all.collect{|user| users << user if user.belongs_to_back_office}
    livian_users = User.all - bo_users
    livian_users.each do |livian_user|
      users << livian_user if livian_user.work_subtypes.include?(work_subtype)
    end
    return users.uniq
  end

  def set_order_of_tasks(params)
    case params[:order_to]
    when 'Client','Assigned To','Assigned By'
      order = "users.first_name #{params[:order_type]}, users.last_name #{params[:order_type]}"
    when 'Task'
      order = "name #{params[:order_type]}"
    when 'Work Sub Type'
      order = "work_subtypes.name #{params[:order_type]}"
    when 'Starts At'
      order = "start_at #{params[:order_type]}"
    when 'Due On'
      order = "due_at #{params[:order_type]}"
    when 'Completed At'
      order = "completed_at #{params[:order_type]}"
    when 'Priority'
      order = "priority #{params[:order_type]}"
    else
      order = 'updated_at DESC'
    end
    order
  end


end
