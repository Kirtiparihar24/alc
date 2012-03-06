class NormalizeActivitie < ActiveRecord::Migration
  def self.up
    # remove unused table
    drop_table :activities
  end

  def self.down
    # recreate deleted table
    create_table :activities do |t|
      t.integer :user_id
      t.integer :subject_id
      t.string :subject_type
      t.string :action
      t.string :info
      t.boolean :private , :default => false
      t.integer :company_id
      t.timestamp :deleted_at
      t.timestamp :permanent_deleted_at
      t.timestamps
    end            
  end
end
