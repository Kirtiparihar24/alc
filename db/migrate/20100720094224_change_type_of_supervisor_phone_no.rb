class ChangeTypeOfSupervisorPhoneNo < ActiveRecord::Migration
  
  def self.up
    change_column :contact_additional_fields,:supervisors_phone_number,:string,:limit => 32
  end

  def self.down
    change_column :contact_additional_fields,:supervisors_phone_number,:integer
  end
  
end
