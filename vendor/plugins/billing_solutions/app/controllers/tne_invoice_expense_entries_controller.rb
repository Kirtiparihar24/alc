class TneInvoiceExpenseEntriesController < ApplicationController

  # Updates billing related values over updating expense entry discount.
  def calculate_discount_rate_for_expense_entry
    data=params
    @tne_invoice_expense_entry = TneInvoiceExpenseEntry.new
    #@discount = @tne_invoice_expense_entry.calculate_new_expense_discount(data[:billing_amount].to_f, data[:billing_percent].to_f)
    @discount = @tne_invoice_expense_entry.calculate_new_expense_discount(data[:final_expense_amount].to_f, data[:billing_percent].to_f)
    respond_to do |format|
      format.js
    end
  end
 def set_expense_entry_status
    data=params
    @i = TneInvoiceExpenseEntry.find(data[:id])
    previous_val = @i.status
    @i.update_attribute( :status, data[:value])
    if (previous_val.nil? or previous_val == 'Open') && @i.status == 'Approved'
      send_tne_status_update_mail(current_user, @i)
    end
    render :text => ''#params[:value]
  end
  # Updates value of expense_type through in line editing feature of expense entry.
  def set_expense_entry_expense_type
    data=params
    @i = TneInvoiceExpenseEntry.find(data[:id])
    f  = Physical::Timeandexpenses::ExpenseType.find(data[:value])
    @i.update_attribute( :expense_type, data[:value])
    render :text => f.lvalue
  end

  # Updates value of expense_amount and related fields through in line editing feature of expense entry.
  def set_expense_entry_expense_amount
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    expense_amount = !data[:value].blank? ? data[:value].to_i : 0
    @error=false
    if expense_amount > 0
      @tne_invoice_expense_entry.update_attribute(:expense_amount,expense_amount)
      @final_expense_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
    else
      @error=true
      flash[:error]= t(:flash_enter_valid_expense_amt)
    end
  end
  def set_expense_entry_full_amount
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @tne_invoice_expense_entry.final_expense_amount
    @tne_invoice_expense_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 1})
    @final_expense_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
  end

  # Updates value of description through in line editing feature of expense entry.
  def set_expense_entry_description
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    @tne_invoice_expense_entry.update_attribute(:description,data[:value])
    render :text => @tne_invoice_expense_entry.description
  end

  # Updates value of billing_percent(discount) and related fields through in line editing feature of expense entry.
  def set_expense_entry_billing_percent
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @tne_invoice_expense_entry.final_expense_amount
    if data[:value].to_i.between?(0,100)
      @tne_invoice_expense_entry.update_attributes({:billing_percent => data[:value], :billing_method_type => 2})
      @final_expense_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end
  end
  def set_expense_entry_markup
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @tne_invoice_expense_entry.final_expense_amount
    if data[:value].to_i.between?(0,1000)
      @tne_invoice_expense_entry.update_attributes({:billing_percent =>data[:value], :billing_method_type => 4,:markup=>data[:value]})
      @final_expense_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
    else
      @error=true
      flash[:error]= "#{t(:tne_billing)}"
    end
  end

  # Updates value of billing_amount(override amount) and related fields through in line editing feature of expense entry.
  def set_expense_entry_billing_amount
    data=params
    @tne_invoice_expense_entry =  TneInvoiceExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @tne_invoice_expense_entry.final_expense_amount
    @tne_invoice_expense_entry.update_attributes({:final_expense_amount => data[:value], :billing_percent => "", :billing_method_type => 3})
    @final_expense_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
  end

  # Updates value of is_billable and related fields through in line editing feature of expense entry.
  def set_expense_is_billable
    data=params
    @tne_invoice_expense_entry = TneInvoiceExpenseEntry.find(data[:id])
    @previous_final_billed_amount = @tne_invoice_expense_entry.final_expense_amount
    if @tne_invoice_expense_entry.billing_method_type.to_i == 1
       @tne_invoice_expense_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal], :billing_percent => ''})
    else
       @tne_invoice_expense_entry.update_attributes({:is_billable => data[:billing_type], :is_internal => data[:is_internal]})
    end

    if data[:is_internal].to_s.eql?("true")
      @tne_invoice_expense_entry.update_attributes({:contact_id => '', :matter_id => ''})
    end
    @billed_amount = @tne_invoice_expense_entry.calculate_final_expense_amount
