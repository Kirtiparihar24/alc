class AddAssingedToUserIdInMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :assigned_to_user_id, :integer
  end

  def self.down
    remove_column :matter_tasks, :assigned_to_user_id
  end
end
