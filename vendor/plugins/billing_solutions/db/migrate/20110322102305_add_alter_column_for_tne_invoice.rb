class AddAlterColumnForTneInvoice < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices, :status_reason, :string
    remove_column :tne_invoices, :status
    add_column :tne_invoices, :tne_invoice_status_id, :integer
  end

  def self.down
    remove_column :tne_invoices, :tne_invoice_status_id
    add_column :tne_invoices, :status, :string
    remove_column :tne_invoices, :status_reason
  end
end
