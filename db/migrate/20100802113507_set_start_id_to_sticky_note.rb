class SetStartIdToStickyNote < ActiveRecord::Migration
  def self.up
    StickyNote.delete_all
    execute 'ALTER SEQUENCE sticky_notes_id_seq START 100;'
  end

  def self.down
    
  end
  
end
