class AlterComplianceForDepartment < ActiveRecord::Migration
  def self.up
    add_column :compliances, :authority_id, :integer
    add_column :compliances, :compliance_department_id, :integer
    add_column :compliances, :compliance_department, :string, :limit=>128
  end

  def self.down
    remove_column :compliances, :authority_id
    remove_column :compliances, :compliance_department_id
    remove_column :compliances, :compliance_department    
  end
end
