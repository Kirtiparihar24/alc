module RptOpportunitiesHelper

  private

  #Getting required lookups from Lookup table
  def get_opp_lookups

    sources,stages = {},{}

    lookup_source = CompanySource.find_all_by_company_id(current_company.id) #Lookup.lead_source
    sources = ReportsHelper.get_lookups(lookup_source)
    sources[""] , sources[nil] = "",""

    lookup_stages = current_company.opportunity_stage_types
    stages = ReportsHelper.get_lookups(lookup_stages)
    stages[""] , stages[nil] = "",""

    [sources,stages]

  end

  #This method is used to set conditions in search string based on user selection
  def set_opp_pipe_conditions(conditions_hash)
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end
    if params[:report][:status]  != "All"
      search += " AND stage = (:s_arr)"
      conditions_hash[:s_arr] = params[:report][:status]
    else
      search+= " AND stage is not :null "
      conditions_hash[:null] = nil
    end
    if params[:report][:probability]  != "1"
      val = params[:report][:probability].split(":-:")
      search += " AND probability #{val[0]} :prob"
      conditions_hash[:prob] = val[1]
    end
    
    [search,conditions_hash]
  end


  #This method is used to set conditions in search string based on user selection
  def set_opp_source_conditions(conditions_hash)
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end

    if params[:report][:status]  != "1"
      second_val = []
      lookups = current_company.opportunity_stage_types
      if params[:report][:status] == "2"
        #ShowOnlyOpen
        obj = nil
        second_val = lookups.collect do |obj|
          obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
        end
        conditions_hash[:s_arr] = second_val.compact
        search += " AND stage IN (:s_arr)"
      elsif params[:report][:status] == "3"
        #ClosedWon/Lost
        second_val = lookups.collect do |obj|
          obj.id if ["Closed/Lost","Closed/Won"].include?(obj.lvalue)
        end

        conditions_hash[:s_arr] = second_val.compact
        search += " AND stage IN (:s_arr)"
      elsif params[:report][:status] == "4"
        #ClosedWon
        second_val = lookups.collect do |obj|
          obj.id if ["Closed/Won"].include?(obj.lvalue)
        end
        conditions_hash[:s_arr] = second_val.compact
        search += " AND stage IN (:s_arr)"
      end
    end
    [search,conditions_hash]
  end


  #This method is used to set conditions in search string based on user selection
  def set_opp_open_conditions
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
	  else
      search = 'company_id=:company_id'
	  end
    search
  end


  def group_opp_pipe_accounts(col,total_data,conditions,stages,sources,amount=0)
    hours = 0
    opps = []
    opps_hash = {}
    opps = col.collect do |opp|
      [opp.name,
       #opp.contact.nil? ? '' : opp.contact.full_name,
       opp.try(:contact).try(:full_name),
       opp.get_assigned_to,
       opp.amount ? opp.amount.to_i : "",
       opp.estimated_hours,
       opp.probability ? opp.probability.to_s + "%" : "",
       opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
       opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
       stages[opp.stage],
       sources[opp.source],
       #opp.contact.nil? ? '' :opp.contact.get_account_name.to_s]
       opp.try(:contact).try(:get_account_name).to_s]
    end
    opps.each do |opp|
      key = opp.pop
      if opps_hash.has_key?(key)
        opps_hash[key] << opp
      else
        opps_hash[key] = [opp]
      end
    end
            
    opps_hash.each_pair do |key,col|
      i_amount = amount
      col.each do |opp|
        amount += opp[3] if opp[3] and opp[3] != ""
        hours += opp[4] if opp[4]
      end
      total_data[key] = col
      conditions[key] = [(amount-i_amount).to_i,hours]
      i_amount = 0
      hours = 0
    end

    [total_data,conditions,amount]
  end
  
  def group_opp_open_accounts(opp_col,total_data,conditions,stages,today,amount=0,total_age=0)
    total_overall_age,total_overall_length,total_avg_age=0,0,0
    hours = 0
    opps = []
    opps_hash = {}
    opps = opp_col.collect do |opp|
      [opp.name,
       #opp.contact.nil? ? "" :opp.contact.full_name
       opp.try(:contact).try(:full_name),
       opp.get_assigned_to,
       opp.amount ? opp.amount.to_i : "",
       opp.estimated_hours,
       opp.probability ? opp.probability.to_s + "%" : "",
       opp.created_at ,
       opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
       stages[opp.stage],
       #opp.contact.nil? ? "" :opp.contact.get_account_name.to_s]
       opp.try(:contact).try(:get_account_name).to_s]
    end
    opps.each do |opp|
      key = opp.pop
      if opps_hash.has_key?(key)
        opps_hash[key] << opp
      else
        opps_hash[key] = [opp]
      end
    end

    opps_hash.each_pair do |key,col|
      i_amount = amount
      col.each do |opp|
        amount += opp[3] if opp[3] and opp[3] != ""
        hours += opp[4] if opp[4]
        created = opp[6].to_date
        age = (today-created).to_i
        total_age += age
        opp[6] = opp[6].strftime('%m/%d/%y')
        opp.insert(-2,age)
      end
      total_data[key] = col
      avg_age = total_age/col.length
      total_overall_age += total_age
      total_overall_length += col.length
      total_avg_age = total_overall_age/total_overall_length
      conditions[:total_avg_age] = total_avg_age
      conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),avg_age,hours.to_f.fixed_precision(2)]
      i_amount = 0
      hours = 0
      total_age = 0
    end
    [total_data,conditions,amount.to_f.fixed_precision(2)]
    
  end

  def set_report_name(r_type,hash)   
    case r_type
    when 1
      if params['get_records'] == 'My'
        hash[:r_name] = "#{t(:label_Opportunity)} Pipeline for #{hash[:lawyer]}"
      else
        hash[:r_name] = "#{t(:label_Opportunity)} Pipeline for #{hash[:l_firm]}"
      end
    when 2
      if params['get_records'] == 'My'
        hash[:r_name] = " #{t(:label_Opportunity)} Sources for #{hash[:lawyer]}"
      else
        hash[:r_name] = " #{t(:label_Opportunity)} Sources of  #{hash[:l_firm]}"
      end
    else
      if params['get_records'] == 'My'
        hash[:r_name] = "Open #{t(:label_opportunities)} for #{hash[:lawyer]}"
      else
        hash[:r_name] = "Open #{t(:label_opportunities)} for #{hash[:l_firm]}"
      end
    end
      
  end

  # This method generate group_by clause
  #   Group by Opportunity stage or,Owner (assigned_to_user_id) order by owner_name
  #    or contact,or account,or source,
  #    and [all,open,closed,closed/won] and probablity"
  def group_opportunity_pipe_rpt(col)
    amount,i_amount,hours,column_widths,@total_data,data = 0,0,0,{},{},[]
    sources,stages = get_opp_lookups 
    if params[:report][:summarize_by] == "stage"
      col.group_by(&:stage).each do |label, gcol|
        key = nil
        i_amount = amount
        gcol.each do |opp|
          amount +=  opp.amount if opp.amount
          hours += opp.estimated_hours if opp.estimated_hours
          if opp.contact
          data << [opp.name,
                   #opp.contact.nil? ? "" : opp.contact.full_name
                   opp.try(:contact).try(:full_name),
                   #opp.contact.nil? ? "" : opp.contact.get_account_name
                   opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   opp.get_assigned_to,
                   sources[opp.source]]
          end
        end
        key = stages[label]
        @total_data[key] = data
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),hours.to_f.fixed_precision(2)]
        hours = 0
        i_amount = 0
        data = []
      end

      @table_headers = [t(:label_name),t(:text_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_owner),t(:text_source)]
      column_widths = { 0 => 110, 1 => 100, 2 => 100 , 3 => 40 , 4 => 40 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 , 9 => 60} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "owner"
      col.group_by(&:assigned_to_employee_user_id).each do |label,gcol|
        key = nil
        i_amount = amount
        gcol.each do |opp|
          amount +=  opp.amount if opp.amount
          hours += opp.estimated_hours if opp.estimated_hours
          key = opp.get_assigned_to.to_s unless key
          data << [opp.name,
                   #opp.contact.nil? ? "" : opp.contact.full_name,
                  # opp.contact.nil? ? "" : opp.contact.get_account_name,
                   opp.try(:contact).try(:full_name),
                   opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   stages[opp.stage],
                   sources[opp.source]]
        end
        @total_data[key] = data
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),hours.to_f.fixed_precision(2)]
        data = []
        hours = 0
        i_amount = 0
      end
      @table_headers = [t(:label_name),t(:text_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_stage),t(:text_source)]
      column_widths = { 0 => 110, 1 => 100, 2 => 100 , 3 => 40 , 4 => 40 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 , 9 => 60} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "contact"
      col.group_by(&:contact_id).each do |label, gcol|
        key = nil
        i_amount = amount
        gcol.each do |opp|
          amount +=  opp.amount if opp.amount

          hours += opp.estimated_hours if opp.estimated_hours
          key = opp.try(:contact).try(:full_name) unless key
          data << [opp.name,
                   #pp.contact.nil? ? "" :opp.contact.get_account_name
                   opp.try(:contact).try(:get_account_name),
                   opp.get_assigned_to,
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   stages[opp.stage],
                   sources[opp.source]]
        end
        @total_data[key] = data
        data = []
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),hours.to_f.fixed_precision(2)]
        i_amount = 0
        hours = 0
      end
      @table_headers = [t(:label_name),"#{t(:label_Account)}",t(:label_owner),t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_stage),t(:text_source)]
      column_widths = { 0 => 110, 1 => 100, 2 => 100 , 3 => 40 , 4 => 60 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 , 9 => 60} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "account"

	    # Grouping is handled by below code. As no account column in opportunities table
	    @total_data , @conditions ,amount = group_opp_pipe_accounts(col,@total_data,@conditions,stages,sources)
      @table_headers = [t(:label_name),t(:label_contact),t(:label_owner),t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_stage),t(:text_source)]
      column_widths = { 0 => 110, 1 => 100, 2 => 100 , 3 => 40 , 4 => 40 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 , 9 => 60} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "source"
      col.group_by(&:source).each do |label,gcol|
        i_amount = amount
        gcol.each do |opp|
          amount +=  opp.amount if opp.amount
          hours += opp.estimated_hours if opp.estimated_hours
          data << [opp.name,
#                   opp.contact.nil? ? "" :opp.contact.full_name,
#                   opp.contact.nil? ? "" :opp.contact.get_account_name,
                    opp.try(:contact).try(:full_name),
                    opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   stages[opp.stage],
                   opp.get_assigned_to]
        end

        key = sources[label].to_s
        @total_data[key] = data
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),hours.to_f.fixed_precision(2)]
        data = []
        i_amount = 0
        hours = 0
      end
      @table_headers = [t(:label_name),t(:label_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_stage),t(:label_owner)]
      column_widths = { 0 => 110, 1 => 100, 2 => 100 , 3 => 40 , 4 => 40 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 , 9 => 60} if params[:format] == "pdf"
    end
    alignment = { 0 => :left, 1 => :left, 2 => :left , 3 => :center , 4=> :center ,5 => :center , 6 => :center ,7 => :center , 8 => :left , 9 => :left} if params[:format] == "pdf"
    return column_widths,amount.to_f.fixed_precision(2),alignment
  end


  # This method generate group_by clause
  #    Group by Opportunity stage and stage is not closed i.e lvalue[closes/won,closed/lost]
  def group_opportunity_open_rpt(tcol,stages)
    total_age,amount,hours,data,@total_data,column_widths,today,total_overall_age,total_overall_length,total_avg_age = 0,0,0,[],{},{},Time.zone.now.to_date,0,0,0
    @conditions[:total_avg_age] = 0
    if params[:report][:summarize_by] == "stage"
      tcol.group_by(&:stage).each do |label, col|
        key = nil
        i_amount = amount
        col.each do |opp|
          amount +=  opp.amount if opp.amount
          created = opp.created_at.to_date
          age = (today-created).to_i
          total_age += age
          hours += opp.estimated_hours if opp.estimated_hours
          
          data << [opp.name,                  
                   opp.try(:contact).try(:full_name),
                   opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   age,
                   opp.get_assigned_to]
        end
        key = stages[label]
        @total_data[key] = data
        avg_age = total_age/col.length
        total_overall_age += total_age
        total_overall_length += col.length
        total_avg_age = total_overall_age/total_overall_length
        @conditions[:total_avg_age] = total_avg_age
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2) ,avg_age ,hours.to_f.fixed_precision(2)]
        total_age = 0
        data = []
        hours = 0
      end
      @table_headers = [t(:label_name),t(:label_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:label_age),t(:label_assigned_to)]
      column_widths = { 0 => 90, 1 => 90, 2 => 90 , 3 => 40 , 4 => 50 , 5 => 50 , 6 => 40 ,7 => 40 , 8 => 40 , 9 => 80} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "owner"
      tcol.group_by(&:assigned_to_employee_user_id).each do |label, col|
        key = nil
        i_amount = amount
        col.each do |opp|
          amount +=  opp.amount if opp.amount
          created = opp.created_at.to_date
          age = (today-created).to_i
          total_age += age
		      hours += opp.estimated_hours if opp.estimated_hours
          key = opp.get_assigned_to unless key
          data << [opp.name,
#                   opp.contact.nil? ? '' : opp.contact.full_name,
#                   opp.contact.nil? ? '' : opp.contact.get_account_name,
                   opp.try(:contact).try(:full_name),
                   opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   age,
                   stages[opp.stage]]
        end
        @total_data[key.to_s] = data
        avg_age = total_age/col.length
        total_overall_age += total_age
        total_overall_length += col.length
        total_avg_age = total_overall_age/total_overall_length
        @conditions[:total_avg_age] = total_avg_age
        @conditions[key.to_s] = [(amount-i_amount).to_f.fixed_precision(2),avg_age,hours.to_f.fixed_precision(2)]
        total_age = 0
        data = []
		    hours = 0
      end
      @table_headers = [t(:label_name),t(:label_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:label_age),t(:text_stage)]
      column_widths = { 0 => 90, 1 => 90, 2 => 90 , 3 => 40 , 4 => 50 , 5 => 50 , 6 => 40 ,7 => 40 , 8 => 40 , 9 => 80} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "contact"
      tcol.group_by(&:contact_id).each do |label, col|
        key = nil
        i_amount = amount
        col.each do |opp|
          amount +=  opp.amount if opp.amount
          hours += opp.estimated_hours if opp.estimated_hours
          created = opp.created_at.to_date
          age = (today-created).to_i
          total_age += age
          key = opp.try(:contact).try(:full_name) unless key
          data << [opp.name,
                    opp.try(:contact).try(:full_name),
                    opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   age,
                   stages[opp.stage]]
        end
        @total_data[key] = data
        avg_age = total_age/col.length
        total_overall_age += total_age
        total_overall_length += col.length
        total_avg_age = total_overall_age/total_overall_length
        @conditions[:total_avg_age] = total_avg_age
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),avg_age,hours.to_f.fixed_precision(2)]
        total_age = 0
        data = []
        hours = 0 
      end
      @table_headers = [t(:label_name),t(:label_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:label_age),t(:text_stage)]
      column_widths = { 0 => 90, 1 => 90, 2 => 90 , 3 => 40 , 4 => 50 , 5 => 50 , 6 => 40 ,7 => 40 , 8 => 40 , 9 => 80} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "account"
      # Grouping is handled by below code. As no account column in opportunities table
      @total_data,@conditions,amount = group_opp_open_accounts(tcol,@total_data,@conditions,stages,today)
      @table_headers = [t(:label_name),t(:label_contact),t(:label_contact),t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:label_age),t(:text_stage)]
      column_widths = { 0 => 90, 1 => 90, 2 => 90 , 3 => 40 , 4 => 50 , 5 => 50 , 6 => 40 ,7 => 40 , 8 => 40 , 9 => 80} if params[:format] == "pdf"
    elsif params[:report][:summarize_by] == "source"
      lookup_source = current_company.company_sources
      sources = ReportsHelper.get_lookups(lookup_source)
      sources[""] , sources[nil] = "",""
      
      tcol.group_by(&:source).each do |label, col|
        i_amount = amount
        col.each do |opp|
          amount +=  opp.amount if opp.amount
          hours += opp.estimated_hours if opp.estimated_hours
          created = opp.created_at.to_date
          age = (today-created).to_i
          total_age += age
          data << [opp.name,
#                   opp.contact.nil? ? '' : opp.contact.full_name,
#                   opp.contact.nil? ? '' : opp.contact.get_account_name,
                    opp.try(:contact).try(:full_name),
                    opp.try(:contact).try(:get_account_name),
                   opp.amount ? opp.amount.to_f.fixed_precision(2) : "",
                   opp.estimated_hours.to_f.fixed_precision(2),
                   opp.probability ? opp.probability.to_s + "%" : "",
                   opp.created_at ? opp.created_at.strftime('%m/%d/%y') : "",
                   opp.closes_on ? opp.closes_on.strftime('%m/%d/%y') : "",
                   stages[opp.stage],
                   age,
                   opp.get_assigned_to]
        end
        
        key = sources[label]

        @total_data[key] = data
        avg_age = total_age/col.length
        total_overall_age += total_age
        total_overall_length += col.length
        total_avg_age = total_overall_age/total_overall_length
        @conditions[:total_avg_age] = total_avg_age
        @conditions[key] = [(amount-i_amount).to_f.fixed_precision(2),avg_age,hours.to_f.fixed_precision(2)]
        total_age = 0
        data = []
		    hours = 0
      end
      @table_headers = [t(:label_name),t(:label_contact),"#{t(:label_Account)}",t(:text_amt),"#{t(:text_est)} #{t(:text_hour)}",t(:text_probability),t(:text_created),t(:label_closure),t(:text_stage),t(:label_age),t(:label_owner)]
      column_widths = { 0 => 90, 1 => 90, 2 => 90 , 3 => 40 , 4 => 50 , 5 => 50 , 6 => 40 ,7 => 40 , 8 => 80 , 9 => 40 , 10 => 70} if params[:format] == "pdf"
    end
    alignment={1=>:left,2=>:left,3=>:left,4=>:center,5=>:center,6=>:center,7=>:center,8=>:center,9=>:left,10=>:center,11=>:left} if params[:format] == "pdf"
    @conditions[:amount] = amount.to_f.fixed_precision(2)
    return column_widths,alignment
  end
  
end
