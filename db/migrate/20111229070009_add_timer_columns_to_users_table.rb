class AddTimerColumnsToUsersTable < ActiveRecord::Migration
  def self.up
    add_column :users, :timer_start_time, :string
    add_column :users, :timer_state, :string
    add_column :users, :base_seconds, :string
  end

  def self.down
    remove_column :users, :timer_start_time
    remove_column :users, :timer_state
    remove_column :users, :base_seconds
  end
end
