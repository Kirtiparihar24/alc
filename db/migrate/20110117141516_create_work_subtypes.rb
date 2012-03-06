class CreateWorkSubtypes < ActiveRecord::Migration
  def self.up
    create_table :work_subtypes do |t|
      t.string :name
      t.text :description
      t.integer :work_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :work_subtypes
  end
end
