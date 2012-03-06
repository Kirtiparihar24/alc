class InvoicesController < ApplicationController
  layout "admin"
  #This function is used to provide the data for index view of the invoice. Here if the login person is a livia admin ,
  #the person can able to see invoices generated and also can be able to see  the options for filtering to see the selected invoices.
  #In the case of Lawfirm admin, that person can be able see only that company invoices only.
  #The actions that can be done like delete etc. will get displayed based on the login
  def index
    authorize!(:index,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    if current_user.role? :livia_admin
      @company_id = ((params[:company].blank?? "all" : params[:company][:id]) == "")? "all" : (params[:company].blank?? "all" : params[:company][:id])
    elsif current_user.role? :lawfirm_admin
      @company_id = current_user.company.id
    end
    @companies = Company.getcompanylist(current_user.company_id)
    @month = (params[:invoiceMonth].blank?? "All" : params[:invoiceMonth][:select])
    @status = (params[:invoiceStatus].blank?? "All" : params[:invoiceStatus][:select])
    @invoices = Invoice.index_invoice(@company_id,@month,@status).paginate :page => params[:page], :per_page => 20
    if request.xhr?
      respond_to do |format|
        format.js
      end
    end
  end

  #This functon is used to provide the default dates for invoice generation in Billing & Payment module
  def selected_company_invoice_dates
    company = Company.find(params[:company_id])
    if company.billingdate      
      end_month = Time.zone.now.to_date.month.to_i
      @end_date = (company.billingdate.to_date - ((company.billingdate.to_date.month.to_i - end_month.to_i)).months).to_date
      @start_date = (company.billingdate.to_date - ((company.billingdate.to_date.month.to_i + 1 - end_month.to_i)).months).to_date + 1.days
    else
      render :nothing=>true
    end
  end

  #This functon is used to provide the data required for generation of new invoice
  def new
    authorize!(:new,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @companies = Company.getcompanylist(current_user.company_id)
  end

  #This function is used to delete the selected invoice. Here for deleting the invoice there should not be any payment related to that invoice.
  def delete
    authorize!(:delete,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @invoice = Invoice.find(params[:id])
    if @invoice.payments.empty?
      InvoiceDetail.delete_all(:invoice_id=>params[:id])
      @invoice.delete
      flash[:notice] = "#{t(:text_invoices)} " "#{t(:flash_was_successful)} " "#{t(:text_deleted)}"
    else
      flash[:error] = t(:flash_invoice_cannot_deleted)
    end
    respond_to do |format|
      format.html { redirect_to :action=>'index'}
      format.xml  { head :ok }
    end
  end

  #This function is used to provide the data for showing the invoices and also for generating PDF's and CSV's for the invoices
  def show
    authorize!(:show,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @data,@opts,conditions,@total_data = [],{},{},[]
    @invoice = Invoice.find(params[:id])
    @payments = Payment.find_all_by_invoice_id(params[:id]).paginate :page => params[:page], :per_page => 20
    @payment = Payment.new
    @emp_bill_records = InvoiceDetail.grouped_records(params[:id]).paginate :page => params[:page], :per_page => 20
    @invoice_status = @invoice.status
    @opts[:total_amount] = InvoiceDetail.sum(:total_amount, :conditions=>['invoice_id=?',params[:id]])
    @payment_modes = Lookup.payment_mode_type
    @amount = Invoice.sum(:invoice_amount,:conditions=>["id=#{params[:id]}"]) - Payment.sum(:amount, :conditions=>['invoice_id=?', params[:id]])
    @emp_bill_records.each do |record|
      @data << [Product.find(record.product_id).name, livia_date(record[:product_purchase_date]), record[:count], record[:cost], record[:total_amount]]
    end
    column_widths = { 0 => 120, 1 => 150,2 => 100, 3 => 80 , 4 => 140 }
    @opts[:company_name] = @invoice.company.name
    @opts[:invoice_date] = livia_date(@invoice.invoice_date)
    @opts[:start_date] = livia_date(@invoice.invoice_from_date)
    @opts[:end_date] = livia_date(@invoice.invoice_to_date)
    @table_headers = ["Product","Product Purchase Date","No. of Licences","Actual Price($)","Total Amount($)"]
    conditions[:table_width] = 750
    respond_to do|format|
      format.csv {}
      format.pdf {
        LiviaReport.generate_report_for_invoice(@data,@table_headers,@emp_bill_records.length,column_widths,@opts,conditions)
        send_file("livia_report.pdf", :type => 'application/pdf', :disposition => 'inline')
      }
      format.html
    end

  end

  #Function for creation of  New invoice record and also invoice_detail records for that invoice. The ralted tables here are Licences, product_livences, product_licence_details.
  def generate_user_invoice_reports
    generate_invoice = true
    if params[:date_end].blank? || params[:date_start].blank? or params[:company][:id].blank?
      flash[:error] = t(:flash_select_fields)
      generate_invoice = false
    else
      if  (params[:date_end].to_date - params[:date_start].to_date).to_i < 0
        flash[:error] = t(:flash_invoice_date)
        generate_invoice = false
      end
    end
    respond_to do |format|
      if generate_invoice == true
        Invoice.create_invoice(params)
        format.html {redirect_to :action => 'index'}
        format.xml  { head :ok }
      else
        @companies = Company.getcompanylist(current_user.company_id)
        format.html {render :action=>'new'}
        format.xml  { render :xml => @companies}
      end
    end
  end

end

