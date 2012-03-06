module Physical::Clientservices::HomeHelper

  # Below code is use get the contact count depending on ths type passed,count is used to pass with google api graph.
  def contact_count_for(t)
    type = CompanyLookup.find_by_lvalue_and_company_id(t, current_company.id).id
    rejected = current_company.prospect_status_types.find_by_lvalue("Rejected").id
    contacts = Contact.scoped_by_company_id(get_company_id).find(:all,
      :conditions => ["assigned_to_employee_user_id = ? AND status = ? AND (status_type != ? or status_type is null)",
        get_employee_user_id, type, rejected])
    contacts.size
  end

  # Below code is use to get the contact count depending on the type.
  def contact_count(user_id, type)
    @contacts = Contact.find(:all, :conditions => "assigned_to_employee_user_id=#{user_id} and  contact_stage_id=#{type} and (status_type!=#{current_company.prospect_status_types.find_by_lvalue("Rejected").id} or status_type is null)")
    return @contacts.collect{|c| c.contact_stage_id if c.contact_stage_id == type}.compact.size
  end

  # Below code is use to give the "Total hours accounted last week" count which is displayed in right hand side of the lawywers dashboard.
  def total_hours_accounted_last_week
    saved_time_entries = Physical::Timeandexpenses::TimeEntry.find(:all,
      :conditions => ['employee_user_id = ? and time_entry_date between ? and ?', get_employee_user_id,1.week.ago,5.days.from_now(1.week.ago)])
    saved_time_entries.collect(&:actual_duration).inject(0){|key, value| key + value}
  end

  # Below code is use to show "Active clients" count,which is displayed in right hand side of the lawywers dashboard.
  def active_clients 
    Contact.count(:all, :conditions => ["assigned_to_employee_user_id=? AND  contact_stage_id=? AND status_type=?",get_employee_user_id,current_company.contact_stages.array_hash_value('lvalue','Client','id'),current_company.prospect_status_types.find_by_lvalue("Active").id])
  end

  # Below code is use to show "Open matters" count,which is displayed in right hand side of the lawywers dashboard.
  def open_matters
    Matter.my_matters(get_employee_user_id, get_company_id).size
  end

  # Below code is use to show "Opportunities open" count,which is displayed in right hand side of the lawywers dashboard.
  def opportunities_open
    Opportunity.count(:all,:conditions=>["assigned_to_employee_user_id=? AND stage NOT IN (#{current_company.opportunity_stage_types.find_by_lvalue('Closed/Won').id},#{current_company.opportunity_stage_types.find_by_lvalue('Closed/Lost').id})",get_employee_user_id])
  end

  # Below code is use get the opportunities overdue count, which is pass to generated the graph.
  def opportunities_overdue
    Opportunity.count(:all,:conditions=>["assigned_to_employee_user_id=? AND stage NOT IN (#{current_company.opportunity_stage_types.find_by_lvalue('Closed/Won').id},#{current_company.opportunity_stage_types.find_by_lvalue('Closed/Lost').id}}) AND closes_on < ?",get_employee_user_id,Time.zone.now])
  end

  # Below code is use to show "Total campaigns open" count, which is pass to generated the graph.
  def total_campaigns_open
    @campaigns_status_type = []
    @campaigns_status_type_completed_id= current_company.campaign_status_types.find_by_lvalue('Completed').id
    @campaigns_status_type_aborted_id= current_company.campaign_status_types.find_by_lvalue('Aborted').id
    @campaigns_status_type << @campaigns_status_type_completed_id
    @campaigns_status_type << @campaigns_status_type_aborted_id
    @campaigns =  Campaign.count(:all,:conditions=>["owner_employee_user_id=? AND campaign_status_type_id NOT IN(?)",get_employee_user_id,@campaigns_status_type.flatten])
  end

end