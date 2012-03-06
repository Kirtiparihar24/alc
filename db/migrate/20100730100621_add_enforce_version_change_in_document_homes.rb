class AddEnforceVersionChangeInDocumentHomes < ActiveRecord::Migration
  def self.up
    add_column :document_homes,:enforce_version_change, :boolean
  end

  def self.down
    remove_column :document_homes, :enforce_version_change
  end
end
