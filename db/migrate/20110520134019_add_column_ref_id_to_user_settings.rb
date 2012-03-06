class AddColumnRefIdToUserSettings < ActiveRecord::Migration
  def self.up
    add_column :user_settings, :ref_id, :integer
  end

  def self.down
    remove_column :user_settings, :ref_id
  end
end
