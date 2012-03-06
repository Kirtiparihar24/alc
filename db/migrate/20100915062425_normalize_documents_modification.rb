class NormalizeDocumentsModification < ActiveRecord::Migration
  def self.up
    remove_column :documents, :documentable_type
    remove_column :documents, :documentable_id
    remove_column :documents, :type
    remove_column :documents, :linked_issue_id
    remove_column :documents, :linked_facts_id
    remove_column :documents, :recipient
    remove_column :documents, :brief
    remove_column :documents, :document_rights
  #  drop_table :assets
  end

  def self.down
    add_column :documents, :documentable_type,:string
    add_column :documents, :documentable_id, :integer
    add_column :documents, :type,:string
    add_column :documents, :linked_issue_id, :integer
    add_column :documents, :linked_facts_id, :integer
    add_column :documents, :recipient,:string
    add_column :documents, :brief,:string
    add_column :documents, :document_rights, :integer
    
#    create_table "assets", :force => true do |t|
#    t.string   "data_file_name"
#    t.string   "data_content_type"
#    t.integer  "data_file_size"
#    t.integer  "document_id"
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.integer  "parent_id"
#    t.integer  "attachable_id"
#    t.string   "attachable_type"
#    t.integer  "company_id",           :default => 100, :null => false
#    t.datetime "deleted_at"
#    t.datetime "permanent_deleted_at"
#    t.integer  "created_by_user_id"
#    t.integer  "updated_by_user_id"
#  end
  end
end
