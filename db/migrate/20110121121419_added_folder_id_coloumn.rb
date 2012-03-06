class AddedFolderIdColoumn < ActiveRecord::Migration
  def self.up
    add_column(:links, :folder_id, :integer)
  end

  def self.down
    remove_column(:links, :folder_id)
  end
end
