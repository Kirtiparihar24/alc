class AddFieldsForTneInvoice < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices,  :primary_tax_name, :string
    add_column :tne_invoices,  :secondary_tax_name, :string
    add_column :tne_invoices,  :consolidated_by, :string
    add_column :tne_invoices,  :view, :string
  end

  def self.down
    remove_column :tne_invoices,  :primary_tax_name
    remove_column :tne_invoices,  :secondary_tax_name
    remove_column :tne_invoices,  :consolidated_by
    remove_column :tne_invoices,  :view
  end
  
end
