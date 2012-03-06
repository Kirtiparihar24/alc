class AddIdsToTimeExpense < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_time_entries, :tne_time_entry_id, :integer
    add_column :tne_invoice_expense_entries, :tne_expense_entry_id, :integer
  end

  def self.down
    remove_column :tne_invoice_time_entries, :tne_time_entry_id
    remove_column :tne_invoice_expense_entries, :tne_expense_entry_id
  end
end
