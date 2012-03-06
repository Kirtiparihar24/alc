class CreateFavourites < ActiveRecord::Migration
  def self.up
    create_table :favourites do |t|
      t.string :fav_type
      t.string :name
      t.text :url
      t.string :controller_name
      t.string :action_name
      t.integer :company_id
      t.integer :employee_user_id
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :favourites
  end
end
