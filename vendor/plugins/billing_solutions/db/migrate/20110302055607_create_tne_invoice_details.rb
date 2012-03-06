class CreateTneInvoiceDetails < ActiveRecord::Migration
  def self.up
    create_table :tne_invoice_details do |t|
      t.integer :tne_invoice_id
      t.string :entry_type
      t.integer :matter_id
      t.integer :contact_id
      t.date :tne_entry_date
      t.string :lawyer_designation
      t.string :lawyer_name
      t.float :duration
      t.integer :rate
      t.string :activity
      t.text :description
      t.float :amount
      t.integer :company_id
      t.timestamps
    end
  end

  def self.down
    drop_table :tne_invoice_details
  end
end
