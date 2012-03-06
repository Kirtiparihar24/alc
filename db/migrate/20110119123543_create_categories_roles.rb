class CreateCategoriesRoles < ActiveRecord::Migration
  def self.up
    create_table :categories_roles, :id => false do |t|
      t.integer :category_id
      t.integer :role_id
    end
  end

  def self.down
    drop_table :categories_roles
  end
end
