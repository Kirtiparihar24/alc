class AddTempAssignmentColumnsToClusterUsers < ActiveRecord::Migration
  def self.up
    add_column :cluster_users, :from_date, :timestamp
    add_column :cluster_users, :to_date, :timestamp
  end

  def self.down
    remove_column :cluster_users, :from_date
    remove_column :cluster_users, :to_date
  end
end
