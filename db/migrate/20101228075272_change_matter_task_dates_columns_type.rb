class ChangeMatterTaskDatesColumnsType < ActiveRecord::Migration
  def self.up
    remove_column :matter_tasks, :start_date
    remove_column :matter_tasks, :end_date
    add_column :matter_tasks, :start_date, :date
    add_column :matter_tasks, :end_date, :date
  end

  def self.down
    remove_column :matter_tasks, :start_date
    remove_column :matter_tasks, :end_date
    add_column :matter_tasks, :start_date, :string
    add_column :matter_tasks, :end_date, :string
  end
end
