class CreateCompanyEmailSettings < ActiveRecord::Migration
  def self.up
    create_table :company_email_settings do |t|
      t.string :setting_type
      t.text :address
      t.integer  :port
      t.text :domain
      t.text :user_name
      t.string :password
      t.integer  :company_id
      t.boolean :enable_ssl , :default=>false, :null=>false
      t.boolean :enable_starttls_auto ,:default=>false,:null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :company_email_settings
  end
end
