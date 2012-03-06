module Wfm::UserTasksHelper

  def get_assigned_by(user_id)
    if user_id.nil?
      return 'Common Queue'
    else
      user = User.find(user_id,:select=>'first_name,last_name')
      return user.full_name
    end

  end

  def get_assigned_to(option,user_id)
    if user_id.present?
      user = User.find_with_deleted(user_id)
      if option.eql?('user')
        return user.full_name
      elsif option.eql?('clusters')
        clusters=[]
        user.clusters.each do |cluster|
          clusters << cluster.name
        end
        return clusters * ", "
      end
    else
      result = option.eql?('user') ? "Common Queue" : "-"
    end
  end

  def edit_task?(task)
    current_user.role?("team_manager") ? true : task.assigned_to_user_id.eql?(current_user.id)
  end

  def is_parent_task(task)
    task.sub_tasks.open_tasks.present?
  end

  def get_time_from_time_zone(date,time_zone)
    date.in_time_zone(time_zone) if date && time_zone
  end

  def get_user_name(user_id)
    User.find_with_deleted(user_id).full_name rescue '-'
  end

  def get_company_name(company_id)
    Company.find(company_id).name rescue '-'
  end

  def get_task_type(task)
    if task.parent_task.present?
      "<span title = 'Sub Task'>#{image_tag 'child_tag.png'}</span>"
    elsif task.sub_tasks.present?
      "<span title = 'Parent Task'>#{image_tag 'parent_tag.png'}</span>"
    end
  end
end