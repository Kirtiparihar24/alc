class AddParentIdInDocumentHomes < ActiveRecord::Migration
  def self.up
    add_column :document_homes, :parent_id, :integer
  end

  def self.down
    remove_column :document_homes, :parent_id
  end
end
