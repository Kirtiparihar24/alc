class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.string :notification_type
      t.integer :notification_id
      t.string :title
      t.boolean :is_read
      t.integer :receiver_user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
