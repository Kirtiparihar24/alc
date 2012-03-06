class AddMiddleNameToContact < ActiveRecord::Migration
  def self.up
    add_column :contacts, :middle_name, :string, :limit => 64,:default=>''
  end

  def self.down
    remove_column :contacts, :middle_name
  end
end
