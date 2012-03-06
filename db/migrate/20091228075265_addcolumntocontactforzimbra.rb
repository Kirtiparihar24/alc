class Addcolumntocontactforzimbra < ActiveRecord::Migration
  def self.up
       add_column :contacts, :zimbra_contact_id, :integer
       add_column :contacts, :zimbra_contact_status, :boolean
  end

  def self.down
    remove_column :contacts, :zimbra_contact_id
    remove_column :contacts, :zimbra_contact_status
  end
end
