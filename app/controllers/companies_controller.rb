# Companies - This controller is used for CRUD in Company

class CompaniesController < ApplicationController
  # GET /law_firms
  # GET /law_firms.xml
  before_filter :authenticate_user!
  skip_before_filter :check_if_changed_password # added by kalpit patel 09/05/11
  load_and_authorize_resource(:except => [:activate_user,:company_licences])  
  before_filter :is_liviaadmin
  before_filter :offset_settings, :only=>[:index,:company_licences]

  layout 'admin'

  private
  def get_vals_for_lawfirm_lawyer(lawfirm, lawyer, key, hash_array, date_array)
    arr = [nil] * date_array.size
    date_array.each_with_index do|date, ind|
      hash_array.each do|hash|
        if hash["lawfirm"] == lawfirm && hash["lawyer"] == lawyer 
          if hash["logged_in_date"] == date.strftime("%Y-%m-%d")
            if ["logged_in_time", "logged_in_date"].include?(key)
              arr[ind] = hash[key]
            else
              if ind > 0
                arr[ind] = arr[ind-1].to_i + hash[key].to_i
              else
                arr[ind] = hash[key]
              end
            end
            break
          else
            unless ["logged_in_time", "logged_in_date"].include?(key)
              arr[ind] = arr[ind-1].to_i if ind > 0
            end
          end
        end
      end
    end
    arr
  end

  def readable_time(t)
    return unless t.present?
    t = t.split ":"
    "#{t[0].to_i} hrs, #{t[1].to_i} min, #{t[2].to_i} secs"
  end

  public
  def portal_usage_report_employee_list
    employees = Company.find(params[:company_id]).employees.all(:order => "last_name ASC")
    render :partial => "portal_usage_report_employee_list", :locals => {:employees => employees}
  end

  def portal_usage_report_form
    @companies_list = Company.all(:order => "name ASC", :conditions => ["id > 1"]).collect {|p| [ p.name, p.id ] }
    @employees_list = []
    @company_selected = nil
    @employee_selected = nil
    @usage_start_date = Date.parse(params[:usage_start_date]).strftime("%m/%d/%Y") if params[:usage_start_date].present?
    @usage_end_date = Date.parse(params[:usage_end_date]).strftime("%m/%d/%Y") if params[:usage_end_date].present?
    if params[:company] && params[:company][:id].present?
      @company_selected = Company.find(params[:company][:id])
    end
    if params[:employee] && params[:employee][:id].present?
      @employee_selected = Employee.find(params[:employee][:id])
    end
    if @company_selected
      @employees_list = @company_selected.employees.all(:order => "last_name ASC", :select => "first_name, last_name, id").collect{|e| [e.full_name, e.id]}
    end
    @selected_company_id = @company_selected.id if @company_selected
    @selected_employee_id = @employee_selected.id if @employee_selected
  end

  def portal_usage_report_download
    send_file "tmp/portal_usage_report.xls"
  end

  def portal_usage_report
    if params[:usage_start_date].blank? || params[:usage_end_date].blank?
      flash[:error] = "Start date and End date are mandatory"
      params[:action] = :portal_usage_report_form
      redirect_to params 
      return
    end
    start_date = Date.parse(params[:usage_start_date])
    end_date = Date.parse(params[:usage_end_date])
    hash_array = Company.portal_usage_report(start_date, end_date, params[:company][:id], params[:employee][:id])
    array_of_arrays = []
    report = Spreadsheet::Workbook.new
    sheet = report.create_worksheet
    row_num = 0
    ind  = 0
    date_array = (start_date..end_date).to_a
    arr = ["Lawfirm", "Lawyer", "Date"] + date_array
    sheet_columns = arr.count
    sheet.row(row_num).concat(arr)
    #set the width of the columns in excel and add some formatting
    format = Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre ,:text_wrap =>true
    format1 = Spreadsheet::Format.new :horizontal_align=>:centre ,:text_wrap =>true 
    sheet.row(0).default_format = format
    sheet_columns.times{ |x| sheet.column(x+1).width = 25}
    sheet.column(0).width = 50
    (3..sheet_columns).each{|c| sheet.column(c).default_format = format1}
    array_of_arrays << arr
    lawfirm = nil
    lawyer = nil
    hash_array.each do|hash|
      if hash["lawyer"] != lawyer || hash["lawfirm"] != lawfirm
        row_num += 1
        lawyer = hash["lawyer"]
        lawfirm = hash["lawfirm"]
        arr = [lawfirm, lawyer, "Login"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "logged_in_time", hash_array, date_array).collect{|e| e.present? ? "Yes" : "No"}
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr
        arr = ["", "", "#Matter"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "matter_count", hash_array, date_array)
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr        
        arr = ["", "", "#Contact"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "contact_count", hash_array, date_array)
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr
        arr = ["", "", "#Opportunity"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "opportunity_count", hash_array, date_array)
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr
        arr = ["", "", "#Time entry"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "time_entry_count", hash_array, date_array)
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr
        arr = ["", "", "Hours logged on"] + get_vals_for_lawfirm_lawyer(lawfirm, lawyer, "logged_in_time", hash_array, date_array).collect{|e| readable_time(e)}
        sheet.row(row_num += 1).concat(arr)
        array_of_arrays << arr
      end
    end
    xls_string = StringIO.new ''
    report.write xls_string
    File.open("tmp/portal_usage_report.xls", "wb") {|f| f.write(xls_string.string)}
    @records_array = array_of_arrays
  end

  def index
    update_session
    @companies ||= Company.company(current_user.company_id).all(:include => [:employees, {:users => [:role]}, :licences])
    @companies = @companies.paginate :page => params[:page], :per_page => 25
  end

  # GET /law_firms/1
  # GET /law_firms/1.xml
  def show
    @company = Company.find(params[:id])
    @product_licences = ProductLicence.find_all_by_company_id(params[:id], :include => :company, :order => 'product_id').paginate :page => params[:page], :per_page => 20
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /law_firms/new
  # GET /law_firms/new.xml
  def new
    @company = Company.new
    @company.billing_address.build
    @company.shipping_address.build
    @user=@company.users.build()
    @lawfirm_admin = []
    respond_to do |format|
      format.html #new.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /law_firms/1/edit
  def edit
    @company = Company.find(params[:id])
    @shippingadd=@company.billing_address.find_or_create_by_address_type('shipping')
    @billingadd=@company.shipping_address.find_or_create_by_address_type('billing')
    @lawfirm_admin = @company.company_admin
    @employees=@company.employees
    @roles = @company.roles
  end

  # To create or setup new company with company_admin
  # New company will be created with some default values.
  # DB Updtes : Company  User(firm admin) CompanyTempLicence DynamicLabel UserRole Designation Department and company_lookup
  # Modified By - Hitesh
  def create
    Company.transaction do
      params[:company][:created_by_user_id] = current_user.id
      @company = Company.new(params[:company])
      User.transaction do
        @user = @company.users.build(params[:user])
        @msgerror = ""
        raise ActiveRecord::Rollback
      end
      @role_id = Role.find_by_name('lawfirm_admin').id
      respond_to do |format|
        reg = /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/
        unless reg.match(params[:user][:password])
          @msgerror = t(:flash_password)
        end
        if @msgerror.blank? && (@company.save && @user.save)
          save_and_update_defaults('new', @user.id, @role_id, @company)
          CompanyTempLicence.create(:company_id => @company.id, :licence_limit => params[:company][:temp_licence_limit],:created_by_user_id =>current_user.id)
          create_documentsubcategory_for_company(@company)
          session[:company_id] = @company.id
          file_name = "#{params[:dynamic_label][:file_name]}_#{@company.id}"
          DynamicLabel.create(:company_id=>@company.id,:file_name=>file_name)
          flash[:notice] =  "#{t(:text_company)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"          
          format.html { redirect_to(companies_url) }
          format.xml  { render :xml => @company, :status => :created, :location => @company }
        else
          @user.errors.each do |obj, val|
            @company.errors.add_to_base(obj + ' ' + val)
          end
          unless @msgerror.blank?
            @company.errors.add_to_base(@msgerror)
          end
          format.html { render :controller=>"companies",:action => "new"}
          format.xml  { render :xml => @company.errors}
        end
      end
    end
  end

  #This function is used to send mail related to new company creation
  def send_mail_for_company_creation()
    url=url_link
    recipient = params[:user][:email]
    cc = current_user.email
    subject = "Creation of " + @company.name + " in Livia Portal"
    email = {}
    email[:notice] = "Your company " + @company.name + " has been added in Livia Portal and a Admin has been created for your company."
    email[:adminid] = @user.username
    email[:adminpassword] = @user.password
    email[:company_name] = @company.name
    @liviaMailer = LiviaMailer
    @liviaMailer.deliver_send_company_creation_details_mail(url,cc,recipient, email)
  end

  # Internal actoin use to create default values like department/designation for new/existing company
  # DB Updtes : UserRole Designation and Department
  # Modified By - Hitesh
  def save_and_update_defaults(action, user, role, company)
    if action=="new"
      @userrole = UserRole.create(:user_id => user.to_i, :role_id => role.to_i)
      #Creating default designation for new company
      ['Sr. Lawyer', 'Lawyer', 'Paralegal', 'Secretary'].each do |desig|
        Designation.create(:lvalue => desig.to_s, :alvalue => desig.to_s, :company_id => company.id)
      end
      #Create default department
      @department=Department.new(:name => 'Corporate', :company_id => company.id)
      @department.save(false)
    elsif action=='edit'
      @designations = CompanyLookup.company_and_type(company.id, 'Designation')
      @user_role = UserRole.find_by_user_id(user.to_i)
      if @user_role.nil?
        @userrole = UserRole.create(:user_id => user.to_i, :role_id => role.to_i)
      end
      if @designations.empty?
        ['Sr. Lawyer', 'Lawyer', 'Paralegal', 'Secretary'].each do |desig|
          Designation.create(:lvalue => desig.to_s, :alvalue => desig.to_s, :company_id => company.id)
        end
      end
      if company.departments.empty?
        @department=Department.new(:name => 'Corporate', :company_id => company.id)
        @department.save(false)
      end
    end
  end

  # To update existing company
  # DB Updtes : Company  User(firm admin) CompanyTempLicence DynamicLabel UserRole Designation Department and company_lookup
  # Modified By - Hitesh
  def update
    @company = Company.find(params[:id])
    params[:company][:updated_by_user_id] = current_user.id
    User.transaction do
      if params[:user].present?
        @user = @company.users.build(params[:user])
      else
        user = @company.company_admin
        @user = user[0]
      end
      @msgerror = ""
      Role.transaction do
        @role_id = Role.find_by_name('lawfirm_admin').id
        raise ActiveRecord::Rollback
      end
      @shippingadd=@company.billing_address.find_by_address_type('shipping')
      @billingadd=@company.shipping_address.find_by_address_type('billing')
      CompanyTempLicence.create(:company_id =>@company.id,:licence_limit =>params[:company][:temp_licence_limit],:created_by_user_id =>current_user.id)
      params[:company][:temp_licence_limit] = @company.temp_licence_limit
      @companies ||=Company.company(current_user.company_id)
      respond_to do |format|   
        if @company.update_attributes(params[:company])
          save_and_update_defaults('edit', @user.id, @role_id, @company) unless params[:commit]=="Upload Logo"          
          unless params[:company][:own_file].nil?
            unless params[:dynamic_label][:file_name].nil?
              if params[:company][:own_file] == '1'
                comp_id = @company.id
                abt_paths = "#{RAILS_ROOT}/config/locales/"
                selected_file_type = params[:dynamic_label][:file_name]
                file_name = "#{selected_file_type}_#{comp_id}"
                # Below function is for creating company own dynamic label file
                create_company_own_file( abt_paths, selected_file_type , file_name)
                dynamicLabel = DynamicLabel.find_by_company_id(@company.id)
                dynamicLabel.update_attributes(:company_id  => comp_id,:file_name=>file_name)
              else
                dynamicLabel = DynamicLabel.find_by_company_id(@company.id)
                abt_paths = "#{RAILS_ROOT}/config/locales/"
                file_name = "#{abt_paths}#{dynamicLabel.file_name}" + ".yml"
                selected_file_type = params[:dynamic_label][:file_name]
                if File.exist? file_name                  
                end
                dynamicLabel.update_attributes(:company_id=>@company.id,:file_name=>params[:dynamic_label][:file_name])
                I18n.load_path << abt_paths + "#{selected_file_type}.yml"
                I18n.reload!
              end
            end
          end         
          flash[:notice] =  "#{t(:text_company)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
          format.html { redirect_to(companies_url) }
          format.xml  { head :ok }
        else
          unless params[:commit]=="Upload Logo"
            @user.errors.each do |obj, val|
              @company.errors.add_to_base(obj + ' ' + val)
            end
            unless @msgerror.blank?
              @company.errors.add_to_base('Password ' + @msgerror)
            end
            @lawfirm_admin = @company.company_admin
          end
          format.html {         
            render :action => "edit"
          }
          format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
        end
      end
    end
  end


  # DELETE /law_firms/1
  # DELETE /law_firms/1.xml
  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    respond_to do |format|
      format.html { redirect_to(companies_url) }
      format.xml  { head :ok }
    end
  end

  #This function is for providing the list of all licences when a company id is provided
  def company_licences
    @company = Company.find(params[:id])
    @product_licences = ProductLicence.company_id(params[:id]).all(:include => [:product, {:product_licence_details => [:product_licence, :user]}], :offset => @offset.to_i - 1, :limit => @no_of_records, :order => ['product_id, id'])
    @total_licences = ProductLicence.company_id(params[:id]).all(:include => [:product, {:product_licence_details => [:product_licence, :user]}], :conditions =>["company_id = ?",params[:id]], :order => ['product_id,id'])
    @next_page = (@total_licences.length > (@offset + @no_of_records - 1))? true:false
    if params[:height]
      render :partial => "company_licences"
    end
  end

  #This function is for providing the list of company for company dropdown and when a company gets selected then the list of users related to that company gets sent to the view
  def showusers
    !params[:id].blank?? session[:company_id] = params[:id] : params[:id] = session[:company_id]
    @companies = Company.company(current_user.company_id)
    if current_user.role?:lawfirm_admin
      params[:id] = current_user.company_id
    end
    if params[:id]
      @company = Company.find(params[:id])
      @users=User.not_client(@company.id)
    end
  end

  #This function is for providing the list of deactivated users when a company id is provided
  def deactivated_users
    @company = Company.find(params[:company_id])
    @users = User.find_only_deleted(:all, :conditions => ["company_id = ?", @company.id])
  end

  # Reactivate the deactivated user with his employee
  def activate_user
    @company = Company.find(params[:company_id])
    user = User.find_only_deleted(:first, :conditions => {:id => params[:id]})
    user.update_attribute('deleted_at', '')
    employee = Employee.find_only_deleted(:first, :conditions => {:user_id => params[:id]})
    employee.update_attribute('deleted_at', '')
    @users = User.find_only_deleted(:all, :conditions => {:company_id => @company.id})
  end

  #This function is used to provide the list of clients when a company id is provided and also for providing the list of companies
  def clients
    !params[:id].blank?? session[:company_id] = params[:id] : params[:id] = session[:company_id]
    @companies = Company.company(current_user.company_id)
    if params[:id]
      @company = Company.find(params[:id], :include => [:contacts => :matters])
      @clients = @company.user_clients
    end
  end

  #This function is for providing the information related for creating the new client by proving a form for new client creation
  def new_client
    @user = User.new
    @company = Company.find(params[:company_id])
    @contacts = Contact.clients(@company.id).find_all {|e| e.user_id.nil?}
    if params[:cont_id]
      @contact = Contact.find(params[:cont_id])
      @user.email = @contact.email
      @user.first_name = @contact.first_name
      @user.last_name = @contact.last_name
    end
  end

  #This function is for creating a new client. Here the client will get creared only when there is one contact related to that client otherwise it will give the alert to select the contact
  def create_client
    data=params    
    @company = Company.find(data[:company_id], :include => :contacts)
    @user = User.new(data[:user])
    @contacts = @company.contacts
    unless data[:contact].blank? or data[:contact][:id].blank?
      @contact = Contact.find(data[:contact][:id])
    else
      @user.errors.add("Contact", "#{t(:error_please_select_a_contact)}")
      render :action => "new_client"
      return
    end
    @user.first_name = @contact.first_name unless @user.first_name
    @user.last_name = @contact.last_name unless @user.last_name
    @user.company_id= @company.id
    if @user.save
      r = Role.find_by_name('client')
      userrole = UserRole.find_or_create_by_user_id_and_role_id(@user.id,r.id)
      flash[:notice] = "User entry for #{@contact.full_info}  #{t(:flash_was_successful)}" " #{t(:text_created)}."
      @contact.update_attribute(:user_id, @user.id)
      redirect_to clients_companies_url
    else
      render :action => "new_client"
    end
  end

  def offset_settings
    @no_of_records = params[:action] == "company_licences" ? 4 :10
    if params[:offset]
      if params[:req].eql?('next')
        @offset = params[:offset].to_i + @no_of_records
      elsif params[:req].eql?('prev')
        @offset = params[:offset].to_i - @no_of_records
      end
    else
      @offset = 1
    end
  end

  def logo_upload
    authorize!(:logo_upload,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
    else
      @companies ||= Company.company(current_user.company_id)
    end
    @company ||= Company.find(params[:company_id]) unless params[:company_id].nil?
  end

  def matter_documents
    unless current_user.role.name.eql?('lawfirm_admin')
      @companies ||= Company.getcompanylist(current_user.company_id)
      if params[:company_id]
        @company ||= Company.find params[:company_id]
      else
        @company ||= Company.find session[:company_id] if session[:company_id]
      end
    else
      @company ||= Company.find current_user.company_id
    end
    if @company
      session[:company_id] = @company.id
      @matters = @company.matters.paginate :per_page => 15, :page => params[:page]
    end
  end

  def company_employee_clusters
    if current_user.role?:lawfirm_admin
      params[:company_id] = current_user.company_id
    else
      @companies = Company.all(:include => [:employees], :conditions => ['id NOT IN (?)', current_user.company_id],:order => "name")
    end
    if params[:company_id]
      @company = Company.find(params[:company_id])
      @employees = @company.employees.all(:include => [:company, {:user=>:clusters}])
      @assign_clusters = @employees.first.user.clusters
      @unassign_clusters = Cluster.all - @assign_clusters
    end
  end

end
