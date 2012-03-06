class AddOwnFileToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :own_file, :boolean, :default => false
  end

  def self.down
    remove_column :companies, :own_file
  end
end
