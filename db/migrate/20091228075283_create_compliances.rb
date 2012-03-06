class CreateCompliances < ActiveRecord::Migration
  def self.up
    create_table :compliances do |t|
      t.integer 'company_id'
      t.text 'definition'
      t.integer 'type_id'
      t.integer 'subtype_id'
      t.string 'authority'
      t.string 'frequency', :limit=>32
      t.string 'custom_freq', :limit=>32
      t.date 'start_date'
      t.date 'end_date'
      t.text 'emails'      
      t.integer 'create_by_user_id'
      t.integer 'assigned_to_user_id'
      t.timestamps
    end
  end

  def self.down
    drop_table :compliances
  end
end
