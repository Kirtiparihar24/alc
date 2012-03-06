class AddDeletedToInvoices < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices, :deleted_at, :datetime
    add_column :tne_invoice_details, :deleted_at, :datetime
  end

  def self.down
    remove_column :tne_invoices, :deleted_at
    remove_column :tne_invoice_details, :deleted_at
  end
end
