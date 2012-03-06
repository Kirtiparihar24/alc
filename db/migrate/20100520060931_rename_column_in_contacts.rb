class RenameColumnInContacts < ActiveRecord::Migration
  def self.up
    rename_column :contacts, :company, :company_name
  end

  def self.down
    rename_column :contacts, :company_name, :company
  end
end
