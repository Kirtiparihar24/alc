class AdditionalFields < ActiveRecord::Migration
  def self.up
     add_column :employees, :registered_number1,:string
     add_column :employees, :registered_number2,:string
     add_column :employees, :registered_number3,:string
     add_column :employees, :access_code,:string
     add_column :service_provider_employee_mappings,:priority,:integer
     add_column :users, :priority, :integer
     add_column :users, :cluster_id, :integer
     add_column :users, :reset_tpin_token, :string
     add_column :service_sessions, :employee_user_id, :integer
  end

  def self.down
    remove_column :employees, :registered_number1
    remove_column :employees, :registered_number2
    remove_column :employees, :registered_number3
    remove_column :employees, :access_code
    remove_column :service_provider_employee_mappings, :priority
    remove_column :users, :priority
    remove_column :users, :cluster_id
    remove_column :users, :reset_tpin_token
    remove_column :service_sessions, :employee_user_id
  end
end
