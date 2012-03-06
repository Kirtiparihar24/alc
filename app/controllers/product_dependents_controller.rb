class ProductDependentsController < ApplicationController

  # GET /product_dependents
  # GET /product_dependents.xml
  #This function is used to provide the list of all product dependents
  def index
    @product_dependents = ProductDependent.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @product_dependents }
    end
  end

  # GET /product_dependents/1
  # GET /product_dependents/1.xml
  #This function is used to show the details of a particular product dependent
  def show
    @product_dependent = ProductDependent.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product_dependent }
    end
  end

  # GET /product_dependents/new
  # GET /product_dependents/new.xml
  #This function is used to provide a new record for creation of a new product dependent
  def new
    @product_dependent = ProductDependent.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product_dependent }
    end
  end

  # GET /product_dependents/1/edit
  #This function is used to provide the details of a selected product dependent
  def edit
    @product_dependent = ProductDependent.find(params[:id])
  end

  # POST /product_dependents
  # POST /product_dependents.xml
  #This function is used to create a new product dependent
  def create
    params[:selectedproducts]=params[:selectedproducts].split(',').compact
    params[:selectedproducts].delete_at(0)
    params[:selectedproducts].each do |parent_id|
      ProductDependent.find_or_create_by_product_id_and_parent_id(params[:product_id], parent_id)
    end
    render :nothing=>true
  end

  # PUT /product_dependents/1
  # PUT /product_dependents/1.xml
  #This function is used to uddate the selected product dependent detials
  def update
    @product_dependent = ProductDependent.find(params[:id])
    respond_to do |format|
      if @product_dependent.update_attributes(params[:product_dependent])
        flash[:notice] = "#{t(:text_product_dependent)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(@product_dependent) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product_dependent.errors, :status => :unprocessable_entity }
      end
    end
  end

  #This function is used to delete the selected product dependent
  def destroy
    params[:selectedproducts]=params[:selectedproducts].split(',').compact
    params[:selectedproducts].delete_at(0)
    params[:selectedproducts].each do |parent_id|
      ProductDependent.delete_all("parent_id=#{parent_id} and product_id = #{params[:product_id]}")
    end
    render :nothing=>true
  end

end
