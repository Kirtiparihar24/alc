class AddSourceDetailsToContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :source_details, :string
  end

  def self.down
    remove_column :contacts, :source_details
  end
end
