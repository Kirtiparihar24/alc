class TneInvoiceTimeEntriesController < ApplicationController

  before_filter :get_duration_setting ,:only=>[:add_new_time_entry,:set_time_entry_actual_duration,:set_time_entry_formatted_start_time,:set_time_entry_formatted_end_time]

  # Updates value of actual_duration and related fields through in line editing feature of time entry.
  def set_time_entry_actual_duration
    data=params
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
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
        @time_entry.save
        @error=false
      end
    end
  end

  # Updates value of start_time and related fields through in line editing feature of time entry.
  def set_time_entry_formatted_start_time
    data=params
    @error=false
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @previous_duration = @time_entry.actual_duration
    @old_start_time = @time_entry.send(:formatted_start_time)
    #    regexp = /^([0-9]{2}):([0-9]{2})$/
    ActiveRecord::Base.transaction do
      if data[:value].present?
        #      if data[:value].present? && regexp.match(data[:value].to_s)
        #        @time_entry.update_attribute(:start_time,data[:value])
        @time_entry.start_time=Time.parse(@time_entry.time_entry_date.to_s + ' '+ data[:value])
        time_diff=@time_entry.get_time_difference
        unless time_diff.kind_of? String
          @time_entry.actual_duration = time_diff
          @billed_amount = @time_entry.calculate_billed_amount
          @final_billed_amount = @time_entry.calculate_final_billed_amt
          @time_entry.save(false)
          @formatedstarttime=@time_entry.send(:formatted_start_time)
          #          flash[:notice] = t(:flash_end_time_format) if time_diff.to_i == 0
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
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @previous_duration = @time_entry.actual_duration
    @old_start_time = @time_entry.send(:formatted_end_time)
    @error=false
    #    regexp = /^([0-9]{2}):([0-9]{2})$/
    ActiveRecord::Base.transaction do
      unless @time_entry.start_time.blank?
        #      unless @time_entry.start_time.blank? && regexp.match(data[:value].to_s)
        @time_entry.end_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ data[:value])
        time_diff=@time_entry.get_time_difference
        unless(time_diff.nil? && time_diff.kind_of?(String))
          if(time_diff > 0)
            @time_entry.update_attributes(:actual_duration=>time_diff)
            #          @time_entry.update_attribute(:actual_duration,time_diff)
            @billed_amount = @time_entry.calculate_billed_amount
            @final_billed_amount = @time_entry.calculate_final_billed_amt
            @time_diff =@time_entry.get_time_difference
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
    #  rescue
    #    @old_start_time = @time_entry.end_time
    #    @time_entry.end_time = @old_end_time
    #    render :text => @time_entry.formatted_end_time
  end

  # Updates value of billing_rate and related fields through in line editing feature of time entry.
  def set_time_entry_actual_bill_rate
    data=params
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.calculate_final_billed_amt
    override_rate = !data[:value].blank? ? data[:value].to_f.roundf2(2) : 0
    @error=false
    #reg = /^[0-9]+(.[0-9]{1,5})$/
    if (override_rate > 0)
      ActiveRecord::Base.transaction do
        @time_entry.update_attribute(:actual_activity_rate,override_rate)
        @billed_amount = @time_entry.calculate_billed_amount
        @final_billed_amount = @time_entry.calculate_final_billed_amt
        @time_entry.update_attribute(:final_billed_amount,@final_billed_amount)
      end
    else
      @error=true
      flash[:error] = t(:flash_enter_valid_rate)
    end
  end

  # Updates value of description through in line editing feature of time entry.
  def set_time_entry_description
    data=params
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @time_entry.update_attribute(:description,data[:value])
    render :text => @time_entry.description
  end

  # Updates value of billing amount (override amount) and related fields through in line editing feature of time entry.
  def set_time_entry_billing_amount
    data=params
    @time_entry = TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @time_entry.update_attributes({:final_billed_amount => data[:value], :billing_method_type => 3, :billing_percent => ''})
    @final_billed_amount = @time_entry.calculate_final_billed_amt
    @bill_entry_id = data[:bill_entry_id]
  end

  # Updates value of is_billable and related fields through in line editing feature of time entry.
  def set_is_billable
    data=params
    ActiveRecord::Base.transaction do
      @time_entry = TneInvoiceTimeEntry.find(data[:id])
      @previous_final_billed_amount = @time_entry.final_billed_amount
      @time_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal]})
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
    flash[:notice] = "#{t(:text_time_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
  end

  # Updates value of activity_type through in line editing feature of time entry.
  def set_time_entry_activity_type
    data=params
    @i = TneInvoiceTimeEntry.find(data[:id])
    f  = current_company.company_activity_types.find(data[:value])
    @i.update_attribute( :activity_type, data[:value])
    render :text => f.lvalue
  end

  # Updates value of billing_percent (discount) and related fields through in line editing feature of time entry.
  def set_time_entry_billing_percent
    data=params
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @error=false
    if data[:value].to_i.between?(0,100)
      @time_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 2})
      @final_billed_amount = @time_entry.calculate_final_billed_amt
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end

  end
  def set_time_entry_full_amount
    data=params
    @time_entry =  TneInvoiceTimeEntry.find(data[:id])
    @previous_final_billed_amount = @time_entry.final_billed_amount
    @time_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 1})
    @final_billed_amount = @time_entry.calculate_final_billed_amt
  end

  def get_contacts
    #@contacts = Contact.find_all_by_company_id_and_employee_user_id(get_company_id, get_employee_user_id)
    @contacts = Contact.find_all_by_company_id(get_company_id,:include=>:company,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    #    @contacts = @contacts.sort{|x,y| x.name <=>y.name}
  end
  def get_unexpired_matters(date,employee_user_id)
    @matters = Matter.unexpired_team_matters(employee_user_id, get_company_id, date)
    #@matters = @matters.sort{|x,y| x.name <=>y.name}
  end
  
  def create_time_entry
    params[:tne_invoice_time_entry][:created_by_user_id]=current_user.id
    (params[:tne_invoice_time_entry][:tne_invoice_id].present? && params[:regenerate]=="false") ? params[:tne_invoice_time_entry][:status]='Billed' : params[:tne_invoice_time_entry][:status]='Approved'
    params[:tne_invoice_time_entry][:company_id]=get_company_id
    params[:tne_invoice_time_entry][:contact_id]=params[:contact_id] unless params[:contact_id].nil?
    params[:tne_invoice_time_entry][:actual_activity_rate] = params[:tne_invoice_time_entry][:actual_activity_rate].gsub(',','') if params[:tne_invoice_time_entry][:actual_activity_rate]
	  params[:tne_invoice_time_entry][:final_billed_amount] = params[:tne_invoice_time_entry][:final_billed_amount].gsub(',','') if params[:tne_invoice_time_entry][:final_billed_amount]
    params[:tne_invoice_time_entry][:actual_duration] = params[:tne_invoice_time_entry][:actual_duration].to_f * 60.0
    @tne_invoice_time_entry=TneInvoiceTimeEntry.new(params[:tne_invoice_time_entry])
    if @tne_invoice_time_entry.employee_user_id.nil?
      @tne_invoice_time_entry.employee_user_id = get_employee_user_id
    end

    if params[:nonuser].eql?('nonuser')
       params[:tne_invoice_time_entry][:matter_people_id].nil? ? @tne_invoice_time_entry.errors.add('Please','Select Matter People') : @tne_invoice_time_entry.errors
     end
     if @tne_invoice_time_entry.valid?
      @tne_invoice_time_entry.save
      unless @tne_invoice_time_entry.tne_invoice_id.nil?
        consolidated_by = params[:consolidated_by]
        act_type_val =  @tne_invoice_time_entry.company.company_activity_types.find_by_id(@tne_invoice_time_entry.activity_type).alvalue
        conditions = "entry_type= 'Time' and tne_invoice_id= #{@tne_invoice_time_entry.tne_invoice_id} and matter_id = #{@tne_invoice_time_entry.matter_id}" if @tne_invoice_time_entry.matter_id.present?
        conditions = "entry_type= 'Time' and tne_invoice_id= #{@tne_invoice_time_entry.tne_invoice_id} and contact_id = #{@tne_invoice_time_entry.contact_id}" if @tne_invoice_time_entry.contact_id.present?
        lawyer_name = User.find_by_id_and_company_id(@tne_invoice_time_entry.employee_user_id,@tne_invoice_time_entry.company_id).full_name rescue ''
        if consolidated_by.eql?('User')
          conditions += " and lawyer_name = '#{lawyer_name}'"
        elsif consolidated_by.eql?('Date')
          conditions += " and tne_entry_date = '#{@tne_invoice_time_entry.time_entry_date}'"
        else
          conditions += " and activity = '#{act_type_val}'"
        end
          tne_inv_details=TneInvoiceDetail.find(:all,:conditions=>conditions)

        if tne_inv_details.size==0
          @tne_invoice_detail_data=TneInvoiceDetail.new()
          @tne_invoice_detail_data.tne_invoice_id=@tne_invoice_time_entry.tne_invoice_id
          @tne_invoice_detail_data.entry_type="Time"
          @tne_invoice_detail_data.matter_id=@tne_invoice_time_entry.matter_id
          if consolidated_by.eql?('Date')
            @tne_invoice_detail_data.tne_entry_date = @tne_invoice_time_entry.time_entry_date
          end
          @tne_invoice_detail_data.lawyer_name= lawyer_name
          @tne_invoice_detail_data.duration=@tne_invoice_time_entry.actual_duration
          @tne_invoice_detail_data.rate=@tne_invoice_time_entry.actual_activity_rate
          @tne_invoice_detail_data.activity= act_type_val
          @tne_invoice_detail_data.amount=@tne_invoice_time_entry.final_billed_amount
          @tne_invoice_detail_data.company_id=get_company_id
          @tne_invoice_detail_data.contact_id= @tne_invoice_time_entry.contact_id
          @tne_invoice_detail_data.save
        end
        @tne_invoice=TneInvoice.find(@tne_invoice_time_entry.tne_invoice_id)
        @tne_invoice_time_entry.final_billed_amount.nil? ? @tne_invoice_time_entry.final_billed_amount=0.0 :  @tne_invoice_time_entry.final_billed_amount
        @tne_invoice.invoice_amt.nil? ? @tne_invoice.invoice_amt=0.0 : @tne_invoice.invoice_amt
        @tne_invoice.invoice_amt+=@tne_invoice_time_entry.final_billed_amount
        @tne_invoice.send(:update_without_callbacks)
        @tne_invoice.tne_invoice_details.each do |id|
          if id.entry_type == 'Time'
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',@tne_invoice.company_id,id.activity,"CompanyActivityType"]).id rescue 0
             if consolidated_by.eql?('User')
              lawyer_name= id.lawyer_name.downcase.split(' ')
              lawyer_id = User.find(:first,:conditions=>['company_id = ? and Lower(Trim(first_name)) = ? and Lower(Trim(last_name)) = ? ',@tne_invoice.company_id,lawyer_name[0],lawyer_name[1]]).id rescue 0
              select_condition= "employee_user_id = #{lawyer_id}"
            elsif consolidated_by.eql?('Date')
              select_condition = "time_entry_date = '#{id.tne_entry_date}'"
            else
            act_type = CompanyLookup.find(:first,:conditions => ['company_id = ? and alvalue=? and type like ?',@tne_invoice.company_id,id.activity,"CompanyActivityType"]).id rescue 0
             select_condition= "activity_type = '#{act_type}'"
            end
            select_condition += " and tne_invoice_id = #{@tne_invoice.id}"
            time_entries=TneInvoiceTimeEntry.find(:all,:conditions=>select_condition)
            amount = 0
            duration = 0
            time_entries.each do |te|
              amount+=te.final_billed_amount
              duration+=te.actual_duration
                if te.tne_invoice_detail_id.blank?
                  te.tne_invoice_detail_id=id.id
                  te.save
                end
            end
            duration = duration > 0 ? duration : id.duration
            amount = amount > 0 ? amount : id.amount
            actual_duration= @dur_setng_is_one100th ?  one_hundredth_timediffernce(duration) : one_tenth_timediffernce(duration)
            rate = amount.to_f / actual_duration.to_f
            id.update_attributes(:duration=>duration, :amount=>amount,:rate => rate)
            time_entry= time_entries.collect{|te| true if te.id==@tne_invoice_time_entry.id}.compact
            @tne_invoice_time_entry.update_attribute("tne_invoice_detail_id" ,id.id) if time_entry.present?
          end
        end

      end
    end
    respond_to do |format|
      format.js {
        render :update do|page|
          if(@tne_invoice_time_entry.errors.empty?)
            page << "tb_remove();"
            page << " show_error_msg('errorCont','Time Entry Saved Successfully','message_sucess_div');"
            page << "time_entry_refresh();"
          else
            page << "jQuery('#loader').hide();"
            format_ajax_errors(@tne_invoice_time_entry, page, 'error_notice')
          end
        end
      }
      format.xml  { render :xml => @tne_invoice_time_entry, :status => :created, :location => @tne_invoice_time_entry }
      format.html {
        #flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        redirect_to(new_tne_invoice_path(:matter_id=>params[:matter_id]))
      }

    end
  end
  
  def new_time_entry
    @tne_invoice_time_entry= TneInvoiceTimeEntry.new(:company_id => get_company_id)
    data=params
    

    unless data[:physical_timeandexpenses_time_entry].blank?
      @entry_date = data[:physical_timeandexpenses_time_entry][:time_entry_date]
    else
      @entry_date = data[:time_entry_date] || Time.zone.now.to_date.strftime('%m/%d/%Y')
    end
    @note_id=params[:id]
    #    @note_name=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:id],assigned_user) if params[:id]
    @tne_invoice_time_entry.employee_user_id = get_employee_user_id
    get_unexpired_matters(@entry_date,@tne_invoice_time_entry.employee_user_id)
    get_contacts
    default_activity_type_id = CompanyActivityType.find(:first,:conditions=>"company_id=#{current_company.id}").id
    if !params[:matter_id].blank?
      @matter = current_company.matters.find(params[:matter_id])
      @lawyers=@matter.matter_peoples.client
      @matter_people_others = @matter.matter_peoples.other_related.for_allow_time_entry
    else
      @lawyers = {}
      @matter_people_others={}
    end
    
    @tne_invoice_time_entry.activity_rate = @tne_invoice_time_entry.actual_activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, default_activity_type_id, get_user_role_id,get_employee_user_id))
    @tne_invoice_time_entry.tne_invoice_id=params[:invoice_id]
    @tne_invoice_time_entry.contact_id=params[:contact_id]
    if @tne_invoice_time_entry.contact_id.present?
      @contact_name=Contact.find(@tne_invoice_time_entry.contact_id).full_name
    end
    @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
    render :layout => false if params[:height]
  end

  def delete_all_time_entries
    params[:invoice_id].present?? bill_status='Billed' :  bill_status='Approved'
    if params[:consolidate_by].eql?('Activity')
      if params[:matter_id].present?
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['matter_id=? and activity_type=? and status=?',params[:matter_id],params[:activity_type],bill_status])
      else
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['contact_id=? and activity_type=? and status=?',params[:contact_id],params[:activity_type],bill_status])
      end
    elsif params[:consolidate_by].eql?('Date')
      if params[:matter_id].present?
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['matter_id=? and time_entry_date=? and status=?',params[:matter_id],params[:activity_type],bill_status])
      else
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['contact_id=? and time_entry_date=? and status=?',params[:contact_id],params[:activity_type],bill_status])
      end
    else
      if params[:matter_id].present?
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['matter_id=? and employee_user_id=? and status=?',params[:matter_id],params[:activity_type],bill_status])
      else
        @time_entry =  TneInvoiceTimeEntry.find(:all,:conditions=>['contact_id=? and employee_user_id=? and status=?',params[:contact_id],params[:activity_type],bill_status])
      end
    end
    if @time_entry[0].tne_invoice_detail_id.present?
       @time_entry_detail=TneInvoiceDetail.find(@time_entry[0].tne_invoice_detail_id)
    end
     unless  @time_entry_detail.nil?
      @time_entry_detail.destroy
     end
      @time_entry.each do |time_entry|
        if time_entry.tne_time_entry_id.present?
          time_entry.destroy
        else
          time_entry.destroy!
        end
      end
      render :text=>''
  end

  def destroy
    @time_entry =  TneInvoiceTimeEntry.find(params[:id])
    if @time_entry.tne_time_entry_id.present?
      
      if params[:to_do] == "delete_appear"
        if @time_entry.tne_invoice_detail_id.present?
          @time_entry_detail=TneInvoiceDetail.find(@time_entry.tne_invoice_detail_id)
          @time_entry_detail.amount-=@time_entry.final_billed_amount
          @time_entry_detail.duration-=@time_entry.actual_duration
          @time_entry_detail.rate=@time_entry_detail.amount/@time_entry_detail.duration
          @time_entry_detail.save
        end
        @time_entry.update_attributes(:billing_percent=>100,:billing_method_type => 2,:final_billed_amount=>0.0)
      end
      if params[:to_do] == "delete_donot_appear"
        if @time_entry.tne_invoice_detail_id.present?
          @time_entry_detail=TneInvoiceDetail.find(@time_entry.tne_invoice_detail_id)
          @time_entry_detail.amount-=@time_entry.final_billed_amount
          @time_entry_detail.save
        end
        @time_entry.is_billable = false
        @time_entry.status = "Approved"
        @time_entry.final_billed_amount = 0.0
        @time_entry.billing_method_type = 1
        @time_entry.tne_invoice_id = ""
        @time_entry.tne_invoice_detail_id = ""
        @time_entry.send(:update_without_callbacks)
        time=Physical::Timeandexpenses::TimeEntry.find_by_id(@time_entry.tne_time_entry_id)
        time.update_attributes(:status => "Approved", :is_billable => false)
      end
