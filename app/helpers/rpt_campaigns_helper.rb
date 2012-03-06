module RptCampaignsHelper

private
  #This method is used to set conditions in search string based on user selection

  def set_contact_act_conditions(checked)
    if checked == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end
    search
  end

  def set_campaigns_conditions(conditions_hash)
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND owner_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end
    lookups = []
    lookups = current_company.campaign_status_types
    select = nil
    select = params[:report][:status] if params[:report]
    if  select
      if  params[:report][:status] != "All"
        search += " AND campaign_status_type_id = (:s_arr)"
        conditions_hash[:s_arr] = params[:report][:status]
      else
        search+= " AND campaign_status_type_id is not :null "
        conditions_hash[:null] = nil
      end
    end
    lookups = ReportsHelper.get_lookups(lookups) unless lookups == []
    [search,conditions_hash,lookups]
  end

  #This method is used to get the report name
  def set_report_name(r_type,hash)
    r_name = nil
    case r_type
    when 1
      if params['get_records'] == 'My'
        r_name = "#{t(:text_campaign)} Status for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_campaign)} Status for #{hash[:l_firm]}"
      end
    when 2
      if params['get_records'] == 'My'
        hash[:r_name] = "#{t(:text_campaign)} Responsiveness for #{hash[:lawyer]}"
      else
        hash[:r_name] = "#{t(:text_campaign)} Responsiveness for #{hash[:l_firm]}"
      end
      return hash[:r_name]
    when 3
      if params['get_records'] == 'My'
        r_name = "#{t(:text_campaign)} #{t(:label_contacts)} for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_campaign)} #{t(:label_contacts)} for #{hash[:l_firm]}"
      end
    else
      if params['get_records'] == 'My'
        r_name = "#{t(:text_campaign)} Revenue for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_campaign)} Revenue for #{hash[:l_firm]}"
      end
    end
    r_name
  end

  
  #This method is used to group the col based on selection of summarized by
  # This method generate group_by clause
  #  Group by status(campaign_status_type_id) or group by owner(owner_employee_user_id)
  #  and [all,open,closed,aborted]i.e[Planned,In progress,Completed,Aborted,Completed ] -- from dyanamic_listing
  def group_campaign_status_rpt(col,params,lookups)
    total_data,data,obj = {},[],nil
    if params[:report][:summarize_by] == "status"

      col.group_by(&:campaign_status_type_id).each do |label, c_col|
        c_col.each do |obj|
          data << [obj.name,obj.members.length,obj.starts_on ? obj.starts_on.strftime('%m/%d/%y') : "",obj.ends_on ? obj.ends_on.strftime('%m/%d/%y') : "",obj.mail_sent ? (obj.get_campaign_mail_date if obj.get_campaign_mail_date) : "",obj.opportunities.length,rounding(obj.get_total_revenue),obj.get_assigned_to]
        end
        total_data[lookups[label]] = data
        data = []
      end
      
      column_widths = { 0 => 110, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80 , 5 => 80 , 6 => 80 ,7 => 100 , 8 => 100 }

      table_headers = [t(:text_campaign),t(:label_contacts),t(:text_start_date),t(:label_end_date),t(:text_1st_mailed_date),t(:text_opportunities),t(:text_value_d),t(:text_owner)]
    else
       col.group_by(&:owner_employee_user_id).each do |label, c_col|
         key = nil
        c_col.each do |obj|
          key = obj.get_assigned_to.to_s unless key
          data << [obj.name,lookups[obj.campaign_status_type_id],obj.members.length,obj.starts_on ? obj.starts_on.strftime('%m/%d/%y') : "",obj.ends_on ? obj.ends_on.strftime('%m/%d/%y') : "",obj.mail_sent ? (obj.get_campaign_mail_date if obj.get_campaign_mail_date) : "",obj.opportunities.length,obj.get_total_revenue]
        end
        total_data[key] = data
        data = []
      end
      column_widths = { 0 => 110, 1 => 80, 2 => 140 , 3 => 80 , 4 => 60 , 5 => 60 , 6 => 60 ,7 => 100 , 8 => 60 }
      table_headers = [t(:text_campaign),t(:text_status),t(:label_contacts),t(:text_start_date), t(:text_closure_date),t(:text_1st_mailed_date),t(:text_opportunities),t(:text_value_d)]
    end

    [total_data,table_headers,column_widths]
  end

  #This method is used to retrieve contact data 
  def get_contact_members(col)
    data = []
    table_headers = [t(:label_contacts),"#{t(:label_Account)}","#{t(:text_no_of)} #{t(:text_campaign)}", t(:text_responded), "#{t(:text_responded)} %",t(:text_opportunities),"#{t(:text_opportunities)} %"]
    if col.length != 0
        lookup = current_company.campaign_member_status_types.find_by_lvalue("Opportunity").id
    else
      return [data,table_headers]
    end
    col.each do|contact|
          members = contact.members
          mlength = members.length
          next if mlength == 0
          member = nil
          rcol = members.select do |member|
              member.responded_date != nil
          end
          ocol = members.select do |member|
              member.campaign_member_status_type_id == lookup
          end
          rl = rcol.length
          ol = ocol.length
          data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",mlength,rl,rl != 0 ? "#{((rl/mlength.to_f) * 100).roundf2(2)} %" : "",ol,ol != 0 ? "#{((ol/mlength.to_f) * 100).roundf2(2)} %" : "" ]
    end
    
    [data,table_headers]
  end

  #This method is used to retrieve account data 
  def get_account_members(col)
    total_data,data = {},[]
    table_headers = [t(:label_contacts),"#{t(:text_no_of)} #{t(:text_campaign)}",t(:text_responded),"#{t(:text_responded)} %",t(:text_opportunities),"#{t(:text_opportunities)} %"]
    if col.length != 0
        lookup = current_company.campaign_member_status_types.find_by_lvalue("Opportunity").id
    else
      return [total_data,table_headers]
    end
    
    col.each do|account|
          
          account.contacts.each do |contact|
              next if contact.nil?
              members = contact.members
              mlength = members.length
              next if mlength == 0
              member = nil
              rcol = members.select do |member|
                  member.responded_date != nil
              end
              ocol = members.select do |member|
                  member.campaign_member_status_type_id == lookup
              end
              rl = rcol.length
              ol = ocol.length
              data << [contact.name,mlength,rl,rl != 0 ? "#{((rl/mlength.to_f) * 100).roundf2(2)} %" : "",ol,ol != 0 ? "#{((ol/mlength.to_f) * 100).roundf2(2)} %" : "" ]
              
          end
          
          total_data[account.name.to_s] = data unless data == []
          data = []
    end
    
    [total_data,table_headers]
  end

  #This method is used to set conditions in search string based on user selection
  def set_conditions(checked)
    if checked == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end
      
    search
  end

  

end
