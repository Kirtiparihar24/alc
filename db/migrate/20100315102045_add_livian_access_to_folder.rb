class AddLivianAccessToFolder < ActiveRecord::Migration
  def self.up
    add_column :folders, :livian_access, :boolean
  end

  def self.down
    remove_column :folders, :livian_access
  end
end
