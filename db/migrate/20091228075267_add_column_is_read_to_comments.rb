class AddColumnIsReadToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :is_read, :boolean
  end

  def self.down
    remove_column :comments, :is_read
  end
end
