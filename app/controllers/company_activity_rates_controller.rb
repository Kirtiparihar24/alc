class CompanyActivityRatesController < ApplicationController
  layout 'admin'
  before_filter :is_liviaadmin
  # GET /company_activity_rates
  # GET /company_activity_rates.xml
  def index
    @company_activity_rates = CompanyActivityRate.all
    respond_to do |format|
      format.html # index.html.erb     
    end
  end

  # GET /company_activity_rates/1
  # GET /company_activity_rates/1.xml
  def show
    @company_activity_rate = CompanyActivityRate.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company_activity_rate }
    end
  end

  # GET /company_activity_rates/new
  # GET /company_activity_rates/new.xml
  def new
    @company_activity_rate = CompanyActivityRate.new
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}
    @rate_activities = @company.company_activity_types.collect{|activity|[ activity.lvalue,activity.id ]}
    respond_to do |format|
      format.html # new.html.erb    
    end
  end

  # GET /company_activity_rates/1/edit
  def edit
    @company_activity_rate = CompanyActivityRate.find(params[:id])
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    @rate_activity = @company.company_activity_types.find(@company_activity_rate.activity_type_id).lvalue
  end

  # POST /company_activity_rates
  # POST /company_activity_rates.xml
  def create
    @company_activity_rate = CompanyActivityRate.new(params[:company_activity_rate])
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    @company_activity_rate.company_id = current_user.company_id if current_user.role?(:lawfirm_admin)
    @company_activity_rate.company_id = session[:company_id] if current_user.role?(:livia_admin)
    session[:company_id] = @company_activity_rate.company_id  if current_user.role?(:livia_admin)
    respond_to do |format|
      if @company_activity_rate.save
        flash[:notice] = "#{t(:text_company_activity_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(rate_cards_url) }
      else
        @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}
        @rate_activities = @company.company_activity_types.collect{|activity|[ activity.lvalue,activity.id ]}
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /company_activity_rates/1
  # PUT /company_activity_rates/1.xml
  def update
    @company_activity_rate = CompanyActivityRate.find(params[:id])
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?

    respond_to do |format|
      if @company_activity_rate.update_attributes(params[:company_activity_rate])
        flash[:notice] = "#{t(:text_company_activity_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html {  redirect_to(rate_cards_url)}        
      else
        @companies = Company.all(:conditions => ['id != ?', current_user.company_id]).collect{|company|[ company.name,company.id ]}        
        @rate_activity = @company.company_activity_types.find(@company_activity_rate.activity_type_id).lvalue
        format.html { render :action => "edit" }        
      end
    end
  end

  # DELETE /company_activity_rates/1
  # DELETE /company_activity_rates/1.xml
  def destroy
    @company_activity_rate = CompanyActivityRate.find(params[:id])
    @company_activity_rate.destroy

    respond_to do |format|
      format.html { redirect_to(rate_cards_url)}    
    end
  end
  
end
