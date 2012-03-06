class RenameColumnInDocumentHomes < ActiveRecord::Migration
  def self.up
    rename_column :document_homes, :upload_by, :converted_by_user_id
  end

  def self.down
    rename_column :document_homes, :converted_by_user_id, :upload_by
  end
end
