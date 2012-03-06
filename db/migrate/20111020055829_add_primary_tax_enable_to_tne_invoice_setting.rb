class AddPrimaryTaxEnableToTneInvoiceSetting < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_settings, :primary_tax_enable, :boolean, :default => false
  end

  def self.down
    remove_column :tne_invoice_settings, :primary_tax_enable
  end
end
