class CreateCgcCompanyAccounts < ActiveRecord::Migration
  def self.up
    create_table :cgc_company_accounts ,:force=>true do |t|
      t.integer "cgc_company_id"
      t.integer "company_id"
      t.integer "account_id"
      t.timestamps
    end

    add_index :cgc_company_accounts, :cgc_company_id  
  end

  def self.down
    drop_table :cgc_company_accounts
  end
end
