class AddColumnViewForTneInvoice < ActiveRecord::Migration
  def self.up
    add_column :tne_invoices, :view_by, :string
  end

  def self.down
    remove_column :tne_invoices, :view_by
  end
end
