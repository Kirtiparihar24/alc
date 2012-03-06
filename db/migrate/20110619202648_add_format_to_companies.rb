class AddFormatToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :format, :string,:limit=>50
  end

  def self.down
    remove_column :companies, :format
  end
end
