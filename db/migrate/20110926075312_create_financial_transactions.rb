class CreateFinancialTransactions < ActiveRecord::Migration
  def self.up
    create_table :financial_transactions do |t|
      t.boolean     :transaction_type,:default=> true
      t.boolean     :inter_transfer,:default=> false
      t.datetime    :transaction_date
      t.string      :details
      t.column      :financial_account_id, 'BIGINT'
      t.integer     :company_id
      t.string      :payer
      t.string      :firm_name
      t.text        :address
#      t.integer     :income_type_id
      t.integer     :transaction_status_id
      t.integer     :approval_status_id
#      t.integer     :purpose_id
#      t.integer     :expense_type_id
      t.integer     :created_by
      t.integer     :updated_by
      t.column      :matter_id,  'BIGINT'
      t.column      :account_id, 'BIGINT'
      t.decimal     :amount, :precision => 18, :scale => 2, :default => 0.00
      t.decimal     :balance, :precision => 18, :scale => 2, :default => 0.00
      t.string      :transaction_mode
      t.string      :inter_transfer_relation_token
      t.column      :transaction_no, 'BIGINT'
      t.string      :reference
      t.integer     :approved_by
      t.string      :invoice_no
      t.timestamps
    end
#    add_index :financial_transactions, ["accountable_id","accountable_type"], :name => ["index_financial_transactions_on_accountable_id","index_financial_transactions_on_accountable_type"]
  end

  def self.down
    drop_table :financial_transactions
  end
end
