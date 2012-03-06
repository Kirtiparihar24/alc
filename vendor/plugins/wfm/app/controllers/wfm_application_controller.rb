# Customised application controller for WFM

class WfmApplicationController < ApplicationController
  skip_before_filter :check_if_changed_password # added by kalpit patel 09/05/11
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  helper_method :get_skills_path

  # Return all clusters associated livians for currentuser
  def cluster_livian
    User.all_cluster_livian(current_user.clusters)
  end

  # Return all cluster livian ids in array
  def cluster_livian_ids
    @cluster_livian_users ||= cluster_livian
    @cluster_livian_users.map(&:id)
  end

  # lawfirm users for right sidebar
  # get lawyers belonging to the same cluster as the livian
  # if logged in user is a secretary, then take current_user.id, else take ids of livians belonging to the current user's cluster
  # getting overdue, upcomming, taoday's tasks counts for alerts on left bottom of the page
  def get_default_data
    @assigned_lawfirm_users = User.all_cluster_lawyer(current_user.clusters)
    if is_secretary?
      @user_ids ||= [current_user.id]
      @cluster_livian_users ||= cluster_livian
    else
      @user_ids ||= cluster_livian_ids
    end
  end

  def get_company_lawyers(user, company_id, model_name)
    users=[]
    if user.belongs_to_common_pool || user.belongs_to_back_office
      if company_id == ""
        if is_secretary?
          created_by_user_ids=@assigned_lawfirm_users.map(&:id)
          created_by_user_ids << user.id
          if model_name == "communications"
            records = Communication.notes_for_secretary(created_by_user_ids,user.id)
          else
            records = UserTask.find(:all,:select=>'DISTINCT assigned_by_employee_user_id,company_id',:conditions=>"assigned_to_user_id = #{current_user.id}")
          end
        else
          livian_ids = @cluster_livian_users.map(&:id)
          livian_ids = [0] if livian_ids.blank?
          lawyer_ids = @assigned_lawfirm_users.map(&:id)
          lawyer_ids = [0] if lawyer_ids.blank?
          if model_name == "communications"
            records = Communication.notes_for_manager(lawyer_ids,livian_ids)
          else
            conditions= "assigned_by_employee_user_id in (#{lawyer_ids.join(',')})"
            if user.belongs_to_common_pool
              cp_livian = Cluster.get_common_pool_livian_users
              cp_livian_ids = cp_livian.map(&:id)
              cp_livian_ids = [0] if cp_livian_ids.blank?
              bo_work_subtypes = WorkSubtype.back_office_work_subtypes
              bo_work_subtype_ids = bo_work_subtypes.map(&:id)
              bo_work_subtype_ids = [0] if bo_work_subtype_ids.blank?
              conditions = "(" + conditions + " or assigned_to_user_id in (#{cp_livian_ids.join(',')}) or (assigned_to_user_id is null and work_subtype_id not in (#{bo_work_subtype_ids.join(',')})))"
            else
              skills_id = user.get_users_bo_skills.map(&:id)
              conditions = "(" + conditions + ")"  + " or " + "( work_subtype_id in (#{skills_id.join(',')}))" unless skills_id.blank?
            end
            records = UserTask.find(:all,:select=>'DISTINCT assigned_by_employee_user_id,company_id',:conditions=>conditions)
          end
        end
        user_ids = records.map(&:assigned_by_employee_user_id)
        users = User.find(user_ids)
      else
        users = Company.find(company_id.to_i).employees.map(&:user)        
      end
    else
      users = company_id == "" ? @assigned_lawfirm_users : @assigned_lawfirm_users.select{|lawyer| lawyer.company_id == company_id.to_i }
    end
    users.compact.uniq
  end

  def notes_tasks_common_clusters(objects)
    lawyers=[]
    for obj in objects
      lawyers << obj.receiver
    end
    lawyers.uniq!
    cl = lawyers.pop.clusters
    return 'Lawyer is not assigned to any clusters.' if cl.blank?
    for lawyer in lawyers
      cl = cl & lawyer.clusters
    end
    cl
  end

  def tasks_common_category(tasks)
    complexity = []
    for task in tasks
      if task.category
        complexity << task.is_back_office_task?
      end
    end
    return  complexity.uniq.size <= 1
  end

  def get_skills_path
    skills_path = belongs_to_back_office? ? skills_by_backoffice_agents_wfm_user_work_subtypes_path : wfm_user_work_subtypes_path
  end

  def get_alert_task_counts
    secretary = is_secretary?
    lawyer_ids = @assigned_lawfirm_users.map(&:id)
    livian_user_ids = @user_ids
    @overdue_task_count,@upcoming_task_count,@todays_task_count = UserTask.get_alert_task_counts(lawyer_ids,livian_user_ids,secretary,current_user)
  end

  def sort_by_first_name_and_last_name(users)
    users.sort { |a,b| [a.first_name.downcase,a.last_name.downcase] <=> [b.first_name.downcase,b.last_name.downcase] }
  end

  def update_start_due_date_params(params,user)
    if !params[:task][:start_at].blank?
      start_time = params[:task][:start_time].present? ? params[:task][:start_time] : "00:00:00"
      task_start_date = DateTime.parse(params[:task][:start_at])
      start_date = task_start_date.strftime("%d-%m-%Y")
      lawyer_tz = params[:task][:time_zone]
      livian_tz = user.time_zone
      diff = (task_start_date.in_time_zone(lawyer_tz).utc_offset) - (task_start_date.in_time_zone(livian_tz).utc_offset)
      new_start_date = DateTime.parse(start_date+" "+start_time)
      params[:task][:start_at] = new_start_date.advance(:seconds=> -diff).strftime("%d-%m-%Y %H:%M:%S")
    end
    if !params[:task][:due_at].blank?
      due_time = params[:task][:due_time].present? ? params[:task][:due_time] : "23:59:59"
      task_due_date = DateTime.parse(params[:task][:due_at])
      due_date = task_due_date.strftime("%d-%m-%Y")
      lawyer_tz = params[:task][:time_zone]
      livian_tz = user.time_zone
      diff = (task_due_date.in_time_zone(lawyer_tz).utc_offset) - (task_due_date.in_time_zone(livian_tz).utc_offset)
      new_due_date = DateTime.parse(due_date+" "+due_time)
      params[:task][:due_at] = new_due_date.advance(:seconds=> -diff).strftime("%d-%m-%Y %H:%M:%S")
    end
    params[:task].delete_if{|k,v| k.eql?('due_time') || k.eql?('start_time')}
  end

  def get_notes_and_tasks_count
    secretary = is_secretary?
    lawyer_ids = @assigned_lawfirm_users.map(&:id)
    livian_user_ids = @user_ids
    @notes_count = Communication.get_notes_count(lawyer_ids,livian_user_ids,secretary,current_user)
    @tasks_count,@overdue_task_count,@upcoming_task_count,@todays_task_count = UserTask.get_task_count(lawyer_ids,livian_user_ids,secretary,current_user)
  end

  def update_notifications
    Notification.read_notifications(current_user.id,params[:id])
  end

  def get_user_notifications
    @notifications = current_user.one_time_notifications
    @unread_notification = current_user.open_notifications_count.open_notifications
  end

  def lock_the_note
    if params[:id]
      note_id= params[:id]
    else
      note_id= params[:note_id]
    end
    note= Communication.find_by_id(note_id)
    user_name = User.find_by_id(note.lock_by_user_id)
    if note.lock_by_user_id.present? &&  note.lock_by_user_id != current_user.id
      flash[:error]="#{user_name.first_name} #{user_name.last_name}  has locked Please Unlock"
      redirect_to wfm_notes_path
    elsif note.lock_by_user_id.blank? && note.assigned_by_employee_user_id == note.created_by_user_id
      flash[:error]="Please lock the note first"
      redirect_to wfm_notes_path
    end
  end

  
end
