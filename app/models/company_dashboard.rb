class CompanyDashboard < ActiveRecord::Base
  belongs_to  :dashboard_chart
  serialize :thresholds, Hash
  serialize :parameters, Hash
  serialize :rag, Hash

  named_scope :current_company_and_current_employee, lambda { |company_id, employee_user_id|
    { :conditions => { :company_id => company_id,  :employee_user_id => employee_user_id} }
  }
  named_scope :favorite, :conditions => {:is_favorite => true }
  named_scope :show_on_home_page, :conditions => {:show_on_home_page => true }


  def self.manage_dashboard(company_id, employee_user_id, selected_charts, checked_charts, hidden_checked, managed_checked)
    checked = []
    charts_info = DashboardChart.all(:order => 'id')
    manage_dashboard = CompanyDashboard.current_company_and_current_employee(company_id, employee_user_id)
		charts_info.each do |item|
			checked_list = manage_dashboard.detect{ |obj| obj.dashboard_chart_id == item.id  and obj.is_favorite != true }
			hidden_checked = hidden_checked ?  hidden_checked + checked_list.dashboard_chart_id.to_s + "," :  checked_list.dashboard_chart_id.to_s + "," if checked_list
			managed_checked = managed_checked ?  managed_checked + checked_list.id.to_s + "," :  checked_list.id.to_s + "," if checked_list
		end
		if manage_dashboard!=[]
			manage_dashboard.each do |obj|
				if obj.show_on_home_page == true
					checked << obj.dashboard_chart_id
					checked_charts[obj.dashboard_chart.template_name]=obj.id
				end
			end
		else
			charts_info.each do |obj|
				if obj.default_on_home_page == true
					checked << obj.id
				end
			end
		end
		charts_info.each do |obj|
			if checked.include?(obj.id)
				selected_charts[obj.template_name] =['checked',obj.id]
			else
				selected_charts[obj.template_name]=['',obj.id]
			end
		end
    return selected_charts, checked_charts, hidden_checked, managed_checked
  end

end

# == Schema Information
#
# Table name: company_dashboards
#
#  id                 :integer         not null, primary key
#  dashboard_chart_id :integer
#  parameters         :string(255)
#  employee_user_id   :integer
#  company_id         :integer
#  thresholds         :string(255)
#  rag                :string(255)
#  show_on_home_page  :boolean
#  created_at         :datetime
#  updated_at         :datetime
#  is_cgc             :boolean
#  is_favorite        :boolean
#  favorite_title     :string(255)
#

