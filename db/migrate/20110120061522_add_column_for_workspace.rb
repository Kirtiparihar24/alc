class AddColumnForWorkspace < ActiveRecord::Migration
  def self.up
    add_column(:folders, :for_workspace, :boolean)
  end

  def self.down
    remove_column(:folders, :for_workspace)
  end
end
