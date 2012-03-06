class CreateComplianceTrail < ActiveRecord::Migration
  def self.up
    create_table :compliance_trails do |t|
      t.integer 'compliance_id'
      t.integer 'compliance_item_id'
      t.integer 'user_id'
      t.string  'email'
      t.string  'org_status'
      t.string  'new_status'      
      t.timestamps
    end
  end

  def self.down
    drop_table :compliance_trails
  end
end
