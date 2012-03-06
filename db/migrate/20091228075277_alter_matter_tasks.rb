class AlterMatterTasks < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :category, :string
    add_column :matter_tasks, :location, :string
    add_column :matter_tasks, :priority, :string
    add_column :matter_tasks, :progress, :string
    add_column :matter_tasks, :progress_percentage, :string
    add_column :matter_tasks, :start_date, :string
    add_column :matter_tasks, :end_date, :string
    add_column :matter_tasks, :show_as, :string
    add_column :matter_tasks, :mark_as, :string
    add_column :matter_tasks, :all_day_event, :boolean
    add_column :matter_tasks, :start_time, :time
    add_column :matter_tasks, :end_time, :time
    add_column :matter_tasks, :repeat, :string
    add_column :matter_tasks, :reminder, :string
  end

  def self.down
    remove_column :matter_tasks, :category
    remove_column :matter_tasks, :location
    remove_column :matter_tasks, :priority
    remove_column :matter_tasks, :progress
    remove_column :matter_tasks, :progress_percentage
    remove_column :matter_tasks, :start_date
    remove_column :matter_tasks, :end_date
    remove_column :matter_tasks, :show_as
    remove_column :matter_tasks, :mark_as
    remove_column :matter_tasks, :all_day_event
    remove_column :matter_tasks, :start_time
    remove_column :matter_tasks, :end_time
    remove_column :matter_tasks, :repeat
    remove_column :matter_tasks, :reminder
  end
end
