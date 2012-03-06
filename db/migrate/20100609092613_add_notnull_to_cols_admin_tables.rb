class AddNotnullToColsAdminTables < ActiveRecord::Migration
  def self.up
    change_column :subproduct_assignments, :user_id, :integer, :null => false
    change_column :subproduct_assignments, :subproduct_id, :integer, :null => false
    change_column :subproduct_assignments, :product_licence_id, :integer, :null => false
    change_column :subproduct_assignments, :company_id, :integer, :null => false

    change_column :product_subproducts, :product_id, :integer, :null => false
    change_column :product_subproducts, :subproduct_id, :integer, :null => false

    change_column :product_dependents, :product_id, :integer, :null => false
    change_column :product_dependents, :parent_id, :integer, :null => false

    change_column :licences, :company_id, :integer, :null => false
    change_column :licences, :product_id, :integer, :null => false
    change_column :licences, :licence_count, :integer, :null => false
    change_column :licences, :cost, :integer, :null => false
    change_column :licences, :start_date, :datetime, :null => false

    change_column :product_licences, :product_id, :integer, :null => false
    change_column :product_licences, :licence_key, :string, :null => false
    change_column :product_licences, :licence_cost, :float, :null => false
    change_column :product_licences, :licence_id, :integer, :null => false
    change_column :product_licences, :licence_type, :integer, :null => false
    change_column :product_licences, :start_at, :datetime, :null => false

    change_column :product_licence_details, :product_licence_id, :integer, :null => false
    change_column :product_licence_details, :start_date, :datetime, :null => false
    change_column :product_licence_details, :user_id, :integer, :null => false

    change_column :departments, :company_id, :integer, :null => false
    change_column :departments, :name, :string, :null => false

    change_column :service_providers, :user_id, :integer, :null => false
    
    change_column :assignments, :user_id, :integer, :null => false
    change_column :assignments, :role_id, :integer, :null => false

  end

  def self.down
    change_column :subproduct_assignments, :user_id, :integer, :null => true
    change_column :subproduct_assignments, :subproduct_id, :integer, :null => true
    change_column :subproduct_assignments, :product_licence_id, :integer, :null => true
    change_column :subproduct_assignments, :company_id, :integer, :null => true

    change_column :product_subproducts, :product_id, :integer, :null => true
    change_column :product_subproducts, :subproduct_id, :integer, :null => true

    change_column :product_dependents, :product_id, :integer, :null => true
    change_column :product_dependents, :parent_id, :integer, :null => true

    change_column :licences, :company_id, :integer, :null => true
    change_column :licences, :product_id, :integer, :null => true
    change_column :licences, :licence_count, :integer, :null => true
    change_column :licences, :cost, :integer, :null => true
    change_column :licences, :start_date, :datetime, :null => true

    change_column :product_licences, :product_id, :integer, :null => true
    change_column :product_licences, :licence_key, :string, :null => true
    change_column :product_licences, :licence_cost, :float, :null => true
    change_column :product_licences, :licence_id, :integer, :null => true
    change_column :product_licences, :licence_type, :integer, :null => true
    change_column :product_licences, :start_at, :datetime, :null => true

    change_column :product_licence_details, :product_licence_id, :integer, :null => true
    change_column :product_licence_details, :start_date, :datetime, :null => true
    change_column :product_licence_details, :user_id, :integer, :null => true

    change_column :departments, :company_id, :integer, :null => true
    change_column :departments, :name, :string, :null => true

    change_column :service_providers, :user_id, :integer, :null => true

    change_column :assignments, :user_id, :integer, :null => true
    change_column :assignments, :role_id, :integer, :null => true

  end
end
