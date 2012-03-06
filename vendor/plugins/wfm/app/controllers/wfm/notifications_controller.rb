class Wfm::NotificationsController < WfmApplicationController
  before_filter :authenticate_user!

  def show
    obj = ''
    if params[:notify_id].blank?
      obj = Notification.find(params[:id])
    else
      obj = Notification.find(:first, :conditions => ['receiver_user_id = ? AND notification_id = ? AND (is_read IS NULL OR is_read = false)',current_user.id, params[:notify_id]])
    end
    if current_user.role?('lawyer')
      Notification.read_notifications_for_lawyer(current_user.id, obj.notification_id, obj.title)
    else
      Notification.read_notifications(current_user.id, obj.notification_id)
    end
    type = obj.notification_type
    notify= obj.notification
    if type == "UserTask"
      notify_name = notify.name.size > 50 ? notify.name[0..47].gsub(/[^0-9A-Za-z]/, '') + '...' : notify.name.gsub(/[^0-9A-Za-z]/, '')
      if notify.status == "complete"
        if current_user.role?('lawyer')
          url = obj.title == "Document Upload for Task." ? "tb_show('#{notify_name} Document','#{wfm_new_document_home_path('UserTask', notify.id,:height=>350,:width=>800)}?height=250&width=700','');" : "tb_show('#{notify_name} Comment','#{add_comment_with_grid_comments_path(:id=>notify.id,:commentable_type=>'UserTask',:path=> root_path)}?height=250&width=700','');"
        else
          url = wfm_user_task_path(notify)
        end
      else
        if current_user.role?('lawyer')
          url = obj.title == "Document Upload for Task." ? "tb_show('#{notify_name} Document','#{wfm_new_document_home_path('UserTask', notify.id)}?height=350&width=800','');" : "tb_show('#{notify_name} Comment','#{add_comment_with_grid_comments_path(:id=>notify.id,:commentable_type=>'UserTask',:path=> root_path)}?height=350&width=800','');"
        else
          url = edit_wfm_user_task_path(notify)
        end
      end
    else
      if notify.status == "complete"
        url = wfm_notes_path()
      else
        url = current_user.role?('lawyer') ? "tb_show('#{notify.name} Document','#{wfm_new_document_home_path('Communication', notify.id)}?height=350&width=800','');" : edit_wfm_note_path(notify)
      end
    end
    if current_user.role?('lawyer')
      render :update do |page|
        limit = params[:limit].present? ? params[:limit] : 3
        @notifications = current_user.notifications.find(:all, :limit => limit)
        t_unread_notifications = current_user.open_notifications_count.open_notifications
        task_on_notifications = Notification.user_unread_notifications(current_user.id, obj.notification.id).count
        if t_unread_notifications == '0'
          page.replace_html "task_#{obj.notification.id}_notify_link" , ''
          page.replace_html "message-count" , ""
        else
          page.replace_html "message-count" , t_unread_notifications
          if task_on_notifications <= 0
            page.replace_html "task_#{obj.notification.id}_notify_link" , ''
          else
            page.replace_html "task_#{obj.notification.id}_notify_count", task_on_notifications
          end
        end
        page.replace_html 'notification_div', :partial=>'layouts/notifications'
        page << url
      end
    else
      render :update do |page|
        page.redirect_to url
      end
    end
  end

  def more_notifications
    limit = params[:limit].present? ? params[:limit] : 3
    @notifications = current_user.notifications.find(:all, :limit => limit)
    render :update do |page|
      page.replace_html 'notification_div', :partial=>'layouts/notifications'
    end
  end

end

