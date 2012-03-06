class AddCategoryTypeIdToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :category_type_id, :integer
  end

  def self.down
    remove_column :matter_tasks, :category_type_id
  end
end
