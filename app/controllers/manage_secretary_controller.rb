# This controller provides interface to manage serviceproviders for the livia_admin.
# with the help of this controller admin can do following things
# * Assign serviceprovider to the lawyer
# * Unassign serviceprovider from the lawyer
# * Assign/unassign subproduct(module) wise access to the serviceprovider from the lawyer.
class ManageSecretaryController < ApplicationController
  include ApplicationHelper
  before_filter :authenticate_user!  
  before_filter :find_manager , :only => [:edit, :update_manager, :destroy]

  layout "admin"
  
  #This function is used to provide the list of all service providers
  def index
    authorize!(:index,current_user) unless current_user.role?:livia_admin
    if is_liviaadmin
      @secretaries = ServiceProvider.all(:include => [:user,{:service_provider_employee_mappings=>[:user=>:company]}], :order => "users.first_name ASC, users.last_name ASC").paginate :page => params[:page], :per_page => 20
      @companies = Company.all
    else
      @secretaries = current_user.service_provider_employee_mappings.collect{|sa| sa.service_provider}
      params[:company_id] = current_user.company_id
      populateemployees
    end
  end
  
  # Return the list of users(lawyers) who belongs to specific company.
  def populateemployees
    company = Company.find(params[:company_id])
    @employees = company.employees.all(:conditions => ['user_id IS NOT NULL'])
  end
  
  # Returns the licenced subproducts(modules) list of the lawyer.
  def getsubproductlists
    @unassigned_subp = []    
    @assigned_subp = []
    @subproductassignments = SubproductAssignment.find_all_by_user_id_and_company_id(params[:user_id], params[:company_id], :include => [:user, :company, :subproduct])
    @lawyersubproducts = @subproductassignments.collect{|sub| sub.subproduct}
    @secretarysubproductassignment = SubproductAssignment.find_all_by_employee_user_id_and_company_id(params[:user_id], params[:company_id], :include => [:user, :company, :subproduct])
    @assigned_subp = @secretarysubproductassignment.collect{|sub| sub.subproduct}.uniq
    @unassigned_subp = @lawyersubproducts.find_all{|s| !@assigned_subp.include?(s)}    
  end
  
  # This method is use to assigne subproduct(module) access to the serviceprovider for the lawyer, from lawyer side.
  def assignSubproducts_to_secretary
    sp_list, module_list = [], []
    serviceproviders = []
    subproducts = params[:subproducts].split(",")    
    @serviceassignments = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_employee_user_id(params[:user_id])
    @serviceassignments.each do |sa|
      sp_list << User.find(sa.service_provider.user_id).full_name
      serviceproviders << sa.service_provider.user_id
    end    
    subproducts.each do |sub|
      resp = SubproductAssignment.update_all("deleted_at = NULL",["employee_user_id = ? and subproduct_id = ? and deleted_at IS NOT NULL",params[:user_id],sub])    
      tempobj = SubproductAssignment.find_by_user_id_and_subproduct_id(params[:user_id], sub)        
      serviceproviders.each do |sps|
        issubproductassign =  SubproductAssignment.find_by_user_id_and_subproduct_id_and_employee_user_id(sps, sub, params[:user_id])
        if issubproductassign.blank?
          SubproductAssignment.create(:user_id => sps, :subproduct_id => sub, :product_licence_id => tempobj.product_licence_id, :company_id => params[:company_id], :employee_user_id => params[:user_id])
        end
      end    
      module_list << Subproduct.find(sub).name
    end
    lawyer_name = User.find(params[:user_id]).full_name
    modules_assignment_unassignment_mail(params[:user_id],"assignment",sp_list, module_list, lawyer_name)
    usersecretary
  end

  # This method is use to unassigne subproduct(module) access to the serviceprovider for the lawyer, from lawyer side.
  def unassignSubproducts_from_secretary
    sp_list, module_list = [], []
    subproducts = params[:subproducts].split(",")
    subproducts.each do |sub|
      SubproductAssignment.delete_all(["employee_user_id = ? and subproduct_id = ?",params[:user_id],sub])
      module_list << Subproduct.find(sub).name
    end
    SubproductAssignment.find_with_deleted(:all, :select=>["distinct user_id"],:conditions=>["employee_user_id = ?", params[:user_id]]).each do |sp|
      user = User.find_by_id(sp.user_id)
      sp_list << user.full_name if user
    end
    lawyer_name = User.find(params[:user_id]).full_name
    modules_assignment_unassignment_mail(params[:user_id],"unassignment",sp_list, module_list, lawyer_name)
    usersecretary
  end


  #This function is to send mail when a lawyer unassing the modules from the service providers
  def modules_assignment_unassignment_mail(lawyer_user_id,action, sp_list, module_list, lawyer_name)
    recipient = []
    recipient << get_lawfirm_admin_email(lawyer_user_id)
    recipient << User.find(lawyer_user_id).email
    cc = []
    cc << get_liviaadmin_email
    sp_list.each do |sp|
      recipient << sp
    end
    subject = "Modules #{action} to the service providers"
    email = {}
    email[:module_list] = module_list
    email[:action] = action
    @liviaMailer = LiviaMailer    
  end

  #This function is used to provide the list of all users of the selected company
  def manageprivilege
    authorize!(:manageprivilege,current_user) unless (current_user.role?:livia_admin or current_user.role?:lawfirm_admin)
    @companies  = Company.getcompanylist(current_user.company_id)
    session[:company_id] = session_status
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    if current_user.role?:livia_admin
      @users = User.find_user_not_admin_not_client(params[:company_id])
    elsif current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
      @users = User.find_user_not_admin_not_client(params[:company_id])
    else  
      params[:company_id] = current_user.company_id
      params[:user_id] = current_user.id
      usersecretary
    end
  end

  #This function is used to return the list of all modules for which the selected lawyer has given the access privileges to the service providers
  def usersecretary
    service_assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_employee_user_id(params[:user_id], :include => :user)
    @secretary = service_assignment.collect{|s| s.service_provider.user}
    getsubproductlists
  end

  #This function is to provide the list of companies for the Company dropdown in the Service providers assignment module.
  def show_company_list
    @secretary = ServiceProvider.find_by_id(params[:secretary_id], :include=>{:service_provider_employee_mappings => [:user=>:company]})
    #@company = Company.getcompanylist(current_user.company_id)
    @cluster = Cluster.find(@secretary.user.cluster_id) unless @secretary.user.cluster_id.nil?
    cluster_emps,assigned_emps = [],[]
    cluster_emps = Employee.get_cluster_employees(@cluster.id) unless @cluster.nil?
    Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_service_provider_id(@secretary.id).each do |sa|
      assigned_emps << Employee.find_by_user_id(sa.employee_user_id)
    end
    @employees =  cluster_emps - assigned_emps
    @priority_types = PriorityType.all
  end 

  def show_employee_list_of_cluster
    @secretary = ServiceProvider.find(params[:sec_id], :include => [:service_provider_employee_mappings => [:user]]) if params[:sec_id].present?
    @users = []
    users =  User.users_of_cluster(params[:cluster_id])
    @priority_types = PriorityType.all
    for user in users
      @users << user unless user.employee.nil?
    end
  end

  #This function is to provide the list of lawyers for the lawyers dropdown in the Service providers assignment module.
  def show_employee_list
    @secretary_id = params[:secretary_id]
    @show = true
    @product_licence=ProductLicence.find_by_company_id(params[:company_id], :include => :company)
    unless @product_licence
      @company = Company.find(params[:company_id]).name
      flash[:error] = "#{@company} has no licences."
      @show = false
    end
    # slList contains the list of Lawyers to whom this service provider is serving. These records are not to be shown in the lawyers dropdown.
    slList =[]
    Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_service_provider_id(@secretary_id).each do |sa|
      slList << Employee.find_by_user_id(sa.employee_user_id).id
    end    
    if slList.blank?
      @employees = Employee.getcompanyemployeelist(params[:company_id])
    else
      @employees = Employee.getcompanyemployeelist_not_sp(params[:company_id],slList)
    end
    @clusters=Cluster.all
  end


  #This function is to unassign the selected service to the selected lawyer. Tables having effect are service_provider, subproduct_assignments and service_provider_employee_mappings
  def unassign_sec_to_emp
    @secretary = ServiceProvider.find_by_id(params[:secretary_id], :include => [:user])    
    SubproductAssignment.delete_all(:user_id => @secretary.user_id, :employee_user_id => params[:lawyer_id])
    Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_service_provider_id_and_employee_user_id(params[:secretary_id], params[:lawyer_id]).destroy
    service_provider_assignment_unassignment_mail(params[:lawyer_id],"unassigned")
    @employees,assigned_emps = [],[]
    unless @secretary.user.cluster_id.nil?
      @cluster = Cluster.find(@secretary.user.cluster_id)
      cluster_emps,assigned_emps = [],[]
      cluster_emps = Employee.get_cluster_employees(@cluster.id)
      Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_service_provider_id(@secretary.id).each do |sa|
        assigned_emps << Employee.find_by_user_id(sa.employee_user_id)
      end
      @employees =  cluster_emps - assigned_emps
    end
    @priority_types = PriorityType.all
    flash[:notice] = "#{t(:text_livian)} #{t(:flash_was_successful)} #{t(:text_unassigned)}"
  end

  
  def update_priority
    @secretary = ServiceProvider.find_by_id(params[:secretary_id], :include => [:user])
    @company = Company.getcompanylist(current_user.company_id)
    @sa=Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_service_provider_id_and_id(params[:secretary_id], params[:mapping_id])
    @sa.priority=params[:priority]
    @sa.save
    @employees,assigned_emps = [],[]
    unless @secretary.user.cluster_id.nil?
      @cluster = Cluster.find(@secretary.user.cluster_id)
      cluster_emps = Employee.get_cluster_employees(@cluster.id)
      Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_service_provider_id(@secretary.id).each do |sa|
        assigned_emps << Employee.find_by_user_id(sa.employee_user_id)
      end
      @employees =  cluster_emps - assigned_emps
    end
    @priority_types = PriorityType.all    
  end
  
  # This function is used to assign the selected service provider to the selected lawyer.
  # Modified By - Hitesh
  def assign_sec_to_emp
    emp = Employee.find_by_id(params[:lawyer_id])
    @secretary = ServiceProvider.find_by_id(params[:secretary_id], :include=>[:user])
    mailmodule = Subproduct.find_by_name('Mail')
    empSubAssignment = SubproductAssignment.find_all_by_user_id(emp.user_id, :include => :user)
    user = User.find(emp.user_id)
    #Added exeptional hadling, transaction block and also checking with Livian is already assigned or not-----santosh challa
    service_assignment_validation=Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id_and_service_provider_id(emp.user_id,params[:secretary_id])
    begin
      unless empSubAssignment.blank?
        if !service_assignment_validation
          Physical::Liviaservices::ServiceProviderEmployeeMappings.transaction do
            @service_assignment=Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:employee_user_id=>emp.user_id, :service_provider_id=>params[:secretary_id], :status=>1, :created_by_user_id => current_user.id,:priority=>nil)
            spl = SubproductAssignment.getsubproductlist(emp.user_id)
            if spl.blank?
              empSubAssignment.each do |spa|
                if mailmodule.id != spa.subproduct_id
                  @subproduct_assignment=SubproductAssignment.create(:user_id=>@secretary.user_id,:subproduct_id =>spa.subproduct_id,:product_licence_id =>empSubAssignment.first.product_licence_id,:company_id => emp.company.id,:employee_user_id => emp.user_id)                  
                end
              end
            else
              spl.each do |spa|
                if mailmodule.id != spa.subproduct_id
                  @subproduct_assignment=SubproductAssignment.create(:user_id=>@secretary.user_id,:subproduct_id =>spa.subproduct_id,:product_licence_id =>empSubAssignment.first.product_licence_id,:company_id => emp.company.id,:employee_user_id => emp.user_id)                  
                end
              end
            end
            @employee = Employee.find(params[:lawyer_id]).user_id
            service_provider_assignment_unassignment_mail(@employee,"assigned")           
          end
          flash[:notice] = "#{t(:text_livian)} #{t(:flash_was_successful)} #{t(:text_assigned)}"
        end
      else
        flash[:error] = "#{emp.full_employee_name} has no licence and hence service provider cannot be assigned."
      end
      @cluster = Cluster.find(@secretary.user.cluster_id)
      cluster_emps,assigned_emps = [],[]
      cluster_emps = Employee.get_cluster_employees(@cluster.id)
      Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_service_provider_id(@secretary.id).each do |sa|
        assigned_emps << Employee.find_by_user_id(sa.employee_user_id)
      end
      @employees =  cluster_emps - assigned_emps
      @priority_types = PriorityType.all
    rescue Exception => exc
      logger.info("Assign Secretary Error : #{exc.message}")
      flash[:error] = "DB Store Error: #{exc.type}"
    end
    
  end

  #This function is used to send the mail related to service provider assignment and unassignment to the lawyer.
  def service_provider_assignment_unassignment_mail(lawyer_user_id,action)
    url = url_link
    sp = User.find(ServiceProvider.find(params[:secretary_id]).user_id)
    user = User.find(lawyer_user_id)
    recipient = []
    recipient << user.email
    recipient << sp.email
    recipient << get_lawfirm_admin_email(user.id)
    cc = current_user.email    
    subject = (action.to_s == "unassigned") ? "Service Provider unassignment to #{user.full_name}" : "Service Provider assignment to #{user.full_name}"
    email = {}
    (action.to_s == "unassigned") ? (email[:message] = "Service Provider named #{sp.full_name} has been unassigned to #{user.full_name}") : (email[:message] = "Service Provider named " + sp.full_name + " has been assigned to " + user.full_name)
    @liviaMailer = LiviaMailer    
  end
  
  # This method is used by lawyer to controll his module access from livians
  def livian_access    
    subproductassignments = SubproductAssignment.find_all_by_user_id_and_company_id(current_user.id,current_user.company_id)
    lawyer_subproducts = subproductassignments.collect{|sub| sub.subproduct}
    # following code written for separating parent sub_products from Child sub_products for UX perspective.
    lawyersubproducts = []
    parent_child_hash = {}
    lawyer_subproducts.each do |sub|
      if sub.parent_id.blank?
        lawyersubproducts << sub
      else
        if parent_child_hash.has_key?(sub.parent_id)
          parent_child_hash[sub.parent_id] << sub
        else
          parent_child_hash[sub.parent_id] = [sub]
        end
      end
    end
    @lawyersubproducts = lawyersubproducts
    @lawyer_child_sub_products = parent_child_hash
    secretarysubproductassignment = SubproductAssignment.find_all_by_employee_user_id_and_company_id(current_user.id,current_user.company_id)
    @assigned_subp = secretarysubproductassignment.collect{|sub| sub.subproduct}.uniq    
    render :layout => false
  end
  
  # This method is used by lawyer to unassign module access right to secretary
  def releasemoduleaccess_from_secretary
    subproduct_id = params[:subproduct_id]
    SubproductAssignment.delete_all(["employee_user_id = ? and subproduct_id = ?",current_user.id,subproduct_id])
    livian_access
  end
  
  # This method is used by lawyer to assign module access right to secretary
  def assignmoduleaccess_to_secretary
    subproduct_id = params[:subproduct_id]
    service_assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_all_by_employee_user_id(current_user.id)
    secretary = service_assignment.collect{|s| s.service_provider.user}
    resp = SubproductAssignment.update_all("deleted_at = NULL",["employee_user_id = ? and subproduct_id = ? and deleted_at is NOT NULL",current_user.id,subproduct_id])
    tempobj = SubproductAssignment.find_by_user_id_and_subproduct_id(current_user.id,subproduct_id)
    secretary.each do |sps|
      issubproductassign =  SubproductAssignment.find_by_user_id_and_subproduct_id_and_employee_user_id(sps.id,subproduct_id,current_user.id)
      if issubproductassign.blank?
        SubproductAssignment.create(:user_id=>sps.id,:subproduct_id =>subproduct_id,:product_licence_id =>tempobj.product_licence_id,:company_id => tempobj.company_id,:employee_user_id => current_user.id)
      end
    end
    livian_access    
  end

  def manager_list
    authorize!(:manager_list,current_user) unless current_user.role?:livia_admin
    @role = Role.getmanagerrole.first
  end

  #Creating service provider (manager) login
  def new
    @user= User.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @manager }
    end
  end

  def create
    authorize!(:create,current_user) unless current_user.role?:livia_admin
    @user=User.new(params[:user])
    @user.company_id=current_user.company_id
    respond_to do |format|
      if @user.save
        @role = Role.find_by_name("manager")
        @userrole = UserRole.create(:user_id=>@user.id,:role_id=>@role.id)
        flash[:notice] = "#{t(:text_manager)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to('/manage_secretary/manager_list') }
        format.xml  { render :xml => @user, :status => :created, :location => @user}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_manager
    authorize!(:update_manager,current_user) unless current_user.role?:livia_admin
    respond_to do |format|
      if @manager.update_attributes(params[:manager])
        flash[:notice] ="#{t(:text_manager)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to('/manage_secretary/manager_list') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :html => @manager.errors }
      end
    end
  end

  def destroy
    authorize!(:destroy,current_user) unless current_user.role?:livia_admin
    @manager.destroy
    @manager.user_role.destroy
    respond_to do |format|
      flash[:notice] = "#{t(:text_manager)} " "#{t(:flash_was_successful)} " "#{t(:text_deactivated)}"
      format.html { redirect_to('/manage_secretary/manager_list') }
      format.xml  { head :ok }
    end
  end

  def assign_unassign_serviceprovider
    authorize!(:assign_unassign_serviceprovider,current_user) unless current_user.role?:livia_admin
  end

  def view_managers
    authorize!(:view_managers,current_user) unless current_user.role?:livia_admin
    role_id = Role.find_by_name('team_manager').id
    user_roles = UserRole.all(:conditions => {:role_id => role_id}).uniq
    user_id = []
    user_roles.collect{|u| user_id << u.user_id}
    user_id = user_id.flatten
    @secretaries = ServiceProvider.all(:include => [:user,{:service_provider_employee_mappings => [:user => :company]}], :conditions => ['user_id IN (?)',user_id]).paginate :page => params[:page], :per_page => 20
    @companies = Company.all
    render :action=>'index'
  end

  def filter_livian_by_name
    name = params[:q].strip
    livians = ServiceProvider.find_by_name(name)
    render :partial=>"livian_listings", :locals=>{:livians=>livians}
  end
  
  protected
  def find_manager
    @manager = User.find(params[:id])
  end
  
end

