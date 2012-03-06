class AddTransactionIdInMatterBilling < ActiveRecord::Migration
  def self.up
    add_column :matter_billings, :financial_transaction_id, 'BIGINT'
    add_column :matter_billings, :deleted_at, :timestamp
  end

  def self.down
    remove_column(:matter_billings, :financial_transaction_id)
    remove_column(:matter_billings, :deleted_at)
  end
end
