class AddColumnInDocumentsTable < ActiveRecord::Migration
  def self.up
    add_column :documents ,:comment_id, :integer
  end

  def self.down
    remove_column :documents ,:comment_id
  end
end
