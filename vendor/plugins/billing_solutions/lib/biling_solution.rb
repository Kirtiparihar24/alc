module BilingSolution
  
  # Returns all matters and contacts for current company.
  def get_matters_and_contacts
    begin
    @matters = Matter.find_with_deleted(:all, :conditions=>["company_id=?", get_company_id], :include=>:company)
    @matters = @matters.sort{|x,y| x.name <=>y.name}
    #@matters = @matters.sort{|x,y| x.name <=>y.name}
    get_all_contacts
    rescue Exception=>ex
      puts ex.message
    end
  end

  def get_all_contacts
    @contacts = Contact.find_with_deleted(:all, :conditions=>["company_id=?", get_company_id], :include=>:company)
    @contacts = @contacts.sort{|x,y| x.name <=>y.name}
  end

   # Returns employee and service provider objects.
  def get_receiver_and_provider
    cur_usr=current_user
    cur_ser_sess=current_service_session
    unless cur_ser_sess.nil?
      @receiver = cur_ser_sess.assignment.nil? ? cur_ser_sess.user : cur_ser_sess.assignment.user
      @provider = cur_usr
    else
      @receiver =  cur_usr
      @provider = cur_usr
    end
  end

  # Returns total number of hours for which the time entry has been done for specific date.
  def get_working_hours_total
    @total_hours = 0.0
    unless @saved_time_entries.empty?
      @total_hours =  @saved_time_entries.map(&:actual_duration).inject(0) do |total,duration|
        actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(duration) : one_tenth_timediffernce(duration)
        total.to_f.roundf2(2) + actual_duration.to_f
      end
      @total_hours = @total_hours.to_f.roundf2(2)
    end
    @total_hours || 0.0
  end

  # Returns total amount for which the time entry has been done for specific date.
  def get_total_billable_time_amount
    @total_amount = 0.0
    @billed_time = 0.0
    unless @saved_time_entries.empty?
      @total_amount =  @saved_time_entries.map(&:final_billed_amount).inject(0) do |total,amount|
        total + amount
      end
      @billed_time = @saved_time_entries.inject(0) do | total, time_entry|
        actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(time_entry.actual_duration) : one_tenth_timediffernce(time_entry.actual_duration)
        time_entry.is_billable ? total + actual_duration : total
      end
      @total_amount = @total_amount.to_f.roundf2(2)
    end
    @total_amount || 0.0    
  end

  # Returns total expenses and billed expenses for specific date.
  def get_expense_details
    @total_expenses = 0.0
    @billed_expenses = 0.0
    @expense_entries = {}
    @expense_entries = @saved_expense_entries
    for time_entry in @saved_time_entries
      @expense_entries += time_entry.tne_invoice_expense_entries
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
  end

    def number_with_lformat(number)
    unless number.blank?
       number_with_precision(number,:precision => 2,:separator => ".", :delimiter => ",")
    else
      "0.00"
    end
  end

  def remove_lformat(number)
    unless number.blank?
      number= number.gsub(",","")
      return number
    else
      0.00
    end
  end


end
