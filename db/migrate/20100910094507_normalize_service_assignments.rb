class NormalizeServiceAssignments < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:service_assignments, :company_id)
    remove_column(:service_assignments, :service_start)
    remove_column(:service_assignments, :service_end)
    
    # rename table
    rename_table(:service_assignments, :service_provider_employee_mappings)
    
  end

  def self.down
    # add removed columns
    add_column(:service_provider_employee_mappings, :company_id, :integer)
    add_column(:service_provider_employee_mappings, :service_start, :timestamp)
    add_column(:service_provider_employee_mappings, :service_end, :timestamp)
    
    # rename table
    rename_table(:service_provider_employee_mappings, :service_assignments)

  end
end
