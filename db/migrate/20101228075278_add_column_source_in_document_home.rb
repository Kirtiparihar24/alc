class AddColumnSourceInDocumentHome < ActiveRecord::Migration
  def self.up
    add_column :documents, :doc_source_id, :integer
    add_column :matter_facts, :doc_source_id, :integer
  end

  def self.down
    remove_column :documents, :doc_source_id
    remove_column :matter_facts, :doc_source_id
  end
end
