class AddInvoiceNoteColumnToInvoiceSettings < ActiveRecord::Migration
  def self.up
    add_column :tne_invoice_settings, :invoice_note, :text
  end

  def self.down
    remove_column :tne_invoice_settings, :invoice_note
  end
end

