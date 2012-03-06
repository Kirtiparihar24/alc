module Physical::Timeandexpenses::TimeAndExpensesHelper

  # Returns name of the day, used in calendar.
  def day_name(day)
    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][day % 7]
  end

  # Returns month name, used in calendar.
  def month_name(month)
    ["~", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month]
  end

  # Returns total time accounted for specific set of time entries, used in calendar.
  def get_total_time_accounted(time_entries)
    @saved_time_entries = time_entries
    @total_hours = 0.00
    if @saved_time_entries.present?
      @total_hours =  @saved_time_entries.map(&:actual_duration).inject(0) do |total,duration|
        duration= @dur_setng_is_one100th ? one_hundredth_timediffernce(duration) : one_tenth_timediffernce(duration)
        total + duration.to_f
      end     
      @total_hours = @total_hours
    end
    @total_hours > 0 ? (@total_hours.to_f.fixed_precision(2)) : "0.00"
  end

  # Returns total billed amount for specific set of time entries, used in calendar.
  def get_total_billed_amount(time_entries)
    @saved_time_entries = time_entries
    @total_amount = 0.00
    
    unless @saved_time_entries.empty?
      @total_amount =  @saved_time_entries.map(&:final_billed_amount).inject(0) do |total,amount|
        total + amount
      end
      @total_amount = @total_amount
    end
    @total_amount > 0 ? number_with_lformat(@total_amount) : "0.00"
  end

  # Returns total time billed for specific set of time entries, used in calendar.
  def get_total_time_billed(time_entries)
    @saved_time_entries = time_entries
    @billed_time = 0.00
    if @saved_time_entries.present?
      @billed_time = @saved_time_entries.inject(0) do | total, time_entry|
        #time_entry.billable_type == 1 ? total + time_entry.actual_duration : total
        actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(time_entry.actual_duration) : one_tenth_timediffernce(time_entry.actual_duration)
        time_entry.is_billable ? total + actual_duration.to_f : total
      end
      @billed_time = @billed_time
    end
    @billed_time > 0 ? (@billed_time.to_f.fixed_precision(2)) : "0.00"
  end

  # Returns a role of an employee for specific matter, used in matter view.
  def get_role(employee_user_id, matter_id)
    mp = MatterPeople.find(:first, :conditions=>["employee_user_id=? and matter_id = ?", employee_user_id, matter_id])
    if mp
      mp.matter_team_role.alvalue
    end
  end

  # Returns an expense document.
  def get_expense_entry_document(id)
    @ass = DocumentHome.find_by_mapable_type_and_mapable_id('ExpenseEntry',id)    
    return  @ass.latest_doc.nil? ? nil : @ass.latest_doc unless @ass.nil?
  end

  def get_document(mapable_type,mapable_id)
    DocumentHome.find_by_mapable_type_and_mapable_id(mapable_type,mapable_id)

  end
  
  # Returns time entry document.
  def get_time_entry_document(id)
    @ass = DocumentHome.find_by_mapable_type_and_mapable_id('TimeEntry',id)  
    return  @ass.latest_doc if @ass
  end

  def check_matter_people_access(matter, employee_user_id)
    return true if(is_access_matter? )
    leadlawyer = matter.employee_user_id == employee_user_id
    access = matter.matter_peoples.find_by_employee_user_id(employee_user_id).can_change_status_time_and_expense?
    if leadlawyer || access
      return true
    else
      return false
    end
  end
  
  def check_for_lead_lawyer(entry, employee_user_id)
    if(entry.matter.nil? || entry.matter.employee_user_id == employee_user_id || is_access_t_and_e? )
      return true
    end
    matter_people_client = entry.matter.matter_peoples.find_by_employee_user_id(employee_user_id)
    unless matter_people_client.nil?
      return true if matter_people_client.can_change_status_time_and_expense?
    else
      return false
    end
  end

  def time_and_expense_total_details
    if @receiver.nil? || @provider.nil?
      cur_ser_sess=current_service_session
      unless cur_ser_sess.nil?
        @receiver = cur_ser_sess.assignment.user
        @provider = current_user
      else
        @receiver =  current_user
        @provider = current_user
      end
    end
    @saved_time_entries ||= Physical::Timeandexpenses::TimeEntry.find(:all,
      :conditions => ['employee_user_id = ? and time_entry_date = ?', @receiver.id, (!@time_entry.time_entry_date.blank? ? @time_entry.time_entry_date : Time.zone.now.to_date)])
    @saved_expense_entries ||= Physical::Timeandexpenses::ExpenseEntry.find(:all,
      :conditions =>['employee_user_id =? and expense_entry_date =? and related_time_entry is null',@receiver.id,(!@time_entry.time_entry_date.blank? ? @time_entry.time_entry_date : Time.zone.now.to_date)])
    @total_hours = 0.0
    unless @saved_time_entries.empty?
      @total_hours =  @saved_time_entries.map(&:actual_duration).inject(0) do |total,duration|
        total + duration
      end
      @total_hours = @total_hours.to_f.roundf2(2)
    end
    @total_amount = 0.0
    @billed_time = 0.0
    unless @saved_time_entries.empty?
      @total_amount =  @saved_time_entries.map(&:final_billed_amount).inject(0) do |total,amount|
        total + amount
      end
      @billed_time = @saved_time_entries.inject(0) do | total, time_entry|
        #time_entry.billable_type == 1 ? total + time_entry.actual_duration : total
        time_entry.is_billable ? total + time_entry.actual_duration : total
      end
      @total_amount = @total_amount.to_f.roundf2(2)
    end
    @total_expenses = 0.0
    @billed_expenses = 0.0
    @expense_entries = {}
    @expense_entries = @saved_expense_entries
    for time_entry in @saved_time_entries
      @expense_entries += time_entry.expense_entries
    end
    unless @expense_entries.empty?
      @total_expenses =  @expense_entries.map(&:expense_amount).inject(0) do |total,amount|
        total + amount
      end
      @billed_expenses =  @expense_entries.map(&:final_expense_amount).inject(0) do |total,amount|
        total + amount
      end
      @billed_expenses = @billed_expenses.to_f.roundf2(2)
    end
    @grand_total = @total_amount + @billed_expenses
  end

  def time_and_expense_destroy_link(time_and_expense, from, can_change = true)    
    if time_and_expense.status.eql?("Open") and can_change
      physical_timeandexpenses_time_and_expense_path(time_and_expense.id, :entry_type => from)
    else
      "NO"
    end
  end

  def is_open?(entry)
    entry.status.eql?('Open') ? true : false
  end
 
end
