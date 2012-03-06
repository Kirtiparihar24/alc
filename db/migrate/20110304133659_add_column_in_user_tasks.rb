class AddColumnInUserTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :assigned_by_user_id, :integer
  end

  def self.down
    remove_column :tasks, :assigned_by_user_id
  end
end
