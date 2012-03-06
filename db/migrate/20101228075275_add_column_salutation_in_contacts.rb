class AddColumnSalutationInContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :salutation, :string
  end

  def self.down
    remove_column :contacts, :salutation
  end
end
