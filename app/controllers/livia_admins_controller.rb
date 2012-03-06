class LiviaAdminsController < ApplicationController
  # GET /law_firms
  # GET /law_firms.xml
  layout 'admin', :except =>[:new_assignment]
  
  before_filter :authenticate_user!    
  def index
    @companies = Company.all
    @secretaries=ServiceProvider.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml =>  @companies }
      authorize!(:index,current_user) unless current_user.role?:livia_admin
    end
  end

  def new_assignment
    @secretary = ServiceProvider.find(params[:id])
    @assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.new
    @lawyers = Employee.all
    if request.post?
      params[:assignment][:status] = 1
      params[:assignment][:service_provider_id] = params[:secretary_id]
      params[:assignment][:created_by_user_id] = current_user.id
      params[:assignment][:company_id] = current_user.company_id
      @assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.new(params[:assignment])
      if @assignment.save
        redirect_to livia_admins_url
      end
    end
  end
  
  def remove_assignment
    @assignment = Physical::Liviaservices::ServiceProviderEmployeeMappings.find(params[:id])
    @assignment.destroy
    respond_to do |format|
      format.html { redirect_to livia_admins_url }
      format.xml  { head :ok }
    end
  end

  def show_user
    @company = Company.find(params[:id])
    @employees = @company.employees
    @roles = @company.roles
  end

end
