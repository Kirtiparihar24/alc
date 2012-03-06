class AddMapableToFolders < ActiveRecord::Migration
  def self.up
    add_column :folders, :mapable_type, :string
    add_column :folders, :mapable_id, :integer
#    add_column :folders, :matter_id, :integer
  end

  def self.down
    remove_column :folders, :mapable_type
    remove_column :folders, :mapable_id
#    remove_column :folders, :matter_id
  end
end
