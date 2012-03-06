class CreateMatterAccessPeriods < ActiveRecord::Migration
  def self.up
    create_table :matter_access_periods do |t|
      t.integer :matter_id
      t.integer :matter_people_id
      t.date :start_date
      t.date :end_date
      t.integer :company_id
      t.integer :employee_user_id
      t.boolean :is_active
      t.datetime :deleted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :matter_access_periods
  end
end
