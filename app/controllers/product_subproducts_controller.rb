class ProductSubproductsController < ApplicationController
  #This function is used to create a list of product_subprouducts records for the selected product
  before_filter :authenticate_user!
 
  def create
    params[:selectedproducts]=params[:selectedproducts].split(',').compact
    params[:selectedproducts].delete_at(0)
    flash[:notice] =""
    params[:selectedproducts].each do |sub_id|
      ProductSubproduct.find_or_create_by_product_id_and_subproduct_id_and_created_by_user_id(params[:product_id], sub_id.to_i, current_user.id)
    end
    render :nothing=>true
  end

  #This function is used to delete the "product_subproducts" records based on product and subproducts selected
  def destroy    
    params[:selectedproducts]=params[:selectedproducts].split(',').compact
    params[:selectedproducts].delete_at(0)
    params[:selectedproducts].each do |sub_id|
      ProductSubproduct.delete_all("product_id=#{params[:product_id]} and subproduct_id=#{sub_id}")
    end    
    render :nothing=>true
  end

end
