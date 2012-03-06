class CreateDashboardCharts < ActiveRecord::Migration
  def self.up
    create_table :dashboard_charts do |t|
      t.string :chart_name
      t.string :type_of_chart
      t.string :xml_builder_name
      t.string :template_name
      t.string :colors
      t.string :defult_thresholds
      t.string :parameters
      t.boolean :defult_on_home_page
    end
  end

  def self.down
    drop_table :dashboard_charts
  end
end
