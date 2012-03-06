class CreateMatterClientTaskDetails < ActiveRecord::Migration
  def self.up
    create_table :matter_client_task_details do |t|
      t.date :from_date
      t.date :to_date
      t.string :venue
      t.string :judge_name
      t.string :doc_name
      t.text :doc_details
      t.string :task_type
      t.integer :matter_task_id
      t.timestamps
    end
  end

  def self.down
    drop_table :matter_client_task_details
  end
end
