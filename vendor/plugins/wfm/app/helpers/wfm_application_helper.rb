# Methods added to this helper will be available to all templates in the application.
module WfmApplicationHelper

  def per_page_pegination_links(params,redirect_url)
    links = "Per Page: "
    if !params[:per_page].present? or params[:per_page] == "10"
      links += "<b>10</b> | "
    else
      url = redirect_url + '?per_page=10'
      url = build_search_url(url,params) if params[:search].present?
      links += (link_to "10", url) + " | "
    end
    if params[:per_page] == "20"
      links += "<b>20</b> | "
    else
      url = redirect_url + '?per_page=20'
      url = build_search_url(url,params) if params[:search].present?
      links += (link_to "20", url) + " | "
    end
    if params[:per_page] == "50"
      links += "<b>50 | </b>"
    else
      url = redirect_url + '?per_page=50'
      url = build_search_url(url,params) if params[:search].present?
      links += (link_to "50", url) + " | "
    end
    if params[:per_page] == "75"
      links += "<b>75 | </b>"
    else
      url = redirect_url + '?per_page=75'
      url = build_search_url(url,params) if params[:search].present?
      links += (link_to "75", url) + " | "
    end
    if params[:per_page] == "100"
      links += "<b>100</b>"
    else
      url = redirect_url + '?per_page=100'
      url = build_search_url(url,params) if params[:search].present?
      links += link_to "100", url
    end
  end

  def alert_image(option,object)
    if option.eql?('task')
      if object.status.eql?('complete')
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_complete.png" title="Complete" alt="Complete" />'
        
      elsif object.due_at.present? && object.due_at.to_date < Date.today
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_high_priority.png" title="Overdue" alt="Overdue" />'

      elsif object.due_at.present? && object.due_at.to_date == Date.today
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_normal_priority.png" title="Today" alt="Today" />'

      elsif object.due_at.present? && object.due_at.to_date > Date.today 
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_medium_priority.png" title="Upcoming" alt="Upcoming" />'
      end
    elsif option.eql?('note')
      if object.status.eql?('complete')
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_complete.png" title="Complete" alt="Complete" />'

      elsif object.created_at.to_date == Time.zone.now.to_date
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_normal_priority.png" title="Today" alt="Today" />'

      elsif object.created_at.to_date < Time.zone.now.to_date-2
        '<img src="/images/../stylesheets/wfm/layout/site/icon/icon_high_priority.png" title="Open for more than 2 days" alt="Open for more than 2 days" />'
      end
    end
  end

  def get_selected_values(params,lawyers)
    if params[:search].present?
      cluster_selected = params[:search][:cluster_id].to_i
      company_selected = params[:search][:company_id].to_i
      params[:search][:employee_user_ids].reject(&:blank?) if params[:search][:employee_user_ids].present?
      if params[:search][:employee_user_ids].present?
        lawyer_selected  = params[:search][:employee_user_ids].collect{|a|a.to_i}
      elsif params[:controller].include?("user_tasks")
        lawyer_selected  = lawyers.map(&:id)
      else
        lawyer_selected  =params[:search][:employee_user_id].to_i
      end
      user_selected     = params[:search][:user_id].to_i
      status_selected   = params[:search][:status]
      my_clusters       = params[:search][:my_clusters] == "1"
      all_clusters      = params[:search][:all_clusters] == "1"
      priority_selected = params[:search][:priority]
      from_date         = params[:search][:from_date].blank? ? date_picker_date_format(Date.today - 7) : params[:search][:from_date]
      to_date           = params[:search][:to_date].blank? ? date_picker_date_format(Date.today) : params[:search][:to_date]
      if params[:search][:due_at].blank?
        due_at          = date_picker_date_format(Date.today + 7.day)
      else
        due_at          = params[:search][:due_at]
      end
    else
      due_at            = date_picker_date_format(Date.today + 7.day)
      from_date         = date_picker_date_format(Date.today - 7)
      to_date           = date_picker_date_format(Date.today)
      lawyer_selected   = lawyers.map(&:id) if params[:controller].include?("user_tasks")
    end
    return from_date,to_date,due_at,my_clusters,all_clusters,priority_selected,cluster_selected,company_selected,lawyer_selected,user_selected,status_selected
  end

  def get_cluster_user(cluster_id,livian_user_id)
    ClusterUser.find_by_cluster_id_and_user_id(cluster_id,livian_user_id)
  end

  def is_temp_livian(cluster_id,livian_user_id)
    cluster_user =  get_cluster_user(cluster_id,livian_user_id)
    cluster_user.present? && cluster_user.from_date.present?
  end

  # styling and events for temporary livian th in manage priority
  def temp_livian(cluster_id,livian_user_id,option) 
    is_temp_livian(cluster_id,livian_user_id) && option == 'style' ? "background:url(layout/site/icon/icon_temp_livian.png) no-repeat left 5px" : ""
  end

  #check given user is manager or not.
  def is_manager(livian_user_id)
    User.find(:first, :joins => [:role], :conditions => ["user_id = ? AND roles.name = ?", livian_user_id, 'team_manager']).present?
  end

  # check whether the notes/tasks 'status' filter is on and are filtered as 'completed'
  def is_completed
    params[:search].present? ? params[:search][:status].eql?('Completed') : false
  end

  def wfm_date_format(date)
    date.strftime("%m/%d/%Y %l:%M:%S %p") if date
  end

  def get_note_priority(priority_id)
    priority_id == 2 ? "<span style='color:red;'>Urgent</span>" : "Normal"
  end

  def document_homes_nil_or_empty?(object)
    !object.document_homes.empty?
  end

  def created_by_logged_in_user?(object)
     object.created_by_user_id == current_user.id
  end

  # this is to get the category name of the front office or livian category on the basis of the condition of 'has_complexity' field
  def get_category_name
    Category.find(:first, :select => ['name'],:conditions=>['has_complexity=?',false]).name rescue ''
  end

  def get_livian_users_work_subtype_ids(livian_user)
    livian_user.work_subtypes.map(&:id)
  end

  def check_presence_of_start_date(task)
     task.start_at.present?
  end

  def date_picker_date_format(date)
    date.strftime("%m/%d/%Y") if date
  end

  def time_picker_format(date)
    date.strftime("%I:%M %p") if date
  end

  #return confirm which user can update check box value on comment or document in user task.
  def disable_check_box?(user)
    !((user.role?("team_manager") || user.role?("secretary")) && (user.eql?(current_user) || is_team_manager))
  end

  def build_search_url(url,params)
    if params[:search].present?
      for key in params[:search].keys
        if params[:search][key].class == Array
          for val in params[:search][key]
            url += ('&search[' + key.to_s + '][]=' + val)
          end
        else
          url += ('&search[' + key.to_s + ']=' + params[:search][key])
        end
      end
    end
    url
  end

  #return full name of completed user
  def get_completed_by(task)
    task.completed_by.full_name rescue '-'
  end

  #return notification count on given notification object such like note or user task.
  def notification_count(notify)
    notifies = Notification.user_unread_notifications(current_user.id, notify.id)
    notifies.count > 0 ? [notifies.first.id, notifies.count] : []
  end

  def sort_tasks_by(order,params)
    order_type =  params[:order_to] == order && params[:order_type] == 'ASC' ? 'DESC' : 'ASC'
    build_search_url(wfm_user_tasks_path(:order_to=>"#{order}", :order_type => "#{order_type}"),params)
  end
end
