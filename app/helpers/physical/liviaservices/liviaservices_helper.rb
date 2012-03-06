module Physical::Liviaservices::LiviaservicesHelper
  
  # Below code is used to give notes count secretary wise.
  def notes_count(secratary)
    @com_notes_entries= Communication.find(:all,:conditions=>["(status is null  or status != 'complete') and assigned_to_user_id = ?",secratary],:order => "created_at DESC").size
  end

  # Below code is used to give total notes count secretary wise.
  def total_notes_count
    @com_notes_entries= Communication.find(:all,:conditions=>["(status is null  or status != 'complete')"],:order => "created_at DESC").size
  end

  # Below code is used to give oldest notes date,secretary wise.
  def notes_oldest(secratary)
    @com_notes_entries=Communication.find(:last,:conditions=>["(status is null  or status != 'complete') and assigned_to_user_id = ?",secratary],:order => "created_at")
  end

  # Below code is used to give task count secretary wise.
  def task_count(secratary)
    @tasks = UserTask.find(:all, :conditions=>["assigned_to_user_id=? and (status is null  or status != 'complete')",secratary],:order => "created_at DESC").size
  end

  # Below code is used to give total task count secretary wise.
  def total_task_count
    @tasks = UserTask.find(:all, :conditions=>["(status is null  or status != 'complete')"],:order => "created_at DESC").size
  end

  # Below code is used to give oldest task date,secretary wise.
  def task_oldest(secratary)
    @tasks = UserTask.find(:last,:conditions=>["assigned_to_user_id=? and (status is null  or status != 'complete')",secratary],:order => "created_at")
  end

  # Below code is used to give unassigned task count.
  def task_unassigned_count
    @tasks = UserTask.find(:all, :conditions=>["assigned_to_user_id is null and (status is null  or status != 'complete')"],:order => "created_at DESC").size
  end

  # Below code is used to give oldest unassigned task date.
  def task_unassigned_oldest
    @tasks = UserTask.find(:last,:conditions=>["assigned_to_user_id is null and (status is null  or status != 'complete')"],:order => "created_at")
  end 

end