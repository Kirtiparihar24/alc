class AddWipDocToDocumentHomes < ActiveRecord::Migration
  def self.up
     add_column :document_homes,:wip_doc, :integer
  end

  def self.down
     remove_column :document_homes,:wip_doc
  end
end
