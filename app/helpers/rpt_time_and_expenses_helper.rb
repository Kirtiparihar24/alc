module RptTimeAndExpensesHelper

  private

  def set_time_accounted_conditions(conditions_hash)
    
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND employee_user_id=:assign_to '
    else
      search = 'company_id=:company_id '
    end

    if params[:report][:selected] == "matter"
      
      unless params[:report][:matter_id].blank?
        search += "AND matter_id = :matter_id "
        conditions_hash[:matter_id] = params[:report][:matter_id].to_i
      else
        search += "AND matter_id is not :null "
        conditions_hash[:null] = nil
      end
    elsif params[:report][:selected] == "contact"
      
      unless params[:report][:contact_id].blank?
        search += "AND contact_id = :contact_id "
        conditions_hash[:contact_id] = params[:report][:contact_id].to_i
        unless params[:report][:matter_id].blank?
          search += "AND matter_id = :matter_id "
          conditions_hash[:matter_id] = params[:report][:matter_id].to_i
        end
      else
        search += "AND contact_id is not :null "
        conditions_hash[:null] = nil
      end
      
    elsif params[:report][:selected] == "internal"
      search += "AND  is_internal = :internal "
      conditions_hash[:internal] = true
    end

    
    

    [search,conditions_hash]
    
  end


  def set_time_billed_conditions(checked)
    if checked == 'My'
      search = 'company_id=:company_id AND employee_user_id=:assign_to and matter_people_id is null '
    else
      search = 'company_id=:company_id  and matter_people_id is null '
    end
  end

  def set_matter_acct_conditions(conditions_hash)
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND employee_user_id=:assign_to '
    else
      search = 'company_id=:company_id '
    end
    unless params[:report][:matter_id].blank?
      search += "AND matter_id = :matter "
      conditions_hash[:matter] = params[:report][:matter_id].to_i
    else
      search += "AND matter_id is not :null "
      conditions_hash[:null] = nil
    end
    [search,conditions_hash]
  end

  def set_contact_acct_conditions(conditions_hash)
    if params[:get_records] == 'My'
      search = 'company_id=:company_id AND employee_user_id=:assign_to '
    else
      search = 'company_id=:company_id '
    end
    unless params[:report][:contact_id].blank?
      search += "AND contact_id = :contact "
      conditions_hash[:contact] = params[:report][:contact_id].to_i
    else
      search += "AND contact_id is not :null "
      conditions_hash[:null] = nil
    end
    unless params[:report][:matter_id].blank?
      search += "AND matter_id = :matter_id "
      conditions_hash[:matter_id] = params[:report][:matter_id].to_i
    end
    [search,conditions_hash]
  end


  #This method is used to set date conditions in search string
  def append_time_expense_date_cond(search,r_name,conditions_hash)
    
    search += "AND time_entry_date Between :start_date AND :end_date "
    
    time = nil
    case params[:report][:duration]
    when "1" #1 week
      time = 7.days.ago
    when "2" #2 weeks
      time = 14.days.ago
    when "3" #1month
      time = Time.zone.now.last_month
    when "4" #3months
      3.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    when "range" #Date Range
      r_name += " entered between #{params[:date_start]} - #{params[:date_end]}"
      conditions_hash[:start_date] = params[:date_start].to_time
      conditions_hash[:end_date] = params[:date_end].to_time + (23.9*60*60)
    end
    if params[:report][:duration] != "range"
      conditions_hash[:start_date] = time
      conditions_hash[:end_date] = Time.zone.now
    end
    [search,r_name]
  end


  #This method is used to get the report name
  def set_report_name(r_type,hash)
    r_name = nil
    case r_type
    when 1
      if params['get_records'] == 'My'
        r_name = "#{t(:text_time)} Accounted for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_time)} Accounted for #{hash[:l_firm]}"
      end
    when 2
      if params['get_records'] == 'My'
        r_name = "#{t(:text_time)} #{t(:label_Billed)} for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_time)} #{t(:label_Billed)} for #{hash[:l_firm]}"
      end
    when 3
      if params['get_records'] == 'My'
        r_name = "#{t(:text_matter)} #{t(:text_accounting)} for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_matter)} #{t(:text_accounting)} for #{hash[:l_firm]}"
      end
    else
      if params['get_records'] == 'My'
        r_name = "#{t(:text_contact)} #{t(:text_accounting)} for #{hash[:lawyer]}"
      else
        r_name = "#{t(:text_contact)} #{t(:text_accounting)} for #{hash[:l_firm]}"
      end
    end
    r_name
  end

  

  # This method generate group_by clause
  #  Group by Matter( or matter_id) or
  #  Group by Contact( or Contact_id) or
  #  Group by internal( or internal)
  #  and duration
  def group_time_accounted_hash(params,tcol)
    lookup_activities = current_company.company_activity_types
    activities = ReportsHelper.get_lookups(lookup_activities)
    conditions,data,total_data,table_headers = {},[],{},[]
    duration,billamount,discount,override,finalamount = 0,0,0,0,0
    if params[:report][:selected] == "matter"

      tcol.group_by(&:matter_id).each do|label,col|
        key = nil
        client = nil
        col.each do |obj|
          @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
          if  !key and obj.matter
            key = obj.matter.clipped_name
            client = "  Contact : " + (obj.matter.contact ? obj.matter.contact.name : "")
          end
          duration += actual_duration.to_f if actual_duration
          billamount = billamount + (obj.actual_activity_rate * actual_duration.to_f)
          discount += obj.billing_percent if obj.billing_percent
          override += obj.final_billed_amount if obj.billing_method_type == 3
          finalamount += obj.final_billed_amount if obj.final_billed_amount


          data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize),actual_duration,activities[obj.activity_type],obj.is_billable ? "Yes" : "No",obj.actual_activity_rate,obj.actual_activity_rate * actual_duration.to_f,obj.billing_percent,obj.billing_method_type == 3 ? obj.final_billed_amount : '',obj.final_billed_amount]
        end
        next unless key
        total_data[key] = data
        conditions[key] = client

        data = []
      end
      conditions[:entries] = [duration,billamount,discount,override,finalamount]
      column_widths = { 0 => 60, 1 => 80, 2 => 80 , 3 => 120 , 4 => 60 , 5 => 60 , 6 => 60 ,7 => 70 , 8 => 60 , 9 => 60}
      table_headers = [t(:label_date),t(:text_lawyer),t(:label_duration_hrs),t(:text_activity_type),t(:text_billable),"Rate/hr($)","#{t(:text_bill)} #{t(:text_amt)}",t(:text_discount_p),"#{t(:text_override)} #{t(:text_amt)}","#{t(:label_final_bill)} #{t(:text_amt)}"]
      alignment = { 0 => :right, 1 => :right} if params[:format] == "pdf"
    elsif params[:report][:selected] == "contact"
      tcol.group_by(&:contact_id).each do|label,col|
        key = nil

        col.each do |obj|
          @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
          if  !key and obj.contact
            key = obj.contact.name

          end
          duration += actual_duration.to_f if actual_duration
          billamount = billamount + (obj.actual_activity_rate * actual_duration.to_f)
          discount += obj.billing_percent if obj.billing_percent
          override += obj.final_billed_amount if obj.billing_method_type == 3
          finalamount += obj.final_billed_amount if obj.final_billed_amount

          data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize),obj.matter ? obj.matter.clipped_name : "",actual_duration,activities[obj.activity_type],obj.is_billable ? "Yes" : "No",obj.actual_activity_rate,obj.actual_activity_rate * actual_duration.to_f,obj.billing_percent,obj.billing_method_type == 3 ? obj.final_billed_amount : '',obj.final_billed_amount]
        end
        next unless key
        total_data[key] = data

        data = []
      end
      conditions[:entries] = [duration,billamount,discount,override,finalamount]
      column_widths = { 0 => 60, 1 => 80, 2 => 80 , 3 => 60 , 4 => 80 , 5 => 60 , 6 => 60 ,7 => 60 , 8 => 70 , 9 => 60,10 => 60}
      table_headers = [t(:label_date),t(:text_lawyer),t(:text_matter),t(:label_duration_hrs),t(:text_activity_type),t(:text_billable),"#{t(:label_rate_hr)}","#{t(:text_bill)} #{t(:text_amt)}",t(:text_discount_p),"#{t(:text_override)} #{t(:text_amt)}","#{t(:label_final_bill)} #{t(:text_amt)}"]
      end

    [total_data,conditions,table_headers,column_widths, alignment]

  end

  # This method generate group_by clause
  #  Group by Matter( or matter_id) or
  #  and duration
  def group_time_accounted_array(params,tcol)
     
    conditions,data,table_headers,duration = {},[],[],0
    
    
    lookup_activities = current_company.company_activity_types
    activities = ReportsHelper.get_lookups(lookup_activities)

    if params[:report][:selected] == "all"
      billamount,discount,override,finalamount,num_discount = 0,0,0,0,0
      tcol.each do |obj|
        @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)

        duration += actual_duration.to_f if actual_duration
        unless obj.is_internal
          billamount = billamount + (obj.actual_activity_rate * actual_duration.to_f)
