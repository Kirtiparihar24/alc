class NormalizeMatterTask < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:matter_tasks, :complete_by)
    remove_column(:matter_tasks, :actual_hour_spent)
    remove_column(:matter_tasks, :document_id)
    remove_column(:matter_tasks, :is_milestone)
    remove_column(:matter_tasks, :expected_hours)
    remove_column(:matter_tasks, :billable_hours)
    remove_column(:matter_tasks, :zimbra_task_uid)
  end

  def self.down
    # add removed columns
    add_column(:matter_tasks, :complete_by,:date) 
    add_column(:matter_tasks, :actual_hour_spent,:string) 
    add_column(:matter_tasks, :document_id,:integer) 
    add_column(:matter_tasks, :is_milestone,:boolean) 
    add_column(:matter_tasks, :expected_hours,:string) 
    add_column(:matter_tasks, :billable_hours,:string) 
    add_column(:matter_tasks, :zimbra_task_uid,:string) 
  end
end
