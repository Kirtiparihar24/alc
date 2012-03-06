class Add3ColumnInEmployeeTable < ActiveRecord::Migration
  def self.up
    add_column :employees, :is_firm_manager, :boolean,:default=>false
    add_column :employees, :can_access_matters, :boolean,:default=>false
    add_column :employees, :can_access_t_and_e, :boolean,:default=>false
  end

  def self.down
    remove_column :employees, :is_firm_manager
    remove_column :employees, :can_access_matters
    remove_column :employees, :can_access_t_and_e
  end
end
