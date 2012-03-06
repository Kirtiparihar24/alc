class AddColumnParentIdToMatterRisks < ActiveRecord::Migration
  def self.up
    add_column :matter_risks, :parent_id, :integer
  end

  def self.down
    remove_column :matter_riks, :parent_id
  end
end