#      @time_entry.destroy
     else
      unless @time_entry.tne_invoice_detail_id.blank?
        if @time_entry.contact_id.present? && @time_entry.matter_id.nil?
          @time_entries_count=TneInvoiceTimeEntry.find(:all,:conditions=>['tne_invoice_detail_id=? and contact_id=? ',@time_entry.tne_invoice_detail_id,@time_entry.contact_id])
        else
          @time_entries_count=TneInvoiceTimeEntry.find(:all,:conditions=>['tne_invoice_detail_id=? and matter_id=?',@time_entry.tne_invoice_detail_id,@time_entry.matter_id])
        end
        @time_entry_detail=TneInvoiceDetail.find(@time_entry.tne_invoice_detail_id);
        if @time_entries_count.size==1
          @time_entry_detail.destroy
        else
          @time_entry_detail.amount-=@time_entry.final_billed_amount
          @time_entry_detail.duration-=@time_entry.actual_duration
          @time_entry_detail.rate=@time_entry_detail.amount/@time_entry_detail.duration
          @time_entry_detail.save
        end
      end
      @time_entry.destroy!
     end

      render :text=>''
    
  end

   def add_new_time_entry
     unless params[:time_invoice_id].blank?
        tne_invoices=TneInvoice.find(params[:time_invoice_id])
        consolidated_by = params[:consolidated_by]
        act_type_val=  current_company.company_activity_types.find_by_id(params[:activity_type]).alvalue
        conditions="entry_type= 'Time' and tne_invoice_id= #{tne_invoices.id} and matter_id = #{tne_invoices.matter_id}" if tne_invoices.matter_id.present?
        conditions = "entry_type= 'Time' and tne_invoice_id= #{tne_invoices.id} and contact_id = #{tne_invoices.contact_id}" if tne_invoices.contact_id.present?
        if consolidated_by.eql?('Date')
          conditions += " and tne_entry_date = '#{Time.zone.now.to_date}'"
        elsif consolidated_by.eql?('User')
          conditions += " and lawyer_name= '#{current_user.full_name}'"
        else
          conditions += " and entry_type =  '#{act_type_val}'"
        end
         tne_invoice_detail_count=TneInvoiceDetail.find(:first,:conditions =>conditions)
           
        if tne_invoice_detail_count.nil?
          @tne_invoice_detail_data=TneInvoiceDetail.new(:entry_type=>"Time",
          :matter_id=>params[:matter_id],:contact_id=>params[:contact_id],:lawyer_name=>current_user.full_name,
          :duration=> params[:activity_duration],:rate=>params[:activity_rate].to_f,:activity=> act_type_val,
          :amount=>params[:activity_duration].to_f*params[:activity_rate].to_f,:company_id=>get_company_id,:tne_invoice_id=>tne_invoices.id)
         @tne_invoice_detail_data.duration = @tne_invoice_detail_data.duration.to_f * 60.0
         @tne_invoice_detail_data.save
        else
          tne_invoice_detail_count.amount.nil? ? tne_invoice_detail_count.amount= 0.00 : tne_invoice_detail_count.amount
          tne_invoice_detail_count.duration.nil? ? tne_invoice_detail_count.duration=0.00 : tne_invoice_detail_count.duration       
          tne_invoice_detail_count.amount+=params[:actual_duration].to_f*params[:activity_rate].to_f
          tne_invoice_detail_count.duration+=params[:actual_duration].to_f * 60.0 
          tne_invoice_detail_count.save
          actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(tne_invoice_detail_count.duration) : one_tenth_timediffernce(tne_invoice_detail_count.duration)
          tne_invoice_detail_count.rate=tne_invoice_detail_count.amount/actual_duration
          tne_invoice_detail_count.save
        end
     end
    status = params[:time_invoice_id].blank? ? 'Approved' : (params[:regenerate]== "true" ? "Approved" : 'Billed')
      @tne_invoice_time_entry=TneInvoiceTimeEntry.new(:activity_type=>params[:activity_type],:actual_duration=>params[:activity_duration].to_f * 60.0,
               :employee_user_id=>get_employee_user_id,:contact_id=>params[:contact_id],:status=>status,:created_by_user_id=>current_user.id,
               :company_id=>get_company_id,:time_entry_date=>Time.zone.now.to_date,:is_billable=>1,:matter_id=>params[:matter_id],
               :billing_method_type=>1,:actual_activity_rate=>params[:activity_rate].to_f,:activity_rate=>params[:activity_rate].to_f,:description=>params[:description],
               :final_billed_amount=>params[:activity_duration].to_f*params[:activity_rate].to_f
      )

      if params[:matter_id].present?
        @tne_invoice_time_entry.contact_id=current_company.matters.find(params[:matter_id]).contact_id
      else
        @tne_invoice_time_entry.contact_id=params[:contact_id]
      end

      @tne_invoice_time_entry.billing_method_type=1
      params[:primary_tax].eql?('true') ? @tne_invoice_time_entry.primary_tax=1 : @tne_invoice_time_entry.primary_tax=0
      params[:secondary_tax].eql?('true') ? @tne_invoice_time_entry.secondary_tax=1 : @tne_invoice_time_entry.secondary_tax=0

     unless tne_invoice_detail_count.nil?
        @tne_invoice_time_entry.tne_invoice_detail_id=tne_invoice_detail_count.id
        @tne_invoice_time_entry.tne_invoice_id=tne_invoice_detail_count.tne_invoice_id
     else
       unless params[:time_invoice_id].blank?
        @tne_invoice_time_entry.tne_invoice_detail_id=@tne_invoice_detail_data.id
        @tne_invoice_time_entry.tne_invoice_id=@tne_invoice_detail_data.tne_invoice_id
       end
     end
     
     if @tne_invoice_time_entry.valid? && @tne_invoice_time_entry.errors.empty?
         @tne_invoice_time_entry.save
     end

     unless tne_invoices.nil?
      tne_invoices.invoice_amt+=@tne_invoice_time_entry.final_billed_amount
      tne_invoices.save
     end
     
       respond_to do |format|
        format.js {render :text=>''}
        format.xml  { render :xml => @tne_invoice_time_entry, :status => :created, :location => @tne_invoice_time_entry }
        format.html {
          #flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          redirect_to(new_tne_invoice_path(:matter_id=>params[:matter_id]))
        }

      end
    end

   def delete_time_entry
    @time_entry = TneInvoiceTimeEntry.find(params[:time_entry_id])
    @counter = params[:counter]
    @detail_entry= params[:detail_id]
    render :layout=>false
  end

   private
   def get_duration_setting
     @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
   end
  
end

