class Physical::Timeandexpenses::ExpenseEntriesController < ApplicationController
     
  # Updates billing related values over updating expense entry discount.
  def calculate_discount_rate_for_expense_entry
    data=params
    @expense_entry = Physical::Timeandexpenses::ExpenseEntry.new   
    @discount = @expense_entry.calculate_new_expense_discount(data[:final_expense_amount].to_f, data[:billing_percent].to_f)
    respond_to do |format|
      format.js
    end
  end

  def set_expense_entry_status
    data=params
    @i = Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    previous_val = @i.status
    if previous_val=='Billed'
      flash[:error] = "This Expense Entry is already Billed.";
    else
      @i.update_attributes( :status=>data[:value],:time_entry_id => "")
      if (previous_val.nil? or previous_val == 'Open') && @i.status == 'Approved'
        send_tne_status_update_mail(current_user, @i)
      end      
    end
  end
  
  # Updates value of expense_type through in line editing feature of expense entry.
  def set_expense_entry_expense_type
    data=params
    @i = Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    f  = Physical::Timeandexpenses::ExpenseType.find(data[:value])
    @i.update_attribute( :expense_type, data[:value])
    render :text => f.lvalue
  end

  # Updates value of expense_amount and related fields through in line editing feature of expense entry.
  def set_expense_entry_expense_amount
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    expense_amount = !data[:value].blank? ? data[:value].to_i : 0
    @error=false
    if expense_amount > 0
      @expense_entry.update_attribute(:expense_amount,expense_amount)
      @final_expense_amount = @expense_entry.calculate_final_expense_amount      
    else
      @error=true
      flash[:error]= t(:flash_enter_valid_expense_amt)
    end
  end

  def set_expense_entry_full_amount
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @expense_entry.final_expense_amount
    @expense_entry.update_attributes({:billing_percent => nil, :billing_method_type => 1,:markup=>nil})
    @final_expense_amount = @expense_entry.calculate_final_expense_amount
    #<!-------------Feature 11298-----  ---------->
    get_receiver_and_provider
    if params[:time_entry_date].present?
		   unless @receiver.nil?
			   @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and status =? and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
		   end
    else
       set_condition(@receiver, @expense_entry, params[:view_type])
       @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => @e_condition)
    end
    get_expense_details_for_status
    #<!------------------ ----------------------- >
  end

  # Updates value of description through in line editing feature of expense entry.
  def set_expense_entry_description
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @expense_entry.update_attribute(:description,data[:value])
    render :text => @expense_entry.description
  end

  # Updates value of billing_percent(discount) and related fields through in line editing feature of expense entry.
  def set_expense_entry_billing_percent
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @expense_entry.final_expense_amount
    if data[:value].to_i.between?(0,100)
      @expense_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 2,:markup=>nil})
      @final_expense_amount = @expense_entry.calculate_final_expense_amount
      #<!-------------Feature 11298-----  ---------->
      get_receiver_and_provider
      if params[:time_entry_date].present?
		     unless @receiver.nil?
			     @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and status =? and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
		     end
      else
         set_condition(@receiver, @expense_entry, params[:view_type])
         @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => @e_condition)
      end
      get_expense_details_for_status
      #<!------------------ ----------------------- >
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end
  end

  def set_expense_entry_markup
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @expense_entry.final_expense_amount
    if data[:value].to_i.between?(0,1000)
      @expense_entry.update_attributes({:billing_percent => nil, :billing_method_type => 4,:markup=>data[:value]})
      @final_expense_amount = @expense_entry.calculate_final_expense_amount
      #<!-------------Feature 11298-----  ---------->
      get_receiver_and_provider
      if params[:time_entry_date].present?
		     unless @receiver.nil?
			     @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and status =? and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
		     end
      else
         set_condition(@receiver, @expense_entry, params[:view_type])
         @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => @e_condition)
      end
      get_expense_details_for_status
      #<!------------------ ----------------------- >
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end
  end

  # Updates value of billing_amount(override amount) and related fields through in line editing feature of expense entry.
  def set_expense_entry_billing_amount
    data=params
    @expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @expense_entry.final_expense_amount
    @expense_entry.update_attributes({:final_expense_amount => data[:value], :billing_percent => nil, :billing_method_type => 3,:markup=>nil})
    @final_expense_amount = @expense_entry.calculate_final_expense_amount
    #<!-------------Feature 11298-----  ---------->
    get_receiver_and_provider
    if params[:time_entry_date].present?
		   unless @receiver.nil?
			   @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and status =? and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
		   end
    else
       set_condition(@receiver, @expense_entry, params[:view_type])
       @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => @e_condition)
    end
    get_expense_details_for_status
    #<!------------------ ----------------------- >
  end  

  # Updates value of is_billable and related fields through in line editing feature of expense entry.
  def set_expense_is_billable
    data=params
    @expense_entry = Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @expense_entry.final_expense_amount
    @expense_entry.update_attributes({:billing_method_type=>data[:billing_type]})     
    if @expense_entry.billing_method_type.to_i == 1
      @expense_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal], :billing_percent => '',:markup=>nil})
    else
      @expense_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal]})
    end    
    if data[:is_internal].to_s.eql?("true")
      @expense_entry.update_attributes({:contact_id => '', :matter_id => ''})
    end   
    @billed_amount = @expense_entry.calculate_final_expense_amount   
    #<!-------------Feature 11298-----  ---------->
    get_receiver_and_provider
    if params[:time_entry_date].present?
		   unless @receiver.nil?
			   @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and status =? and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), 'Open', true])
		   end
    else
       set_condition(@receiver, @expense_entry, params[:view_type])
       @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => @e_condition)
    end
    get_expense_details_for_status
    #<!------------------ ----------------------- >
  end

  #Returns employee and service provider objects.
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

  #set condition when date params is not passed
  def set_condition(receiver, expense_entry, object_type)
      @e_condition = ""
      if object_type == "contact"
         @object = Contact.find_with_deleted(expense_entry.contact_id)
      end
      if object_type == "contact"
          e_conditions = "contact_id =  #{@object.id} and matter_id is null and company_id = #{@object.company_id}"
      else
         mp = MatterPeople.find(:first, :conditions=>["employee_user_id=? and matter_id = ?", receiver.id, expense_entry.matter_id])
         if(mp !=nil)
            id = mp.matter_team_role_id.to_i
            if(id == 0 || is_access_t_and_e? || (!mp.matter_team_role_id.nil? && mp.matter_team_role.alvalue.eql?("Lead Lawyer")) || mp.can_change_status_time_and_expense?)
                e_conditions = "matter_id = #{expense_entry.matter_id} and company_id = #{receiver.company_id}"
            else
                e_conditions = "matter_id = #{expense_entry.matter_id} and company_id = #{receiver.company_id} and employee_user_id = #{receiver.id}"
            end
         else
           if expense_entry.matter_id
             e_conditions = "matter_id = #{expense_entry.matter_id} and "
           end
           e_conditions = "company_id = #{receiver.company_id}"
         end
      end
     @e_condition = e_conditions + " and status ='Open' and is_billable = true"
  end

  #Returns total expenses for open status.
	def get_expense_details_for_status
		total_expenses_open = 0.0    
		@expense_entries = {}
		@expense_entries = @saved_expense_entries
		unless @expense_entries.empty?
			@expense_entries.each do |expe_entry|		 		
         total_expenses_open += expe_entry.final_expense_amount			 
      end
		end
    @total_expenses_open = total_expenses_open.to_f.roundf2(2)

    return @total_expenses_open || 0.0
	end
  
end
