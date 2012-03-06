# devise lockable integrated locking the users after a certain number.
# for which failed_attempts column in users table needs to be default 0 and not nil.
# migration assignes default 0 and updates users column failed_attempts = 0
# Supriya Surve :: 8:26 am :: 02/05/2011
class SetDefaultForUserFailedAttempts < ActiveRecord::Migration
  def self.up
    change_column :users, :failed_attempts, :integer, :default => 0
    User.update_all ["failed_attempts = ?", 0]
  end

  def self.down
    change_column :users, :failed_attempts, :integer, :default => nil
    User.update_all ["failed_attempts = ?", nil]
  end
end
