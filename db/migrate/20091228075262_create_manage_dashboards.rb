class CreateManageDashboards < ActiveRecord::Migration
  def self.up
    create_table :manage_dashboards do |t|
      t.integer :dashboard_chart_id
      t.string  :parameters
      t.integer :employee_user_id
      t.integer :company_id
      t.string  :thresholds
      t.string  :rag
      t.boolean :show_on_home_page
      t.timestamps
    end
  end

  def self.down
    drop_table :manage_dashboards
  end
end
