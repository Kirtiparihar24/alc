class AddColumnParentIdToSubproducts < ActiveRecord::Migration
  def self.up
    add_column :subproducts, :parent_id, :integer
  end

  def self.down
    remove_column :subproducts, :parent_id
  end
end
