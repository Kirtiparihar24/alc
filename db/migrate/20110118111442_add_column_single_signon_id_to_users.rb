class AddColumnSingleSignonIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :single_signon_id, :string
  end

  def self.down
    remove_column :users, :single_signon_id
  end
end
