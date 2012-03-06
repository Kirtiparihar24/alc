class AlterMatterClientTaskDetailsTable < ActiveRecord::Migration
  def self.up
    remove_column :matter_client_task_details, :from_date
    remove_column :matter_client_task_details, :to_date
    add_column :matter_client_task_details, :from_time, :time
    add_column :matter_client_task_details, :to_time, :time
  end

  def self.down
    remove_column :matter_client_task_details, :from_time
    remove_column :matter_client_task_details, :to_time
    add_column :matter_client_task_details, :from_date, :date
    add_column :matter_client_task_details, :to_date, :date
  end
end
