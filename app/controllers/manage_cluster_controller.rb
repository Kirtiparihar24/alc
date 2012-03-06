class ManageClusterController < ApplicationController
  layout "admin"
  
  before_filter :authenticate_user!, :get_objects
  before_filter :set_company_lawyer_and_livian, :only => [:index,:show_assigned_cluster_employee_list,:update_priority]

  def index
    authorize!(:index,current_user) unless current_user.role?:livia_admin
  end

  def show_assigned_cluster_employee_list
    if(params[:page].present?)
      redirect_to :controller=>'manage_cluster',:action=>'index', :cluster_id => params[:cluster_id], :page => params[:page]
    else
      render :update do |page|
        page.replace_html 'show_assigned_cluster_employee_list', :partial=>'show_assigned_cluster_employee_list', :locals => {:cluster => @cluster}
      end
    end
  end
    
  def show_company_users_list
    @cluster = Cluster.find(params[:cluster_id])
    @cluster_users = @cluster.all_lawfirm_users
    @lawfirm_users = Employee.all(:conditions => ['company_id = ? AND user_id IS NOT NULL',params[:company_id]]) - @cluster_users
  end

  def assign_user_to_cluster
    lawfirm_emp = Employee.find_by_id(params[:lawyer_id])
    if lawfirm_emp.cluster_assignment(params[:cluster_id])
      cluster_user = ClusterUser.find_by_cluster_id_and_user_id(params[:cluster_id], lawfirm_emp.user_id)
      unless cluster_user
        cluster_user = ClusterUser.new(:cluster_id=>params[:cluster_id],:user_id=> lawfirm_emp.user_id)
        cluster_user.save
      end
      flash[:notice] = "#{lawfirm_emp.full_name} assigned to cluster successfully."
    else
      flash[:error] = "#{lawfirm_emp.full_name} dosn't have any licences assigned."
    end
    render :update do |page|
      page.redirect_to :controller=>'manage_cluster',:action=>'index', :cluster_id => params[:cluster_id]
    end
  end

  def assign_sec_to_cluster
    @service_provider = ServiceProvider.find_by_id(params[:secretary_id])
    @service_provider.cluster_assignment(params[:cluster_id])
    cluster_user = ClusterUser.find_by_cluster_id_and_user_id(params[:cluster_id], @service_provider.user_id)
    unless cluster_user
      cluster_user = ClusterUser.new(:cluster_id=>params[:cluster_id],:user_id=>@service_provider.user_id)
      if cluster_user.save
        user_cluster_types = @service_provider.user.clusters.map(&:cluster_type)
        update_provider_type(@service_provider,user_cluster_types)
        flash[:notice] = "#{@service_provider.sp_full_name} assigned to cluster successfully."
      else
        flash[:error] = "#{@service_provider.sp_full_name} cannot be assigned to cluster."
      end
    else
      flash[:notice] = "#{@service_provider.sp_full_name} assigned to cluster successfully."
    end
    render :update do |page|
      page.redirect_to :controller=>'manage_cluster',:action=>'index', :cluster_id => params[:cluster_id]
    end
  end

  def update_priority
    arr = params[:priority_types]
    if(Physical::Liviaservices::ServiceProviderEmployeeMappings.update_priority_set(arr))
      flash[:notice] = "Priority updated successfuly."
      @priority_type = params[:priority_types]
    else
      flash[:error]= "Error while updating priority, please try again."
    end
    render :update do |page|
      page.replace_html 'flash_messages', :partial=>'/common/common_flash_message'
      page.replace_html "priority_#{params[:lawyer_id]}_#{params[:livian_id]}", :partial=>'priority_select', :locals =>{:lawyer_id => params[:lawyer_id], :livian_id => params[:livian_id]}
    end
  end


  def unassign_lawfirm_user
    lawfirm_users = Employee.find(params[:lawfirm_users])
    cluster = Cluster.find(params[:cluster_id])
    service_providers = cluster.all_employees
    for lawfirm_user in lawfirm_users
      for service_provider in service_providers
        Physical::Liviaservices::ServiceProviderEmployeeMappings.destroy_all(:service_provider_id=>service_provider.id,:employee_user_id=>lawfirm_user.user_id)
      end
      cluster_user = ClusterUser.find_by_user_id_and_cluster_id(lawfirm_user.user_id, cluster.id)
      cluster_user.destroy
    end
    flash[:notice] = "Lawfirm users unassigned successfully."
    render :update do |page|
      page.redirect_to :controller=>'manage_cluster',:action=>'index', :cluster_id => params[:cluster_id]
    end
  end

  def unassign_livian
    livians = ServiceProvider.find(params[:livians])
    cluster = Cluster.find(params[:cluster_id])
    lawfirm_users = cluster.all_lawfirm_users
    for livian in livians
      for lawfirm_user in lawfirm_users
        Physical::Liviaservices::ServiceProviderEmployeeMappings.destroy_all(:service_provider_id=>livian.id,:employee_user_id=>lawfirm_user.user_id)
      end
      cluster_user = ClusterUser.find_by_user_id_and_cluster_id(livian.user_id,cluster.id)
      cluster_user.destroy
      user_cluster_types = livian.user.clusters.map(&:cluster_type)
      update_provider_type(livian,user_cluster_types)
    end
    flash[:notice] = "Livians unassigned successfully."
    render :update do |page|
      page.redirect_to :controller=>'manage_cluster',:action=>'index', :cluster_id => params[:cluster_id]
    end
  end

  def show_cluster_list
    if params[:user_type] == 'ServiceProvider'
      service_provider = ServiceProvider.find(params[:id])
      @user = service_provider.user
    else
      lawfirm_user = Employee.find(params[:id])
      @user = lawfirm_user.user
    end
    @clusters = @user.clusters
  end

  private
  def get_objects
    @clusters = Cluster.all
    @companies = Company.getcompanylist(current_user.company_id)
  end

  def update_provider_type(service_provider,user_cluster_types)
    service_provider.provider_type = 0
    user_cluster_types.each do|e|
      service_provider.provider_type |= e.to_i
    end
    service_provider.update_attribute(:provider_type,service_provider.provider_type)
  end

  def set_company_lawyer_and_livian
    unless params[:cluster_id].blank?
      @cluster = Cluster.find(params[:cluster_id])
      @livians = @cluster.all_employees
      @service_providers = ServiceProvider.all(:include => [:user])
      @service_providers = @service_providers - @livians unless @livians.nil?
      @all_lawfirm_users = @cluster.all_lawfirm_users
      @lawfirm_users = @all_lawfirm_users.paginate :per_page => 10, :page => params[:page]
      @priority_types = PriorityType.all
      @priority_type = []
      @livians.each do |liv|
        @lawfirm_users.each do |law|
          mapping = liv.service_provider_employee_mappings.find_by_employee_user_id law.user_id
          mapping =  mapping.priority unless mapping.nil?
          priority_type = liv.id.to_s + "-"+ law.user_id.to_s + "-" + mapping.to_s
          @priority_type << priority_type if mapping != nil
        end
      end
    end
  end

end
