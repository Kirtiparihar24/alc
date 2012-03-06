class CompanyRoleRatesController < ApplicationController
  layout 'admin'
  before_filter :is_liviaadmin

  # GET /company_role_rates
  # GET /company_role_rates.xml
  def index
    @company_role_rates = CompanyRoleRate.all
    respond_to do |format|
      format.html # index.html.erb    
    end
  end

  # GET /company_role_rates/1
  # GET /company_role_rates/1.xml
  def show
    @company_role_rate = CompanyRoleRate.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company_role_rate }
    end
  end

  # GET /company_role_rates/new
  # GET /company_role_rates/new.xml
  def new
    @company_role_rate = CompanyRoleRate.new
    @company = Company.find(params[:id], :include => :designations) #if !session[:company_id].blank?
    @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}
    @roles = @company.designations.collect{|role|[role.lvalue,role.id]}
    respond_to do |format|
      format.html # new.html.erb    
    end
  end

  # GET /company_role_rates/1/edit
  def edit
    @company_role_rate = CompanyRoleRate.find(params[:id])
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    @role = @company.designations.find(@company_role_rate.role_id)
  end

  # POST /company_role_rates
  # POST /company_role_rates.xml
  def create
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    @company_role_rate = CompanyRoleRate.new(params[:company_role_rate])
    @company_role_rate.company_id = current_user.company_id if current_user.role?(:lawfirm_admin)
    @company_role_rate.company_id = session[:company_id] if current_user.role?(:livia_admin)
    session[:company_id] = @company_role_rate.company_id if current_user.role?(:livia_admin)
    respond_to do |format|
      if @company_role_rate.save
        flash[:notice] =  "#{t(:text_company_role_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(rate_cards_url) }      
      else
        @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}
        @roles = @company.designations.collect{|role|[ role.lvalue,role.id ]}
        format.html { render :action => "new" }      
      end
    end
  end

  # PUT /company_role_rates/1
  # PUT /company_role_rates/1.xml
  def update
    @company_role_rate = CompanyRoleRate.find(params[:id])
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    respond_to do |format|
      if @company_role_rate.update_attributes(params[:company_role_rate])
        flash[:notice] = "#{t(:text_company_role_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(rate_cards_url) }     
      else
        @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}
        @role = @company.designations.find(@company_role_rate.role_id)
        format.html { render :action => "edit" }     
      end
    end
  end

  # DELETE /company_role_rates/1
  # DELETE /company_role_rates/1.xml
  def destroy
    @company_role_rate = CompanyRoleRate.find(params[:id])
    @company_role_rate.destroy
    respond_to do |format|
      format.html { redirect_to(rate_cards_url) }  
    end
  end
  
end
