class TneInvoiceDetailsController < ApplicationController
  layout "full_screen"

  def index
    @tne_invoice_details = TneInvoiceDetail.all

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @tne_invoice_details }
    end
  end

  def show
    @tne_invoice_detail = TneInvoiceDetail.find(params[:id])

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @tne_invoice_detail }
    end
  end

  def new
    @tne_invoice_detail = TneInvoiceDetail.new

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @tne_invoice_detail }
    end
  end

  def edit
    @tne_invoice_detail = TneInvoiceDetail.find(params[:id])
  end

  def create
    @tne_invoice_detail = TneInvoiceDetail.new(params[:tne_invoice_detail])

    respond_to do |format|
      if @tne_invoice_detail.save
        flash[:notice] = 'Invoice Detail was successfully created.'
        format.html { redirect_to(@tne_invoice_detail) }
        format.xml  { render :xml => @tne_invoice_detail, :status => :created, :location => @tne_invoice_detail }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tne_invoice_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @tne_invoice_detail = TneInvoiceDetail.find(params[:id])

    respond_to do |format|
      if @tne_invoice_detail.update_attributes(params[:tne_invoice_detail])
        flash[:notice] = 'Invoice Detail was successfully updated.'
        format.html { redirect_to(@tne_invoice_detail) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tne_invoice_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @tne_invoice_detail = TneInvoiceDetail.find(params[:id])
    @tne_invoice_detail.destroy

    respond_to do |format|
      format.html { redirect_to(tne_invoice_details_url) }
      format.xml  { head :ok }
    end
  end
end
