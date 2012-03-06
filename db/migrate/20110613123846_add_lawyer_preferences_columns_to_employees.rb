class AddLawyerPreferencesColumnsToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :clients_working_hours_days, :string
    add_column :employees, :likes_to_be_addressed_as, :string
    add_column :employees, :preferred_mode_of_communication, :string
    add_column :employees, :preferred_time_of_communication, :string
    add_column :employees, :personality_charachteristics, :text
    add_column :employees, :specialization, :string
    add_column :employees, :address, :text
    add_column :employees, :sales_representatives_name, :string
    add_column :employees, :implementation_representatives_name, :string
    add_column :employees, :date_of_handover_from_implementation_to_operations, :date
  end

  def self.down
    remove_column :employees, :clients_working_hours_days
    remove_column :employees, :likes_to_be_addressed_as
    remove_column :employees, :preferred_mode_of_communication
    remove_column :employees, :preferred_time_of_communication
    remove_column :employees, :personality_charachteristics
    remove_column :employees, :specialization
    remove_column :employees, :address
    remove_column :employees, :sales_representatives_name
    remove_column :employees, :implementation_representatives_name
    remove_column :employees, :date_of_handover_from_implementation_to_operations
  end
end
