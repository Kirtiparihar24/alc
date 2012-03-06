DashboardChart.create :chart_name=>"Contacts - Stage-wise breakup",:template_name=>"contact_graph",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'contact_chart.builder',:parameters=>{'created_date'=>'','to_date'=>'','duration'=>''},:colors=>{"Prospect"=>"CCFF66", "Client"=>"6666FF", "Lead"=>"FF0000"},:default_on_home_page=>true
DashboardChart.create :chart_name=>"Opportunity pipeline",:template_name=>"get_opportunities_graph",:type_of_chart=>'FCF_Funnel.swf',:xml_builder_name=>'opportunities_chart.builder',:parameters=>{'created_date'=>'','to_date'=>'','duration'=>''},:colors=>{"Negotiation"=>"99FF33", "Prospecting"=>"FF0000", "Final Review"=>"CCCC66", "Proposal"=>"333366"},:default_on_home_page=>true
DashboardChart.create :chart_name=>"Time Billed",:template_name=>"billing_amount_graph",:type_of_chart=>'FCF_Area2D.swf',:xml_builder_name=>'billing_amount.builder',:parameters=>{"from_date"=>'','to_date'=>'','duration'=>''},:defult_thresholds=>{'lower_threshold'=>'','upper_threshold'=>''},:default_on_home_page=>true
DashboardChart.create :chart_name=>"Open Matter Tasks",:template_name=>"matter_task_chart_graph",:type_of_chart=>'FCF_StackedColumn3D.swf',:xml_builder_name=>'matter_task.builder',:parameters=>{'today-tasks'=>'today','overdue'=>'overdue','open_task'=>'open_task'},:default_on_home_page=>true
DashboardChart.create :chart_name=>"Opportunities Closed",:template_name=>"get_closed_opportunities",:type_of_chart=>'FCF_Line.swf',:xml_builder_name=>'closed_opportunities.builder',:parameters=>{"from_date"=>'','to_date'=>'','duration'=>''}
DashboardChart.create :chart_name=>"Open Opportunities",:template_name=>"get_open_opportunities",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'open_opportunities.builder',:parameters=>{"probability"=>''}
DashboardChart.create :chart_name=>"Campaign Response",:template_name=>"get_campaign_responsiveness",:type_of_chart=>'FCF_MSBar2D.swf',:xml_builder_name=>'campaign_responsiveness.builder',:parameters=>{"from_date"=>'','to_date'=>'','duration'=>''}
DashboardChart.create :chart_name=>"Campaign Response - Value",:template_name=>"get_campaign_response_value",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'campaign_response_value.builder',:parameters=>{"from_date"=>'','to_date'=>'','duration'=>''}
DashboardChart.create :chart_name=>"Lead - Stage-wise breakup",:template_name=>"lead_contact_stages",:type_of_chart=>'FCF_Doughnut2D.swf',:xml_builder_name=>'lead_contact_stage.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:colors=>{"New"=>"CCFF66", "Contacted"=>"6666FF", "Rejected"=>"FF0000"}
DashboardChart.create :chart_name=>"Accounts - Active & InActive",:template_name=>"active_inactive_accounts",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'active_inactive_accounts.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:colors=>{"InActive"=>"FF0000", "Active"=>"6666FF"}
DashboardChart.create :chart_name=>"Time Accounted - Week wise",:template_name=>"time_accounted_week_wise",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'time_accounted_week.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:defult_thresholds=>{'target'=>''},:colors=>{}
DashboardChart.create :chart_name=>"Time Accounted - Month wise",:template_name=>"time_accounted_month_wise",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'time_accounted_month.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:defult_thresholds=>{'target'=>''},:colors=>{}
DashboardChart.create :chart_name=>"Time Billed - Week wise",:template_name=>"time_billed_week_wise",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'time_billed_week.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:defult_thresholds=>{'target'=>''},:colors=>{}
DashboardChart.create :chart_name=>"Time Billed - Month wise",:template_name=>"time_billed_month_wise",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'time_billed_month.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:defult_thresholds=>{'target'=>''},:colors=>{}
DashboardChart.create :chart_name=>"Key Opportunities to Focus",:template_name=>"top_opportunities",:type_of_chart=>'FCF_Area2D.swf',:xml_builder_name=>'top_opportunities.builder',:parameters=>{},:colors=>{}
DashboardChart.create :chart_name=>"Time Accounted vs. Creditable - Month wise",:template_name=>"time_accounted_and_creditable_month_wise",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'time_accounted_and_creditable_month.builder',:parameters=>{'duration'=>''}
DashboardChart.create :chart_name=>"Time Accounted vs. Creditable - Week wise",:template_name=>"time_accounted_and_creditable_week_wise",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'time_accounted_and_creditable_week.builder',:parameters=>{'duration'=>''}
DashboardChart.create :chart_name=>"Compliance Filing - Status",:template_name=>"compliance_filing_status",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'compliance_filing_status.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Compliance Completed - Status",:template_name=>"compliance_closure_status",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'compliance_closure_status.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Open Compliances - Status",:template_name=>"open_compliances_status",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'open_compliances_status.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Compliance Meter",:template_name=>"compliance_meter",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'compliance_meter.builder',:parameters=>{'from_date'=>'','to_date'=>'','duration'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Category wise - Estimates",:template_name=>"category_wise_estimates",:type_of_chart=>'FCF_Pie3D.swf',:xml_builder_name=>'category_wise_estimates.builder',:parameters=>{'period'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Law firm wise - Estimates",:template_name=>"law_firm_wise_estimates",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'law_firm_wise_estimates.builder',:parameters=>{'period'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Estimates Vs Actual Billing - Category wise",:template_name=>"estimates_vs_actual_billing_cat",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'estimates_vs_actual_billing_cat.builder',:parameters=>{'period'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Estimates Vs Actual Billing - Law firm wise",:template_name=>"estimates_vs_actual_billing_law",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'estimates_vs_actual_billing_law.builder',:parameters=>{'period'=>''},:is_cgc=>"true"
DashboardChart.create :chart_name=>"Performance against Budget - Matters",:template_name=>"performance_against_budget_matters",:type_of_chart=>'FCF_Column3D.swf',:xml_builder_name=>'performance_against_budget_matters.builder',:parameters=>{'period'=>''},:is_cgc=>"true"


livia = Company.find_by_name('Livia')

if livia.blank?
  livia = Company.new(:name => 'Livia')
  livia.save(false)
  p "Livia company created.."  
  liviaadmin = User.new(:username => 'liviaadmin', :email => 'admin@livialegal.com', :first_name => 'Livia', :last_name => 'Admin',:company_id => livia.id,:password=> 'L1i2v3@',:password_confirmation => 'L1i2v3@') 
  liviaadmin.save(false)
  p "Livia admin created.."
else
  #rename the user_type 'liviaadmin' to 'livia_admin'
  @user = User.find_by_user_type('liviaadmin')
  @user.update_attributes(:user_type => 'livia_admin') unless @user.nil?  
end




Role.find_or_create_by_name_and_company_id(:name => 'livia_admin',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'lawfirm_admin',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'secretary',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'client',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'lawyer',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'cgc',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'manager',:company_id => livia.id)
Role.find_or_create_by_name_and_company_id(:name => 'cgc_compliance',:company_id => livia.id)



#Populating Assignmets tables for all the users
@company = Company.all
@company.each do |comp|
    #Creating default departments for companies
    if comp.id != livia.id
      depart = Department.find_by_name_and_company_id('Corporate',comp.id)	
      if depart.nil?	
          dep = Department.new(:name => 'Corporate', :company_id => comp.id)
          dep.save(false)
      end
    end
    @users = comp.users
    @users.each do |user|
        # assign user role in assignment table if the user_type is not blank
        # Modified By - Hitesh
        unless user.user_type.blank?
          roleid = Role.find_by_name(user.user_type).id
          Assignment.find_or_create_by_user_id_and_role_id(:user_id => user.id, :role_id => roleid)
        end
        
        #Assign default departments to all user of company
        if comp.id != livia.id
          if dep.blank?
            user.department_id = depart.id
          else
            user.department_id = dep.id
          end
          user.save(false)        
        end
    end
end

#Updating employee details
@employee = Employee.all
@employee.each do |emp|
  unless emp.user.blank?
    emp.first_name = emp.user.first_name
    emp.last_name = emp.user.last_name
    emp.email = emp.user.email
    emp.phone = emp.user.phone
    emp.mobile = emp.user.mobile
    emp.department_id = emp.user.department_id
    emp.save(false)
  end
end

comlook = CompanyLookup.new
#execute "SELECT setval('company_lookups_id_seq', (SELECT MAX(id) FROM company_lookups)+1);"
@companies = Company.find(:all,:conditions => ["id != ?",livia.id])
puts "companies .... ",@companies.size
@companies.each do |comp|
  designation = Designation.find_by_lvalue_and_company_id('Para Legal',comp.id)
  unless designation.nil?
    designation.update_attribute(:lvalue , 'Paralegal') 
  end
  #Creating default designation for companies
  ['Sr. Lawyer', 'Lawyer', 'Paralegal', 'Secretary'].each do |desig|
	Designation.find_or_create_by_lvalue_and_company_id(:lvalue => desig.to_s, :company_id => comp.id)	
  end  
end

['Accounts','Contacts','Mail','Campaigns','Opportunity','Matters','Time & Expense','Reports','Workspace','Document Repository'].each do |sub_product|
  Subproduct.find_or_create_by_name(:name=>sub_product.to_s)
end

  
