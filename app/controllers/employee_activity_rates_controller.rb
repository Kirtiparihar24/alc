class EmployeeActivityRatesController < ApplicationController
  layout 'admin'

  before_filter :is_liviaadmin
  # GET /employee_activity_rates
  # GET /employee_activity_rates.xml
  def index
    !params[:id].blank?? session[:emp_company_id] = params[:id] : params[:id] = session[:emp_company_id]
    @employee_activity_rates = EmployeeActivityRate.all(:conditions => ["company_id = ?", params[:id]])
    @company = Company.find(params[:id])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /employee_activity_rates/1
  # GET /employee_activity_rates/1.xml
  def show
    @employee_activity_rate = EmployeeActivityRate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @employee_activity_rate }
    end
  end

  # GET /employee_activity_rates/new
  # GET /employee_activity_rates/new.xml
  def new
    @employee_activity_rate = EmployeeActivityRate.new
    @company = Company.find(params[:id], :include => :company_activity_types)
    @employees = Employee.all(:conditions => ["company_id = ? AND user_id IS NOT NULL", params[:id]]).collect{|emp|[ emp.full_employee_name,emp.user_id ]}
    @emp_activities = @company.company_activity_types.all.collect{|activity|[ activity.lvalue,activity.id ]}
    respond_to do |format|
      format.html # new.html.erb    
    end
  end

  # GET /employee_activity_rates/1/edit
  def edit
    @employee_activity_rate = EmployeeActivityRate.find(params[:id])
    @user = User.find(@employee_activity_rate.employee_user_id)
    @company = Company.find(@employee_activity_rate.company_id)
    @employees = Employee.all(:conditions => ["company_id = ?", @employee_activity_rate.company_id]).collect{|emp|[ emp.full_employee_name,emp.user_id ]}
    @activity = CompanyActivityType.find(@employee_activity_rate.activity_type_id).lvalue
  end

  # POST /employee_activity_rates
  # POST /employee_activity_rates.xml
  def create
    @employee_activity_rate = EmployeeActivityRate.new(params[:employee_activity_rate])
    @employee_activity_rate.company_id = params[:company_id]
    @company = Company.find(params[:company_id], :include => :company_activity_types)
    if @employee_activity_rate.save
      flash[:notice] = "#{t(:text_employee_activity_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      @employee_activity_rates = EmployeeActivityRate.all(:conditions => ["company_id = ?", params[:company_id]])
      redirect_to :controller => 'rate_cards', :action => 'index'
    else
      @employees = Employee.all(:conditions => ["company_id = ? and user_id IS NOT NULL", params[:company_id]]).collect{|emp|[ emp.full_employee_name,emp.user_id ]}
      @emp_activities = @company.company_activity_types.collect{|activity|[ activity.lvalue,activity.id ]}
      render :action => "new"
    end

  end

  # PUT /employee_activity_rates/1
  # PUT /employee_activity_rates/1.xml
  def update
    @employee_activity_rate = EmployeeActivityRate.find(params[:id])
    @user = User.find(@employee_activity_rate.employee_user_id)
    @company = Company.find(params[:company_id])
    respond_to do |format|
      if @employee_activity_rate.update_attributes(params[:employee_activity_rate])
        flash[:notice] = "#{t(:text_employee_activity_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        @employee_activity_rates = EmployeeActivityRate.find(:all, :conditions=>["company_id = ?",params[:company_id]])
        format.html {  redirect_to(rate_cards_url)}
        format.xml  { head :ok }
      else
        @employees = Employee.all(:conditions => ["company_id != ? AND user_id IS NOT NULL", current_user.company_id]).collect{|emp|[ emp.full_employee_name,emp.user_id ]}
        @activity = CompanyActivityType.find(@employee_activity_rate.activity_type_id).lvalue
        format.html { render :action => "edit" }
        format.xml  { render :xml => @employee_activity_rate.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_activity_rates/1
  # DELETE /employee_activity_rates/1.xml
  def destroy
    @employee_activity_rate = EmployeeActivityRate.find(params[:id])
    @employee_activity_rate.destroy
    @company = Company.find(@employee_activity_rate.company_id)
    @employee_activity_rates = EmployeeActivityRate.all(:conditions => ["company_id = ?", @employee_activity_rate.company_id])
    redirect_to :controller =>'rate_cards', :action => 'index'
  end
  
end
