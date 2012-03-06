class AddExceptionColumnToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :exception_status, :boolean
    add_column :matter_tasks, :exception_start_date, :date
    add_column :matter_tasks, :exception_start_time, :time
    add_column :matter_tasks, :task_id, :integer
  end

  def self.down
    remove_column :matter_tasks, :task_id
    remove_column :matter_tasks, :exception_start_time
    remove_column :matter_tasks, :exception_start_date
    remove_column :matter_tasks, :exception_status
  end
end
