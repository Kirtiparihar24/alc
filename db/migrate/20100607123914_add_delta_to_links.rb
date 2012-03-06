class AddDeltaToLinks < ActiveRecord::Migration
  def self.up
    add_column :links, :delta, :boolean, :default=>true    
  end

  def self.down
    remove_column :links, :delta
  end
end
