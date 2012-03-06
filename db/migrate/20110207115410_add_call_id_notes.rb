class AddCallIdNotes < ActiveRecord::Migration
  def self.up
    add_column(:notes,:call_id,:string)
  end

  def self.down
    remove_column(:notes,:call_id)
  end
end