#    flash[:error]= t(:flash_enter_valid_expense_amt)
  end

  def get_unexpired_matters(date,employee_user_id)
    @matters = Matter.unexpired_team_matters(employee_user_id, get_company_id, date)
    #@matters = @matters.sort{|x,y| x.name <=>y.name}
  end

  def get_contacts
    #@contacts = Contact.find_all_by_company_id_and_employee_user_id(get_company_id, get_employee_user_id)
    @contacts = Contact.find_all_by_company_id(get_company_id,:include=>:company,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    #    @contacts = @contacts.sort{|x,y| x.name <=>y.name}
  end

  def new_expense_entry
    @company_id = get_company_id
    @tne_invoice_expense_entry = TneInvoiceExpenseEntry.new
    
    @tne_invoice_expense_entry.employee_user_id = get_employee_user_id
    @tne_invoice_expense_entry.tne_invoice_id=params[:invoice_id]

    get_unexpired_matters(Date.today,@tne_invoice_expense_entry.employee_user_id)
    get_contacts
     if params[:from].eql?("matters")
      @matter = current_company.matters.find(params[:matter_id])
      @lawyers=@matter.matter_peoples.client
     else
     @tne_invoice_expense_entry.contact_id=params[:contact_id]
     @contact_name=Contact.find(@tne_invoice_expense_entry.contact_id).full_name
     @lawyers={}
    end
    render :layout => false
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
  
  def add_new_expense_entry
    unless params[:expense_invoice_id].eql?('0')
        tne_invoices=TneInvoice.find(params[:expense_invoice_id])
        act_type_val = CompanyLookup.find(:first,:conditions => ['company_id = ? and id=? and type like ?',current_company.id,params[:activity_type],"Physical::Timeandexpenses::ExpenseType"]).alvalue rescue 0
        consolidated_by = params[:consolidated_by]
        conditions="entry_type= 'Expense' and tne_invoice_id= #{tne_invoices.id} and matter_id = #{tne_invoices.matter_id}" if tne_invoices.matter_id.present?
        conditions = "entry_type= 'Expense' and tne_invoice_id= #{tne_invoices.id} and contact_id = #{tne_invoices.contact_id}" if tne_invoices.contact_id.present?
        if consolidated_by.eql?('Date')
          conditions += " and tne_entry_date = '#{Time.zone.now.to_date}'"
        elsif consolidated_by.eql?('User')
          conditions += " and lawyer_name= '#{current_user.full_name}'"
        else
          conditions += " and entry_type =  '#{act_type_val}'"
        end
         tne_invoice_detail_count=TneInvoiceDetail.find(:first,:conditions =>conditions)
        
        if  tne_invoice_detail_count.nil?
          @tne_invoice_detail_data=TneInvoiceDetail.new()
          @tne_invoice_detail_data.entry_type="Expense"
          @tne_invoice_detail_data.matter_id=params[:matter_id]
          @tne_invoice_detail_data.contact_id=params[:contact_id]
          if consolidated_by.eql?('Date')
            @tne_invoice_detail_data.tne_entry_date = Time.zone.now.to_date
          end
          @tne_invoice_detail_data.lawyer_name=current_user.full_name          
          @tne_invoice_detail_data.activity= act_type_val
          @tne_invoice_detail_data.amount=params[:activity_amount]
          @tne_invoice_detail_data.company_id=get_company_id
          @tne_invoice_detail_data.tne_invoice_id=tne_invoices.id
          @tne_invoice_detail_data.save
        else
          tne_invoice_detail_count.amount+=params[:activity_amount].to_f
          tne_invoice_detail_count.save          
        end
     end

      @tne_invoice_expense_entry=TneInvoiceExpenseEntry.new
      @tne_invoice_expense_entry.employee_user_id=get_employee_user_id
      @tne_invoice_expense_entry.created_by_user_id=current_user.id
      @tne_invoice_expense_entry.expense_type=params[:activity_type]
      @tne_invoice_expense_entry.description=params[:description]
      @tne_invoice_expense_entry.expense_entry_date=Time.zone.now.to_date
      @tne_invoice_expense_entry.billing_method_type=1
      @tne_invoice_expense_entry.expense_amount=params[:activity_amount]
      @tne_invoice_expense_entry.final_expense_amount=params[:activity_amount]
      if params[:matter_id].present?
        @tne_invoice_expense_entry.contact_id=current_company.matters.find(params[:matter_id]).contact_id
      else
        @tne_invoice_expense_entry.contact_id=params[:contact_id]
      end
      @tne_invoice_expense_entry.matter_id=params[:matter_id]
      @tne_invoice_expense_entry.company_id=get_company_id
      params[:expense_invoice_id].eql?('0') && params[:regenerate]== "false" ? @tne_invoice_expense_entry.status='Approved':  (params[:regenerate]== "true" ? @tne_invoice_expense_entry.status='Approved' : @tne_invoice_expense_entry.status='Billed' )
      @tne_invoice_expense_entry.is_billable=1
      @tne_invoice_expense_entry.is_internal=0
      params[:primary_tax].eql?('true')?@tne_invoice_expense_entry.primary_tax=1:@tne_invoice_expense_entry.primary_tax=0
      params[:secondary_tax].eql?('true')?@tne_invoice_expense_entry.secondary_tax=1:@tne_invoice_expense_entry.secondary_tax=0

      unless tne_invoice_detail_count.nil?
          @tne_invoice_expense_entry.tne_invoice_detail_id=tne_invoice_detail_count.id
          @tne_invoice_expense_entry.tne_invoice_id=tne_invoice_detail_count.tne_invoice_id
      else
        unless params[:expense_invoice_id].eql?('0')
          @tne_invoice_expense_entry.tne_invoice_detail_id=@tne_invoice_detail_data.id
          @tne_invoice_expense_entry.tne_invoice_id=@tne_invoice_detail_data.tne_invoice_id
        end
      end
      
      

     if @tne_invoice_expense_entry.valid? && @tne_invoice_expense_entry.errors.empty?
         @tne_invoice_expense_entry.save
     end

    unless tne_invoices.nil?
      tne_invoices.invoice_amt+=@tne_invoice_expense_entry.expense_amount
      tne_invoices.save
     end
       respond_to do |format|
        format.js {
          render :update do|page|
            if(@tne_invoice_expense_entry.errors.empty?)
              page << "tb_remove();"
              page << "time_entry_refresh();"
              #page << "window.location.href=#{request.referer.inspect};"
            else
              page << "jQuery('#loader').hide();"
              format_ajax_errors(@tne_invoice_expense_entry, page, 'error_notice')
            end
          end
        }
        format.xml  { render :xml => @tne_invoice_expense_entry, :status => :created, :location => @tne_invoice_expense_entry }
        format.html {
          #flash[:notice] = "#{t(:text_matter_task)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          redirect_to(new_tne_invoice_path(:matter_id=>params[:matter_id]))
        }

      end
   end

    def save_all_expense_entries_home
    data=params    
    get_receiver_and_provider
    errs = "<ul>"
    consolidated_by = params[:consolidated_by]
    @expense_save_result = data.rehash.each_pair do |key,value|
      if key.eql?('0')
      @tne_invoice_expense_entry = TneInvoiceExpenseEntry.new(value[:tne_invoice_expense_entry])
     ActiveRecord::Base.transaction do
      unless @tne_invoice_expense_entry.tne_invoice_id.nil?
        tne_invoices=TneInvoice.find(@tne_invoice_expense_entry.tne_invoice_id)
        act_type_val = CompanyLookup.find(:first,:conditions => ['company_id = ? and id=? and type like ?',current_company.id,@tne_invoice_expense_entry.expense_type,"Physical::Timeandexpenses::ExpenseType"]).alvalue rescue 0
        conditions = "entry_type= 'Expense' and tne_invoice_id= #{tne_invoices.id} and matter_id = #{tne_invoices.matter_id}" if tne_invoices.matter_id.present?
        conditions = "entry_type= 'Expense' and tne_invoice_id= #{tne_invoices.id} and contact_id = #{tne_invoices.contact_id}" if tne_invoices.contact_id.present?
        lawyer_name = User.find_by_id_and_company_id(value[:tne_invoice_expense_entry][:employee_user_id] || get_employee_user_id,tne_invoices.company_id).full_name rescue ''
        if consolidated_by.eql?('User')
          conditions += " and lawyer_name = '#{lawyer_name}'"
        elsif consolidated_by.eql?('Date')
          conditions += " and tne_entry_date = '#{@tne_invoice_expense_entry.expense_entry_date}'"
        else
          conditions += " and activity = '#{act_type_val}'"
        end
          tne_invoice_detail_count=TneInvoiceDetail.find(:first,:conditions=>conditions)
        if tne_invoice_detail_count.nil?
          @tne_invoice_detail_data=TneInvoiceDetail.new()
          @tne_invoice_detail_data.entry_type="Expense"
          @tne_invoice_detail_data.matter_id=@tne_invoice_expense_entry.matter_id
          @tne_invoice_detail_data.contact_id=@tne_invoice_expense_entry.contact_id
           if consolidated_by.eql?('Date')
            @tne_invoice_detail_data.tne_entry_date = @tne_invoice_expense_entry.expense_entry_date
          end
          @tne_invoice_detail_data.lawyer_name=lawyer_name
          @tne_invoice_detail_data.activity= act_type_val
          @tne_invoice_detail_data.amount=@tne_invoice_expense_entry.expense_amount.to_f
          @tne_invoice_detail_data.company_id=get_company_id
          @tne_invoice_detail_data.tne_invoice_id=tne_invoices.id
          @tne_invoice_detail_data.save
        else
          tne_invoice_detail_count.amount+=@tne_invoice_expense_entry.expense_amount.to_f
          tne_invoice_detail_count.save
        end

        unless tne_invoice_detail_count.nil?
          @tne_invoice_expense_entry.tne_invoice_detail_id=tne_invoice_detail_count.id
          @tne_invoice_expense_entry.tne_invoice_id=tne_invoice_detail_count.tne_invoice_id
          else
            unless @tne_invoice_expense_entry.tne_invoice_id.nil?
              @tne_invoice_expense_entry.tne_invoice_detail_id=@tne_invoice_detail_data.id
              @tne_invoice_expense_entry.tne_invoice_id=@tne_invoice_detail_data.tne_invoice_id
            end
        end
      end
     
        if @tne_invoice_expense_entry.employee_user_id.blank?
          @tne_invoice_expense_entry.employee_user_id = get_employee_user_id
        end
        @tne_invoice_expense_entry.tne_invoice_id.present? && params[:regenerate]=="false" ? @tne_invoice_expense_entry.status='Billed' : @tne_invoice_expense_entry.status='Approved'
        if (data[key+'_nonuser'].present? && value[:tne_invoice_expense_entry][:matter_people_id].present?)
          matter = Matter.find(@tne_invoice_expense_entry.matter_id)
          @tne_invoice_expense_entry.employee_user_id = value[:tne_invoice_expense_entry][:employee_user_id]
        end
        @tne_invoice_expense_entry.performer = User.find(get_employee_user_id)        
        @tne_invoice_expense_entry.created_by = current_user
        @tne_invoice_expense_entry.company_id = get_company_id
        
          if @tne_invoice_expense_entry.valid? && @tne_invoice_expense_entry.errors.empty?            
              @tne_invoice_expense_entry.save
              flash[:notice]="#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"            
          else
            errs += @tne_invoice_expense_entry.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ")
          end
        end
      
    end
    end
    errs += "</ul>"
   
    responds_to_parent do
      errs = errs.gsub(/[']/, '''').to_s
      render :update do |page|         
        unless errs == "<ul></ul>"          
          page << "jQuery('#expense_loader').hide();"
          page << "enableAllSubmitButtons('time_and_expense');"
          page << "jQuery('input[name=save_and_add_expense]').val('Save & Exit');"
          page << "show_error_msg('modal_expense_entry_errors','#{errs}','message_error_div');"
          page<< "jQuery('#modal_expense_entry_errors').show();"
          page << "jQuery('#expense_loader').hide();"
        else          
           if params[:from].eql?("matters")
              flash[:notice] =  "#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
              page << "tb_remove();"
              page << " show_error_msg('errorCont','Expense Entry Saved Successfully','message_sucess_div');"
              page << "time_entry_refresh();"             
           else
          page << "parent.tb_remove();"
          page << "jQuery('#altnotice').html('#{escape_javascript(render(:partial => 'common/common_flash_message'))}')";
           end
          if params[:note_id].present?
            page.call "deleteStickyNote",params[:note_id]
          end
        end
      end
    end
  end

  def destroy
    @expense_entry =  TneInvoiceExpenseEntry.find(params[:id])
      if  @expense_entry.tne_expense_entry_id.present?
        if params[:to_do] == "delete_appear"
          if @expense_entry.tne_invoice_detail_id.present?
            @expense_entry_detail=TneInvoiceDetail.find(@expense_entry.tne_invoice_detail_id)
            @expense_entry_detail.amount-=@expense_entry.final_expense_amount
            @expense_entry_detail.save
          end
          @expense_entry.update_attributes(:billing_percent=>100,:billing_method_type => 2,:final_expense_amount=>0.0)
        end
        if params[:to_do] == "delete_donot_appear"
          if @expense_entry.tne_invoice_detail_id.present?
            @expense_entry_detail=TneInvoiceDetail.find(@expense_entry.tne_invoice_detail_id)
            @expense_entry_detail.amount-=@expense_entry.final_expense_amount
            @expense_entry_detail.save
          end
          @expense_entry.is_billable = false
          @expense_entry.status = "Approved"
          @expense_entry.final_expense_amount = 0.0
          @expense_entry.billing_method_type = 1
          @expense_entry.tne_invoice_id = ""
          @expense_entry.tne_invoice_detail_id = ""
          @expense_entry.send(:update_without_callbacks)
          expense=Physical::Timeandexpenses::ExpenseEntry.find_by_id(@expense_entry.tne_expense_entry_id)
          expense.update_attributes(:status => "Approved", :is_billable => false)
        end
      else
        unless @expense_entry.tne_invoice_detail_id.nil?
          if @expense_entry.contact_id.present? && @expense_entry.matter_id.nil?
            @expense_entries_count=TneInvoiceExpenseEntry.find(:all,:conditions=>['tne_invoice_detail_id=? and contact_id=? ',@expense_entry.tne_invoice_detail_id,@expense_entry.contact_id])
          else
            @expense_entries_count=TneInvoiceExpenseEntry.find(:all,:conditions=>['tne_invoice_detail_id=? and matter_id=? ',@expense_entry.tne_invoice_detail_id,@expense_entry.matter_id])
          end
          @expense_entry_detail=TneInvoiceDetail.find(@expense_entry.tne_invoice_detail_id);
          if @expense_entries_count.size==1
            @expense_entry_detail.destroy
          else
            @expense_entry_detail.amount-=@expense_entry.final_expense_amount
            @expense_entry_detail.save

          end
        end
        @expense_entry.destroy!
      end
      render :text=>''
  end

   def delete_all_expense_entries
     params[:invoice_id].present?? bill_status='Billed' :  bill_status='Approved'

    if params[:consolidate_by].eql?('Activity')
      if params[:matter_id].present?
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['matter_id=? and expense_type=? and status=?',params[:matter_id],params[:expense_type],bill_status])
      else
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['contact_id=? and expense_type=? and status=?',params[:contact_id],params[:expense_type],bill_status])
      end
    elsif params[:consolidate_by].eql?('Date')
       if params[:matter_id].present?
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['matter_id=? and expense_entry_date=? and status=?',params[:matter_id],params[:expense_type],bill_status])
      else
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['contact_id=? and expense_entry_date=? and status=?',params[:contact_id],params[:expense_type],bill_status])
      end
    else
      if params[:matter_id].present?
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['matter_id=? and employee_user_id=? and status=?',params[:matter_id],params[:expense_type],bill_status])
      else
        @expense_entry =  TneInvoiceExpenseEntry.find(:all,:conditions=>['contact_id=? and employee_user_id=? and status=?',params[:contact_id],params[:expense_type],bill_status])
      end
    end
    if @expense_entry[0].tne_invoice_detail_id.present?
      @expense_entry_detail=TneInvoiceDetail.find(@expense_entry[0].tne_invoice_detail_id)
    end
      unless@expense_entry_detail.nil?
       @expense_entry_detail.destroy
      end
      #TneInvoiceExpenseEntry.destroy @expense_entry.collect(&:id)
      @expense_entry.each do |expense_entry|
        if expense_entry.tne_expense_entry_id.present?
          expense_entry.destroy
        else
          expense_entry.destroy!
        end
      end
      render :text=>''
  end

   def delete_expense_entry
    @expense_entry = TneInvoiceExpenseEntry.find(params[:expense_entry_id])
    @counter = params[:counter]
    @detail_entry= params[:detail_id]
    render :layout=>false
  end
end


