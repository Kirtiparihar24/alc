# Feature 6464 : Creator v/s Owner for document creation
# owner_user_id column added to document_homes folder
# run rake update_owner:for_document_homes after this
# Supriya Surve : 26th May 2011, 13:44
class AddOwnerToDocumentHomes < ActiveRecord::Migration
  def self.up
    add_column :document_homes, :owner_user_id, :integer
  end

  def self.down
    remove_column :document_homes, :owner_user_id
  end
end
