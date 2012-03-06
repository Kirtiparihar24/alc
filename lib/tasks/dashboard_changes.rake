namespace :dashboard_name_change do

  task :template_name => :environment do
    dashboard_name_change
  end
  task :show_on_home_page => :environment do
    dashboard_unchecking_show_on_home_page
  end
  task :duplicate_manage_dashboards => :environment do
    delete_duplicate_manage_dashboards
  end
  task :three_from_four => :environment do
    change_three_from_four
  end
  task :type_of_chart => :environment do
    changing_type_of_chart
  end
  task :type_campaign_of_chart => :environment do
    changing_campaign_type_of_chart
  end
  task :change_in_matter_task => :environment do
    changing_start_and_end_date_matter_task
  end
  task :change_type_of_chart => :environment do
    changing_time_billed_type_of_chart
  end

  task :upgrading_chart => :environment do
    changing_all_type_of_chart
  end
  
  task :removing_fav => :environment do
    removeing_old_fav
  end

  task :show_on_home_page => :environment do
    delete_show_on_home_page
  end

end

def dashboard_name_change
  prevoius_names=["Contacts - Stage-wise breakup","Lead - Stage-wise breakup","Time Accounted - Week wise","Time Accounted - Month wise","Time Billed - Week wise","Time Billed - Month wise","Time Accounted vs. Creditable - Month wise","Time Accounted vs. Creditable - Week wise","Time Billed - Discount Provided - Month wise","Category wise - Estimates","Law firm wise - Estimates","Estimates Vs Actual Billing - Category wise","Estimates Vs Actual Billing - Law firm wise"]
  current_names=["Contacts Breakup - By Stage","Breakup - By Status","Time Accounted - Per Week","Time Accounted - Per Month","Time Billed - Per Week","Time Billed - Per Month","Time Accounted vs. Creditable - Per Month","Time Accounted vs. Creditable - Per Week","Time Billed - Discount Provided - Per Month","Estimates - By Category","Estimates - By Law Firm","Estimates Vs Actual Billing - By Category","Estimates Vs Actual Billing - By Law firm"]
  prevoius_names.each_with_index do |ele,index|
    obj = DashboardChart.find_by_chart_name(ele)
    next unless obj
    obj.chart_name = current_names[index]
    obj.save
  end
end
def dashboard_unchecking_show_on_home_page
  user_ids=User.find(:all,:select => [:id]).collect {|obj| obj.id}
  user_ids.each do |emp_id|
    col = CompanyDashboard.find(:all,:conditions=>"employee_user_id=#{emp_id} and show_on_home_page=true")
    if col.size == 4
      obj = col.first
      obj.show_on_home_page="false"
      obj.save
    end
  end
  dashboards=DashboardChart.find :all
  dashboard_obj=dashboards.second
  dashboard_obj.default_on_home_page= "false"
  dashboard_obj.save
end

def delete_duplicate_manage_dashboards
  dashboard_chart=DashboardChart.find :all
  dashboard_chart.each do |obj|
      user_ids=User.find :all
      user_ids.each do |user|
         col = CompanyDashboard.find(:all,:conditions=>"employee_user_id=#{user.id} and company_id=#{user.company_id} and dashboard_chart_id=#{obj.id} and is_favorite is not true")
         if col.size > 1
         col.reverse[0..col.size - 2].each do |chart|
              chart.destroy
         end
         end
      end
  end
end

def change_three_from_four
  dash_board_obj=DashboardChart.find_by_template_name("matter_task_chart_graph")
  dash_board_obj.default_on_home_page='false'
  dash_board_obj.save
end

def changing_type_of_chart
  dashboard=DashboardChart.find_all_by_type_of_chart("FCF_MSColumn3DLineDY.swf")
  dashboard.each do |chart|
      chart.type_of_chart="FCF_MSColumn3D.swf"
      chart.save
  end
end

def changing_campaign_type_of_chart
  dashboard=DashboardChart.find_by_template_name("get_campaign_response_value")
  dashboard.type_of_chart="FCF_MSColumn3DLineDY.swf"
  dashboard.save
end

def changing_start_and_end_date_matter_task
  matter_task = MatterTask.find(:all,:conditions=>"start_date is null and end_date is null")
  matter_task.each do |task|
    task.start_date = task.created_at.to_date
    task.end_date = task.created_at.to_date
    task.save
  end
end

def changing_time_billed_type_of_chart
  dash=DashboardChart.find_by_type_of_chart('FCF_Area2D.swf')
  dash.type_of_chart='FCF_Column3D.swf'
  dash.save
end

def changing_all_type_of_chart

  @dash_board=DashboardChart.find :all
  @dash_board.each do |obj|
    puts obj.type_of_chart
    obj.type_of_chart="Pie3D.swf" if obj.type_of_chart=="FCF_Pie3D.swf"
    obj.type_of_chart="Area2D.swf" if obj.type_of_chart=="FCF_Area2D.swf"
    obj.type_of_chart="StackedColumn3D.swf" if obj.type_of_chart=="FCF_StackedColumn3D.swf"
    obj.type_of_chart="Line.swf" if obj.type_of_chart=="FCF_Line.swf"
    obj.type_of_chart="MSBar3D.swf" if obj.type_of_chart=="FCF_MSBar2D.swf"
    obj.type_of_chart="MSColumn3D.swf" if obj.type_of_chart=="FCF_MSColumn3DLineDY.swf"
    obj.type_of_chart="Doughnut3D.swf" if obj.type_of_chart=="FCF_Doughnut2D.swf"
    obj.type_of_chart="Column3D.swf" if obj.type_of_chart=="FCF_Column3D.swf"
    obj.save
  end
  
end

def removeing_old_fav
  comp_fav=CompanyDashboard.find(:all,:conditions=>["is_favorite=?",true])
  comp_fav.each do |obj|
    obj.show_on_home_page=false if obj.show_on_home_page
    obj.save
  end
end

def delete_show_on_home_page
  user_ids=User.find :all
  user_ids.each do |user|
    col = CompanyDashboard.find(:all,:conditions=>"employee_user_id=#{user.id} and company_id=#{user.company_id} and show_on_home_page is true")
    if col.size > 3
      col.reverse[3..col.size].each do |obj|
        obj.show_on_home_page=false
        obj.save
      end
    end
  end
end
