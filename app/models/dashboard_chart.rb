class DashboardChart < ActiveRecord::Base
  serialize :colors, Hash
  serialize :parameters, Hash
  serialize :defult_thresholds, Hash
  validates_uniqueness_of :template_name
  has_many :company_dashboards
  
end

# == Schema Information
#
# Table name: dashboard_charts
#
#  id                   :integer         not null, primary key
#  chart_name           :string(255)
#  type_of_chart        :string(255)
#  xml_builder_name     :string(255)
#  template_name        :string(255)
#  colors               :string(255)
#  defult_thresholds    :string(255)
#  parameters           :string(255)
#  default_on_home_page :boolean
#  is_cgc               :boolean
#

