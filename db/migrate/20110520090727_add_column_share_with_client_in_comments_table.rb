class AddColumnShareWithClientInCommentsTable < ActiveRecord::Migration
  def self.up
    add_column :comments, :share_with_client, :boolean
  end

  def self.down
    remove_column :comments, :share_with_client
  end
end
