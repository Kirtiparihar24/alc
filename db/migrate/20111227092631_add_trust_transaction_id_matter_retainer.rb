class AddTrustTransactionIdMatterRetainer < ActiveRecord::Migration
  def self.up
     add_column :matter_retainers, :financial_transaction_id, 'BIGINT'
  end

  def self.down
    remove_column :matter_retainers, :financial_transaction_id
  end
end
