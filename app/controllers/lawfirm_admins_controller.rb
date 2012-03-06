#This is Lawfirm Admin module
class LawfirmAdminsController < ApplicationController
  before_filter :authenticate_user!
  
  layout 'admin'
   
  #This is landing page when lawfirm admin logs in
  def index
    update_session
    @company_id = current_user.company_id    
    @company = Company.find(@company_id, :include => :product_licences)
    @users = User.find(:all,:include=>[:company,:employee,:role,{:product_licence_details=>{:product_licence=>:product}}],:conditions=>['company_id=?',@company.id]) if @company.users_not_client
    @employees = @company.employees.size
    @totalusers =  @users.size
    @activeusers = SubproductAssignment.all(:select => ["distinct user_id"], :conditions => ["company_id = ? AND employee_user_id IS NULL", @company_id]).size
    @activepermlicence = 0
    @activetemplicence = 0
    @remainpermlicence = 0
    @remaintemplicence = 0
    @duration_setting = @company.duration_setting
    @company.product_licences.each do |pl|
      @activepermlicence += 1 if (pl.licence_type == 0 and pl.status == 1)
      @activetemplicence += 1 if (pl.licence_type == 1 and pl.status == 1)
      @remainpermlicence += 1  if (pl.licence_type == 0 and pl.status == 0)
      @remaintemplicence += 1  if (pl.licence_type == 1 and pl.status == 0)
    end
    params[:company_id]=current_user.company_id
    if params[:company_id].present?
      @company ||= Company.find(params[:company_id])
      @tne_setting = @company.tne_invoice_setting.id if @company.tne_invoice_setting.present?
    end
    respond_to do |format|
      format.html #index.html.erb
      format.xml  { render :xml => @users }
      authorize!(:index,current_user) unless current_user.role?:lawfirm_admin
    end
  end

  # GET /lawfirm_admins/new
  # GET /lawfirm_admins/new.xml
  def new
    @employee = Employee.new
    @lawfirm_admin = User.new
    @roles = Role.scoped_by_company_id(current_user.company_id)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lawfirm_admin }
      authorize!(:new,current_user) unless current_user.role?:lawfirm_admin
    end
  end

  # GET /lawfirm_admins/1/edit
  def edit
    @company = Company.find(current_user.company_id)
    @lawfirm_admin = User.find(params[:id])
    @subproducts=ProductLicence.all
    @employees=Employee.scoped_by_user_id_and_company_id(@lawfirm_admin.id,current_user.company_id).first
    authorize!(:edit,current_user) unless current_user.role?:lawfirm_admin
  end
  
  #Creating a new user for lawfirm
  # POST /lawfirm_admins
  # POST /lawfirm_admins.xml
  def create
    @employee = Employee.new(params[:employee])
    @employee.company_id=current_user.company_id
    respond_to do |format|
      if @employee.save_with_user(params)  
        flash[:notice] = "#{t(:text_new_user)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to lawfirm_admins_url}
        format.xml  { render :xml => @lawfirm_admin, :status => :created, :location => @lawfirm_admin }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lawfirm_admin.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lawfirm_admins/1
  # PUT /lawfirm_admins/1.xml
  #This function is used to update the lawfirm admin details
  def update
    @lawfirm_admin = User.find(params[:id])
    respond_to do |format|
      if @lawfirm_admin.update_attributes(params[:lawfirm_admin])
        flash[:notice] = "#{t(:text_lawfirmadmin)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(@lawfirm_admin) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lawfirm_admin.errors, :status => :unprocessable_entity }
        authorize!(:update,current_user) unless current_user.role?:lawfirm_admin
      end
    end
  end

  # DELETE /lawfirm_admins/1
  # DELETE /lawfirm_admins/1.xml
  #This function is used to delete the lawfirm admin having provided id
  def destroy
    @lawfirm_admin = User.find(params[:id])
    @lawfirm_employee=Employee.find(:first,:conditions=>["user_id=?",@lawfirm_admin.id])
    @product_licence_detail=ProductLicenceDetail.find(:all,:conditions=>["user_id=?",params[:id]])
    @subproduct=SubproductAssignment.find(:all,:conditions=>["user_id=? OR employee_user_id=?",params[:id],params[:id]])
    respond_to do |format|
      if @lawfirm_employee.destroy
        for  product_licence_detail in  @product_licence_detail
          product_licence_detail.product_licence.update_attributes(:status=>0)
          product_licence_detail.destroy
        end
        @subproduct.each do |subproduct|
          subproduct.destroy
        end         
        @lawfirm_admin.destroy
        flash[:notice] = "#{t(:text_new_user)} " "#{t(:flash_was_successful)} " "#{t(:text_deactivated)}"
        format.html { redirect_to(:controller=>"lawfirm_admins",:action=>"index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        authorize!(:destroy,current_user) unless current_user.role?:lawfirm_admin
      end
    end
  end

  #This function is used to update the selected employee details
  def update_employee 
    @user = User.find(params[:id])
    @user.update_attributes(:first_name=>params[:lawfirm_admin][:first_name],:last_name=>params[:lawfirm_admin][:last_name])
    @employees=Employee.scoped_by_user_id_and_company_id(@user.id,current_user.company_id).first
    respond_to do |format|
      if  @employees.update_attributes(:birthdate => params[:lawfirm_admin][:employee][:birthdate],
          :security_question => params[:lawfirm_admin][:employee][:security_question],
          :security_answer => params[:lawfirm_admin][:employee][:security_answer],
          :billing_rate => params[:lawfirm_admin][:employee][:billing_rate]
        )
        flash[:notice] = "#{t(:text_user)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html {  redirect_to:controller=>"lawfirm_admins",:action=>"index" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  #This function is used to provide the list of deactivated users of the selected company
  def deactivated_users
    @users=User.find_with_deleted(:all,:conditions=>['company_id=? AND deleted_at IS NOT NULL',current_user.company_id])
  end

  #This function is used to reactivate the selected deactivated user
  def activate
    @users=User.find_with_deleted(params[:id])
    @lawfirm_employee=Employee.find_with_deleted(:first,:conditions => {:user_id => @users.id})
    respond_to do |format|
      if @users.update_attribute('deleted_at','')
        @lawfirm_employee.update_attribute('deleted_at','')
        flash[:notice] = "#{t(:text_user)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
        format.html {redirect_to :controller=>"lawfirm_admins",:action=>"index"}
        format.xml  { head :ok }
      else
        format.html { render :action => "deactivated_users" }
      end
    end
  end
  
end
