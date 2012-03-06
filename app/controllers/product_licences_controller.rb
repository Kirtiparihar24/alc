class ProductLicencesController < ApplicationController
  include ProductLicencesHelper
  include ApplicationHelper
  before_filter :authenticate_user!  
  before_filter :authorization_checking, :only => [:new,:create,:delete,:data_after_licence_unassignment_deactivation,:get_company_licence,:product_pricing]

  layout "admin"
  
  #This is for checking the authorization
  def authorization_checking
    authorize!(:authorization_checking,current_user) unless current_user.role?(:livia_admin) || current_user.role?(:lawfirm_admin)
  end
  # GET /product_licences/new
  # GET /product_licences/new.xml
  #This function is used to provide the data required to create a new "product licence" record
  def new
    session[:company_id] = session_status
    @product_licence = ProductLicence.new
    @products = Product.all(:order =>"name").map{|prd| [prd.name, prd.id]}
    @companies = Company.getcompanylist(current_user.company_id)
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @product_licence }
    end
  end

  # POST /product_licences
  # POST /product_licences.xml
  #This function is used to create a new "Product licence" record
  def create
    respond_to do |format|
      @ret_val = ProductLicence.product_licence_save(params, url_link)
      @product_licence = @ret_val.empty? ? true : false
      if @product_licence
        flash[:notice] = "#{t(:text_product_licence)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        flash[:msg] = nil
        format.html { redirect_to(new_product_licence_url) }
        format.xml  { render :xml => @product_licence, :status => :created, :location => @product_licence }
      else
        flash[:msg] = @ret_val
        format.html { redirect_to(new_product_licence_url) }
      end
    end
  end

  # DELETE /product_licences/1
  # DELETE /product_licences/1.xml
  #This fucntion is used to delete the selected "product licence"  record.
  #While deleting a product_licence record all the related records in subproduct_assignments table are also to be deleted
  def delete
    has_dependent = false
    @product_licence = ProductLicence.find(params[:id])
    @user = User.find(ProductLicenceDetail.find_by_product_licence_id(@product_licence.id).user_id)
    ProductLicenceDetail.find_all_by_user_id(@user.id).each do |pld|
      has_dependent = true if ProductDependent.find_by_product_id_and_parent_id(ProductLicence.find(pld.product_licence_id).product_id,@product_licence.product_id ).present?
    end
    if has_dependent
      @msg = "#{Product.find(@product_licence.product_id).name} cannot be deactivated/un-assigned due to dependency"
      return false
    else
      ProductLicence.product_licence_delete(@product_licence,params)
      Physical::Liviaservices::ServiceProviderEmployeeMappings.destroy_all(:employee_user_id=>@user.id)
      ClusterUser.destroy_all(:user_id=>@user.id)
      licence_assign_unassign_deactivate_mail(params[:type])
      data_after_licence_unassignment_deactivation
      @licences = Product.with_licences(@company_id)
      expire_fragment('active_licences')
    end
  end

  #It is a support function for delete operation. It provides the data related to no. of licences after deletion operation.
  def data_after_licence_unassignment_deactivation
    @company_id = @product_licence.company_id
    @totalusers = User.find_user_not_admin_not_client(@company_id)
    @activeusers = SubproductAssignment.scoped_by_company_id_and_employee_user_id(@company_id,nil).all(:select => 'user_id').collect{|sa| sa.user_id}.uniq.compact
    @employees = User.find_user_not_admin_not_client(@company_id)
    @productlicence = ProductLicence.scoped_by_company_id(@company_id)
    @activepermlicence = @productlicence.select {|o| o.licence_type == 0}.size
    @activetemplicence = @productlicence.select {|o| o.licence_type == 1}.size
    @usedpermlicence = @productlicence.select {|o| o.status == 1 && o.licence_type == 0}.size
    @usedtemplicence = @productlicence.select {|o| o.status == 1 && o.licence_type == 1}.size
    @remainlicence = @productlicence.select {|o| o.status == 0 && o.licence_type == 0}.size
    @remaintemplicence = @productlicence.select {|o| o.status == 0 && o.licence_type == 1}.size
  end

  #This function is used to send a mail when a licence has been assigned or unassigned to a user
  def licence_assign_unassign_deactivate_mail(type)
    url=url_link
    user = User.find(ProductLicenceDetail.find_with_deleted(:first, :conditions => ["product_licence_id = ?", "#{@product_licence.id}"]).user_id)
    recipient = []
    recipient << user.email
    recipient << get_lawfirm_admin_email(user.id)
    cc = current_user.email
    subject = (type == "u"? "Licence unassignment details" : "Licence de-activation details")
    email = {}
    (type == "u") ? (email[:message] = "#{Product.find(@product_licence.product_id).name} licence has been unassigned to #{user.full_name}") : (email[:message] = "#{Product.find(@product_licence.product_id).name} licence has been deactivated and it is currently been assigned to #{user.full_name}")
    liviaMailer = LiviaMailer
  end

  #This function is used to provide the information related to all licences of the selected company
  def get_company_licence
    session[:company_id] = params[:company_id]
    @company = Company.find(params[:company_id])
    @product_licences = ProductLicence.find_all_by_company_id(params[:company_id], :order => 'product_id')
    temp_licence_limits = CompanyTempLicence.find_all_by_company_id(params[:company_id])
    @tmpl = 0
    temp_licence_limits.each do |t|
      @tmpl += t.licence_limit.to_i
    end
  end

  #This function is used to show the pricing list of the selected product along with the dependent products pricings
  def product_pricing
    @product = Product.find(params[:id])
    @dependent_product = @product.product_dependents.find_all.map {|prd| [Product.find(prd.parent_id), 'Dependent Product'] }
    @product_dependency = @dependent_product.empty? ? [[@product, nil]] : @dependent_product + [[@product, nil]]
    render :partial => 'product_pricing', :locals => {:product_dependent => @product_dependency}
  end

end
