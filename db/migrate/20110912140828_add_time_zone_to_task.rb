class AddTimeZoneToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :time_zone, :string
  end

  def self.down
    remove_column :tasks, :time_zone
  end
end
