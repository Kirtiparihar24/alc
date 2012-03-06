class AddColumnToCompanyForZimbra < ActiveRecord::Migration
  def self.up
    add_column :companies, :zimbra_admin_account_email, :string
    add_column :companies, :zimbra_admin_account_id, :string
    add_column :companies, :zimbra_contact_folder_id, :integer
  end

  def self.down
    remove_column :companies, :zimbra_admin_account_email
    remove_column :companies, :zimbra_admin_account_id
    remove_column :companies, :zimbra_contact_folder_id
  end
end
