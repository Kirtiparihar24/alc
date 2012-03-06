# Service Provider - This controller is used to create new livians as the service providers

class ServiceProvidersController < ApplicationController
  # GET /secretaries
  # GET /secretaries.xml
  load_and_authorize_resource :except => [:activate_secretary]

  layout 'admin'

  #This function is used to show all the secretaries
  def index
    @secretaries = ServiceProvider.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @secretaries }
    end
  end

  # GET /secretaries/1
  # GET /secretaries/1.xml
  #This function is used to provide the details of the selected secretary
  def show
    @secretary = ServiceProvider.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @secretary }
    end
  end

  #This function is used to get all the deactivated service providers details
  def view_deactivated_secretaries
    @secretaries = ServiceProvider.find_with_deleted(:all, :conditions => ["deleted_at IS NOT NULL"]).paginate :page => params[:page], :per_page => 20
  end

  #This function is used to reactivate the selected deactivated secretary
  def activate_secretary
    authorize!(:activate_secretary,current_user) unless current_user.role?(:livia_admin)
    #Added Exceptional hadling and also transaction block ---SantoshChalla
    begin
      ServiceProvider.transaction do
        @secretary = ServiceProvider.find_with_deleted(params[:id])
        @secretary.update_attribute('deleted_at', '')
        @user = User.find_with_deleted(@secretary.user_id)
        @user.update_attribute('deleted_at', '')
        flash[:notice] = "#{t(:text_secretary)} #{t(:flash_was_successful)} #{t(:text_activated)}"
        redirect_to :controller=>'manage_secretary',:action=>'index'
      end
    rescue Exception =>e
      flash[:error] = "#{t(:text_secretary)} was not successfuly activated"
    end
  end

  # GET /secretaries/new
  # GET /secretaries/new.xml
  #This function is used to provide a new secretary record for creation of a new secretary
  def new
    @secretary = ServiceProvider.new
    @user= User.new
    set_clusters_value()
    @roles = Role.all_wfm
    @cluster_users = ClusterUser.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @secretary }
    end
  end

  # GET /secretaries/1/edit
  #This function is used to provide the details of the selected secretary for edit purpose
  def edit
    id = params[:id]
    @secretary = ServiceProvider.find_service_provider(id)
    @user= User.find(@secretary.user_id,:include => :work_subtypes)
    set_clusters_value()
    @secretary.first_name,@secretary.last_name = @user.first_name,@user.last_name
    @priority_types = PriorityType.all
    @roles = Role.all_wfm
    @clusterid = @user.cluster_users.all(:select => :cluster_id).collect{|a| a.cluster_id}
    @user_cluster =  @user.clusters
    @user_work_subtypes = @user.work_subtypes
    @user_work_subtypes_complexities = @user.work_subtype_complexities
  end

  # POST /secretaries
  # POST /secretaries.xml
  #This function is used to create a new secretary. While creating a new record in service_prviders_ table the related record is to be created in users table.
  def create
    @user= User.new
    params[:service_provider][:company_id]=current_user.company_id
    params[:service_provider][:created_by_user_id]=current_user.id
    @secretary = ServiceProvider.new(params[:service_provider])
    @user=User.new(params[:user])
    @roles = Role.all_wfm
    respond_to do |format|
      if @secretary.save_with_user(params)
        @secretary.user.create_helpdesk_user(current_company,params[:user][:password],"")
        if params[:cluster_ids].present?
          emp_users = []
          clusters = Cluster.find(params[:cluster_ids]).uniq
          for cluster in clusters
            for user in cluster.users
              emp_users << user if user.employee
            end
          end
          assign_sec_to_cluster_emps(@secretary,emp_users)
        end
        flash[:notice] = "#{t(:text_secretary)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to('/manage_secretary') }
        format.xml  { render :xml => @secretary, :status => :created, :location => @secretary }
      else
        set_clusters_value()
        format.html { render :action => "new" }
        format.xml  { render :xml => @secretary.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /secretaries/1
  # PUT /secretaries/1.xml
  #This function is used to update the selected secretary details
  def update
    id = params[:id]
    @secretary = ServiceProvider.find_secretary(id)
    @user= User.find(@secretary.user_id, :include => :work_subtypes)
    @priority_types = PriorityType.all
    @roles = Role.all_wfm
    @clusterid = @user.cluster_users.all(:select => :cluster_id).collect{|a| a.cluster_id}
    old_cluster_ids = @secretary.user.clusters.map(&:id)
    new_cluster_ids = []
    params[:cluster_ids].each {|id|new_cluster_ids << id.to_i } if params[:cluster_ids].present?
    respond_to do |format|
      if @secretary.update_attributes(params[:service_provider])
        @secretary.user.update_attributes(:first_name=>params[:service_provider][:first_name],:last_name=>params[:service_provider][:last_name])
        @secretary.update_role(params[:role][:id])
        @secretary.update_provider_type(params)
        update_skills(@secretary,params[:work_skills])
        propagate_cluster_changes(@secretary,new_cluster_ids,old_cluster_ids)
        flash[:notice] = "#{t(:text_secretary)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to('/manage_secretary') }
        format.xml  { head :ok }
      else
        @clusters = Cluster.all
        format.html { render :action => "edit" }
        format.xml  { render :xml => @secretary.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /secretaries/1
  # DELETE /secretaries/1.xml
  #This function is used to delete the selected service provider.
  # While deleting a service_provider record the related records in service_provider_employee_mappings table are also to be deleted
  def destroy
    @secretary = ServiceProvider.find(params[:id])
    User.delete(@secretary.user_id)
    Physical::Liviaservices::ServiceProviderEmployeeMappings.delete_all(:service_provider_id=>@secretary.id)
    SubproductAssignment.delete_all(:user_id=>@secretary.user_id)
    @secretary.delete
    flash[:notice] = "#{t(:text_secretary)} #{t(:flash_was_successful)} #{t(:text_deactivated)}"
    respond_to do |format|
      format.html { redirect_to('/manage_secretary') }
      format.xml  { head :ok }
    end
  end

  def update_mapping_priority
    @sa = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_service_provider_id_and_id(params[:secretary_id], params[:mapping_id])
    @sa.priority = params[:priority]
    @sa.save
    @secretary = ServiceProvider.find_by_id(params[:secretary_id], :include => [:service_provider_employee_mappings => [:user]])
    @priority_types = PriorityType.all
  end

  def get_work_subtypes
    @work_subtypes = []
    role =  Role.find(params[:role_id],:include => [{:categories => {:work_types => :work_subtypes}}])
    for category in role.categories
      for work_type in category.work_types
        for work_subtype in work_type.work_subtypes
          @work_subtypes << work_subtype
        end
      end
    end
    render :update do |page|
      page.replace_html 'work_type_list', :partial=>'work_type_list'
    end
  end

  private

  # assigns the secretary(Livian) to the cluster employees(Lawyers)
  def assign_sec_to_cluster_emps(sec,emp_users,priorities = [])
    mailmodule = Subproduct.find_by_name('Mail')
    for emp_user in emp_users
      service_assignment_validation = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id_and_service_provider_id(emp_user.id, sec.id)
      empSubAssignment = SubproductAssignment.find_all_by_user_id(emp_user.id)
      begin
        unless empSubAssignment.blank?
          if !service_assignment_validation
            Physical::Liviaservices::ServiceProviderEmployeeMappings.transaction do
              if priorities.blank?
                @service_assignment=Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:employee_user_id=>emp_user.id, :service_provider_id=>sec.id, :status=>1, :created_by_user_id => current_user.id,:priority=>nil)
              else
                @service_assignment=Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:employee_user_id=>emp_user.id, :service_provider_id=>sec.id, :status=>1, :created_by_user_id => current_user.id,:priority=>priorities[emp_user.id.to_s])
              end
              spl = SubproductAssignment.getsubproductlist(emp_user.id)
              if spl.blank?
                empSubAssignment.each do |spa|
                  if mailmodule.id != spa.subproduct_id
                    @subproduct_assignment=SubproductAssignment.create(:user_id=>sec.user_id,:subproduct_id =>spa.subproduct_id,:product_licence_id =>empSubAssignment.first.product_licence_id,:company_id => emp_user.company_id,:employee_user_id => emp_user.id)
                  end
                end
              else
                spl.each do |spa|
                  if mailmodule.id != spa.subproduct_id
                    @subproduct_assignment=SubproductAssignment.create(:user_id=>sec.user_id,:subproduct_id =>spa.subproduct_id,:product_licence_id =>empSubAssignment.first.product_licence_id,:company_id => emp_user.company_id,:employee_user_id => emp_user.id)
                  end
                end
              end
              service_provider_assignment_unassignment_mail(emp_user,"assigned", sec)
            end
          end
        end
      rescue
      end
    end
  end

  #This function is used to send the mail related to service provider assignment and unassignment to the lawyer.
  def service_provider_assignment_unassignment_mail(emp_user,action,sec)
    url = url_link
    sec_user = sec.user
    recipient = []
    recipient << emp_user.email
    recipient << sec_user.email
    recipient << get_lawfirm_admin_email(emp_user.id)
    cc = current_user.email
    subject = (action.to_s == "unassigned") ? "Service Provider unassignment to #{emp_user.full_name}" : "Service Provider assignment to #{emp_user.full_name}"
    email = {}
    (action.to_s == "unassigned") ? (email[:message] = "Service Provider named #{sec_user.full_name} has been unassigned to #{emp_user.full_name}") : (email[:message] = "Service Provider named " + sec_user.full_name + " has been assigned to " + emp_user.full_name)
    @liviaMailer = LiviaMailer
  end

  # unassigns livian from the employees of privious cluster and assign livian to the employees of new cluster
  def propagate_cluster_changes(sec,new_cluster_ids,old_cluster_ids)
    cluster_ids_to_be_added=new_cluster_ids - old_cluster_ids
    cluster_ids_to_be_removed=old_cluster_ids - new_cluster_ids
    unless cluster_ids_to_be_removed.blank?
      for cluster_id in cluster_ids_to_be_removed
        ClusterUser.delete_all(:user_id=>sec.user_id,:cluster_id=>cluster_id)
        cluster = sec.user.clusters.pop {|c| c.id == cluster_id}
        employees = cluster.all_lawfirm_users
        for employee in employees
          Physical::Liviaservices::ServiceProviderEmployeeMappings.destroy_all(:service_provider_id=>sec.id,:employee_user_id=>employee.user_id)
          SubproductAssignment.delete_all(:user_id=>sec.user_id, :employee_user_id=>employee.user_id)
          service_provider_assignment_unassignment_mail(employee.user,"unassigned", sec)
        end
      end
    end
    unless cluster_ids_to_be_added.blank?
      for cluster_id in cluster_ids_to_be_added
        ClusterUser.create(:user_id=>sec.user_id,:cluster_id=>cluster_id)
      end
      emp_users = []
      clusters = Cluster.find(cluster_ids_to_be_added)
      for cluster in clusters
        for user in cluster.users
          emp_users << user if user.employee
        end
      end
      assign_sec_to_cluster_emps(sec,emp_users.uniq)
    end
  end

  def update_skills(secretary,skill_ids)
    UserWorkSubtype.destroy_all(:user_id=>secretary.user_id) if secretary.user.work_subtypes
    unless skill_ids.blank?
      secretary.create_user_work_subtypes(secretary.user,skill_ids)
    end
  end

  def set_clusters_value
    @bo_clusters=[]
    @cp_clusters=[]
    @fo_clusters=[]
    @fo_skills = WorkSubtype.front_office_work_subtypes
    @bo_skills = WorkSubtype.back_office_work_subtypes
    @clusters = Cluster.all
    @clusters.each do |c|
      if c.is_back_office_cluster?
        @bo_clusters << c
      end
      if c.is_common_pool_cluster?
        @cp_clusters << c
      end
      if c.is_front_office_cluster?
        @fo_clusters << c
      end
    end
  end
  
end
