class ModifyCluster < ActiveRecord::Migration
  def self.up
    rename_column(:clusters, :cluster_no, :name)
  end

  def self.down
    rename_column(:clusters, :name, :cluster_no)
  end
end
