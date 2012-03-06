class NormalizeProductLicenceDetail < ActiveRecord::Migration
  def self.up
    # remove unused column
    remove_column(:product_licence_details, :lawyers_id)
  end

  def self.down
    # add removed column
    add_column(:product_licence_details, :lawyers_id, :integer)
  end
end
