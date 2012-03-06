class AddColumnExtToDocumentHome < ActiveRecord::Migration
  def self.up
    add_column :document_homes, :extension, :string
  end

  def self.down
    remove_column :document_homes, :extension
  end
end

