class SubproductsController < ApplicationController
  before_filter :authenticate_user!    
  load_and_authorize_resource
  
  layout "admin"
  #This function is to provide the list of modules and their detials in the index view of Module
  def index
    @subproducts = Subproduct.all(:include => [:product_subproducts => :product]).paginate :page => params[:page], :per_page => 20
  end

  #This function is used to provide a new product record for creating a new product
  def new
    @subproduct = Subproduct.new
  end

  #This function is to create a new module
  def create
    begin
      params[:subproduct][:created_by_user_id] = current_user.id
      @subproduct = Subproduct.new(params[:subproduct])
      if @subproduct.save
        flash[:notice] = "#{t(:text_module)} " "#{t(:flash_was_successful)} "" #{t(:text_created)}"
        redirect_to :action => 'index'
      else
        render :action=> 'new'
      end
    rescue => ex
    end
  end

  #This function is to provide the selected module details for edit operation
  def edit
    @subproduct = Subproduct.find(params[:id])
  end

  #This function is to update the selected module details
  def update
    @subproduct = Subproduct.find(params[:id])
    params[:subproduct][:updated_by_user_id] = current_user.id
    if @subproduct.update_attributes(params[:subproduct])
      flash[:notice] = "#{t(:text_module)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      redirect_to :action => 'index', :id => @subproduct
    else
      render :action => 'edit'
    end
  end

  #This function is to provide the selected module details for showing its complete details
  def show
    @subproduct = Subproduct.find(params[:id])
  end

  #This function is to delete the selected module. If a module gets deleted then the related records in product_subproducts table are also gets deleted
  def delete
    ProductSubproduct.delete_all("subproduct_id=#{params[:id]}")
    Subproduct.find(params[:id]).delete
    redirect_to :action => 'index'
    flash[:notice] = "#{t(:text_subproducts)} #{t(:flash_was_successful)} #{t(:text_deleted)}"
  end

end
