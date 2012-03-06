class EmployeesController < ApplicationController
  before_filter :authenticate_user!
  
  layout 'admin'
  
  # GET /lawyers
  # GET /lawyers.xml
  before_filter :get_company , :except => [:index,:show_all_employee_rates,:edit_emp_rate,:update_emp_rate,:employee_cluster_mapping]
  def index
    authorize!(:index,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
    else
      @companies = Company.all(:conditions => ['id NOT IN (?)', current_user.company_id], :include => [:employees], :order => "name")
    end
    if params[:company_id]
      @company = Company.find(params[:company_id])
      @employees = @company.employees.all(:include => [:company,{:user=>:clusters}])
    end
  end

  # GET /lawyers/1
  # GET /lawyers/1.xml
  def show
    authorize!(:show,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @employee = @company.employees.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  def show_all_employee_rates
    authorize!(:show_all_employee_rates,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:id].blank?? session[:emp_company_id] = params[:id] : params[:id] = session[:emp_company_id]
    @company = Company.find(session[:emp_company_id])
    @employee_rates = Employee.getemployees(session[:emp_company_id]).paginate :page => params[:page], :per_page => 20
  end

  def edit_emp_rate
    authorize!(:edit_emp_rate,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(session[:emp_company_id])
    @employee = Employee.find(params[:id])
  end
  
  def update_emp_rate
    authorize!(:update_emp_rate,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @employee = Employee.find(params[:id])
    @employee.update_attribute('billing_rate',params[:employee][:billing_rate])
    redirect_to :action=>'show_all_employee_rates'
  end

  # This method is used to create new employee
  def new
    authorize!(:new,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @employee = @company.employees.new
    @user= User.new
    @designations = CompanyLookup.getdesignations(@company.id)
    @departments=@company.departments 
    show_employee_reporting_to_list
    @helpdesk_roles= ActiveRecord::Base.connection.execute("select * from helpdesk.roles where name not in ('Admin','Company Admin','Client User') order by name") if APP_URLS[:use_helpdesk]
  end
  
  # This method is used to edit existing employee
  def edit
    authorize!(:edit,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @employee = @company.employees.find(params[:id])    
    @user = @employee.user_id ? User.find(@employee.user_id) : User.new
    @designations = CompanyLookup.getdesignations(@company.id)
    @departments=@company.departments
    @reporting_to_id=@employee.parent_id
    show_employee_reporting_to_list
    @helpdesk_roles= ActiveRecord::Base.connection.execute("select * from helpdesk.roles where name not in ('Admin','Company Admin','Client User') order by name") if APP_URLS[:use_helpdesk]
  end

  # This method is used to create new employee.
  # also create user with his role if reququest is comes for user creation
  # Modified By - Hitesh
  def create
    authorize!(:create,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    params[:employee][:created_by_user_id] = current_user.id
    @employee = @company.employees.new(params[:employee])
    @designations = CompanyLookup.getdesignations(@company.id)
    @departments=@company.departments
    @helpdesk_roles= ActiveRecord::Base.connection.execute("select * from helpdesk.roles where name not in ('Admin','Company Admin','Client User') order by name") if APP_URLS[:use_helpdesk]
    respond_to do |format|
      begin
        if @employee.save_with_user(params)
          if params[:is_user]
            @employee.user.create_helpdesk_user(@company,params[:user][:password],params[:employee][:helpdesk_role_id] || "")
            @employee.user.save_default_questions
            url=url_link
            recipient =[]
            recipient << params[:user][:email]
            recipient << get_lawfirm_admin_email_for_companyid(params[:user][:company_id])
            userDetails = params[:user]
            @liviaMailer = LiviaMailer
          end   
          flash[:notice] = params[:is_user] ? "#{t(:text_user)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}" :  "#{t(:text_employee)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          format.html { redirect_to(company_employees_path(:company_id => @company.id)) }
          format.xml  { render :xml => @employee, :status => :created, :location => @employee }
        else
          @user= User.new(params[:user])
          @roles = @company.roles
          format.html { render :action => "new" }
          format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
        end
      rescue Exception => exc
        logger.info("Create Employee Error : #{exc.message}")
        flash[:error] = "DB Store error: #{exc.type}."
        format.html{ redirect_to(company_employees_path(:company_id => @company.id)) }
      end
    end    
  end
  
  # This method is used to update existing employee.
  # also create user with his role if request is comes for user creation
  # and if employee already a user then it update user records.
  # Modified By - Hitesh
  def update
    authorize!(:update,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @helpdesk_roles = ActiveRecord::Base.connection.execute("select * from helpdesk.roles where name not in ('Admin','Company Admin','Client User') order by name") if APP_URLS[:use_helpdesk]
    @employee = @company.employees.find(params[:id])
    respond_to do |format|
      begin
        @employee, @stat = @employee.update_with_user(params[:id], params)
        if @stat
          @employee.user.create_helpdesk_user(@employee.company,params[:user][:password],"") if params[:is_user]
          flash[:notice] = "#{t(:text_employee)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
          unless params[:employee][:reference1].blank?
            format.html { redirect_to :back }
          else
            format.html { redirect_to(company_employees_path(:company_id =>@company.id)) }
          end
          format.xml  { head :ok }
        else
          @user = @employee.user_id ? User.find(@employee.user_id) : User.new
          @designations = CompanyLookup.getdesignations(@company.id)
          @departments=@company.departments
          @reporting_to_id=@employee.parent_id
          show_employee_reporting_to_list
          format.html { render :action => "edit" }
          format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
        end
      rescue Exception => exc
        logger.info("Update Employee Error : #{exc.message}")
        flash[:error] = "DB Store error: #{exc.type}."
        format.html{redirect_to(company_employees_path(:company_id => @company.id))}
      end
    end
  end

  # This method is used to destroy the existing employee with user record
  # If user already have the product licence then it will not remove the productlicence
  # it just change the status of licence as a unassign instead of delete.
  def destroy
    authorize!(:destroy,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @employee = Employee.find(params[:id])
    if @employee.user_id
      ur = UserRole.find_by_user_id(@employee.user_id)
      ur.destroy unless ur.nil?
      User.find(@employee.user_id).destroy
      # Remove all the subproduct assignment of selected employee
      SubproductAssignment.delete_all(["user_id = ? OR employee_user_id = ?",@employee.user_id,@employee.user_id])
      Physical::Liviaservices::ServiceProviderEmployeeMappings.delete_all(:employee_user_id => @employee.user_id )
      @productlicence_details = ProductLicenceDetail.getuserlicence(@employee.user_id)
      @productlicence_details.each do |pld|
        pld.product_licence.update_attributes({:status => 0})
        pld.destroy
      end
      @employee.destroy
    else
      @employee.destroy
    end
    respond_to do |format|
      format.html { redirect_to(company_employees_path(:company_id =>@company.id)) }
      format.xml  { head :ok }
    end
  end

  # This method is used to modify the user access for the particular subproduct
  def editaccess
    authorize!(:editaccess,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @user = @company.users.find(params[:id])
    @subproductassign = SubproductAssignment.find_all_by_user_id(@user.id)
    @pld = ProductLicenceDetail.getuserlicence(@user.id)
    @productlicences = @pld.collect{|pld| pld.product_licence}
    if @pld.empty?
      flash[:error] =  "#{t(:text_licences)} " "#{t(:flash_not_available)}"
    end
  end

  #This function is used to get the company record when a company id is provided
  def get_company
    authorize!(:get_company,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(params[:company_id])
  end

  # This method is used to unassign subproduct access from the user
  def unassignsubproduct
    authorize!(:unassignsubproduct,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    if request.xhr?
      sub_product_ids = Subproduct.all(:select => [:id], :conditions => ["id = ? OR parent_id = ?", params[:sub_id], params[:sub_id]]).map(&:id)
      assignments = SubproductAssignment.all(:conditions => ["(user_id = ? OR employee_user_id = ?) AND subproduct_id in (?) AND product_licence_id = ?", params[:user_id], params[:user_id], sub_product_ids, params[:pl_id]])
      if assignments.present?
        assignments.each do |assignment|
          assignment.destroy
        end
      end
      if Subproduct.find(params[:sub_id]).name == "Activities"
        dashboard = CompanyDashboard.first(:conditions => ["company_id =? AND employee_user_id =  ? AND show_on_home_page = ? AND dashboard_charts.chart_name =?", params[:company_id], params[:user_id],true, "Open Matter Tasks"], :include => [:dashboard_chart], :order => 'dashboard_chart_id')
        unless dashboard.blank?
          dashboard.update_attribute('show_on_home_page', false)
        end
      end
      params[:id] = params[:user_id]
      editaccess      
    end
  end

  # This method is used to reassign subproduct access for user.
  def reassignsubproduct
    authorize!(:reassignsubproduct,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    if request.xhr?
      sub_product_ids = Subproduct.all(:select => [:id], :conditions => ["id = ? OR parent_id = ?", params[:sub_id], params[:sub_id]]).map(&:id)
      assignments = SubproductAssignment.find_with_deleted(:all, :conditions => ["(user_id = ? OR employee_user_id = ?) AND subproduct_id in (?) AND product_licence_id = ?", params[:user_id], params[:user_id], sub_product_ids, params[:pl_id]])
      if assignments.present?
        assignments.each do |assignment|
          assignment.update_attribute('deleted_at', '')
        end
      else
        assignments = SubproductAssignment.create(:user_id=>params[:user_id],:subproduct_id =>params[:sub_id],:product_licence_id =>params[:pl_id],:company_id => params[:company_id])
      end
      params[:id] = params[:user_id]
      editaccess      
    end
  end

  # This method is used to add existing employee as a user.
  def adduser
    authorize!(:adduser,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(params[:company_id])
    @employees = @company.employees.all(:conditions =>['user_id is null'])
    @user= User.new  
  end
  
  # This method is used to create new user from the existing employee.
  # also create user role.
  # This function creates a user record for a selected employee
  # Modified By - Hitesh
  def createuser
    authorize!(:createuser,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    unless params[:employee][:id].empty?
      @employee = @company.employees.find(params[:employee][:id])
      params[:user][:first_name]  = @employee.first_name
      params[:user][:last_name]   = @employee.last_name
      params[:user][:email]       = @employee.email
      params[:user][:phone]       = @employee.phone
      params[:user][:mobile]      = @employee.mobile
      params[:user][:time_zone] = params[:user][:time_zone]
      params[:user][:company_id]  = @employee.company_id
      @user = User.new(params[:user])
      @user.errors.add_to_base("Alternate Email:" + '' + "Alternate Email should not be blank") if params[:user][:alt_email].blank?
      reg = /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/
      @user.errors.add_to_base("Password:" + '' + t(:flash_password)) if !(reg.match(params[:user][:password]))
      respond_to do |format|
        begin
          if @user.errors.size == 0 && @user.save #Bug 11661: Rashmi.N
            Employee.transaction do              
              @employee.update_attributes(:user_id => @user.id)
              @role = Role.find_by_name('lawyer')
              @userrole = UserRole.find_or_create_by_user_id_and_role_id(@user.id,@role.id)
              @employee.user.create_helpdesk_user(@company,params[:user][:password],@role.id)
            end
            url=url_link
            recipient =[]
            recipient << params[:user][:email]
            recipient << get_lawfirm_admin_email_for_companyid(params[:user][:company_id])
            userDetails = params[:user]
            @liviaMailer = LiviaMailer
            flash[:notice] ="#{t(:text_user)} " "#{t(:flash_was_successful)} " "#{t(:text_added)}"
            if current_user.role?(:livia_admin)
              format.html { redirect_to showusers_companies_path+"/#{@company.id}" }
            else
              format.html { redirect_to lawfirm_admins_url }
            end
          else
            @roles = @company.roles
            @employees = @company.employees.all(:conditions => ['user_id IS NULL'])
            format.html { render(:action => 'adduser' ,:company_id =>@company.id) }
            format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
          end
        rescue Exception => exc
          logger.info("Create User Error : #{exc.message}")
          flash[:error] = "DB Store error: #{exc.type}."
          format.html{ redirect_to showusers_companies_path+"/#{@company.id}"}
        end
      end
    else
      flash[:error] = t(:flash_create_employee)
      redirect_to(:action => 'adduser' ,:company_id =>@company.id)
    end
  end

  #This function provides the list of deactivated employees of the selected company
  def deactivated_employees
    authorize!(:deactivated_employees,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(params[:company_id])
    @employees = Employee.find_only_deleted(:all,:conditions => ["company_id = ?", @company.id])
  end

  #This function activates the selected deactiveted employee
  def activate_employee
    authorize!(:activate_employee,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(params[:company_id])
    employee = Employee.find_only_deleted(:first, :conditions => ["id = ?", params[:id]])
    employee.update_attribute('deleted_at', '')
    if employee.user_id
      user = User.find_only_deleted(:first, :conditions => ["id = ?", employee.user_id])
      user.update_attribute('deleted_at', '')
      user_role = UserRole.find_only_deleted(:first, :conditions => ["user_id = ?", employee.user_id])
      user_role.update_attribute('deleted_at', '')
    end
    @employees = Employee.find_only_deleted(:all, :conditions => ["company_id = ?", @company.id])
  end

  #This function provides the list of employees of the selected department based on ajax request
  def show_employee_reporting_to_list
    authorize!(:show_employee_reporting_to_list,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    if params[:action] && params[:action] == "edit"
      dept_id = @employee.department_id
    else
      dept_id = params[:department_id]
    end
    unless dept_id.blank?
      depart = Department.find_parents(dept_id)
      @emp_list = Employee.getdepartmentemployeelist(depart)
    end
  end

  def employee_cluster_mapping
    if current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
      employee_cluster_details(params[:company_id])
    else
      @companies = Company.all(:conditions => ['id NOT IN (?)', current_user.company_id], :order => "name")
    end
  end

  def show_employee_with_cluster
    employee_cluster_details(params[:company_id], params[:lawyer_id])
    render :update do |page|
      page.replace_html 'employees', :partial=>'employees_clusters'
      page.replace_html 'cmp_name', @company.name
    end
  end
  private

  def employee_cluster_details(company_id, lawyer_id = nil)
    @company = Company.find(company_id)
    @employees = @company.employees.all(:joins => [:user], :include => [:company, {:user => :clusters}])
    unless @employees.blank?
      if lawyer_id.blank?
        @user = @employees.first.user
      else
        @user = User.find(lawyer_id)
      end
      @assign_clusters = @user.clusters.compact
      @unassign_clusters = Cluster.all - @assign_clusters
    end
  end
  
end
