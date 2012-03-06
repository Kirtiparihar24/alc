class AddDeltaForCompliance < ActiveRecord::Migration
  def self.up
    add_column :compliances, :delta, :boolean, :default=>true, :null=>false
    add_column :compliance_items, :delta, :boolean, :default=>true, :null=>false
  end

  def self.down
    remove_column :compliances, :delta
    remove_column :compliance_items, :delta
  end
end
