class RateCardsController < ApplicationController
  include ApplicationHelper

  layout 'admin'

  before_filter :is_liviaadmin

  def index
    session[:company_id] = session_status
    !params[:id].blank?? session[:company_id] = params[:id] : params[:id] = session[:company_id]
    session[:company_id] = current_user.company_id if current_user.role?(:lawfirm_admin)
    @companies = Company.all(:conditions => ['id NOT IN(?)', current_user.company_id], :order => "name")
    if session[:company_id].present?
      @company = Company.find(session[:company_id])
      @company_role_rates = CompanyRoleRate.find_all_by_company_id(session[:company_id])
      @company_activity_rates = CompanyActivityRate.find_all_by_company_id(session[:company_id])
      @employee_rates = @company.employees.all
      @employee_activity_rates = EmployeeActivityRate.find(:all, :conditions=>["company_id = ?",session[:company_id]])
    end
  end

  def edit
    @employee = Employee.find(params[:id])
    @company = Company.find(@employee.company_id)
  end

  def update_company_header
    @company = Company.find(params[:id])
  end

  def update
    data = params[:employee]
    begin
      @employee = Employee.find(params[:id])
      @company = Company.find(@employee.company_id)
      respond_to do |format|
        if  data[:billing_rate].present? && data[:billing_rate].to_i > 0
          @employee.update_attribute(:billing_rate, data[:billing_rate].to_f.roundf2(2))
          flash[:notice] = "#{t(:text_employee_rates)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
          format.html { redirect_to(rate_cards_url) }
          format.xml  { head :ok }
        else
          flash[:error] = "Billing Rate should be greater than 0"
          format.html { render :action => "edit" }
          format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
        end
      end
    rescue Exception => ex
      flash[:error] = "Billing Rate should be greater than 0"
      render :action => "edit"
    end
  end
  
end
