class CreateMatterBillings < ActiveRecord::Migration
  def self.up
    create_table :matter_billings do |t|
      t.string :bill_no
      t.date :bill_issue_date
      t.date :bill_pay_date
      t.integer :bill_amount
      t.integer :bill_amount_paid
      t.string :bill_status
      t.integer :matter_id
      t.string :remarks
      t.integer :bill_id
      t.integer :created_by_user_id
      t.integer :updated_by_user_id
      t.integer :company_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :matter_billings
  end
end
