class AddMatterTaskIdToTimeExpenseTable < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :matter_task_id, :integer
    add_column :expense_entries, :matter_task_id, :integer
  end

  def self.down
    remove_column :time_entries, :matter_task_id
    remove_column :expense_entries, :matter_task_id
  end
end
