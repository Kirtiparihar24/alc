class CreateStickyNotes < ActiveRecord::Migration
  def self.up
    create_table :sticky_notes do |t|
      t.datetime "created_at",                                      :null => false
      t.datetime "updated_at"
      #t.integer  "assigned_by_employee_user_id",                    :null => false
      t.integer  "created_by_user_id",                              :null => false
      t.text     "description",                                     :null => false
      # t.integer  "note_priority"
      #t.boolean  "is_actionable",                :default => false
      #t.boolean  "more_action",                  :default => false
      #t.integer  "matter_id"
      #t.integer  "assigned_to_user_id"
      #t.datetime "deleted_at"
      #t.text     "status"
      #t.integer  "contact_id"
      t.integer  "company_id"
      t.integer  "note_id"
      #t.integer  "updated_by_user_id"
      #t.time     "permanent_deleted_at"

    end
  end

  def self.down
    drop_table :sticky_notes
  end
end
