class AddRepeatColumnsToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :repeat, :string
    add_column :tasks, :repeat_wday, :integer
    add_column :tasks, :end_at, :date
  end

  def self.down
    remove_column :tasks, :repeat
    remove_column :tasks, :repeat_wday
    remove_column :tasks, :end_at
  end
end
