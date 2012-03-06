class AddPrimarySecondaryTaxToInvoiceDetails < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_details, :primary_tax, :boolean, :default => false
    add_column :tne_invoice_details, :secondary_tax, :boolean, :default => false
    add_column :tne_invoice_time_entries, :primary_tax, :boolean, :default => false
    add_column :tne_invoice_time_entries, :secondary_tax, :boolean, :default => false
    add_column :tne_invoice_expense_entries, :primary_tax, :boolean, :default => false
    add_column :tne_invoice_expense_entries, :secondary_tax, :boolean, :default => false
  end

  def self.down
    remove_column :tne_invoice_details, :primary_tax
    remove_column :tne_invoice_details, :secondary_tax
    remove_column :tne_invoice_time_entries, :primary_tax
    remove_column :tne_invoice_time_entries, :secondary_tax
    remove_column :tne_invoice_expense_entries, :primary_tax
    remove_column :tne_invoice_expense_entries, :secondary_tax
  end
end
