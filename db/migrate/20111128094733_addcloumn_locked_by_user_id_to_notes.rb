class AddcloumnLockedByUserIdToNotes < ActiveRecord::Migration
  def self.up
     add_column :notes, :lock_by_user_id, :integer
  end

  def self.down
      remove_column :notes, :lock_by_user_id
  end
end
