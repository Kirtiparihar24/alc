class AddDocumentSubCategoriesId < ActiveRecord::Migration
  def self.up
    add_column :documents, :sub_category_id, :integer
    add_column :company_lookups, :category_id, :integer
    add_column :links,  :sub_category_id, :integer
  end

  def self.down
    remove_column :documents, :sub_category_id
    remove_column :company_lookups, :category_id
    remove_column :links, :sub_category_id
  end
end
