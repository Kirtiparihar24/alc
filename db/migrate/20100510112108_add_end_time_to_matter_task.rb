class AddEndTimeToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :occurrence_type, :string, :default => "count"
    add_column :matter_tasks, :count, :integer
    add_column :matter_tasks, :until, :date
  end

  def self.down
    remove_column :matter_tasks, :occurrence_type
    remove_column :matter_tasks, :count
    remove_column :matter_tasks, :until
  end
end
