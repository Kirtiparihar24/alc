class AddUserIdToSession < ActiveRecord::Migration
  def self.up
    add_column :sessions, :user_id, :integer
  end

  def self.down
    remove_column :sessions, :user_id
  end
end
