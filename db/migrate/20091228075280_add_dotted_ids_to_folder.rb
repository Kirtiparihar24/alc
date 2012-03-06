class AddDottedIdsToFolder < ActiveRecord::Migration
  def self.up
    add_column :folders, :dotted_ids, :text
    Folder.rebuild_dotted_ids!
  end

  def self.down
    remove_column :folders, :dotted_ids
  end
end
