class AddColumnsRetainerFeesToMatters < ActiveRecord::Migration
  def self.up
    add_column :matters, :retainer_fee, :integer
    add_column :matters, :min_retainer_fee, :integer
  end

  def self.down
    remove_column :matters, :retainer_fee
    remove_column :matters, :min_retainer_fee
  end
end
