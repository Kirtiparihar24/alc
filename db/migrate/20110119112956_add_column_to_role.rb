class AddColumnToRole < ActiveRecord::Migration
  def self.up
    add_column :roles, :for_wfm, :boolean, :default => false
  end

  def self.down
    remove_column :roles, :for_wfm
  end
end
