class AddColumnSecondaryTaxEnableInTneInvoiceSettings < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_settings, :secondary_tax_enable, :boolean, :default => true
  end

  def self.down
    remove_column :tne_invoice_settings, :secondary_tax_enable
  end
end
