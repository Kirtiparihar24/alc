class AddColumnPercentageComLookup < ActiveRecord::Migration
  def self.up
    add_column :company_lookups, :percentage,:float
  end

  def self.down
    remove_column(:company_lookups, :percentage)
  end
end
