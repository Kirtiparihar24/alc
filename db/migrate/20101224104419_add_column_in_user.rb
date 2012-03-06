class AddColumnInUser < ActiveRecord::Migration
  def self.up
    add_column :users, :is_signedin, :boolean ,:default => false
  end

  def self.down
    remove_column :users, :is_signedin
  end
end
