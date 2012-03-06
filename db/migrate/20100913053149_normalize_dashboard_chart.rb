class NormalizeDashboardChart < ActiveRecord::Migration
  def self.up
    rename_column(:dashboard_charts, :defult_on_home_page, :default_on_home_page)
  end

  def self.down
    rename_column(:dashboard_charts, :default_on_home_page, :defult_on_home_page)
  end
end
