class MatterColTypeChangeToInt < ActiveRecord::Migration
  def self.up
    add_column :matters, :temp_status,:string
    execute "update matters a set temp_status = (select status from matters b where a.id=b.id)"
    remove_column :matters, :status
    add_column :matters, :status,:integer,:default=>nil
  end

  def self.down
    remove_column :matters, :status
    add_column :matters, :status,:string
    execute "update matters a set status = (select temp_status from matters b where a.id=b.id)"
    remove_column :matters, :temp_status
  end
end
