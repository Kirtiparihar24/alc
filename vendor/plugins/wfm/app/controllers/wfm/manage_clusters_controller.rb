class Wfm::ManageClustersController < WfmApplicationController
  before_filter :authenticate_user!
  before_filter :get_default_data
  before_filter :get_cluster_user, :only => [:edit_temp_assignment,:update_temp_assignment]
  before_filter [:get_alert_task_counts, :get_user_notifications] , :only => [:manage_priorities]

  layout 'wfm'


  def manage_priorities
    @clusters = current_user.clusters
    if params[:cluster_id].present?
      @cluster = Cluster.find(params[:cluster_id])
    else
      @cluster = @clusters.first
    end
    if @cluster
      @livians = @cluster.all_employees
      service_providers = ServiceProvider.all
      @service_providers = service_providers - @livians unless @livians.nil?
      @lawfirm_users = @cluster.lawyers
      @priority_types = PriorityType.all(:order=>"lvalue asc")
      @priorities = []
      @livians.each do |livian|
        @lawfirm_users.each do |lawyer|
          mapping = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id_and_service_provider_id(lawyer.id,livian.id)
          if mapping != nil
            priority_type = livian.id.to_s + "-"+ lawyer.id.to_s + "-" + mapping.priority.to_s
            @priorities << priority_type
          end
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html 'lawyers_livians_list', :partial=>"lawyers_livians_list", :locals => {:livians => @livians, :lawfirm_users => @lawfirm_users, :cluster => @cluster}
      end
    end
  end

  def update_priorities
    arr = params[:priority_types]
    arr.delete_if {|x| x == "" }
    arr.each do |record|
      Physical::Liviaservices::ServiceProviderEmployeeMappings.update_priority_set(record)
    end
    flash[:notice] = "Priorities updated successfuly."
    redirect_to :action=>'manage_priorities', :cluster_id=>params[:cluster_id]
  end

  def show_cluster_list
    service_provider = ServiceProvider.find(params[:id])
    @clusters = service_provider.user.clusters
  end

  def assign_sec_to_cluster
    @service_provider = ServiceProvider.find_by_id(params[:secretary_id])
    @service_provider.cluster_assignment(params[:cluster_id])
    cluster_user = ClusterUser.find_by_cluster_id_and_user_id(params[:cluster_id], @service_provider.user_id)
    unless cluster_user
      cluster_user = ClusterUser.new(:cluster_id=>params[:cluster_id],:user_id=>@service_provider.user_id,:from_date=>params[:from_date],:to_date=>params[:to_date])
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
      page.redirect_to :action=>'manage_priorities', :cluster_id => params[:cluster_id]
    end
  end

  def unassign_livian
    livians = ServiceProvider.find(params[:livians])
    cluster = Cluster.find(params[:cluster_id])
    lawfirm_users = cluster.all_lawfirm_users
    if params[:cluster_id].present?
      @cluster = Cluster.find(params[:cluster_id])
    else
      @cluster = @clusters.first
    end
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
      page.redirect_to :action=>'manage_priorities', :cluster_id => params[:cluster_id]
    end
  end

  def edit_temp_assignment
    render :layout => false
  end

  def update_temp_assignment
    from_date = params[:cluster_user][:from_date]
    to_date = params[:cluster_user][:to_date]
    respond_to do |format|
      format.html{
        render :update do |page|
          if @cluster_user.update_attributes(:from_date => from_date, :to_date => to_date)
            page << 'tb_remove();'
            page.redirect_to wfm_manage_priorities_path
            flash[:notice] = "Cluster User #{@cluster_user.user.full_name} updated successfully"
          else
            page << 'tb_remove();'
            page.redirect_to wfm_manage_priorities_path
            flash[:error] = "Error in updating Cluster User #{@cluster_user.user.full_name}"
          end
        end
      }
    end
  end
  
  private

  def get_cluster_user
    cluster_id = params[:cluster_id].to_i
    user_id = params[:id].to_i
    @cluster_user = ClusterUser.find_by_cluster_id_and_user_id(cluster_id,user_id)
  end

  def update_provider_type(service_provider,user_cluster_types)
    service_provider.provider_type = 0
    user_cluster_types.each do|e|
      service_provider.provider_type |= e.to_i
    end
    service_provider.update_attribute(:provider_type,service_provider.provider_type)
  end
end