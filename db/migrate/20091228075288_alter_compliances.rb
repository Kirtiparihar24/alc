class AlterCompliances < ActiveRecord::Migration
  def self.up
    add_column :compliances, :status, :string, :limit=>32
  end

  def self.down
    remove_column :compliances, :status
  end
end
