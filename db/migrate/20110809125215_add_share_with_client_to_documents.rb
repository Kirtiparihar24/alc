class AddShareWithClientToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :share_with_client, :boolean
  end

  def self.down
    remove_column :documents, :share_with_client
  end
end
