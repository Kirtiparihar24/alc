class AddLinksTable < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.integer 'company_id'
      t.text 'description'
      t.string 'name'
      t.integer 'mapable_id'
      t.string 'mapable_type'
      t.integer 'category_id'
      t.datetime "deleted_at"
      t.datetime "permanent_deleted_at"
      t.text 'url'
      t.integer 'created_by_user_id'
      t.integer 'created_by_employee_user_id'
      t.timestamps
    end
  end

  def self.down
     drop_table :links
  end
end
