class AddStatusColumnToTimeAndExpenseEntry < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :status, :string, {:default=>'Open'}
    add_column :expense_entries, :status, :string, {:default=>'Open'}
  end

  def self.down
    remove_column :time_entries, :status
    remove_column :expense_entries, :status
  end
end
