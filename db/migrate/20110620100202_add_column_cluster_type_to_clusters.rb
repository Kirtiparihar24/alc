class AddColumnClusterTypeToClusters < ActiveRecord::Migration
  def self.up
    add_column :clusters, :cluster_type, :integer
  end

  def self.down
    remove_column :clusters, :cluster_type
  end
end
