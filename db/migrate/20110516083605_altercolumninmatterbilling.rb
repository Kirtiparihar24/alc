class Altercolumninmatterbilling < ActiveRecord::Migration
  def self.up
    change_column :matter_billings, :bill_amount,:float
    change_column :matter_billings, :bill_amount_paid,:float
  end

  def self.down
    change_column :matter_billings, :bill_amount,:integer
    change_column :matter_billings, :bill_amount_paid,:integer
  end
end
