class CreateComplianceItems < ActiveRecord::Migration
    def self.up
    create_table :compliance_items do |t|
      t.integer 'compliance_id'
      t.date 'due_date'
      t.string 'primary_status', :limit=>64
      t.string 'secondary_status', :limit=>64
      t.date 'filed_date'
      t.text 'filed_remarks'
      t.date 'completed_date'
      t.text 'completed_remarks'
      t.date 'reminder_start_date'
      t.string 'reminder_frequency'
      t.timestamps
    end
  end

  def self.down
    drop_table :compliance_items
  end
end
