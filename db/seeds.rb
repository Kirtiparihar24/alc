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
DashboardChart.create :chart_name=>"Time Billed - Discount Provided - Month wise",:template_name=>"time_billed_discount_provided",:type_of_chart=>'FCF_MSColumn3DLineDY.swf',:xml_builder_name=>'time_billed_discount_provided.builder',:parameters=>{'duration'=>''}

livia = Company.find_by_name('Livia')

if livia.blank?
  livia = Company.new(:name => 'Livia')
  livia.save(false)
  p "Livia company created.."  
  liviaadmin = User.new(:username => 'liviaadmin', :email => 'admin@livialegal.com', :first_name => 'Livia', :last_name => 'Admin',:company_id => livia.id,:password=> 'L1i2v3@',:password_confirmation => 'L1i2v3@') 
  liviaadmin.save(false)
  p "Livia admin created.."
else
  liviaadmin = User.find_by_username_and_company_id('liviaadmin',livia.id)
end



#Creating default Roles
Role.find_or_create_by_name(:name => 'livia_admin')
Role.find_or_create_by_name(:name => 'lawfirm_admin')
Role.find_or_create_by_name(:name => 'secretary')
Role.find_or_create_by_name(:name => 'client')
Role.find_or_create_by_name(:name => 'lawyer')
Role.find_or_create_by_name(:name => 'cgc')
Role.find_or_create_by_name(:name => 'manager')
Role.find_or_create_by_name(:name => 'cgc_compliance')

#Creating default department for company
dept = Department.find_or_create_by_name_and_company_id(:name => 'Corporate',:company_id => livia.id)
unless dept.blank?
  UserRole.find_or_create_by_user_id_and_role_id(:user_id => liviaadmin.id, :role_id => livia.id)
  liviaadmin.department_id = dept.id
  liviaadmin.save(false)
end


['Accounts','Contacts','Mail','Campaigns','Opportunity','Matters','Time & Expense','Reports','Workspace','Document Repository'].each do |sub_product|
  Subproduct.find_or_create_by_name(:name=>sub_product.to_s)
end

#comlook = CompanyLookup.new
#['Sr. Lawyer', 'Lawyer', 'Paralegal', 'Secretary'].each do |desig|
#  Designation.find_or_create_by_lvalue_and_company_id(:lvalue => desig.to_s, :company_id => livia.id)	
#end



  
