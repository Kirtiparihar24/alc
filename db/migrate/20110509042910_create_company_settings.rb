# Feature 6407 - Supriya Surve - 9th May 2011
class CreateCompanySettings < ActiveRecord::Migration
  def self.up
    create_table :company_settings do |t|
      t.integer :created_by_user_id
      t.integer :company_id
      t.string :type
      t.string :setting_value
      t.datetime :deleted_at
      t.datetime :permanent_deleted_at
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :company_settings
  end
end
