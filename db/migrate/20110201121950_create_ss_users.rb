class CreateSsUsers < ActiveRecord::Migration
  def self.up
    execute "CREATE SCHEMA single_signon;"
    create_table "single_signon.user_apps" do |t|
      t.integer  :livia_portal_user_id
      t.integer  :helpdesk_user_id
      t.integer  :ces_user_id
      t.string   :auth_token
      t.timestamps
    end

    create_table "single_signon.company_apps" do |t|
      t.integer  :livia_portal_company_id
      t.integer  :helpdesk_company_id
      t.integer  :ces_company_id
      t.timestamps
    end

  end

  def self.down
    drop_table "single_signon.user_apps"
    drop_table "single_signon.company_apps"
    execute "DROP SCHEMA single_signon;"
  end
end
