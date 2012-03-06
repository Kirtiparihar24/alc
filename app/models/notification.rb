class Notification < ActiveRecord::Base
  belongs_to  :user, :foreign_key =>'created_by_user_id'
  belongs_to  :notification, :polymorphic => true
  has_many :document_homes, :as => :mapable
  has_one :document

  named_scope :user_unread_notifications, lambda { | user_id , notify_id | { :conditions =>[ "receiver_user_id = ? AND notification_id = ? AND (is_read IS NULL OR is_read = false)", user_id, notify_id ] } }

  def self.create_notification_for_note(obj,title_text,current_user)
    
    emp = obj.receiver
    assign_user = obj.assigned_to
    notification_users=[]
    managers =[]
    clusters = emp.clusters
    if assign_user.blank?
      notification_users = User.all_cluster_livian(clusters)
    else
      managers = User.all_cluster_manager(clusters)
      notification_users = managers << assign_user
    end
    notification_users.compact!
    notification_users.uniq!
    notification_users.each do |user|
      obj.notifications.create(:receiver_user_id => user.id, :title=>title_text)
    end
  end


  def self.create_notification_for_task(obj,title_text,current_user,share_with_client)
    emp = obj.receiver
    assign_user = obj.assigned_user
    notification_users=[]
    managers =[]
    if current_user.role?('lawyer')
      clusters = emp.clusters
      managers = User.all_cluster_manager(clusters)
      notification_users = managers
      if assign_user.blank? || assign_user.belongs_to_common_pool
        comman_pool_cluster = Cluster.common_pool_clusters
        comman_pool_managers = User.all_cluster_manager(comman_pool_cluster)
        notification_users += comman_pool_managers
      end
      notification_users << assign_user
    else
      notification_users << emp if obj.share_with_client && share_with_client
    end
    notification_users.compact!
    notification_users.uniq!
    notification_users.delete(current_user)
    notification_users.each do |user|
      obj.notifications.create(:receiver_user_id => user.id, :title=>title_text)
    end
  end

  def self.read_notifications(user_id,notification_id)
    Notification.update_all({:is_read => true},["notification_id = ? AND receiver_user_id = ? AND (is_read IS NULL OR is_read = false)",notification_id,user_id])
  end

  def self.read_notifications_for_lawyer(user_id,notification_id, notification_title)
    if ['Comment on Task.', 'Task Completed.'].include?(notification_title)
      Notification.update_all({:is_read => true},["notification_id = ? AND receiver_user_id = ? AND (is_read IS NULL OR is_read = false) AND (title = 'Comment on Task.' OR title = 'Task Completed.') ", notification_id, user_id])
    else
      Notification.update_all({:is_read => true},["notification_id = ? AND receiver_user_id = ? AND (is_read IS NULL OR is_read = false) AND title = ? ", notification_id, user_id, notification_title])
    end
  end
end
