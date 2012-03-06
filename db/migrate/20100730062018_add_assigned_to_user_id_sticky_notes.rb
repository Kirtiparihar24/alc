class AddAssignedToUserIdStickyNotes < ActiveRecord::Migration
  def self.up
    add_column :sticky_notes, :assigned_to_user_id, :integer
  end

  def self.down
    remove_column :sticky_notes, :assigned_to_user_id, :integer
  end
end
