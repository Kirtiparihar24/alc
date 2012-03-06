class AddShareWithClientToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :share_with_client, :boolean
  end

  def self.down
    remove_column :tasks, :share_with_client
  end
end
