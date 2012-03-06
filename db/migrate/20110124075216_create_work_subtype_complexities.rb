class CreateWorkSubtypeComplexities < ActiveRecord::Migration
  def self.up
    create_table :work_subtype_complexities do |t|
      t.integer :work_subtype_id
      t.integer :complexity_level
      t.integer :stt
      t.integer :tat

      t.timestamps
    end
  end

  def self.down
    drop_table :work_subtype_complexities
  end
end
