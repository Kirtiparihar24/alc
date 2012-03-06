class AlterUserAndContactTables < ActiveRecord::Migration
  def self.up
    remove_column :users, :contact_id
    add_column :contacts, :user_id, :integer
  end

  def self.down
    remove_column :contacts, :user_id
    add_column :users, :contact_id, :integer
  end
end
