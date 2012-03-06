class AddPTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :p_token, :string
  end

  def self.down
    remove_column :users, :p_token
  end
end
