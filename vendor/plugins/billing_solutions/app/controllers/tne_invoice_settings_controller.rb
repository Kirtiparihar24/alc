class TneInvoiceSettingsController < ApplicationController
  layout "admin"
 
  def new
    @tne_invoice_setting = TneInvoiceSetting.new
    respond_to do |format|
      format.html 
      format.xml { render :xml => @tne_invoice_setting }
    end
  end

  def edit
    add_breadcrumb "Invoice Settings", edit_tne_invoice_setting_path
    @tne_invoice_setting = TneInvoiceSetting.find_or_create_by_id(params[:id])
    @pagenumber = 161
  end

  def create
    params[:tne_invoice_setting][:company_id] =  current_company.id unless is_liviaadmin
    @tne_invoice_setting = TneInvoiceSetting.new(params[:tne_invoice_setting])
    if @tne_invoice_setting.save
      flash[:notice] = 'Invoice Setting was successfully created.'
      if is_lawfirmadmin || is_liviaadmin
        redirect_to(company_settings_path(:company_id => params[:company_id]))
      else
        redirect_to utilities_path
      end
    else
      flash[:error] = @tne_invoice_setting.errors.full_messages
      redirect_to :back
    end
  end

  def update
    tne_invoice_setting_id = params[:tne_invoice_setting].has_key?(:id) ? params[:tne_invoice_setting][:id] : params[:id ]
    @tne_invoice_setting = TneInvoiceSetting.find(tne_invoice_setting_id)
    if @tne_invoice_setting.update_attributes(params[:tne_invoice_setting])
      flash[:notice] = 'Invoice Setting was successfully updated.'
      if is_lawfirmadmin || is_liviaadmin
        redirect_to(company_settings_path(:company_id => params[:company_id]))
      else
        redirect_to utilities_path
      end
    else
      flash[:error] = @tne_invoice_setting.errors.full_messages
      redirect_to :back
    end
  end

end