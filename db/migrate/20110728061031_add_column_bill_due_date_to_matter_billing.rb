class AddColumnBillDueDateToMatterBilling < ActiveRecord::Migration
  def self.up
    add_column :matter_billings, :bill_due_date, :date
  end

  def self.down
   remove_column :matter_billings, :bill_due_date
  end
end
