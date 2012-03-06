class AddDocTypeIdToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :doc_type_id, :integer
  end

  def self.down
    remove_column :documents, :doc_type_id
  end
end
