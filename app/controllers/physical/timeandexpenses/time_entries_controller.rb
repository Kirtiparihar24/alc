class Physical::Timeandexpenses::TimeEntriesController < ApplicationController

    before_filter :get_duration_setting,:only=>[:set_time_entry_actual_duration,:set_time_entry_formatted_start_time,:set_time_entry_formatted_end_time, :set_is_billable]


  # Updates value of actual_duration and related fields through in line editing feature of time entry.
  def set_time_entry_actual_duration
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    #@dur_setng_is_one100th ? actual_duration = one_hundredth_timediffernce(@time_entry.actual_duration) : actual_duration = one_tenth_timediffernce(@time_entry.actual_duration)
    @previous_duration = @time_entry.actual_duration
    @previous_final_billed_amount = @time_entry.calculate_final_billed_amt
    @error=true    
    ActiveRecord::Base.transaction do
      if data[:value].present?
            @time_entry.start_time = nil
            @time_entry.end_time = nil
            @time_entry.actual_duration = data[:value].to_f.roundf2(2) * 60.0
            @billed_amount = @time_entry.calculate_billed_amount
            @final_billed_amount = @time_entry.calculate_final_billed_amt
            @time_entry.final_billed_amount=@final_billed_amount
            @time_entry.save(false)            
            #<!-------------Feature 11298-----  ---------->
            get_receiver_and_provider
            if params[:time_entry_date].present?
              data=params
		          unless @receiver.nil?
			          @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
              else
                @saved_time_entries_new = []
              end
            else               
               set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
               @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
            end
            get_total_hours_for_all_status
            get_total_billable_time_amount_status
            #<!------------------ ----------------------- >
            @error=false
        end
      end
  end

  # Updates value of start_time and related fields through in line editing feature of time entry.
  def set_time_entry_formatted_start_time
    data=params
    @error=false
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    actual_duration = @dur_setng_is_one100th ? one_hundredth_timediffernce(@time_entry.actual_duration) : one_tenth_timediffernce(@time_entry.actual_duration)
    @previous_duration = actual_duration
    @previous_duration = @time_entry.actual_duration
    @old_start_time = @time_entry.send(:formatted_start_time)
    ActiveRecord::Base.transaction do
      if data[:value].present?
        @time_entry.start_time=Time.parse(@time_entry.time_entry_date.to_s + ' '+ data[:value])
        time_diff=@time_entry.get_time_difference
        unless time_diff.kind_of? String
          @time_entry.actual_duration = time_diff.to_f * 60.0
          @billed_amount = @time_entry.calculate_billed_amount
          @final_billed_amount = @time_entry.calculate_final_billed_amt
          @time_entry.save(false)
          @formatedstarttime=@time_entry.send(:formatted_start_time)
          #<!-------------Feature 11298-----  ---------->
          get_receiver_and_provider
          if params[:time_entry_date].present?
             data=params
		         unless @receiver.nil?
			          @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
              else
                @saved_time_entries_new = []
              end
          else
             set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
             @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
          end
          get_total_hours_for_all_status
          get_total_billable_time_amount_status
          #<!------------------ ----------------------- >
        else
          flash[:error] = t(:flash_valid_time_format)
          @error=true
        end
      else
        flash[:error] = t(:flash_valid_time_format)
        @error=true
      end
    end
  end

  # Updates value of end_time and related fields through in line editing feature of time entry.
  def set_time_entry_formatted_end_time
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    actual_duration = @dur_setng_is_one100th ? one_hundredth_timediffernce(@time_entry.actual_duration) : one_tenth_timediffernce(@time_entry.actual_duration)
    @previous_duration = actual_duration
    @previous_duration = @time_entry.actual_duration
    @old_start_time = @time_entry.send(:formatted_end_time)
    @error=false
    ActiveRecord::Base.transaction do
      unless @time_entry.start_time.blank?
        @time_entry.end_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ data[:value])
        time_diff=@time_entry.get_time_difference
        unless(time_diff.nil? && time_diff.kind_of?(String))
          if(time_diff > 0)
            @time_entry.update_attributes(:actual_duration=>time_diff*60.0)
            @billed_amount = @time_entry.calculate_billed_amount
            @final_billed_amount = @time_entry.calculate_final_billed_amt
            @time_entry.save(false)
            @time_diff =@time_entry.get_time_difference
            #<!-------------Feature 11298-----  ---------->
             get_receiver_and_provider
            if params[:time_entry_date].present?
               data=params
		           unless @receiver.nil?
			            @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
               else
                  @saved_time_entries_new = []
               end
            else
               set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
               @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
            end
            get_total_hours_for_all_status
            get_total_billable_time_amount_status
            #<!------------------ ----------------------- >
          else
            @error=true
            flash[:error] = "To time should be greater than Start time"
            @errorgenerated=time_diff
          end
        else
          @error=true
          flash[:error] = "To time should be greater than Start time"
        end
      else
        @error=true
        flash[:error] = t(:flash_start_time_format)
      end
    end
  rescue
    @old_start_time = @time_entry.end_time
    @time_entry.end_time = @old_end_time
    render :text => @time_entry.formatted_end_time
  end

  # Updates value of billing_rate and related fields through in line editing feature of time entry.
  def set_time_entry_actual_bill_rate
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.calculate_final_billed_amt
    override_rate = !data[:value].blank? ? data[:value].to_f.roundf2(2) : 0
    @error=false
    reg = /^[0-9]+(.[0-9]{1,5})$/
    if (override_rate > 0 && reg.match("#{override_rate}"))
      ActiveRecord::Base.transaction do
        @time_entry.update_attribute(:actual_activity_rate,override_rate)
        @billed_amount = @time_entry.calculate_billed_amount
        @final_billed_amount = @time_entry.calculate_final_billed_amt
        @time_entry.update_attribute(:final_billed_amount,@final_billed_amount)
        #<!-------------Feature 11298-----  ---------->
        get_receiver_and_provider
        if params[:time_entry_date].present?
           data=params
		       unless @receiver.nil?
			         @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
           else
               @saved_time_entries_new = []
              end
        else
           set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
           @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
        end
        get_total_billable_time_amount_status
        #<!------------------ ----------------------- >
      end
    else
      @error=true
      flash[:error] = t(:flash_enter_valid_rate)
    end
  end

  # Updates value of description through in line editing feature of time entry.
  def set_time_entry_description
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @time_entry.update_attribute(:description,data[:value])
    render :text => @time_entry.description
  end

  # Updates value of billing amount (override amount) and related fields through in line editing feature of time entry.
  def set_time_entry_billing_amount
    data=params
    @time_entry = Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @time_entry.update_attributes({:final_billed_amount => data[:value], :billing_method_type => 3, :billing_percent => ''})
    @final_billed_amount = @time_entry.calculate_final_billed_amt
    @time_entry.update_attribute(:final_billed_amount, @final_billed_amount)
    #<!-------------Feature 11298-----  ---------->
     get_receiver_and_provider
     if params[:time_entry_date].present?
        data=params
		    unless @receiver.nil?
		        @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
        else
            @saved_time_entries_new = []
         end
     else
        set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
        @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
     end
     get_total_billable_time_amount_status
     #<!------------------ ----------------------- >
  end

  # Updates value of is_billable and related fields through in line editing feature of time entry.
  def set_is_billable
    data=params
    ActiveRecord::Base.transaction do
      @time_entry = Physical::Timeandexpenses::TimeEntry.find(data[:id])
      @previous_final_billed_amount = @time_entry.final_billed_amount
      @time_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal],:billing_method_type => data[:billing_method_type]})
      @time_entry.save(false)
      @expense_entries = @time_entry.expense_entries
      if data[:is_internal].to_s.eql?("true")
        @time_entry.update_attributes({:contact_id => '', :matter_id => ''})
        for expense_entry in @expense_entries
          expense_entry.update_attributes({:is_internal => data[:is_internal], :is_billable => false, :contact_id => '', :matter_id => ''})
          @billed_amount = expense_entry.calculate_final_expense_amount
        end
      end
    end

    # This line is commented By -- Hitesh Rawal
    # It gave problem when we give discount or override amount - check-out billable and then check-in
    # It clear discount and override amount and always shows full bill amount.
    #@time_entry.update_attributes({:billing_percent => ''})
    @billed_amount = @time_entry.calculate_final_billed_amt
    #<!-------------Feature 11298-----  ---------->
    get_receiver_and_provider
    if params[:time_entry_date].present?
       data=params
		   unless @receiver.nil?
		      @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
       else
          @saved_time_entries_new = []
       end
    else
       set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
       @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
    end
    get_total_hours_for_all_status
    get_total_billable_time_amount_status
    #<!------------------ ----------------------- >
    flash[:notice] = "#{t(:text_time_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
  end

  # Updates value of activity_type through in line editing feature of time entry.
  def set_time_entry_activity_type
    data=params
    @i = Physical::Timeandexpenses::TimeEntry.find(data[:id])
    f  = current_company.company_activity_types.find(data[:value])
    @i.update_attribute( :activity_type, data[:value])
    render :text => f.lvalue
  end

  # Updates value of billing_percent (discount) and related fields through in line editing feature of time entry.
  def set_time_entry_billing_percent
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @error=false
    if data[:value].to_i.between?(0,100)      
      @time_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 2})      
      @final_billed_amount = @time_entry.calculate_final_billed_amt
      @time_entry.update_attribute(:final_billed_amount,@final_billed_amount)
      #<!-------------Feature 11298-----  ---------->
      get_receiver_and_provider
      if params[:time_entry_date].present?
         data=params
		     unless @receiver.nil?
		        @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
         else
            @saved_time_entries_new = []
         end
      else
         set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
         @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
      end
      get_total_billable_time_amount_status
      #<!------------------ ----------------------- >
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end
  end

  def set_time_entry_full_amount
    data=params
    @time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @time_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 1})
    @final_billed_amount = @time_entry.calculate_final_billed_amt
    #<!-------------Feature 11298-----  ---------->
    get_receiver_and_provider
    if params[:time_entry_date].present?
       data=params
		   unless @receiver.nil?
		       @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and status = ? and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
       else
           @saved_time_entries_new = []
       end
    else
       set_condition(@receiver,@time_entry, params[:view_type], params[:start_date], params[:end_date])
       @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => @t_condition)
    end
    get_total_billable_time_amount_status
    #<!------------------ ----------------------- >
  end

   #<!-------------Feature 11298-----total hours  ---------->
   def get_total_hours_for_all_status
    @total_hours_open = 0.0
    unless @saved_time_entries_new.empty?
      #to get total hours for open the status
			@saved_time_entries_new.each do |saved_entry|         
        duration= @dur_setng_is_one100th ? one_hundredth_timediffernce(saved_entry.actual_duration) : one_tenth_timediffernce(saved_entry.actual_duration)				
        @total_hours_open += duration.to_f        
		  end
    end
    @total_hours_open = @total_hours_open.to_f.roundf2(2)
		return @total_hours_open || 0
  end

 #Returns total amount for open status
  def get_total_billable_time_amount_status
		total_amount_open = 0.0
		unless @saved_time_entries_new.empty?
			@saved_time_entries_new.each do |saved_tme|
         total_amount_open += saved_tme.final_billed_amount
			end
		end
			@total_amount_open = total_amount_open.to_f.roundf2(2)
		return @total_amount_open || 0.0
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

  #set condition when time params not passed
  def set_condition(receiver, time_entry, object_type, start_date, end_date)
    @t_condition = ""
    if object_type == "contact"
			 @object = Contact.find_with_deleted(time_entry.contact_id)		
		end
    if object_type == "contact"
       t_conditions = "contact_id =  #{@object.id} and matter_id is null and company_id = #{@object.company_id}"
        @t_condition = t_conditions + " and status ='Open' and is_billable = true"
    elsif object_type == "internal"
       t_conditions = "is_internal and company_id = #{receiver.company_id} and time_entry_date between '#{start_date}' and '#{end_date}'"
        @t_condition = t_conditions
    else
        mp = MatterPeople.find(:first, :conditions=>["employee_user_id=? and matter_id = ?", receiver.id, time_entry.matter_id])
        if(mp !=nil)
           id = mp.matter_team_role_id.to_i
           if(id == 0 || is_access_t_and_e? || (!mp.matter_team_role_id.nil? && mp.matter_team_role.alvalue.eql?("Lead Lawyer")) || mp.can_change_status_time_and_expense?)
              t_conditions = "matter_id = #{time_entry.matter_id} and company_id = #{receiver.company_id}"
           else
              t_conditions = "matter_id = #{time_entry.matter_id} and company_id = #{receiver.company_id} and employee_user_id = #{receiver.id}"
           end
        else
          if time_entry.matter_id
             t_conditions = "matter_id = #{time_entry.matter_id} and "
           end
           t_conditions = "company_id = #{receiver.company_id}"
        end
        @t_condition = t_conditions + " and status ='Open' and is_billable = true"
    end
       
  end
  
  def download_xls_format
    send_file RAILS_ROOT+'/public/sample_import_files/time_entries_import_file.xls', :type => "application/xls"
  end

  private

  def get_duration_setting
   @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
  end

end
