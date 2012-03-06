class CreateTneInvoices < ActiveRecord::Migration
  def self.up
    create_table :tne_invoices do |t|
      t.string :invoice_no
      t.date :invoice_date
      t.date :invoice_due_date
      t.float :invoice_amt
      t.integer :primary_tax_rate
      t.integer :secondary_tax_rate
      t.integer :discount,:default=>0 ,:null =>false
      t.string :status
      t.text :invoice_notes
      t.float :final_invoice_amt
      t.integer :company_id
      t.boolean :secondary_tax_rule, :default => false, :null => false
      t.integer :created_by_user_id
      t.integer :updated_by_user_id
      t.integer :matter_id
      t.integer :contact_id
      t.timestamps
    end
  end

  def self.down
    drop_table :tne_invoices
  end
end