#          discount += obj.billing_percent if obj.billing_percent
          if obj.billing_percent
            discount += obj.billing_percent
            num_discount += 1
          end
          override += obj.final_billed_amount if obj.billing_method_type == 3
          finalamount += obj.final_billed_amount if obj.final_billed_amount
        end

        unless obj.is_internal  #Not Internal
          data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize),obj.contact ? obj.contact.name : "",obj.matter ? obj.matter.clipped_name : "","No",actual_duration,activities[obj.activity_type],obj.is_billable ? "Yes" : "No",obj.actual_activity_rate,obj.actual_activity_rate * actual_duration.to_f,obj.billing_percent,obj.billing_method_type == 3 ? obj.final_billed_amount : '',obj.final_billed_amount]
        else
          data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize), "N.A","N.A","Yes",actual_duration,activities[obj.activity_type],"N.A","N.A","N.A","N.A","N.A","N.A"]
        end
      end
      # This condition applied to avoid 0/0 = (Not A Number) with ref to Bug -Bug #7108 Shows junk value in T&E PDF report --Rahul P.
      if (discount>0 and num_discount>0)
          discount = (discount.to_f/num_discount.to_f)
      else
          discount = 0
      end
      #raise discount.inspect
      conditions[:table_width] = 750
      conditions[:all_entries] = [duration,billamount,discount,override,finalamount]
      column_widths = { 0 => 60, 1 => 60, 2 => 60 , 3 => 60 , 4 => 40 , 5 => 70 , 6 => 60 ,7 => 40 , 8 => 60 , 9 => 60,10 => 60,11 => 60 , 12 => 60}
      table_headers = [t(:label_date),t(:text_lawyer),t(:label_client),t(:text_matter),t(:label_internal),t(:label_duration_hrs),t(:text_activity_type),t(:text_billable),"#{t(:label_rate_hr)}","#{t(:text_bill)} #{t(:text_amt)}",t(:text_discount_p),"#{t(:text_override)} #{t(:text_amt)}","#{t(:label_final_bill)} #{t(:text_amt)}"]
      alignment = { 0 => :center, 1 => :left,2 => :left, 3 => :left,4 => :center,6 => :left, 7 => :center,10=>:center} if params[:format] == "pdf"
   
    elsif params[:report][:selected] == "internal"
      
        
      tcol.each do |obj|
        @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
        duration += actual_duration.to_f if obj.actual_duration
        data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize),actual_duration,activities[obj.activity_type]]
      end
      conditions[:internal_entries] = [duration]
      table_headers = [t(:label_date),t(:text_lawyer),t(:label_duration_hrs),t(:text_activity_type)]
      column_widths = { 0 => 100, 1 => 100, 2 => 100 , 3 => 100}       
    end
     
    [data,conditions,table_headers,column_widths, alignment]
    
  end


   #This method generates time entries as per the
   # Duration  selected
  def group_time_billed(tcol)
    conditions,data,total_data,table_headers = {},[],{},[]
    #Grouping by Lawyer
    hours,billedhrs,amt = 0,0,0
    tcol.group_by(&:employee_user_id).each_value do|col|
      
      key = nil
      array = []
      #Grouping by Time entry to calculate total hours billed for particular tima entry date  for individual lawywer
      col.group_by(&:time_entry_date).each do |label,gcol|

        t_hours,billable_hours,famount = 0,0,0
       
        gcol.each do|obj|
        @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
          key = obj.performer.try(:full_name).try(:titleize) unless key
          t_hours += actual_duration.to_f
          if obj.is_billable  #if billable
            billable_hours += actual_duration.to_f
          end
          famount += obj.final_billed_amount
                     
        end
        if t_hours == billable_hours
          billpercent = "100 %"
        elsif billable_hours == 0
          billpercent = ""
        else
          billpercent = ((billable_hours/t_hours.to_f) * 100).roundf2(2).to_s + " %"
        end
        hours += t_hours
        billedhrs += billable_hours
        amt += famount
        data << [label.to_s,t_hours,billable_hours,billpercent,famount]
        unless conditions[key]
          conditions[key] = [t_hours,billable_hours,famount]
        else
          conditions[key][0] += t_hours
          conditions[key][1] += billable_hours
          conditions[key][2] += famount
        end #storing each tables result data
      end
      total_data[key] = data
      data = []
    end
    conditions[:expenses] = [hours,billedhrs,amt]
    column_widths = { 0 => 100, 1 => 100, 2 => 100 , 3 => 100,4 => 100 }
    alignment = { 0 => :center, 1 => :center, 2 => :center , 3 => :center,4 => :center }
    table_headers = [t(:label_date),"#{t(:text_hour)} #{t(:text_accounted)}",t(:text_hoursbilled),t(:text_hoursbilledpercent),t(:text_amt)]
    [total_data,conditions,table_headers,column_widths,alignment]
  end


  # This method generate group_by clause
  #  Group by Contact( or Contact_id) or
  #  and duration
  def group_matter_accounting_rpt(tcol,ecol)
    conditions,data,total_data,total_expenses,matter_name = {},[],{},{},nil
    lookup_activities = current_company.company_activity_types
    activities = ReportsHelper.get_lookups(lookup_activities)
    lookup_activities = Physical::Timeandexpenses::ExpenseType.find(:all)
    exp_activities = ReportsHelper.get_lookups(lookup_activities)
    tcol.group_by(&:matter_id).each_value do|col|
      key,contact = nil,nil
      duration,billamount,discount,override,markup,finalamount = 0.00,0.00,0.00,0.00,0.00,0.00
      col.each do |obj|
        @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
        next unless obj.matter
        key = obj.matter.clipped_name unless key
        matter_name = obj.matter.name unless matter_name
        contact = (obj.matter.contact ? obj.matter.contact.name : nil) unless contact
        duration += actual_duration.to_f if actual_duration
        billamount = billamount + (obj.actual_activity_rate * actual_duration.to_f)
        discount += obj.billing_percent if obj.billing_percent
        override += obj.final_billed_amount if obj.billing_method_type == 3
        finalamount += obj.final_billed_amount if obj.final_billed_amount 
        data << [obj.time_entry_date.to_s,obj.performer.try(:full_name).try(:titleize),rounding(actual_duration.to_f),activities[obj.activity_type],obj.is_billable ? "Yes" : "No",rounding(obj.actual_activity_rate),rounding(obj.actual_activity_rate * actual_duration.to_f),rounding(obj.billing_percent),obj.billing_method_type == 3 ? rounding(obj.final_billed_amount) : '',rounding(obj.final_billed_amount)]
      end
      next unless key
      
      total_data[key] = data
      conditions[key] = [contact,rounding(duration),rounding(billamount),rounding(discount),rounding(override),rounding(finalamount),matter_name]
      data = []
    end

    ecol.group_by(&:matter_id).each_value do|col| 
      key,contact = nil,nil
      override,finalamount,markupamt,bill_amount,disc_sum = 0.00,0.00,0.00,0.00,0.00
      col.each do |obj|
        next unless obj.matter
        bill_amount += obj.expense_amount if obj.expense_amount
        disc_sum += obj.billing_percent if obj.billing_percent
        override += obj.final_expense_amount if obj.billing_method_type == 3
        markupamt += obj.markup if obj.markup
        finalamount += obj.final_expense_amount if obj.final_expense_amount
        key = obj.matter.clipped_name unless key
        contact = (obj.matter.contact ? obj.matter.contact.name : nil) unless contact
        data << [obj.expense_entry_date.to_s,obj.performer.try(:full_name).try(:titleize),exp_activities[obj.expense_type],obj.is_billable ? "Yes" : "No",rounding(obj.expense_amount),rounding(obj.billing_percent),obj.billing_method_type == 3 ? rounding(obj.final_expense_amount) : '',markupamt,rounding(obj.final_expense_amount)]
      end
      next unless key
     
      total_expenses[key] = [data,rounding(override),rounding(finalamount),rounding(bill_amount),rounding(disc_sum),rounding(markupamt)]
      unless conditions.has_key?(key)
        conditions[key] = [contact]
      end
      data = []
    end
    [total_data,total_expenses,conditions]
       
  end


  def group_contact_accounting_rpt(tcol,ecol)
    
    conditions,data,total_data,total_expenses = {},[],{},{}
    lookup_activities = current_company.company_activity_types
    activities = ReportsHelper.get_lookups(lookup_activities)
    lookup_activities = Physical::Timeandexpenses::ExpenseType.find(:all)
    exp_activities = ReportsHelper.get_lookups(lookup_activities)
    tcol.group_by(&:contact_id).each_value do|col|
      key = nil
      
      duration,billamount,discount,override,finalamount = 0,0,0,0,0
      col.each do |obj|
       @dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(obj.actual_duration) : actual_duration = one_tenth_timediffernce(obj.actual_duration)
        key = obj.contact ? obj.contact.name : nil unless key
        duration += actual_duration.to_f if actual_duration
        billamount = billamount + (obj.actual_activity_rate * actual_duration.to_f)
        discount += obj.billing_percent if obj.billing_percent
        override += obj.final_billed_amount if obj.billing_method_type == 3
        finalamount += obj.final_billed_amount if obj.final_billed_amount
        data << [obj.time_entry_date,obj.performer.try(:full_name).try(:titleize),obj.matter ? obj.matter.clipped_name : "",rounding(actual_duration.to_f),activities[obj.activity_type],obj.is_billable ? "Yes" : "No",obj.actual_activity_rate,obj.actual_activity_rate * actual_duration.to_f,obj.billing_percent,obj.billing_method_type == 3 ? obj.final_billed_amount : '',obj.final_billed_amount]
      end
      next unless key
      
      total_data[key] = data
      conditions[key] = [0,duration,billamount,discount,override,finalamount]
      data = []
    end

    ecol.group_by(&:contact_id).each_value do|col|
      key = nil
      override,finalamount,markupamt,discount = 0,0,0.00,0.00
      col.each do |obj|
        override += obj.final_expense_amount if obj.billing_method_type == 3
        markupamt += obj.markup if obj.markup
        finalamount += obj.final_expense_amount if obj.final_expense_amount
        discount += obj.billing_percent if obj.billing_percent
        key = obj.contact ? obj.contact.name : nil unless key
        data << [obj.expense_entry_date,obj.performer.try(:full_name).try(:titleize),obj.matter ? obj.matter.clipped_name : "",exp_activities[obj.expense_type],obj.is_billable ? "Yes" : "No",obj.expense_amount,obj.billing_percent,obj.billing_method_type == 3 ? obj.final_expense_amount : '',markupamt,obj.final_expense_amount]
      end
      next unless key
     
      total_expenses[key] = [data,override,finalamount,markupamt,discount]
      data = []
    end


    [total_data,total_expenses,conditions]

  end
  

end
