class AddColumnsToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :category_id, :integer
    add_column :tasks, :work_subtype_id, :integer
    add_column :tasks, :work_subtype_complexity_id, :integer
    add_column :tasks, :stt, :integer
    add_column :tasks, :tat, :integer
#    change_table :tasks do |t|
#      t.change :name, :text
#    end

  end

  def self.down
    remove_column :tasks, :category_id
    remove_column :tasks, :work_subtype_id
    remove_column :tasks, :work_subtype_complexity_id
    remove_column :tasks, :stt
    remove_column :tasks, :tat
#    change_table :tasks do |t|
#      t.change :name, :string,:default => "", :null => false
#    end
  end
end
