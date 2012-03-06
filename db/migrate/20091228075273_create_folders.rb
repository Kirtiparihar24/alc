class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders do |t|
      t.string :name
      t.integer  "company_id",           :default => 100, :null => false
      t.integer  "parent_id"

      t.datetime "deleted_at"
      t.integer  "created_by_user_id"
      t.integer  "employee_user_id"
      t.integer  "updated_by_user_id"
      t.datetime "permanent_deleted_at"
      t.timestamps
    end
    add_column :document_homes, :folder_id, :integer
  end

  def self.down
    drop_table :folders
    remove_column :document_homes, :folder_id
  end
end
