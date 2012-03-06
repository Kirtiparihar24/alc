class CompanyEmailSettingsController < ApplicationController
  layout 'admin'
  
  # GET /company_email_settings
  # GET /company_email_settings.xml
  def index
    authorize!(:index,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
      @company_email_settings ||= CompanyEmailSetting.find_all_by_company_id(params[:company_id])
    else
      @companies ||=Company.company(current_user.company_id)
      @company_email_settings ||= CompanyEmailSetting.find_all_by_company_id(params[:company_id])
    end
    @company ||=Company.find(params[:company_id]) unless params[:company_id].nil?
    respond_to do |format|
      format.html # index.html.erb    
    end
  end

  def list
    authorize!(:list,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    session[:company_id] = params[:company_id]
    if current_user.role?:lawfirm_admin
      @company=current_user.company_id
      @company_email_settings =  CompanyEmailSetting.find_all_by_company_id(@company)
    else
      @company=Company.find(params[:company_id])
      @company_email_settings =  CompanyEmailSetting.find_all_by_company_id(@company.id)
    end
  end

  
  def index_old
    @company_email_settings = CompanyEmailSetting.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @company_email_settings }
    end
  end

  # GET /company_email_settings/1
  # GET /company_email_settings/1.xml
  def show
   
    @company_email_setting = CompanyEmailSetting.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company_email_setting }
    end
  end

  # GET /company_email_settings/new
  # GET /company_email_settings/new.xml
  def new
   
    @company_smtp_email_setting = CompanyEmailSetting.new
    @company_pop3_email_setting = CompanyEmailSetting.new
    @companies = Company.all(:conditions => ['id NOT IN (?)', current_user.company_id], :order => "name")
    respond_to do |format|
      format.html # new.html.erb     
    end
  end

  # GET /company_email_settings/1/edit
  def edit_individual
    @companies = Company.all(:conditions => ['id NOT IN (?)', current_user.company_id], :order => "name")
    @company_email_settings = CompanyEmailSetting.find_all_by_company_id(params[:company_id])
  end

  # POST /company_email_settings
  # POST /company_email_settings.xml
  def create
    @company_smtp_email_setting = CompanyEmailSetting.new(params[:company_email_setting][:SMTP])
    @company_pop3_email_setting = CompanyEmailSetting.new(params[:company_email_setting][:POP3])
    @company_pop3_email_setting.domain = @company_smtp_email_setting.domain
    respond_to do |format|
      if  @company_smtp_email_setting.valid? && @company_pop3_email_setting.valid? 
        @company_smtp_email_setting.save
        @company_pop3_email_setting.save
        flash[:notice] = 'CompanyEmailSetting was successfully created.'
        format.html { redirect_to(company_email_settings_url) }       
      else
        format.html { render :action => "new"}
        format.xml  { render :xml => @company_email_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_individual
	  params[:company_email_settings].values.first[:domain] = params[:company_email_settings].values.second[:domain]  if params[:company_email_settings].values.second[:domain].present?
	  params[:company_email_settings].values.second[:domain] = params[:company_email_settings].values.first[:domain]  if params[:company_email_settings].values.first[:domain].present?
    @company_email_settings = CompanyEmailSetting.update(params[:company_email_settings].keys, params[:company_email_settings].values).reject { |p| p.errors.empty? }
    respond_to do |format|
      if @company_email_settings.empty?
        flash[:notice] = 'CompanyEmailSetting was successfully updated.'
        format.html { redirect_to(company_email_settings_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_individual" }
        format.xml  { render :xml => @company_email_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @company_email_setting = CompanyEmailSetting.find(params[:id])
    @company_email_setting.destroy
    respond_to do |format|
      format.html { redirect_to(company_email_settings_url) }
      format.xml  { head :ok }
    end
  end
  
end
