class ClustersController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :check_if_changed_password # added by kalpit patel 09/05/11

  layout 'admin'
  
  # GET /lawyers
  # GET /lawyers.xml
  #before_filter :get_company , :except => [:index]

  def index
    @clusters = Cluster.all
    @clusters = @clusters.paginate :page => params[:page], :per_page => 20
  end

  def new
    @cluster = Cluster.new
  end

  def create
    @cluster = Cluster.new(params[:cluster])
    if @cluster.save
      @cluster.update_cluster_type(params)
      flash[:notice] ="#{t(:text_cluster)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @cluster = Cluster.find(params[:id])

  end

  def update
    @cluster = Cluster.find(params[:id])
    if @cluster.update_attributes(params[:cluster])
      @cluster.update_cluster_type(params)
      flash[:notice] = "#{t(:text_cluster)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      redirect_to :action => 'index'
    else
      render :action=>'edit'
    end
  end

  #This function is used to get the company record when a company id is provided
  def get_company
    authorize!(:get_company,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(params[:company_id])
  end
  
  def update_user_cluster
    @user = User.find(params[:lawyer_id])
    if params[:update_user_cluster] == "unassign"
      params[:assigned_clusters].each { |c|
        user_cluster = @user.cluster_users.find_by_cluster_id(c)
        user_cluster.delete
      }
    else
      clusters = params[:unassigned_clusters]
      clusters.each { |cluster|
        @user.cluster_users.create(:cluster_id => cluster)
      }
    end
    @assign_clusters = @user.clusters
    @unassign_clusters = Cluster.all - @assign_clusters
    render :update do |page|
      page.replace_html 'cluster_list', :partial=>'employees/clusters_list'
    end
  end
  
end
