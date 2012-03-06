class NormalizeAsset < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:assets, :document_id)
    remove_column(:assets, :parent_id)
  end

  def self.down
    # add removed columns
    add_column(:assets, :document_id, :integer) 
    add_column(:assets, :parent_id, :integer) 
  end
end
