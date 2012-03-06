class RestructureUserRole < ActiveRecord::Migration
  def self.up
    # add removed columns
    add_column(:user_roles, :created_at, :timestamp)
    add_column(:user_roles, :updated_at, :timestamp)
    add_column(:user_roles, :deleted_at, :timestamp)

  end

  def self.down
    # add removed columns
    remove_column(:user_roles, :created_at)
    remove_column(:user_roles, :updated_at)
    remove_column(:user_roles, :deleted_at)

  end
end
