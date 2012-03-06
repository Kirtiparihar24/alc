class ProductLicenceDetailsController < ApplicationController
  load_and_authorize_resource

  # GET /product_licence_details
  # GET /product_licence_details.xml
  #This function is used to provide the list of all product licences details records
  def index
    @product_licence_details = ProductLicenceDetail.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @product_licence_details }
    end
  end

  # GET /product_licence_details/1
  # GET /product_licence_details/1.xml
  #This function is used to show the details of a particular selected product licences records
  def show
    @product_licence_detail = ProductLicenceDetail.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product_licence_detail }
    end
  end

  # GET /product_licence_details/new
  # GET /product_licence_details/new.xml
  #This function is used to provide the information required to create a new product licence detail record
  def new
    @product_licence_detail = ProductLicenceDetail.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product_licence_detail }
    end
  end

  # GET /product_licence_details/1/edit
  #This function is used to provide the information required to edit a selected product licence detail record
  def edit
    @product_licence_detail = ProductLicenceDetail.find(params[:id])
  end

  # POST /product_licence_details
  # POST /product_licence_details.xml
  #This function is used to create a new "product licence detail" record
  def create
    @product_licence_detail = ProductLicenceDetail.new(params[:product_licence_detail])
    respond_to do |format|
      if @product_licence_detail.save
        flash[:notice] = "#{t(:text_product_licence)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(@product_licence_detail) }
        format.xml  { render :xml => @product_licence_detail, :status => :created, :location => @product_licence_detail }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product_licence_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /product_licence_details/1
  # PUT /product_licence_details/1.xml
  #This function is used to update the selected "Product Licence Detail" record
  def update
    @product_licence_detail = ProductLicenceDetail.find(params[:id])
    respond_to do |format|
      if @product_licence_detail.update_attributes(params[:product_licence_detail])
        flash[:notice] = "#{t(:text_product_licence)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(@product_licence_detail) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product_licence_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /product_licence_details/1
  # DELETE /product_licence_details/1.xml
  #This function is used to delete the selected "Product licence details" record
  def delete    
    @product_licence_detail = ProductLicenceDetail.find_by_product_licence_id(params[:id], :conditions => {:status => 1})
    @product_licence = ProductLicence.find(params[:id])
    @product_licence.update_attributes(:disabled_at => Time.zone.now, :status => 0) unless @product_licence.nil?
    @product_licence_detail.update_attributes(:disabled_at => Time.zone.now, :status => 0) unless @product_licence_detail.nil?
    @subproduct_licence = SubproductAssignment.find_all_by_product_licence_id(params[:id])
    @subproduct_licence.each do |sub|
      sub.update_attributes(:status => 0)
    end
    respond_to do |format|
      format.html { redirect_to(new_product_licence_path) }
      format.xml  { head :ok }
    end
  end
  
end
