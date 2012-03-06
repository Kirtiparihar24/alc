class AddColumnAddressModifiedToTneInvoices < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices,:address_modified,:boolean,:default => false
  end

  def self.down
    remove_column :tne_invoices ,:address_modified
  end
end
