class NormalizeAssignment < ActiveRecord::Migration
  def self.up
    # remove timestamps
    remove_column(:assignments, :created_at)
    remove_column(:assignments, :updated_at)
    remove_column(:assignments, :deleted_at)
    # rename assignment table to user_role, as it is user and role map table
    rename_table(:assignments, :user_roles)
    
  end

  def self.down
    # add removed columns
    add_column(:user_roles, :created_at, :timestamp) 
    add_column(:user_roles, :updated_at, :timestamp) 
    add_column(:user_roles, :deleted_at, :timestamp) 
    # rename table with old name
    rename_table(:user_roles, :assignments)
  end
end
