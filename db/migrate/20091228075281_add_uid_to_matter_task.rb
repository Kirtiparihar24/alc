class AddUidToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :zimbra_task_uid, :string
  end

  def self.down
    remove_column :matter_tasks, :zimbra_task_uid
  end
end
