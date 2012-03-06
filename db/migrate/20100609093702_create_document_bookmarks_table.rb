class CreateDocumentBookmarksTable < ActiveRecord::Migration
  def self.up
    create_table :document_bookmarks do |t|
      t.integer  :document_home_id
      t.integer  :document_id
      t.integer  :user_id
    end  
  end

  def self.down
    drop_table :document_bookmarks
  end
end
