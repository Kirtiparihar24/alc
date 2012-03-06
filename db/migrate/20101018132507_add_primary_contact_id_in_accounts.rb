class AddPrimaryContactIdInAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :primary_contact_id, :integer
  end

  def self.down
    remove_column :accounts, :primary_contact_id
  end
end
