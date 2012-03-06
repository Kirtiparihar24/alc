namespace :dashboard_parameter do
	desc "update opprortunity dashboard parameter with probablity parameter field "
	task :update_parameter_to_opportunity_graph => :environment do
		dashboard_chart = DashboardChart.find_by_template_name("get_opportunities_graph")
		if dashboard_chart.present?
			parameter = dashboard_chart.parameters.merge('probability'=>'')
			dashboard_chart.update_attribute(:parameters,parameter)
			dashboard_chart.company_dashboards.all.each do |comp_dash|
				cd_parameter = comp_dash.parameters || dashboard_chart.parameters
				cd_parameter=cd_parameter.merge('probability'=>'')
				comp_dash.update_attribute(:parameters,cd_parameter)
			end
		end
	end

	desc "update matter task graph by parameter by today"
	task :update_parameter_to_matter_task_graph => :environment do
		dashboard_chart = DashboardChart.find_by_template_name("matter_task_chart_graph")
		if dashboard_chart.present?
			parameter = dashboard_chart.parameters.merge('today'=>'')
	  	parameter = dashboard_chart.parameters.merge('upcoming'=>'')
			parameter['today-tasks'] = ''
			parameter['today'] = ''
   		parameter['overdue'] = ''
			parameter['open_task'] = ''
			dashboard_chart.update_attribute(:parameters,parameter)
			dashboard_chart.company_dashboards.all.each do |comp_dash|
				cd_parameter = comp_dash.parameters
				if cd_parameter.present?
					cd_parameter = comp_dash.parameters.merge('today'=>'')
					cd_parameter = comp_dash.parameters.merge('upcoming'=>'')
					cd_parameter['today'] = cd_parameter['today-tasks']
					cd_parameter['today-tasks'] = ''
					if comp_dash.parameters['open_task'] == "open_task"
						cd_parameter['today']='today'
						cd_parameter['overdue']='overdue'
						cd_parameter['upcoming']='upcoming'
					end
				else
					cd_parameter = dashboard_chart.parameters
				end
				comp_dash.update_attribute(:parameters,cd_parameter)
			end
		end
	end
end
