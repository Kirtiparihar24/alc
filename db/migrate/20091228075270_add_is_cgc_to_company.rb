class AddIsCgcToCompany < ActiveRecord::Migration
  def self.up
     add_column :companies, :is_cgc, :boolean
  end

  def self.down
    remove_column :companies, :is_cgc
  end
end
