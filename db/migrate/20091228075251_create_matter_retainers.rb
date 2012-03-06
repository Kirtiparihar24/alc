class CreateMatterRetainers < ActiveRecord::Migration
  def self.up
    create_table :matter_retainers do |t|
      t.date :date
      t.integer :amount
      t.string :remarks
      t.integer :matter_id
      t.integer :created_by_user_id
      t.integer :updated_by_user_id
      t.integer :company_id

      t.timestamps
    end
  end

  def self.down
    drop_table :matter_retainers
  end
end
