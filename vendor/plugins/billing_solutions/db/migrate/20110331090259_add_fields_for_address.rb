class AddFieldsForAddress < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices,  :client_address, :string
  end

  def self.down
    remove_column :tne_invoices,  :client_address
  end
end
