class AddParentAccountFields < ActiveRecord::Migration
  def self.up
    add_column :accounts, :parent_id, :integer
    add_column :accounts, :dotted_ids, :integer
    change_column :contacts, :fax, :text
  end

  def self.down
    remove_column :accounts, :parent_id
    remove_column :accounts, :dotted_ids
    change_column :contacts, :fax, :integer
  end
end
