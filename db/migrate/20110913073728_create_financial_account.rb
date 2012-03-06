class CreateFinancialAccount < ActiveRecord::Migration
  def self.up
     create_table :financial_accounts do |t|
      t.string    :name
      t.string    :bank_name
      t.column    :account_no, 'BIGINT'
      t.text      :description
      t.text      :address
#      t.integer   :account_type_id
      t.integer   :financial_account_type_id
      t.column    :account_id,'BIGINT'
      t.column    :routing_no,'BIGINT'
      t.column    :matter_id,'BIGINT'
      t.integer   :company_id
      t.string    :status, :default=> 'open'
      t.decimal   :amount, :precision => 18, :scale => 2, :default => 0.00
      t.integer   :created_by
      t.integer   :updated_by
      t.datetime  :deleted_at
      t.timestamps
    end
#    add_index :financial_accounts, ["accountable_id","accountable_type"], :name => ["index_financial_account_on_accountable_id","index_financial_account_on_accountable_type"]
  end

  def self.down
    drop_table :financial_accounts
  end
end
