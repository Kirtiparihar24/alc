module RptMattersHelper

  def set_matters_conditions(conditions_hash)
    if(is_access_matter? && params[:get_records] == "All")
      search = "matters.company_id = :company_id"
     elsif(params[:get_records] == "All")
      search = "matters.company_id = :company_id AND mp.employee_user_id = :assign_to"
    else
      search = "matters.company_id = :company_id AND matters.employee_user_id = :assign_to"
    end
    if params[:report][:status] != "All"
      search += " AND status_id = :status"
    elsif(params[:get_records] == "All" && !is_access_matter?)
      search += " AND mp.is_active = :isactive"
      conditions_hash[:isactive] = true
    end
    conditions_hash[:status] = params[:report][:status].to_i
    search
     
  end

  def matters_dist_conditions(conditions_hash)
    search = "company_id = :company_id "
    if params[:report][:status] != "All"
      conditions_hash[:status_id] = params[:report][:status].to_i
    end
    
    conditions_hash[:isactive] = true
    search
  end


  def matter_task_status_cond(conditions_hash)
    if(is_access_matter? && params[:get_records] == "All")
      search = "matters.company_id = :company_id"
    elsif(params[:get_records] == "All")
      search = "matters.company_id = :company_id AND mp.employee_user_id = :assign_to"
    else
      search = "matters.company_id = :company_id AND matters.employee_user_id = :assign_to"
    end
    if params[:report][:status] != "All"
      search += " AND status_id = :status"
    elsif(params[:get_records] == "All" && !is_access_matter?)
      search += " AND mp.is_active = :isactive"
      conditions_hash[:isactive] = true
    end
    search
  end


  #This method is used to set date conditions in search string
  def append_matter_date_cond(search,conditions_hash)

    
    search += " AND created_at Between :start_date AND :end_date " if  params[:get_records] == "My"
   
    time = nil
    case params[:report][:duration]
    when "1" #1 months
      time = Time.zone.now.last_month
    when "2" #3 months
      3.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    when "3" #6 months
      6.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    else #date range given
      conditions_hash[:start_date] = params[:date_start].to_time
      conditions_hash[:end_date] = params[:date_end].to_time + (23.9*60*60)
    end
    if params[:report][:duration] != "range"
      conditions_hash[:start_date] = time
      conditions_hash[:end_date] = Time.zone.now
    end
    search
  end


  def append_matter_duration_date_cond(search,conditions_hash)
    search += " AND created_at Between :start_date AND :end_date " if  params[:get_records] == "My"

    time = nil
    case params[:report][:duration]
    
    when "1" #3 months
      3.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    when "2" #6 months
      6.times do |i|
        unless time
          time = Time.zone.now.last_month
        else
          time = time.last_month
        end
      end
    when "3"
      time = Time.zone.now.last_year
    else #date range given
      conditions_hash[:start_date] = params[:date_start].to_time
      conditions_hash[:end_date] = params[:date_end].to_time + (23.9*60*60)
    end
    if params[:report][:duration] != "range"
      conditions_hash[:start_date] = time
      conditions_hash[:end_date] = Time.zone.now
    end
    search
  end


  #This method is used to get the report name
  def set_report_name(r_type,hash)
    
    case r_type
    when 1
      "#{t(:text_matter)} Time spent"
    when 2
      "#{t(:text_matter)} Activity Status"
    when 3
      "#{t(:text_matter)} Activity Legal team"
    when 4
      "#{t(:text_matter)} Distribution"
    when 5
      "#{t(:text_matter)} Duration & Ageing"
    when 6
      "#{t(:text_matter)} Master"
    when 7
      "Revenue By #{t(:text_matter)} Type"
    end
    
  end


  def set_matters_master_conditions(conditions_hash)
    if(is_access_matter? && params[:get_records] == "All")
      search = "matters.company_id = :company_id"
    elsif(params[:get_records] == "All")
      search = "matters.company_id = :company_id AND mp.employee_user_id = :assign_to"
    else
      search = "matters.company_id = :company_id AND matters.employee_user_id = :assign_to"
    end
    if params[:report][:status] != "All"
      search += " AND status_id = :status"
    elsif(params[:get_records] == "All" && !is_access_matter?)
      search += " AND mp.is_active = :isactive"
      conditions_hash[:isactive] = true
    end
    conditions_hash[:status] = params[:report][:status].to_i
    if params[:date_selected]
        conditions_hash[:start_date] = params[:date_start].to_time
        conditions_hash[:end_date] = params[:date_end].to_time + (23.9*60*60)
    end
    search += " AND created_at Between :start_date AND :end_date " if  params[:get_records] == "My" and params[:date_selected]

    search
  end


  #Defines condition hash to get matters for revenue report of matter -Ketki 10/5/2011
  def set_matters_revenue_conditions(conditions_hash)
    search = "company_id = :company_id "
    if params[:date_selected]
        conditions_hash[:start_date] = params[:date_start].to_time
        conditions_hash[:end_date] = params[:date_end].to_time + (23.9*60*60)
    end
    search += " AND matter_type_id = :matter_type_id" unless params[:report][:summarize_by].blank?
    search += " AND created_at Between :date_start AND :date_end " if params[:date_selected].eql?("1")

    search
  end
  
  def sum_hrs(conditions,label)
    
    if conditions[:ehrs]
      
      conditions[:ehrs] = conditions[:ehrs].to_f + conditions[label][0].to_f
      conditions[:bhrs] = conditions[:bhrs].to_f + conditions[label][1].to_f
      conditions[:rhrs] = conditions[:rhrs].to_f + conditions[label][2].to_f
      
    else
      conditions[:ehrs] = conditions[label][0]
      conditions[:bhrs] = conditions[label][1]
      conditions[:rhrs] = conditions[label][2]
    end
    
  end

  # This method generate group_by clause
  #  Group by[LeadLawyer=>employee_user_id,Client=>contact_id,:account=>account,mater_type=>:matter_Category]
  #    and status(matter_status id) and matter start date
  def group_matter_time_spent(col)
    total_data,table_headers,conditions,data = {},{},{},[]
    if params[:report][:summarize_by] == "lead_lawyer"
      ehrs,bhrs,rhrs = 0,0,0
      col.group_by(&:employee_user_id).each do |label,matters|
        
        key = nil
        matters.each do|matter|
          key = matter.get_lawyer_name unless key
          est_hours = matter.estimated_hours ? matter.estimated_hours : 0
          bill_hours = 0
          matter.time_entries.select{|obj| obj.is_billable}.each do|e|
            actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(e.actual_duration) : one_tenth_timediffernce(e.actual_duration)
            bill_hours += actual_duration
          end
          
          rem_hours = (est_hours - bill_hours).abs
          ehrs += est_hours
          bhrs += bill_hours
          rhrs += rem_hours
          data << [matter.name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.accounts[0] ? matter.contact.accounts[0].name : "" : "",matter.matter_no,matter.matter_category,matter.matter_status ? matter.matter_status.alvalue : "",rounding(est_hours),rounding(bill_hours),rounding(rem_hours)]
        end
         
        conditions[key] = [rounding(ehrs),rounding(bhrs),rounding(rhrs)]
        total_data[key] = data
        sum_hrs(conditions,key)
        ehrs,bhrs,rhrs = 0,0,0
        data = []
         
      end
      column_widths = {0=> 100,1=> 100,2=> 100,3=> 60,4=> 50,5=> 50,6=> 60,7=> 60,8=> 100}
      table_headers = [t(:label_matter),t(:label_client),t(:label_Account),t(:text_matter_id),t(:label_type),t(:label_status),t(:text_estimated_hours),"#{t(:label_billable)} #{t(:text_hour)}","#{t(:text_projected)} #{t(:text_hour)}"]
    elsif params[:report][:summarize_by] == "client"
      ehrs,bhrs,rhrs = 0,0,0
      col.group_by(&:contact_id).each do |label,matters|
        key = nil
        matters.each do|matter|
          key = matter.contact ? matter.contact.name : nil unless key
          est_hours = matter.estimated_hours ? matter.estimated_hours : 0
          bill_hours = 0
          matter.time_entries.select{|obj| obj.is_billable}.each do|e|
            bill_hours += e.actual_duration
          end
          rem_hours = (est_hours - bill_hours).abs
          ehrs += est_hours
          bhrs += bill_hours
          rhrs += rem_hours
          data << [matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",matter.matter_no,matter.matter_category,matter.matter_status.lvalue,rounding(est_hours),rounding(bill_hours),rounding(rem_hours)]
        end

        conditions[key] = [rounding(ehrs),rounding(bhrs),rounding(rhrs)]
        total_data[key] = data
        sum_hrs(conditions,key)
        ehrs,bhrs,rhrs = 0,0,0
        data = []

      end
      column_widths = {0=> 100,1=> 100,2=> 100,3=> 60,4=> 50,5=> 50,6=> 60,7=> 60,8=> 100}
      table_headers = [t(:label_matter),t(:text_select_lawyer),"#{t(:label_Account)}",t(:text_matter_id),t(:label_type),t(:label_status),t(:text_estimated_hours),"#{t(:label_billable)} #{t(:text_hour)}","Projected hours"]
    elsif params[:report][:summarize_by] == "account"
      ehrs,bhrs,rhrs = 0,0,0
      matters = col.collect do |matter|
        est_hours = matter.estimated_hours ? matter.estimated_hours : 0
        bill_hours = 0
        matter.time_entries.select{|obj| obj.is_billable}.each do|e|
          bill_hours += e.actual_duration
        end
        rem_hours = (est_hours - bill_hours).abs
        account = matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "None" : "None"
        [matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",matter.matter_no,matter.matter_category,matter.matter_status.lvalue,rounding(est_hours),rounding(bill_hours),rounding(rem_hours),account]
      end
      matters_hash = {}
      matters.each do |matter|
        key = matter.pop
        if matters_hash.has_key?(key)
          matters_hash[key] << matter
        else
          matters_hash[key] = [matter]
        end
      end
      matters_hash.each do |label,matters|
        matters.each do |matter|
          ehrs += matter[-3].to_f
          bhrs += matter[-2].to_f
          rhrs += matter[-1].to_f
        end
        conditions[label] = [rounding(ehrs),rounding(bhrs),rounding(rhrs)]
        total_data[label] = matters
        sum_hrs(conditions,label)
      end
      
      column_widths = {0=> 100,1=> 100,2=> 100,3=> 60,4=> 50,5=> 50,6=> 60,7=> 60,8=> 100}
      table_headers = [t(:label_matter),t(:text_select_lawyer),t(:label_client),t(:text_matter_id),t(:label_type),t(:label_status),t(:text_estimated_hours),"#{t(:label_billable)} #{t(:text_hour)}","Projected hours"]
    elsif params[:report][:summarize_by] == "lit_type"
      ehrs,bhrs,rhrs = 0,0,0
      col.group_by(&:matter_category).each do |label,matters|
        matters.each do|matter|
          est_hours = matter.estimated_hours ? matter.estimated_hours : 0
          bill_hours = 0
          matter.time_entries.select{|obj| obj.is_billable}.each do|e|
            bill_hours += e.actual_duration
          end
          rem_hours = (est_hours - bill_hours).abs
          ehrs += est_hours
          bhrs += bill_hours
          rhrs += rem_hours
          data << [matter.name,matter.contact ? matter.contact.name : "",matter.get_lawyer_name,matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",matter.matter_no,matter.matter_status.lvalue,rounding(est_hours),rounding(bill_hours),rounding(rem_hours)]
        end
        label = label.try(:capitalize)
        conditions[label] = [rounding(ehrs),rounding(bhrs),rounding(rhrs)]
        total_data[label] = data
        sum_hrs(conditions,label)
        ehrs,bhrs,rhrs = 0,0,0
        data = []

      end
      column_widths = {0=> 100,1=> 100,2=> 100,3=> 60,4=> 50,5=> 50,6=> 60,7=> 60,8=> 100}
      table_headers = [t(:label_matter),t(:label_client),t(:text_select_lawyer),"#{t(:label_Account)}",t(:text_matter_id),t(:label_status),t(:text_estimated_hours),"#{t(:label_billable)} #{t(:text_hour)}","Projected hours"]
    end
    alignment = {0=> :left,1=> :left,2=> :left,3=> :center,4=> :center,5=>:center,6=> :center,7=> :center,8=> :center} if params[:format] == "pdf"
    [total_data,table_headers,conditions,column_widths,alignment]
  end


  # This method generate
  #    and matter status
  #      start date
  def get_matter_distribution(lawyers,matter_peoples,conditions_hash)
    data = []
    tmatters,tlead,tlit,tnonlit,conditions = 0,0,0,0,{}

    matter_peoples.group_by(&:employee_user_id).each do|label,col|
     
      lawyer = nil
      litigation,nonlitigation = 0,0
#     col.collect do |matter_people|
#        matter_people.collect do |mp|
#          mp.matter if mp.matter && mp.matter.status_id ==554 && mp.matter.created_at >= conditions_hash[:start_date] and mp.matter.created_at <= conditions_hash[:end_date]}.flatten.compact.uniq.
#        end
#      end
      matters = col.collect do |matter_people|
        matter = matter_people.matter
        
        matter = if matter and matter.matter_status and (params[:report][:status] != "All" ? matter.status_id == conditions_hash[:status_id].to_i : true) and (matter.created_at >= conditions_hash[:start_date] and matter.created_at <= conditions_hash[:end_date])
          if matter.matter_category == "litigation"
            litigation += 1
          else
            nonlitigation += 1
          end
          matter
        end
      end #col.collect do |matter_people|
      matters.compact!
      lawyer = lawyers.detect do|lawyer|
        lawyer.id == label
      end
      next unless lawyer

      lmatters = []
      mlength = matters.length
      unless mlength == 0
        tmatters += mlength
        tlit += litigation
        tnonlit += nonlitigation
        litper = ((litigation/mlength.to_f) * 100).roundf2(2)
        nollitper = 100 - litper
        litigation = "#{litigation} (#{litper}%)" unless litigation == 0.0
        nonlitigation = "#{nonlitigation} (#{nollitper}%)"  unless nonlitigation == 0
        
          lmatters = lawyer.matters.select do|matter|
            unless matter.matter_date.nil?
            (params[:report][:status] != "All" ? (matter.matter_status ? matter.status_id == conditions_hash[:status_id].to_i : false) : true) and (matter.matter_date.to_time >= conditions_hash[:start_date] and matter.matter_date.to_time <= conditions_hash[:end_date])
            end
        end
        
        tlead += lmatters.length
      end
      data << ["#{lawyer.first_name} #{lawyer.last_name}",mlength,lmatters.length,litigation,nonlitigation]
        
        
    end
    conditions[:details] = [tmatters,tlead,tlit,tnonlit]
    unless tmatters == 0
      tlitper = ((tlit/tmatters.to_f) * 100).roundf2(2)
      tnonlitper = 100 - tlitper
      tlit = "#{tlit} (#{tlitper}%)" unless tlitper == 0.0
      tnonlit = "#{tnonlit} (#{tnonlitper}%)" unless tnonlitper == 0.0
      conditions[:details] = [tmatters,tlead,tlit,tnonlit]
    end
    table_headers =["#{t(:label_employee)} #{t(:text_name)}","No. of Matters involved in","Involved as a Lead Lawyer",t(:text_litigation),t(:text_non_litigation)]
    [data,table_headers,conditions]
  end

  def task_overdue(date,obj=nil)
    date.to_date < Time.zone.now.to_date if date && obj.overdue?
  end

  def todays_tasks(date,obj=nil)
    if obj.end_date.present?
       obj.start_date.to_date <= Time.zone.now.to_date && Time.zone.now.to_date <= obj.end_date.to_date
    else
       date.to_date <= Time.zone.now.to_date
    end
  end

  def next_weeks_tasks(date,obj=nil)
    today = Time.zone.now.to_date
    date.to_date >= today and date.to_date <= today.next_week.to_date ? true : false if date
  end

  def next_two_weeks_tasks(date,obj=nil)
    today = Time.zone.now.to_date
    date.to_date >= today and date.to_date <= today + 14 ? true : false if date
  end

  def next_one_month(date,obj=nil)
    today = Time.zone.now.to_date
    date.to_date >= today and date.to_date <= today.next_month.to_date ? true : false if date
  end

  def date_range_tasks(date,obj=nil)
    date.to_date >= params[:date_start].to_date and date.to_date <= params[:date_end].to_date ? true : false if date
  end

  def all_tasks(date,obj=nil)
    true
  end

  def use_method
    case params[:report][:duration]
    when "1"
      "task_overdue"
    when "2"
      "todays_tasks"
    when "3"
      "next_weeks_tasks"
    when "4"
      "next_two_weeks_tasks"
    when "5"
      "next_one_month"
    when "6"
      "all_tasks"
    else
      "date_range_tasks"
    end
  end

  
  def check_task_status(status,date)
    if params[:report][:task_status] == "All"
      true
    elsif params[:report][:task_status] == "Completed"
      status
    elsif (params[:report][:task_status] == "Open" || params[:report][:task_status] == "Overdue") and not status
      true
    elsif params[:report][:task_status] == "Overdue" and not status
      (date < Time.zone.now.to_date)
    end
  end

  # This method generate group_by clause
  #    Group by[LeadLawyer=>employee_user_id,Client=>contact_id,:account=>account,mater_type=>:matter_Category]
  #    and [if client_activity = matter_task[client_task=true]] and matter status[Hard coded]
  #    and deadline[i.e date range overdue]
  def group_matter_task_status(col)
    total_data,table_headers,conditions,data,total_tasks = {},{},{},[],0
    method = use_method
    if params[:report][:summarize_by] == "lead_lawyer"
      col.group_by(&:employee_user_id).each do |label,matters|
        key = nil
        matters.each do|matter|
          key = matter.get_lawyer_name unless key
          matter.matter_tasks.each do|task_obj|
            next unless params[:report][:task_type] != "All" ? task_obj.client_task : true
            date = task_obj.send(task_obj.category == "todo" ? "end_date": "start_date")
            next unless check_task_status(task_obj.completed,date)
            next unless self.send(method,date.to_date,task_obj)
            total_tasks += 1
            data << [matter.matter_no,matter.name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),(task_obj.matter_people && task_obj.matter_people.assignee) ? task_obj.matter_people.try(:assignee).try(:full_name).try(:titleize) : "",task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No"]
          end
        end
        total_data[key] = data if data != []
        data = []
      end
      column_widths = {0=> 90,1=> 100,2=> 80,3=> 80,4=> 80,5=> 80,6=> 80,7=> 60,8=> 60}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_client),"#{t(:label_Account)}",t(:text_activity_name),t(:text_due_date),t(:label_assigned_to),t(:text_status),"#{t(:label_client)}#{t(:text_activity)}"]
    elsif params[:report][:summarize_by] == "client"
      col.group_by(&:contact_id).each do |label,matters|
        key = nil
        matters.each do|matter|
          key = matter.contact ? matter.contact.name : nil unless key
          matter.matter_tasks.each do|task_obj|
            next unless params[:report][:task_type] != "All" ? task_obj.client_task : true
            date = task_obj.send(task_obj.category == "todo" ? "end_date": "start_date")
            next unless check_task_status(task_obj.completed,date)
            next unless self.send(method,date)
            total_tasks += 1
            data << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),(task_obj.matter_people && task_obj.matter_people.assignee) ? task_obj.matter_people.try(:assignee).try(:full_name).try(:titleize) : "",task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No"]
          end
        end
        total_data[key] = data if data != []

        data = []
      end
      conditions[:total_tasks] = total_tasks
      column_widths = {0=> 90,1=> 100,2=> 80,3=> 80,4=> 80,5=> 80,6=> 80,7=> 60,8=> 60}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),"#{t(:label_Account)}",t(:text_task_name),t(:text_due_date),t(:label_assigned_to),t(:label_status),"#{t(:label_client)}#{t(:text_to_do_task)}"]
    elsif params[:report][:summarize_by] == "account"
      col.each do |matter|
        matter.matter_tasks.each do|task_obj|
          next unless params[:report][:task_type] != "All" ? task_obj.client_task : true
          date = task_obj.send(task_obj.category == "todo" ? "end_date": "start_date")
          next unless check_task_status(task_obj.completed,date)
          next unless self.send(method,date)
          total_tasks += 1
          key = matter.contact ? matter.contact.accounts[0]? matter.contact.accounts[0].name : "None" : ""
          if total_data.has_key?(key)
            total_data[key] << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),(task_obj.matter_people && task_obj.matter_people.assignee) ? task_obj.matter_people.try(:assignee).try(:full_name).try(:titleize) : "",task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No"]
          else
            total_data[key] = [[matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),(task_obj.matter_people && task_obj.matter_people.assignee) ? task_obj.matter_people.try(:assignee).try(:full_name).try(:titleize) : "",task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No"]]
          end
         
        end
      end
      column_widths = {0=> 90,1=> 100,2=> 80,3=> 80,4=> 70,5=> 80,6=> 80,7=> 60,8=> 60}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),t(:label_client),t(:text_task_name),t(:text_due_date),t(:label_assigned_to),t(:label_status),"#{t(:label_client)}#{t(:text_to_do_task)}"]
    elsif params[:report][:summarize_by] == "matter_type"
      col.group_by(&:matter_category).each do |label,matters|
        matters.each do|matter|
          matter.matter_tasks.each do|task_obj|
            next unless params[:report][:task_type] != "All" ? task_obj.client_task : true
            date = task_obj.send(task_obj.category == "todo" ? "end_date": "start_date")
            next unless check_task_status(task_obj.completed,date)
            next unless self.send(method,date)
            total_tasks += 1
            data << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),(task_obj.matter_people && task_obj.matter_people.assignee) ? task_obj.matter_people.try(:assignee).try(:full_name).try(:titleize) : "",task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No"]
          end
        end
        total_data[label.capitalize] = data if data != []
        data = []
      end
      column_widths = {0=> 70,1=> 100,2=> 70,3=> 70,4=> 70,5=> 70,6=> 70,7=> 70,8=> 60,9 => 60}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),t(:label_client),"#{t(:label_Account)}",t(:text_task_name),t(:text_due_date),t(:label_assigned_to),t(:label_status),"#{t(:label_client)}#{t(:text_to_do_task)}"]
    end
    alignment={0=>:left,1=>:left,2=>:left,3=>:left,4=>:center,5=>:center,6=>:left,7=>:center,8=>:center} if params[:format] == "pdf"
    conditions[:total_tasks] = total_tasks
    [total_data,table_headers,conditions,column_widths,alignment]
  end # def 


  # This method generate group_by clause
  #   and [if client_activity = matter_task[client_task=true]] and matter status
  #    and deadline[i.e date range overdue]
  def group_matter_team_tasks(col)
    total_data,table_headers,conditions,data,total_tasks = {},{},{:users => {}},[],0
    
    method = use_method
    col.each do |matter|
      matter.matter_tasks.each do|task_obj|
        next unless params[:report][:task_type] != "All" ? task_obj.client_task : true
        date = task_obj.send(task_obj.category == "todo" ? "end_date": "start_date")
        next unless check_task_status(task_obj.completed,date)
        next unless self.send(method,date)
        total_tasks += 1
        next unless task_obj.matter_people && task_obj.matter_people.assignee
        unless conditions[:users].has_key?(task_obj.matter_people.assignee.id)
          conditions[:users][task_obj.matter_people.assignee.id] = task_obj.matter_people.assignee.try(:full_name).try(:titleize)
        end
        data << [matter.matter_no,matter.name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "None" : "",task_obj.name ,task_obj.end_date.strftime('%m/%d/%y'),task_obj.completed ? "Closed" : (date < Time.zone.now.to_date) ? "Overdue" : "Open",task_obj.client_task ? "Yes" : "No",task_obj.matter_people.assignee.id]
      end
    end
    data.each do|matter|
      key = matter.pop
      if total_data.has_key?(key)
        total_data[key] << matter
      else
        total_data[key] = [matter]
      end
    end
    conditions[:total_tasks] = total_tasks
    column_widths = {0=> 60,1=> 140,2=> 120,3=> 90,4=> 70,5=> 60,6=> 50,7=> 70}
    alignment={0=>:center,1=>:left,2=>:left,3=>:left,4=>:left,5=>:center,6=>:center,7=>:center} if params[:format] == "pdf"
    table_headers = [t(:label_matter_id),t(:label_matter),t(:text_client),"#{t(:label_Account)}",t(:text_activity_name),t(:text_due_date),t(:text_status),"#{t(:label_client)}#{t(:text_activity)}"]
    [total_data,table_headers,conditions,column_widths,alignment]
  end


  # This method generate group_by clause
  #    Group by[LeadLawyer=>employee_user_id,Client=>contact_id,:account=>account,mater_type=>:matter_Category]
  #    and status,created 
  #    and Ui display aging time
  def group_matter_duration(col)
    total_data,table_headers,conditions,data = {},{},{},[]
    
    today = Time.zone.now.to_date
    if params[:report][:summarize_by] == "lead_lawyer"
      col.group_by(&:employee_user_id).each_value do |matters|
        key = nil
        matters.each do|matter|
          key = matter.get_lawyer_name unless key
          created = matter.created_at
          data << [matter.matter_no,matter.name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",created.strftime('%m/%d/%y'),(today - created.to_date).to_i]
        end
        total_data[key] = data
        data = []
      end
      column_widths = {0=> 80,1=> 200,2=> 120,3=> 100,4=> 70,5=> 80}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_client),"#{t(:label_Account)}",t(:text_created),"#{t(:text_ageing)} #{t(:text_day_s)}"]
    elsif params[:report][:summarize_by] == "client"
      col.group_by(&:contact_id).each_value do |matters|
        key = nil
        matters.each do|matter|

