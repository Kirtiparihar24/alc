namespace :add_column do

  task :assigned_to_user_id => :environment do
    matter_tasks = MatterTask.find :all
    matter_tasks.each do |matter_task|
      mpid = matter_task.assigned_to_matter_people_id
       userid = User.find(MatterPeople.find(mpid).employee_user_id).id if mpid
       MatterTask.update_all({:assigned_to_user_id => userid},{:id => matter_task.id})
    end
  end

  task :user_name_in_zimbra_acitivity => :environment do
    zimbra_activities = ZimbraActivity.find :all
    zimbra_activities.each do |activity|
      user_name = User.find(activity.assigned_to_user_id).full_name if activity.assigned_to_user_id
      ZimbraActivity.update_all({:user_name => user_name},{:id => activity.id})
    end
  end

end