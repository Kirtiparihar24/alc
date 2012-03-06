class CreateUserWorkSubtypes < ActiveRecord::Migration
  def self.up
    create_table :user_work_subtypes do |t|
      t.integer :user_id
      t.integer :work_subtype_id
      t.timestamps
    end
  end

  def self.down
    drop_table :user_work_subtypes
  end
end
