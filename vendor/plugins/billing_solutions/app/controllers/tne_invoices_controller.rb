class TneInvoicesController < ApplicationController
	layout "full_screen"
	before_filter :authenticate_user!
	before_filter :get_base_data
	before_filter :get_duration_setting ,:only=>[:edit,:new,:create,:display_data]

    add_breadcrumb  I18n.t(:text_billing), :tne_invoices_path
	load_and_authorize_resource :except => :change_status
	include BilingSolution
	helper_method :remember_past_path
	def index
    unless(can? :manage, MatterBilling)
      params[:mode_type] = 'client'
    end
    @cancelstatus = @tne_invoice_statuses.find_by_lvalue("Cancelled")
    @statuses = @tne_invoice_statuses.reject{|status| status.lvalue == "Cancelled" || status.lvalue == "Partly Settled"}
    @selected = params.has_key?(:status) ? params[:status].to_i : @tne_invoice_statuses.find_by_lvalue("Open").id
    params[:status] = params[:status].blank? ? @selected : params[:status]
    @status = @tne_invoice_statuses.find_by_id(params[:status]) if !params[:status].blank?
    @pagenumber= params[:status].eql?("Settled") ? 182 : 158
    params[:per_page] ||= 25
    if params[:status].to_i==@cancelstatus.id
      @tne_invoices = TneInvoice.get_invoices(@company, @status, params, false)
    else
      @tne_invoices = MatterBilling.get_bills(@company, @status, params, false)
    end
    if (!params[:date_start].blank? && !params[:date_end].blank?)
      start_date = params[:date_start].to_date if params[:date_start]
      end_date = params[:date_end].to_date if params[:date_end]
      unless start_date <= end_date
        flash[:error] = t(:flash_end_date_start_date)
        return
      end
    end
    @selected_status = params[:status]    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @tne_invoices }
    end
  end

  def show
    @tne_invoice = @company.tne_invoices.find(params[:id])
    pdf_data = @tne_invoice.generate_invoice_pdf(params[:detailed])
    respond_to do |format|
      format.html
      format.xml  { render :xml => @tne_invoice }
      format.pdf {
        send_data(pdf_data,:filename => "invoice_report.pdf", :type => 'application/pdf', :disposition => 'inline')
      }
    end
  end

  def new
    @default_invoice_note = TneInvoiceSetting.find_by_company_id(@company.id).try(:invoice_note)
    @tne_invoice = @company.tne_invoices.new
    @tne_invoice_details = @tne_invoice.tne_invoice_details.build  
    @pagenumber=183     
    @tne_invoice_time_entries = @tne_invoice_details.tne_invoice_time_entries.build
    @tne_invoice_expense_entries = @tne_invoice_details.tne_invoice_expense_entries.build
    params[:view] = params[:mode_type].eql?("client") ? 'presales' : "postsales" if params[:mode_type]
		data = params
		session[:current_time_entry] = nil
		get_matters_and_contacts
		status = "Approved"
		params[:status] = status
		@consolidated_by =  params[:tne_invoice].nil? ? 'Activity' : params[:tne_invoice][:consolidated_by]    
		display_consolidated_view    
    past_path(params) 
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @tne_invoice }
    end
  end

  def display_consolidated_view
    @view_summery = params[:tne_invoice][:view_by] if params[:tne_invoice]
    @consolidated_by= params[:tne_invoice].nil? ? 'Activity' : params[:tne_invoice][:consolidated_by]
    te_conditions, t_conditions, e_conditions = '', '', ''
    if params[:tne_invoice].present?
      @view_summery = params[:tne_invoice][:view_by]
      @consolidated_by = params[:tne_invoice][:consolidated_by]
      if params[:changed_view].present?
        if (params[:tne_invoice][:matter_id].present? || params[:tne_invoice][:contact_id].present?)
          if params[:tne_invoice][:regenerate].present?
            detail_ids = @tne_invoice.tne_invoice_details.map(&:id).join(',')
            te_conditions = "tne_invoice_detail_id IN (#{detail_ids.chop}) and status='Approved' "
          else
            te_conditions = "tne_invoice_id = #{@tne_invoice.id} and status='Billed'"
          end
        end
      else
        get_receiver_and_provider
        if params[:tne_invoice][:matter_id]
          @matter = Matter.find(params[:tne_invoice][:matter_id].to_i)
          te_conditions = "matter_id = #{params[:tne_invoice][:matter_id]} and company_id = #{@receiver.company_id}"
        elsif params[:tne_invoice][:contact_id]
          @contact = Contact.find_with_deleted(params[:tne_invoice][:contact_id].to_i)
          te_conditions = "contact_id =  #{params[:tne_invoice][:contact_id]} and matter_id is null and company_id = #{@contact.company_id}"
        end
        if params[:status].present?
          te_conditions += " and status = '#{params[:status]}' and billing_method_type is not null"
        end
        te_conditions += " and is_billable=true"
      end
      if (params[:start_date].present? && params[:end_date].present?)
        start_date = params[:start_date].to_date if params[:start_date]
        end_date = params[:end_date].to_date if params[:end_date]
        if start_date <= end_date
          t_conditions = " and time_entry_date between '#{params[:start_date]}' and '#{params[:end_date]}'"
          e_conditions = " and expense_entry_date between '#{params[:start_date]}' and '#{params[:end_date]}'"
        else
          @msg = t(:flash_end_date_start_date)
        end
      end
      case @consolidated_by
      when "Activity"
        torder = "activity_type"
        eorder = "expense_type"
      when "User"
        torder = "employee_user_id"
        eorder = "employee_user_id"
      when "Date"
        torder = "time_entry_date"
        eorder = "expense_entry_date"
      end
      @saved_time_entries = TneInvoiceTimeEntry.find(:all,:conditions => te_conditions + t_conditions, :order=> "#{torder} asc")
      @saved_expense_entries = TneInvoiceExpenseEntry.find(:all,:conditions => te_conditions + e_conditions  ,:order =>(eorder))
      @saved_time_entries.delete_if{|time|  params[:excluded_time_entries_ids].include?(time.id.to_s)} if params[:excluded_time_entries_ids]
      @saved_expense_entries.delete_if{|time|  params[:excluded_expense_entries_ids].include?(time.id.to_s)} if params[:excluded_expense_entries_ids]
      get_working_hours_total
      get_total_billable_time_amount
      get_expense_details
      @total_data, @total_expenses = [], []
      @total_amount=0
      case @consolidated_by
      when "Activity"
        time_entry_group_by = @saved_time_entries.group_by(&:activity_type)
        expense_entry_group_by = @saved_expense_entries.group_by(&:expense_type)
      when "User"
        time_entry_group_by = @saved_time_entries.group_by(&:employee_user_id)
        expense_entry_group_by = @saved_expense_entries.group_by(&:employee_user_id)
      when "Date"
        time_entry_group_by = @saved_time_entries.group_by(&:time_entry_date)
        expense_entry_group_by = @saved_expense_entries.group_by(&:expense_entry_date)
      end
      
      time_entry_group_by.each do |label, entries|
        final_billedamount = (entries.inject(0){|i, t| i += t.final_billed_amount})
        activity = entries[0].acty_type.alvalue
        lawyername = entries[0].performer.first_name + " " + entries[0].performer.last_name
        duration = entries.inject(0){|i, t| i += (current_company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(t.actual_duration) : one_tenth_timediffernce(t.actual_duration))}
        rate = final_billedamount.to_f / duration.to_f if duration > 0
        @total_amount+=final_billedamount.to_f
        case @consolidated_by
        when "Activity"
          @total_data << [label, duration * 60.00, activity, final_billedamount, entries,rate,nil,nil,lawyername,entries[0].time_entry_date]
        when "User"
          @total_data << [label, duration * 60.00, lawyername, final_billedamount, entries,rate,nil,nil,activity,entries[0].time_entry_date]
        when "Date"
          @total_data << [label.strftime('%m-%d-%y'), duration * 60.00,entries[0].time_entry_date, final_billedamount, entries,rate,nil,nil,lawyername,activity]
        end
      end
      expense_entry_group_by.each do |label, entries|
        final_expenseamount = (entries.inject(0){|i, t| i += t.final_expense_amount.to_f})
        activity = entries[0].expense.alvalue
        lawyername = entries[0].performer.first_name + " " + entries[0].performer.last_name
        @total_amount+=final_expenseamount.to_f
        case @consolidated_by
        when "Activity"
          @total_expenses << [label, nil, activity, final_expenseamount, entries,nil,nil,nil,lawyername,entries[0].expense_entry_date]
        when "User"
          @total_expenses << [label, nil, lawyername, final_expenseamount, entries,nil,nil,nil,activity,entries[0].expense_entry_date]
        when "Date"
          @total_expenses << [label.strftime('%m-%d-%y'), nil, entries[0].expense_entry_date, final_expenseamount, entries,nil,nil,nil,lawyername,activity]
        end
      end
      @grand_total = @total_amount + @billed_expenses
    end
    past_path(params)
  end

  def edit
    session[:status]= params[:status]
    data = params
    @tne_invoice = @company.tne_invoices.find_with_deleted(data[:id])
    @matter_no = @tne_invoice.matter.matter_no if @tne_invoice.matter
    @total_amount = @tne_invoice.invoice_amt
    @pagenumber=159
    params[:tne_invoice] = @tne_invoice
    past_path(params)
    session[:current_time_entry] = nil
    detailed_entries_data
    add_breadcrumb "Edit Invoice", edit_tne_invoice_path(@tne_invoice)
  end

  def create
    params[:time_entries_ids] = (params[:excluded_time_entries_ids].present? ? (params[:time_entries_ids] - params[:excluded_time_entries_ids]) : params[:time_entries_ids]) if params[:time_entries_ids]
    params[:expense_entries_ids] = (params[:excluded_expense_entries_ids].present? ? (params[:expense_entries_ids] - params[:excluded_expense_entries_ids]) : params[:expense_entries_ids]) if params[:expense_entries_ids]
    params[:tne_invoice][:tne_invoice_details_attributes].each_key do |key|
      params[:tne_invoice][:tne_invoice_details_attributes][key]["duration"]= params[:tne_invoice][:tne_invoice_details_attributes][key]["duration"].to_f*60
    end
    if params[:time_entries_ids].blank? && params[:expense_entries_ids].blank?
      present = false
    else
      present = true
      remove_commas(params)      
      params[:tne_invoice].merge!(:time_entries_ids => params[:time_entries_ids],:expense_entries_ids=>params[:expense_entries_ids],:owner_user_id=>get_employee_user_id)
      params[:tne_invoice][:invoice_no] = (params[:tne_invoice][:invoice_no]).strip if params[:tne_invoice][:invoice_no]
      @tne_invoice = @company.tne_invoices.new(params[:tne_invoice])
      update_tax_of_detailed_view
    end
    respond_to do |format|
      if present
        if @tne_invoice.save
          flash[:notice] = "#{t(:text_invoice)} No.  #{@tne_invoice.invoice_no}  Was  #{t(:flash_was_successful)}  #{t(:text_created)}"
          format.html { redirect_to tne_invoices_path(:mode_type=>params[:mode_type]) }
          format.xml  { render :xml => @tne_invoice, :status => :created, :location => @tne_invoice }
        else
          get_matters_and_contacts
          @consolidated_by= params[:tne_invoice].nil? ? 'Activity' : params[:tne_invoice][:consolidated_by]
          params[:tne_invoice_matter_id]= params[:tne_invoice][:matter_id].blank? ? '' : params[:tne_invoice][:matter_id]
          params[:tne_invoice_contact_id]= params[:tne_invoice][:matter_id].blank? ? '' : params[:tne_invoice][:contact_id]
          params[:view] = params[:view].blank? ? '' : params[:view]
          status = "Approved"
          params[:status] = status
          display_consolidated_view
          format.html { render :action => "new" }
          format.xml  { render :xml => @tne_invoice.errors.full_messages, :status => :unprocessable_entity }
        end
      else
        flash[:error] = "No Time and expense entries for generating bill"
        format.html { redirect_to tne_invoices_path(:mode_type=>params[:mode_type]) }
        format.xml  { render :xml => @tne_invoice, :status => :created, :location => @tne_invoice }
      end
    end
  end

  def update
    params[:time_entries_ids] = (params[:excluded_time_entries_ids].present? ? (params[:time_entries_ids] - params[:excluded_time_entries_ids]) : params[:time_entries_ids]) if params[:time_entries_ids]
    params[:expense_entries_ids] = (params[:excluded_expense_entries_ids].present? ? (params[:expense_entries_ids] - params[:excluded_expense_entries_ids]) : params[:expense_entries_ids]) if params[:expense_entries_ids]
    if params[:tne_invoice][:tne_invoice_details_attributes]
      params[:tne_invoice][:tne_invoice_details_attributes].each_key do |key|
        params[:tne_invoice][:tne_invoice_details_attributes][key]["duration"]= params[:tne_invoice][:tne_invoice_details_attributes][key]["duration"].to_f*60
      end
    end   
    unless params[:delete_time_entries_ids].blank?
      params[:tne_invoice][:tne_invoice_details_attributes].delete_if {|key, value| params[:delete_time_entries_ids].include?(key)}
      if params[:delete_time_detail_entries_ids]
        TneInvoiceDetail.destroy_all("id IN (#{params[:delete_time_detail_entries_ids]})")
      end
    end
    unless params[:delete_expense_entries_ids].blank?
      params[:tne_invoice][:tne_invoice_details_attributes].delete_if {|key, value| [:delete_expense_entries_ids].include?(key)}
      if params[:delete_expense_detail_entries_ids]
        TneInvoiceDetail.destroy_all("id IN (#{params[:delete_expense_detail_entries_ids]})")
      end
    end
    unless params[:excluded_time_entries_ids].blank?
      params[:excluded_time_entries_ids].each do |i|
        @time_entry = TneInvoiceTimeEntry.find(i)
        if params[:delete_time_detail_entries_ids]
          unless params[:delete_time_detail_entries_ids].include?(@time_entry.tne_invoice_detail_id.to_s)
            @time_entry_detail=TneInvoiceDetail.find(@time_entry.tne_invoice_detail_id)
            @time_entry_detail.amount-=@time_entry.final_billed_amount
            @time_entry_detail.duration-=@time_entry.actual_duration
            @time_entry_detail.rate=@time_entry_detail.amount/@time_entry_detail.duration
            @time_entry_detail.save
          end
        end
        @time_entry.update_attributes(:tne_invoice_id => "", :tne_invoice_detail_id => "",  :status => "Approved")        
      end
    end
    unless params[:excluded_expense_entries_ids].blank?
      params[:excluded_expense_entries_ids].each do |i|
        @expense_entry = TneInvoiceExpenseEntry.find(i)
        if params[:delete_expense_detail_entries_ids]
          unless params[:delete_expense_detail_entries_ids].include?(@expense_entry.tne_invoice_detail_id.to_s)
            @expense_entry_detail=TneInvoiceDetail.find(@expense_entry.tne_invoice_detail_id)
            @expense_entry_detail.amount-=@expense_entry.final_expense_amount
            @expense_entry_detail.save
          end
        end
        @expense_entry.update_attributes(:tne_invoice_id => "",:tne_invoice_detail_id => "", :status => "Approved")
      end
    end
    remove_commas(params)
    params[:tne_invoice].merge!(:owner_user_id=>get_employee_user_id)
    params[:tne_invoice].merge!(:time_entries_ids => params[:time_entries_ids]) if params[:time_entries_ids]
    params[:tne_invoice].merge!(:expense_entries_ids=> params[:expense_entries_ids]) if params[:expense_entries_ids]
    params[:tne_invoice][:invoice_no] = (params[:tne_invoice][:invoice_no]).strip if params[:tne_invoice][:invoice_no]
    if params[:tne_invoice][:regenerate].present?
      @tne_invoice = @company.tne_invoices.find(params[:tne_invoice][:id])
    else
      @tne_invoice = @company.tne_invoices.find(params[:id] || params[:tne_invoice][:id])
    end
    old_detail_ids = params[:old_tne_invoice_detail_ids].split(/,/).map(&:to_i) if params[:old_tne_invoice_detail_ids]
    if old_detail_ids
      tne_details=TneInvoiceDetail.find(:all,:conditions=>["id In (?)",old_detail_ids])
      tne_details.collect{|tne_detail| tne_detail.destroy!} if tne_details.present?
    end
    update_tax_of_summary_view
    update_tax_of_detailed_view
    detail_attributes = params[:tne_invoice][:tne_invoice_details_attributes] if old_detail_ids
    params[:tne_invoice].delete("tne_invoice_details_attributes") if old_detail_ids
    if detail_attributes.present?
      detail_attributes.has_value?("tne_invoice_time_entries_attributes")
      new_detail_attributes =  detail_attributes.each_pair do |key,value|
        value.delete("tne_invoice_time_entries_attributes")
        value.delete("tne_invoice_expense_entries_attributes")
      end
      new_detail_attributes.each_pair do |key,value|
        @tne_invoice.tne_invoice_details.create(value)
      end
    end
    respond_to do |format|
      if @tne_invoice.update_attributes(params[:tne_invoice])
        flash[:notice] = "#{t(:text_invoice)} No.  #{@tne_invoice.invoice_no}  Was  #{t(:flash_was_successful)}  #{t(:text_updated)}"
        format.html {
          if (params[:from_matter_billing])
            redirect_to bill_retainers_matter_matter_billing_retainers_path(@tne_invoice.matter_id)
          else
            redirect_to remember_past_path
            session[:status]=nil
          end
        }
        format.xml  { head :ok }        
      else
        detailed_entries_data
        format.html { render :action => "edit" }    
        format.xml  { render :xml => @tne_invoice.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  def get_base_data
    @company = current_company
    @tne_invoice_statuses = @company.tne_invoice_statuses
    @tne_invoice_setting = TneInvoiceSetting.find_by_company_id(@company.id)
  end

  def display_data
    params[:actionname] = params[:actionname]
    unless params[:delete_time_entries_ids].blank?
      params[:tne_invoice][:tne_invoice_details_attributes].delete_if {|key, value| params[:delete_time_entries_ids].include?(key)}
    end
    unless params[:delete_expense_entries_ids].blank?
      params[:tne_invoice][:tne_invoice_details_attributes].delete_if {|key, value| params[:delete_expense_entries_ids].include?(key)}
    end
    @consolidated_by =  'Activity'
     if params[:tne_invoice]
       remove_commas(params)
       @consolidated_by = params[:tne_invoice][:consolidated_by]
     end
    data = params
    @total_amount = data[:tne_invoice][:invoice_amt]
    if (data[:not_new].present? || data[:tne_invoice][:regenerate].present?)
      if data[:tne_invoice][:regenerate].present?
        @tne_invoice = TneInvoice.find(params[:tne_invoice][:id])
      else
        @tne_invoice = @company.tne_invoices.find(params[:not_new])
        @total_amount = @tne_invoice.invoice_amt
      end
      if ((params[:start_date].blank? || !params[:end_date].blank?) && (params[:tne_invoice][:consolidated_by] == @tne_invoice.consolidated_by && params[:tne_invoice][:view_by] == @tne_invoice.view_by))
        tne_invoice_details = TneInvoiceDetail.find(:all, :conditions => ["tne_invoice_id=?", @tne_invoice.id], :order=>'entry_type')
        @total_data, @total_expenses = [], []
        tne_invoice_details.each do |entry|
          if entry.entry_type == "Time"
            entries = entry.tne_invoice_time_entries
            if data[:not_new].present?
              if params[:excluded_time_entries_ids]
                entries.delete_if{|time|  params[:excluded_time_entries_ids].include?(time.id.to_s)}
              end
            end
            unless entries.blank?
              activity_type = @consolidated_by.eql?("Activity") ? entries[0].activity_type : (@consolidated_by.eql?("User") ? entries[0].employee_user_id : entries[0].time_entry_date.strftime('%m-%d-%y'))
              lawyername = @consolidated_by.eql?("Activity") ?  entry.activity : (@consolidated_by.eql?("User") ? entry.lawyer_name : entries[0].time_entry_date)
                activity = @consolidated_by.eql?("Activity") ?  entries[0].performer.first_name + " " + entries[0].performer.last_name : entries[0].acty_type.alvalue
                @total_data << [activity_type, entry.duration, lawyername, entry.amount, entries, entry.rate, entry,nil, activity]
            end
          else
            expenses = entry.tne_invoice_expense_entries
            if data[:not_new].present?
              if params[:excluded_expense_entries_ids]
                expenses.delete_if{|expense|  params[:excluded_expense_entries_ids].include?(expense.id.to_s)}
              end
            end
            unless expenses.blank?
              expense_type = @consolidated_by.eql?("Activity") ? expenses[0].expense_type :  (@consolidated_by.eql?("User") ? expenses[0].employee_user_id : expenses[0].expense_entry_date.strftime('%m-%d-%y'))
              lawyername = @consolidated_by.eql?("Activity") ? entry.activity :  (@consolidated_by.eql?("User") ? entry.lawyer_name : expenses[0].expense_entry_date)
                activity = @consolidated_by.eql?("User") ?  expenses[0].expense.alvalue : expenses[0].performer.first_name + " " + expenses[0].performer.last_name
                @total_expenses << [expense_type, nil, lawyername, entry.amount, expenses, nil,entry, nil,activity]
            end
          end
        end
      else
        @tne_invoice_details = @tne_invoice.tne_invoice_details.build
        @change_view = true
        data.merge!(:changed_view => true)
      end
    else
      @tne_invoice = TneInvoice.new(data[:tne_invoice])
      @tne_invoice_details = @tne_invoice.tne_invoice_details.build
      @tne_invoice_time_entries = @tne_invoice_details.tne_invoice_time_entries.build
      @tne_invoice_expense_entries = @tne_invoice_details.tne_invoice_expense_entries.build
    end
    session[:current_time_entry] = nil
    get_matters_and_contacts
    params[:status] = (params[:actionname].eql?("edit") ?  "Billed" : "Approved")
    if data[:changed_view]
      display_consolidated_view
    else
      display_consolidated_view unless (data[:not_new].present? || data[:tne_invoice][:regenerate].present?)
    end
    if params[:tne_invoice].present?
      @view_summery = params[:tne_invoice][:view_by]
      matterid = params[:tne_invoice][:matter_id].present? ? params[:tne_invoice][:matter_id] : nil
      contactid = params[:tne_invoice][:contact_id].present? ? params[:tne_invoice][:contact_id] : nil
      @error_msg = params[:tne_invoice][:view].eql?('presales')? 'There are no entries for this contact' : 'There are no entries for this matter'
    end
    params[:matter_id] = matterid
    params[:contact_id] = contactid
    past_path(params)
    unless params[:action].eql?('preview_bill')
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html "display",:partial=>'form'
            if @msg
              page << "show_error_msg('errorCont','#{@msg}','message_error_div');"
            end
            unless @saved_time_entries.nil? and @saved_expense_entries.nil?
              if @saved_time_entries.count<=0 and @saved_expense_entries.count<=0
                page << "show_error_msg('errorCont','#{@error_msg}','message_error_div');"
              end
            end
          end
        }
      end
    end
  end

  def destroy
    tne_invoice = @company.tne_invoices.find(params[:id])
    invoice_no = tne_invoice.invoice_no
    tne_invoice.cancel_invoice_and_bill
    
    respond_to do |format|      
      flash[:notice] = "#{t(:text_invoice)} No. #{invoice_no}  was  #{t(:flash_was_successful)}  cancelled."
      if params[:non_matter]
        format.html { redirect_to(remember_past_path) }
      else
        format.html { redirect_to(remember_past_path) }
      end
      format.xml  { head :ok }
    end
  end

  def change_status
    session[:status]= params[:status]
    if params[:automate]
      @tne_invoice = @company.tne_invoices.find(params[:id])
    else
      @bill = MatterBilling.find(params[:id])
      @matter = @bill.matter
    end
    @tne_invoice_statuses = @tne_invoice_statuses.reject{|status| status.lvalue == "Cancelled" || status.lvalue == "Partly Settled"}
    render :layout => false
  end

 	def regenerate
		tne_invoice = @company.tne_invoices.find(params[:id])
		@total_amount=  tne_invoice.invoice_amt
		tne_invoice_details = TneInvoiceDetail.find(:all,:conditions=>["tne_invoice_id=?",tne_invoice.id],:order=>'entry_type')
		dtail_amount = 0
		tne_invoice_details.each do |entry|
			if entry.entry_type=="Time"
				if entry.tne_invoice_time_entries
					tduration, tamount = 0, 0
					entry.tne_invoice_time_entries.each do |time|
						if time.tne_time_entry_id
							timeentry = Physical::Timeandexpenses::TimeEntry.find(time.tne_time_entry_id)
							time.update_attributes(:description => timeentry.description,
                :actual_duration => timeentry.actual_duration,
                :activity_rate => timeentry.activity_rate,
                :actual_activity_rate => timeentry.actual_activity_rate,
                :final_billed_amount => timeentry.final_billed_amount,
                :billing_percent => timeentry.billing_percent)
							tduration += time.actual_duration
							tamount += time.final_billed_amount
            else
              tduration += time.actual_duration
							tamount += time.final_billed_amount
						end
					end
					entry.update_attributes(:duration => tduration, :amount => tamount)
					dtail_amount += tamount
				end
			else
				if entry.tne_invoice_expense_entries
					eamount = 0
					entry.tne_invoice_expense_entries.each do |expense|
						if expense.tne_expense_entry_id
							expenseentry = Physical::Timeandexpenses::ExpenseEntry.find(expense.tne_expense_entry_id)
							expense.update_attributes(:description => expenseentry.description,
                :expense_amount => expenseentry.expense_amount,
                :final_expense_amount => expenseentry.final_expense_amount)
							eamount += expense.final_expense_amount
            else
              eamount += expense.final_expense_amount
						end
					end
					entry.update_attribute("amount", eamount)
					dtail_amount += eamount
				end
			end
		end
		tne_invoice.update_attributes(:invoice_amt => dtail_amount, :final_invoice_amt => dtail_amount)
		redirect_to regenerate_bill_tne_invoice_path(tne_invoice,:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:q=>params[:q],:col=>params[:col],:dir=>params[:dir],:mode_type=>params[:mode_type],:status=>params[:status])
	end

	def regenerate_bill
		@tne_invoice = @company.tne_invoices.find(params[:id])
		@total_amount=   @tne_invoice.invoice_amt
		@tne_invoice.tne_invoice_details.each do |detail|
			detail.tne_invoice_time_entries.each do |time|
        if time.tne_time_entry_id.present?
          tne_timeentries = Physical::Timeandexpenses::TimeEntry.find(time.tne_time_entry_id)
          tne_timeentries.status = 'Approved'
          tne_timeentries.tne_invoice_id=nil
          tne_timeentries.save
          time.update_attributes(tne_timeentries.attributes)
        else
          time.update_attributes(:status =>'Approved', :tne_invoice_id => nil)
        end
			end
			detail.tne_invoice_expense_entries.each do |expense|
        if expense.tne_expense_entry_id.present?
          tne_expenseentries = Physical::Timeandexpenses::ExpenseEntry.find(expense.tne_expense_entry_id)
          tne_expenseentries.status = 'Approved'
          tne_expenseentries.tne_invoice_id=nil
          tne_expenseentries.save
          expense.update_attributes(tne_expenseentries.attributes)
        else
          expense.update_attributes(:status =>'Approved', :tne_invoice_id => nil)
        end
			end     
		end
		newstatus = @tne_invoice.company.tne_invoice_statuses.find_by_lvalue("Open")
		@tne_invoice.update_attribute(:tne_invoice_status_id, newstatus.id)
		params[:tne_invoice] = @tne_invoice
		params[:tne_invoice][:regenerate]=true
		params[:tne_invoice][:id]=params[:id]
		session[:current_time_entry] = nil
    past_path(params)
		get_matters_and_contacts
    bills = MatterBilling.find_all_by_tne_invoice_id(params[:id])
    bills.each { |item|
      if item.id!=item.bill_id
        item.destroy
      end
    }
	end

  def search_invoice
    @cancelstatus = @company.tne_invoice_statuses.find_by_lvalue("Cancelled")
    @status = @tne_invoice_statuses.find_by_id(params[:status]) if params[:status].present? 
    status=(params[:status].to_i==@cancelstatus.id)
    unless params[:q].blank?
      if status        
        result = @company.tne_invoices.find_only_deleted(:all,:include=>[:matter,:contact],:conditions=>["(contacts.first_name ILIKE ? OR matters.name ILIKE ? or invoice_no ILIKE ? OR matters.matter_no ILIKE ? )and tne_invoice_status_id= ?","%#{params[:q]}%","%#{params[:q]}%","%#{params[:q]}%","%#{params[:q]}%",params[:status]],:limit => 10000)
      else
        search_value= "#{params[:q]}"
        if params[:type]=="client"
          result = TneInvoice.search search_value, :with => {:company_id => @company.id, :matter_id => 0}, :star => true
        else
          result =  MatterBilling.search search_value, :with => {:company_id => @company.id}, :without => {:matter_billing_status_id => @cancelstatus.id }, :star => true
        end
      end
    else
      if status
        result = TneInvoice.get_invoices(@company, @status, params, false)
      else
        result = MatterBilling.get_bills(@company, @status, params, false)
      end      
    end
    unless result.nil?
      if params[:display]        
        params[:mode_type] = params[:type]
				render :partial=> 'search_pagination', :locals => {:tne_invoices => result,:mode_type => params[:type]}
      else
        render :partial=> 'invoice_auto_complete', :locals => {:result => result, :mode_type => params[:type],:cancelled=>status}
      end
    end
  end

  def view_unbilled_entries
    add_breadcrumb  "Unbilled(Approved) T & E Entries", view_unbilled_entries_tne_invoices_path
    @pagenumber= 202
    company_id = get_company_id
    @dur_setng_is_one100th = @company.duration_setting.setting_value == "1/100th"
    @cancelstatus = @tne_invoice_statuses.find_by_lvalue("Cancelled")
    matters = Matter.team_matters(get_employee_user_id, company_id)
    @matter_time_entries = Physical::Timeandexpenses::TimeEntry.approved_matter_entries(matters.map(&:id))
    matter_time_entry = @matter_time_entries.blank? ? matters.map(&:id) : @matter_time_entries.map(&:matter_id)
    matter_ids = matters.map(&:id).reject{|id| matter_time_entry.include?(id)}
    @matter_expense_entries =  Physical::Timeandexpenses::ExpenseEntry.approved_expense_matter_entries(matter_ids)
    
    @contact_time_entries = Physical::Timeandexpenses::TimeEntry.approved_contact_entries(company_id)
    contact_expense_entry = Physical::Timeandexpenses::ExpenseEntry.approved_expense_contact_entries(company_id)
    contact_time_entry = @contact_time_entries.blank? ? '' : @contact_time_entries.map(&:contact_id)
    @contact_expense_entries = contact_expense_entry.reject{|expense| contact_time_entry.include?(expense.contact_id)} if contact_expense_entry
    unless(can? :manage, MatterBilling)
      params[:view] = 'presales'
    end
  end

  def detailed_entries_data
    tne_invoice_details = TneInvoiceDetail.find(:all,:conditions=>["tne_invoice_id=?",@tne_invoice.id],:order=>'entry_type')
    tne_invoice_details_x = tne_invoice_details.reverse
    get_matters_and_contacts
    @consolidated_by= params[:tne_invoice].nil? ? 'Activity' : params[:tne_invoice][:consolidated_by]
    @view_summery = params[:tne_invoice][:view_by]
    @total_data, @total_expenses = [], []
    tne_invoice_details_x.each do |entry|
      if entry.entry_type=="Time"
        entries = entry.tne_invoice_time_entries
        unless entries.blank?
          activity_type = @consolidated_by=="Activity" ? entries[0].activity_type : (@consolidated_by== "User" ? entries[0].employee_user_id : entries[0].time_entry_date.strftime('%m-%d-%y'))
          lawyername = @consolidated_by=="Activity" ? entry.activity : (@consolidated_by== "User" ?  entry.lawyer_name : entry.tne_entry_date)
          activity = @consolidated_by=="Activity" ?  entries[0].performer.first_name + " " + entries[0].performer.last_name : entries[0].acty_type.alvalue
          @total_data << [activity_type, entry.duration, lawyername, entry.amount, entries, entry.rate, entry,activity,entries[0].time_entry_date]
        end
      else
        expenses = entry.tne_invoice_expense_entries
        unless expenses.blank?
          expense_type = @consolidated_by=="Activity" ? expenses[0].expense_type : (@consolidated_by== "User" ? expenses[0].employee_user_id : expenses[0].expense_entry_date.strftime('%m-%d-%y'))
          lawyername = @consolidated_by=="Activity" ? entry.activity :  (@consolidated_by== "User" ? entry.lawyer_name : entry.tne_entry_date)
          activity = @consolidated_by=="Activity" ?  expenses[0].performer.first_name + " " + expenses[0].performer.last_name : expenses[0].expense.alvalue
          @total_expenses << [expense_type, nil, lawyername, entry.amount, expenses, nil,entry,activity,expenses[0].expense_entry_date]
        end
      end
    end
  end

  #remove comma from amount before saving into database
	def remove_commas(params)
		params[:tne_invoice][:invoice_amt]= params[:tne_invoice][:invoice_amt].gsub(',','') if params[:tne_invoice][:invoice_amt]
		params[:tne_invoice][:final_invoice_amt] = params[:tne_invoice][:final_invoice_amt].gsub(',','') if params[:tne_invoice][:final_invoice_amt]
		params[:tne_invoice][:discount] = params[:tne_invoice][:discount].gsub(',','') if  params[:tne_invoice][:discount]
		if params[:tne_invoice][:tne_invoice_details_attributes]
			params[:tne_invoice][:tne_invoice_details_attributes].each do |k,v|
				params[:tne_invoice][:tne_invoice_details_attributes][k][:amount] = params[:tne_invoice][:tne_invoice_details_attributes][k][:amount].gsub(',','')
				params[:tne_invoice][:tne_invoice_details_attributes][k][:rate] = params[:tne_invoice][:tne_invoice_details_attributes][k][:rate].gsub(',','') if params[:tne_invoice][:tne_invoice_details_attributes][k][:rate]
			end
		end
		params[:primary_tax_value] = params[:primary_tax_value].gsub(',','') if params[:primary_tax_value]
		params[:secondary_tax_value] = params[:secondary_tax_value].gsub(',','')  if params[:secondary_tax_value]
		return params
	end

	# Update the primary tax and secondary tax of time entry and expense entry when view is summary
	def update_tax_of_summary_view
		if params[:tne_invoice][:view_by]=='Summary'
			invoice=params[:tne_invoice][:tne_invoice_details_attributes]
			invoice.each do |k,v|
				if invoice[k][:tne_invoice_time_entries_attributes]
					time_r_expense= TneInvoiceTimeEntry.find_by_id(invoice[k][:tne_invoice_time_entries_attributes]["0"][:id].to_i)
				elsif invoice[k][:tne_invoice_expense_entries_attributes]
					time_r_expense= TneInvoiceExpenseEntry.find_by_id(invoice[k][:tne_invoice_expense_entries_attributes]["0"][:id].to_i)
				else
					time_r_expense = nil
				end
				unless time_r_expense.nil?
					time_r_expense.primary_tax =invoice[k][:primary_tax]
					time_r_expense.secondary_tax = invoice[k][:secondary_tax]
					time_r_expense.save!
				end
			end
		end
	end

  # Update the primary tax and secondary tax of time entry and expense entry when view is detailed
	def update_tax_of_detailed_view
		if params[:tne_invoice][:view_by]=='Detailed'
			params.each do |k,v|
				if k.match(/check_detailed_p_tax_/)
					id= k.split('check_detailed_p_tax_')[1].to_i
					time= TneInvoiceTimeEntry.find_by_id(id)
					time.primary_tax=params["check_detailed_p_tax_#{id}"]
					time.secondary_tax=params["check_detailed_s_tax_#{id}"]
					time.save!
				elsif k.match(/check_detailed_expense_p_tax_/)
					id= k.split('check_detailed_expense_p_tax_')[1].to_i
					expense= TneInvoiceExpenseEntry.find_by_id(id)
					expense.primary_tax=params["check_detailed_expense_p_tax_#{id}"]
					expense.secondary_tax=params["check_detailed_expense_s_tax_#{id}"]
					expense.save!
				end
			end
		end
	end

  #it used to display radio buttons on clicking on create new invoice icon
  def select_manual_or_system_bill
    @matters = Matter.unexpired_team_matters(get_employee_user_id, get_company_id, Date.today) unless params[:from_matter_billing]
    if can? :manage, MatterBilling
      render :layout=>false
    else
      redirect_to new_tne_invoice_path(:view => params[:view])
    end
  end

  def preview_bill
    if params[:tne_invoice][:contact_id]
      @primary_contact= Contact.find_by_id( params[:tne_invoice][:contact_id])
    else
      @matter=Matter.find_by_id(params[:tne_invoice][:matter_id])
      @primary_contact=@matter.contact
    end
    @invoice_setting = TneInvoiceSetting.find_by_company_id(@company.id)
    @logo=''
    if @company.logo_for_invoice
      @logo=@company.logo.url
    end
    get_matters_and_contacts
    if params[:actionname]== 'new'
      params[:status] = "Approved"
      @tne_invoice = @company.tne_invoices.new
      @tne_invoice_details = @tne_invoice.tne_invoice_details.build
      @tne_invoice_time_entries = @tne_invoice_details.tne_invoice_time_entries.build
      @tne_invoice_expense_entries = @tne_invoice_details.tne_invoice_expense_entries.build
      display_consolidated_view
    else
      @tne_invoice = @company.tne_invoices.find_with_deleted(params[:tne_invoice][:id])
      @tne_invoice.invoice_no = params[:tne_invoice][:invoice_no]
      display_data
    end
    render :layout=>false
  end


  def check_invoice_no
    invoice = MatterBilling.find(:last,:conditions=>["bill_no ilike ? and company_id = ?",params[:invoice_no],current_company.id])
    message= ""
    if invoice && (params[:invoice_id].blank? || (params[:invoice_id].present? &&  invoice.tne_invoice_id != params[:invoice_id].to_i))
      message = "Invoice No Has Already Been Taken"
    end
    respond_to do |format|
      format.js { render :text => message }
    end
  end

  # it is used to redirect to previous path on cancel, update of invoice
  def past_path(params)
    params[:mode_type]=params[:view].eql?("presales") ? "client" : "matter" if params[:mode_type].blank?
    @remember_path={}
    if params[:from_unbilled].present?
      @remember_path=view_unbilled_entries_tne_invoices_path(:mode_type=>params[:mode_type])
    elsif params[:flag].present?
      matterid = @tne_invoice.matter_id.present? ? @tne_invoice.matter_id : (params[:matter_id].present? ? params[:matter_id] : params["tne_invoice"]["matter_id"])
      @remember_path=bill_retainers_matter_matter_billing_retainers_path(:matter_id=>matterid,:from=>"matters")
    else
      @remember_path=remember_past_path
    end
  end


  def get_matter_no
    matter_no = Matter.find_with_deleted(:first,:conditions =>{:id => params[:matter_id]}).matter_no
    respond_to do |format|
      format.js { render :text => matter_no }
    end
  end

   private

  def get_duration_setting
   @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
  end
  
end