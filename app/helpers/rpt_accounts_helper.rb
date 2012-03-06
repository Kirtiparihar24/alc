module RptAccountsHelper

  private
  #This method is used to set conditions in search string based on user selection
  def set_accounts_conditions(checked)
    if checked == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end
    search
  end

  def set_accounts_time(conditions_hash)
    conditions_hash[:date_start],months = set_time_months
    conditions_hash[:date_end] = Time.zone.now
  end

  #This method is used to get the report name
  def set_report_name(r_type,hash)
    case r_type
    when 1
      if params['get_records'] == 'My'
        hash[:r_name] = "Current #{t(:label_accounts)} for #{hash[:lawyer]}"
      else
        hash[:r_name] = "Current #{t(:label_accounts)} for #{hash[:l_firm]}"
      end
    when 2
      if params['get_records'] == 'My'
        hash[:r_name] += " assigned to #{hash[:lawyer]}"
      else
        hash[:r_name] += " of  #{hash[:l_firm]}"
      end
    when 3
      if params['get_records'] == 'My'
        hash[:r_name] = "#{t(:label_contacts)} linked to #{hash[:lawyer]}  #{t(:label_accounts)}"
      else
        hash[:r_name] = "#{t(:label_contacts)} linked to #{hash[:l_firm]} Firm Account"
      end
    when 4
      if params['get_records'] == 'My'
        hash[:r_name] = "Inactive #{t(:label_accounts)} for #{hash[:lawyer]}"
      else
        hash[:r_name] = "Inactive #{t(:label_accounts)} for #{hash[:l_firm]}"
      end
    else
      if params['get_records'] == 'My'
        hash[:r_name] = "Active #{t(:label_accounts)} for #{hash[:lawyer]}"
      else
        hash[:r_name] = "Active #{t(:label_accounts)} for #{hash[:l_firm]}"
      end
    end
    
  end

  #Grouping data based on selection of summarized by
   # This method generate group_by clause
   # Group by has
   # "account","account","account_contact","name"
   # "act_owner","assigned_to_user_id","User","name"
  def group_account_cont_report(col)
    # Getting required Lookups  in the form of hash sources[20] = Campaign    
    sources,stages,status_l = ReportsHelper.get_contacts_lookups(current_company)
    data,@total_data,@conditions = [],{},{}
    @conditions[:t_contacts] = 0
    @conditions[:inner_keys] = 0
    if params[:report][:summarize_by] == "account"
      col.each do |account|       
        next if  account.contacts.length == 0       
        account.contacts.find(:all).each do |contact|
          next unless contact
          if account.company_id==contact.company_id
            data << [contact.name,contact.phone,contact.email,sources[contact.source] ,stages[contact.contact_stage_id],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s]
          end
        end
        next if data.empty?
        @total_data[account.name] = data
        @conditions[:t_contacts] += data.length
        data = []
      end
    else
      a_hash,key = {},nil
      col.group_by(&:assigned_to_employee_user_id).each do |label, a_col|
        clength = 0
        a_col.each do |account|
          len = account.contacts.length
          next if  len == 0
          clength += len
          key = account.get_assigned_to.to_s
          account.contacts.find(:all).each do |contact|
            next unless contact
            data << [contact.name,contact.phone,contact.email,sources[contact.source] ,stages[contact.contact_stage_id],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s]
          end
          next if data.empty?
          a_hash[account.name] = data
          data = []
        end
        @total_data[key] = a_hash
        @conditions[key] = clength
        @conditions[:t_contacts] += clength
        @conditions[:inner_keys] += a_col.length
        a_hash = {}
      end 
    end 
    @table_headers = ["Contact","Phone","Email","Source","Stage","Rating","Created","Owner"]
    @table_headers
  end
  
  #Retrieve inactive accounts
  def get_in_active_accounts(col,params)
    accounts = []
    start_time,months = set_time_months
    end_time  = Time.zone.now.getutc
    lookups = current_company.opportunity_stage_types
    second_val = lookups.collect do |obj|
      obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
    end
    col.each do |account|
      inactive = false
      account.contacts.each do |contact|
        next unless contact
        o_col = contact.opportunities.select do |opp|
          (opp.created_at >= start_time and opp.created_at <= end_time) or (second_val.include?(opp.stage)) or (opp.closed_on ? opp.closed_on >= start_time : false)
        end
        m_col = contact.matters.select do |matter|
          (matter.created_at >= start_time and matter.created_at <= end_time) or (matter.matter_status && matter.matter_status.lvalue== 'Open') or (matter.closed_on ? matter.closed_on >= start_time : false)
        end
        if o_col.length == 0 and m_col.length == 0
          inactive = true
        else
          inactive = false
          break
        end
      end 
      accounts << account if inactive
    end 
    [accounts,months]
  end
  
  #Retrieve active accounts
  def get_active_accounts(col,params)
    accounts = []
    start_time,months = set_time_months
    end_time  = Time.zone.now
    lookups = current_company.opportunity_stage_types
    second_val = lookups.collect do |obj|
      obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
    end
    col.each do |account|
      account.contacts.each do |contact|
        next unless contact
        o_col = contact.opportunities.select do|opp|
          (opp.created_at >= start_time and opp.created_at <= end_time) or (second_val.include?(opp.stage)) or (opp.closed_on ? opp.closed_on >= start_time : false)
        end
        if o_col.length > 0
          accounts << account
          break
        end
        m_col = contact.matters.select do |matter|
          (matter.created_at >= start_time and matter.created_at <= end_time) or (matter.matter_status && matter.matter_status.lvalue  == 'Open') or (matter.closed_on ? matter.closed_on >= start_time : false)
        end
        if m_col.length > 0
          accounts << account
          break
        end
      end
    end
    [accounts,months]
  end

  #This method is used to get time
  def set_time_months

    case params[:report][:duration]
    when "1"
      #1month
      months = "1 months"
      time = Time.zone.now.last_month
    when "2" #3months
      months = "3 months"
      time = nil
      3.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    when "3" #6months
      months = "6 months"
      time = nil
      6.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    else
      time = nil
      time = Time.zone.now.last_year
      months = "1 year"
    end
    [time.getutc,months]

  end

  def get_account_status_by_stage(contact, stage, status_l)
    cstatus = ''
    if stage == 'Lead'
      cstatus = (status_l[contact.status_type].nil? || status_l[contact.status_type].empty?) ? 'New' : status_l[contact.status_type]
    else
      cstatus = (status_l[contact.status_type].nil? || status_l[contact.status_type].empty?) ? 'Active' : status_l[contact.status_type]
    end
    cstatus
  end

end
