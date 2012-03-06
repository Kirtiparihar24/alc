class AddColumnsToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :zimbra_task_id, :string
    add_column :matter_tasks, :zimbra_task_status, :boolean
  end

  def self.down
    remove_column :matter_tasks, :zimbra_task_status
    remove_column :matter_tasks, :zimbra_task_id
  end
end
