class AddCompanyLastNameFirst < ActiveRecord::Migration
  def self.up
    add_column :companies, :last_name_first, :boolean, :default => false, :null => false 
  end

  def self.down
    remove_column :companies, :last_name_first
  end
end
