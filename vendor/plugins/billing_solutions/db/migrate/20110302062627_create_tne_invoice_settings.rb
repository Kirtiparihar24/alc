class CreateTneInvoiceSettings < ActiveRecord::Migration
  def self.up
    create_table :tne_invoice_settings do |t|
      t.integer :currency_type_id
      t.string  :primary_tax_name
      t.integer :primary_tax_rate
      t.string :secondary_tax_name
      t.integer :secondary_tax_rate
      t.boolean :secondary_tax_rule, :default => false, :null => false
      t.integer :payment_terms
      t.integer :company_id
      t.timestamps
      t.timestamps
    end
  end

  def self.down
    drop_table :tne_invoice_settings
  end
end
