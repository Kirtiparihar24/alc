class CreateZimbraActivities < ActiveRecord::Migration
  def self.up
    create_table :zimbra_activities do |t|
      t.string :name
      t.text :description
      t.string :category
      t.integer :zimbra_folder_location
      t.integer :assigned_to_user_id
      t.string :zimbra_task_id
      t.boolean :zimbra_status
      t.integer :reminder
      t.string :repeat
      t.text :location
      t.text :attendees_emails
      t.boolean :response
      t.boolean :notification
      t.string :show_as
      t.string :mark_as
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :all_day_event
      t.boolean :exception_status
      t.integer :task_id
      t.datetime :exception_start_date
      t.string :occurrence_type
      t.integer :count
      t.date :until
      t.string :progress_percentage
      t.string :progress
      t.string :priority
      t.datetime :deleted_at
      t.integer :company_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :zimbra_activities
  end
end
