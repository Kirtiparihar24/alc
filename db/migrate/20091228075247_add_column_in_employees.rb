class AddColumnInEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :created_by_user_id, :integer
    add_column :service_assignments, :created_by_user_id, :integer
  end

  def self.down
   remove_column :service_assignments, :created_by_user_id
  end
end
