class AddcolumncheckNotesintneInvoicetable < ActiveRecord::Migration
  def self.up
    add_column  :tne_invoices, :check_notes ,:boolean ,:default=>false
  end

  def self.down
    remove_column  :tne_invoices, :check_notes
  end
end
