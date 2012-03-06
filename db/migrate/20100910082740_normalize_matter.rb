class NormalizeMatter < ActiveRecord::Migration
  def self.up
    unless Matter.column_names.to_a.include?("client_access")
      add_column(:matters, :client_access, :boolean,:default => false) 
    end
    @matters = Matter.all
    # default client_access is false, if previous value is 4 then set as true
    
    if Matter.column_names.to_a.include?("access_rights")  
      @matters.each do |matter|
        if matter.access_rights == 4
          matter.client_access = true
        else
          matter.client_access = false
        end
        matter.send(:update_without_callbacks)
      end    
    end
    # remove unused columns
    remove_column(:matters, :primary_matter_id)  if Matter.column_names.to_a.include?("primary_matter_id")
    remove_column(:matters, :temp_status)  if Matter.column_names.to_a.include?("temp_status")
    
    rename_column(:matters, :auto_generated_matter_id, :matter_no) if Matter.column_names.to_a.include?("auto_generated_matter_id")  
    rename_column(:matters, :ref_id, :ref_no)  if Matter.column_names.to_a.include?("ref_id")  
    rename_column(:matters, :litigation_type, :matter_category)  if Matter.column_names.to_a.include?("litigation_type")  
    rename_column(:matters, :matter_type, :matter_type_id)  if Matter.column_names.to_a.include?("matter_type")  
    rename_column(:matters, :status, :status_id)  if Matter.column_names.to_a.include?("status")  
    

    remove_column(:matters, :access_rights)  if Matter.column_names.to_a.include?("access_rights")  
  end

  def self.down
    # add removed columns
    add_column(:matters, :primary_matter_id,:string)
    add_column(:matters, :temp_status,:string)
    add_column(:matters, :access_rights,:integer)

    @matters = Matter.all
    # default client_access is false, if previous value is 4 then set as true
    @matters.each do |matter|
      if matter.client_access
        matter.access_rights = 4
      else
        matter.access_rights = 1
      end
      matter.send(:update_without_callbacks)
    end
    
    rename_column(:matters, :matter_no, :auto_generated_matter_id)
    rename_column(:matters, :ref_no, :ref_id)
    rename_column(:matters, :matter_category, :litigation_type)
    rename_column(:matters, :matter_type_id, :matter_type)
    rename_column(:matters, :status_id, :status)
    
    remove_column(:matters, :client_access)    
  end
end
