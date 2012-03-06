class NormalizeMatterClientTaskDetail < ActiveRecord::Migration
  def self.up
    # remove unrequired table
    drop_table :matter_client_task_details
  end

  def self.down
    create_table :matter_client_task_details do |t|
      t.string :venue
      t.string :judge_name
      t.string :doc_name
      t.text :doc_details
      t.string :task_type
      t.integer :matter_task_id
      t.time :from_time
      t.time :to_time
      t.timestamps
    end    
  end
end
