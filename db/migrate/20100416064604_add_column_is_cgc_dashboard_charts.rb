class AddColumnIsCgcDashboardCharts < ActiveRecord::Migration
  def self.up
     add_column :dashboard_charts, :is_cgc, :boolean
  end

  def self.down
     remove_column :manage_dashboards, :is_cgc
  end
end
