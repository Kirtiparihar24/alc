class AddStartAtColumnToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :start_at, :datetime
  end

  def self.down
    remove_column :tasks, :start_at
  end
end
