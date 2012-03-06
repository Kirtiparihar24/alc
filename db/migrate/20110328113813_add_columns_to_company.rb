class AddColumnsToCompany < ActiveRecord::Migration
  def self.up
    add_column :companies, :parent_company, :string
    add_column :companies, :subsidiary, :string
    add_column :companies, :general_info, :text
    add_column :companies, :write_up, :text
  end

  def self.down
    remove_column :companies, :write_up
    remove_column :companies, :general_info
    remove_column :companies, :parent_company
    remove_column :companies, :subsidiary
  end
end
