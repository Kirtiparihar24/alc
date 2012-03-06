class AddColumnsToTneInvoiceSettings < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_settings, :header, :string
    add_column :tne_invoice_settings, :footer, :string
  end

  def self.down
    remove_column :tne_invoice_settings, :header
    remove_column :tne_invoice_settings, :footer
  end
end
