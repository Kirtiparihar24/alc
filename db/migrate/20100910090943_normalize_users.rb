class NormalizeUsers < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:users, :company)
    remove_column(:users, :user_type)
  end

  def self.down
    # add removed columns
    add_column(:users, :company ,:string) 
    add_column(:users, :user_type ,:string) 
  end
end
