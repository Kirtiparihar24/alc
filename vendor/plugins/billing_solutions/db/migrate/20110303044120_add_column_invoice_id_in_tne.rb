class AddColumnInvoiceIdInTne < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :tne_invoice_id, :integer
    add_column :expense_entries, :tne_invoice_id, :integer
  end

  def self.down
    remove_column :time_entries, :tne_invoice_id
    remove_column :expense_entries, :tne_invoice_id
  end
end
