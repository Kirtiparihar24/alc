class CreateReportFavourites < ActiveRecord::Migration
  def self.up
    create_table :report_favourites do |t|
      t.string :report_type
      t.string :report_name
      t.string :controller_name
      t.string :action_name
      t.integer :company_id
      t.integer :employee_user_id
      t.string :get_records
      t.boolean :date_selected
      t.date :date_start
      t.date :date_end
      t.string :selected_options #Serialize 'selected_options' column to store values in the form of Hash
      t.timestamps
    end
  end

  def self.down
    drop_table :report_favourites
  end
end