#          following code is written to differentiate contacts with same names :sania wagle

          if matter.contact
            if total_data.has_key?(matter.contact.name)
               key = matter.contact.name.to_s + "_$"
            else
              key = matter.contact.name 
            end
          else
            key = ""
          end
          created = matter.created_at
          data << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",created.strftime('%m/%d/%y'),(today-created.to_date).to_i]
        end
        total_data[key] = data
        data = []
      end
      column_widths = {0=> 80,1=> 200,2=> 80,3=> 100,4=> 70,5=> 80}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),"#{t(:label_Account)}",t(:text_created),"#{t(:text_ageing)} #{t(:text_day_s)}"]
    elsif params[:report][:summarize_by] == "account"
      matters = col.collect do |matter|
        created = matter.created_at
        key = matter.contact ? matter.contact.accounts[0] ? matter.contact.accounts[0].name : "None" : "None"
        if total_data.has_key?(key)
          total_data[key] << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",created.strftime('%m/%d/%y'),(today-created.to_date).to_i]
        else
          total_data[key] = [[matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",created.strftime('%m/%d/%y'),(today-created.to_date).to_i]]
        end
      end
      column_widths = {0=> 80,1=> 200,2=> 80,3=> 120,4=> 70,5=> 80}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),t(:label_client),t(:text_created),"#{t(:text_ageing)} #{t(:text_day_s)}"]
    elsif params[:report][:summarize_by] == "matter_type"
      col.group_by(&:matter_category).each do |label,matters|
        matters.each do|matter|
          created = matter.created_at
          data << [matter.matter_no,matter.name,matter.get_lawyer_name,matter.contact ? matter.contact.name : "",matter.contact ? matter.contact.get_account ? matter.contact.get_account.name : "" : "",created.strftime('%m/%d/%y'),(today-created.to_date).to_i]
        end
        total_data[label.capitalize] = data
        data = []
      end
      column_widths = {0=> 80,1=> 130,2=> 80,3=> 120,4=> 100,5=> 80,6=>80}
      table_headers = [t(:label_matter_id),t(:label_matter),t(:text_lawyer),t(:label_client),"#{t(:label_Account)}",t(:text_created),"#{t(:text_ageing)} #{t(:text_day_s)}"]
    end
    alignment = {0=> :left,1=> :left,2=> :left,3=> :left,4=> :center,5=> :center,6=>:left}
    [total_data,table_headers,conditions,column_widths,alignment]
  end
end
