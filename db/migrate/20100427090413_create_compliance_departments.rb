class CreateComplianceDepartments < ActiveRecord::Migration
  def self.up
    create_table :compliance_departments do |t|
      t.string 'name', :limit=>256
      t.integer 'company_id'
      t.string 'owner_first_name' , :limit=>256
      t.string 'owner_last_name', :limit=>256
      t.string 'owner_email', :limit=>256
      t.integer 'user_id'
      t.timestamp 'deleted_at'
      t.timestamps
    end
  end

  def self.down
    drop_table :compliance_departments
  end
end
