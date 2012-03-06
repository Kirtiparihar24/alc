class NormalizeStickyNotes < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:sticky_notes, :note_id)
  end

  def self.down
    # add removed columns
    add_column(:sticky_notes, :note_id ,:integer) 
  end
end
