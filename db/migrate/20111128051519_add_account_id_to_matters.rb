class AddAccountIdToMatters < ActiveRecord::Migration
  def self.up
    add_column :matters, :account_id, :integer 
  end

  def self.down
    remove_column :matters, :account_id
  end
end
