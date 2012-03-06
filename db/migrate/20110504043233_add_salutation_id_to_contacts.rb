class AddSalutationIdToContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :salutation_id, :integer
  end

  def self.down
    remove_column :contacts, :salutation_id
  end
end
