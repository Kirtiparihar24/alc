class AddAliasColumnInCompanyLookup < ActiveRecord::Migration
  def self.up
     add_column :company_lookups, :alvalue, :string
  end

  def self.down
     remove_column :company_lookups, :alvalue
  end
end
