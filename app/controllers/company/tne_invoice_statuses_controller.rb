class Company::TneInvoiceStatusesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('tne_invoice_statuses')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @tne_invoice_status = @company.tne_invoice_statuses.new
    render :layout=>false
  end

  def create
    tne_invoice_statuses = @company.tne_invoice_statuses
    tne_invoice_statusescount = tne_invoice_statuses.count
    if tne_invoice_statusescount > 0
      params[:tne_invoice_status][:sequence] = tne_invoice_statusescount+1
    end
    @tne_invoice_status = TneInvoiceStatus.new(params[:tne_invoice_status])
    @tne_invoice_status.valid?
    if  @tne_invoice_status.errors.empty?
      tne_invoice_statuses << @tne_invoice_status
    end
    flash[:notice] = "Invoice Status was successfully created."  if @tne_invoice_status.errors.empty?
    render :update do |page|
      if @tne_invoice_status.errors.empty?
        page<< 'tb_remove();'
        page<<"window.location.href='#{manage_company_utilities_path('tne_invoice_statuses')}';"
      else
        page << "show_error_msg('nameerror','#{@tne_invoice_status.errors.on(:lvalue)}','errorCont');"
      end
    end
  end

  def edit
    @tne_invoice_status = TneInvoiceStatus.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @tne_invoice_status = TneInvoiceStatus.find(params[:id])
    @tne_invoice_status.attributes = params[:invoice_status]
    @tne_invoice_status.valid?
    if @tne_invoice_status.errors.empty?
      @tne_invoice_status.save
    end
    flash[:notice] = "Invoice Status was successfully updated."  if @tne_invoice_status.errors.empty?
    respond_to do |format|
      format.js {
        render :update do |page|
          if @tne_invoice_status.errors.empty?
            active_deactive = find_model_class_data('tne_invoice_statuses')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'tne_invoice_statuses', :header=>"Invoice Status", :modelclass=> 'tne_invoice_statuses'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('tne_invoice_statuses')}';"
          else
            page << "show_error_msg('nameerror','#{@tne_invoice_status.errors.on(:lvalue)}','errorCont');"
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  def show
    @tne_invoice_status = @company.tne_invoice_statuses.find_only_deleted(params[:id])
    unless @tne_invoice_status.blank?
      @tne_invoice_status.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.tne_invoice_statuses)
    end
    respond_to do |format|
      flash[:notice] = "Invoice Status '#{@tne_invoice_status.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('tne_invoice_statuses')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  def destroy
    tne_invoice_status = @company.tne_invoice_statuses.find(params[:id])
    invoiceslength = MatterBilling.find(:all, :conditions => ["company_id = #{@company.id} and matter_billing_status_id = #{params[:id]}"]).length
    if invoiceslength > 0
      message = false
    else
      message = true
      tne_invoice_status.destroy
      set_sequence_for_lookups(@company.tne_invoice_statuses)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Invoice Status '#{tne_invoice_status.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Invoice Status '#{tne_invoice_status.lvalue}' can not be deactivated, #{invoiceslength} Invoice linked."
      end
      format.html { redirect_to(manage_company_utilities_path('tne_invoice_statuses')) }
      format.xml  { head :ok }
    end
  end

end
