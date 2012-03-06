class ChangeColumnNameOfCluster < ActiveRecord::Migration
  def self.up
     change_column(:clusters, :name, :string)
  end

  def self.down
     change_column(:clusters, :name, :string)
  end
end
