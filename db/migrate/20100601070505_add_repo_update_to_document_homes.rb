class AddRepoUpdateToDocumentHomes < ActiveRecord::Migration
  def self.up
    add_column :document_homes,:repo_update,:boolean
  end

  def self.down
    remove_column :document_homes,:repo_update
  end
end
