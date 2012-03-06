class ProductsController < ApplicationController
  before_filter :authenticate_user!  

  layout "admin"

  #This function is to provide the list of products and their detials in the index view of products module
  def index
    authorize!(:index,current_user) unless current_user.role?:livia_admin
    @products = Product.all(:include => [:subproducts, :product_dependents]).paginate :page => params[:page], :per_page => 20
    @subproducts = Subproduct.all.paginate :page => params[:page], :per_page => 20
    @product_licences = ProductLicence.count(:select => 'product_id', :group => 'product_id')
  end

  #This function is to provide the new product record for "New" product creation
  def new
    authorize!(:new,current_user) unless current_user.role?:livia_admin
    @product = Product.new
  end

  #This function is to create a new product
  def create
    authorize!(:create,current_user) unless current_user.role?:livia_admin
    begin
      params[:product][:created_by_user_id] = current_user.id
      @product = Product.new(params[:product])
      if @product.save
        flash[:notice] ="#{t(:text_product)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        redirect_to :action => 'index'
      else
        render :action => 'new'
      end
    end
  end

  #This function is to provide the selected product details for edit operation
  def edit
    authorize!(:edit,current_user) unless current_user.role?:livia_admin
    @product = Product.find(params[:id])
  end

  #This function is to provide the selected product details for configuring its related modules and Dependencies
  def edit_product_config
    authorize!(:edit_product_config,current_user) unless current_user.role?:livia_admin
    @product = Product.find(params[:id])
    subids = []
    @currentSubProds = @product.subproducts
    pspSub = []
    spSub = []
    subids = @currentSubProds.collect(&:id)
    pspSub = ProductSubproduct.all(:select => 'DISTINCT subproduct_id').collect(&:subproduct_id)
    spSub = Subproduct.all(:select => 'id').collect(&:id)
    diff = spSub - subids
    @availableSubProds = Subproduct.all(:conditions => ["id IN (?)", diff])
    ids = []
    @prodDeps = @product.product_dependents.find_all
    ids = @prodDeps.collect(&:parent_id)
    if ids.length > 0
      @products = Product.all(:conditions => ["id != ? AND deleted_at IS NULL AND id NOT IN (?)", params[:id], ids])
    else
      @products = Product.all(:conditions => ["id != ?", params[:id]])
    end
  end

  #This function is to update the selected product details
  def update
    authorize!(:update,current_user) unless current_user.role?:livia_admin
    begin
      @product = Product.find(params[:id])
      params[:product][:updated_by_user_id] = current_user.id
      if @product.update_attributes(params[:product])
        flash[:notice] = "#{t(:text_product)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        redirect_to :action => 'index'
      else
        render :action=>'edit'
      end
    rescue => ex
      render :action => 'edit'
    end
  end

  #This function is to provide the selected product details for showing its complete details
  def show
    authorize!(:show,current_user) unless current_user.role?:livia_admin
    if params[:id].to_s == "product_dropdown_list"
      redirect_to :action=>'product_dropdown_list'
    end
    @product = Product.find(params[:id])
  end

  #This function is to delete the selected product. If a product gets deleted then the related records in product_subproducts table and product_dependents table are also gets deleted
  def delete
    authorize!(:delete,current_user) unless current_user.role?:livia_admin
    begin
      ProductSubproduct.delete_all("product_id=#{params[:id]}")
      ProductDependent.delete_all("product_id=#{params[:id]}")
      ProductDependent.delete_all("parent_id=#{params[:id]}")
      Product.find(params[:id]).delete
      flash[:notice] = "#{t(:text_product)} " "#{t(:flash_was_successful)} " "#{t(:text_deleted)}"
      redirect_to :action=> 'index'
    rescue => ex
      redirect_to :action=> 'index'
    end
  end
  
  def product_dropdown_list
    authorize!(:product_dropdown_list,current_user) unless current_user.role?:livia_admin
  end

end
