class AddMarkupExpenseEntries < ActiveRecord::Migration
  def self.up
    add_column(:expense_entries, :markup, :integer)
    add_column(:tne_invoice_expense_entries, :markup, :integer)
  end

  def self.down
    remove_column(:expense_entries, :markup)
    remove_column(:tne_invoice_expense_entries, :markup)
  end
end
