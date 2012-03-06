class CreateWorkTypes < ActiveRecord::Migration
  def self.up
    create_table :work_types do |t|
      t.string :name
      t.text :description
      t.integer :category_id

      t.timestamps
    end
  end

  def self.down
    drop_table :work_types
  end
end
