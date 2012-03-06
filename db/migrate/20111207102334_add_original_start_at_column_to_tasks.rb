class AddOriginalStartAtColumnToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :original_start_at, :datetime
  end

  def self.down
    remove_column :tasks, :original_start_at
  end
end
