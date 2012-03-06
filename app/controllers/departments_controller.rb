#Shows the departments, view charts and users hierarchy March 4-2010
class DepartmentsController < ApplicationController
  before_filter :authenticate_user!  
  layout 'admin'

  #This function is used to show the list of companies for companies dropdown when a logged in person is a lawfirm
  #and if the logged in person is a lawfirm admin for him the list of all departments related to that person will gets displayed
  def index
    authorize!(:index,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      session[:company_id] = current_user.company_id
      params[:company_id] = current_user.company_id
      @departments = Department.company_id(params[:company_id]).all(:include => :employees)
    else
      @companies = Company.company(current_user.company_id)
      @departments = Department.company_id(params[:company_id]).all(:include => :employees)
    end
    @company = Company.find(session[:company_id]) unless session[:company_id].blank?
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @departments }
    end
  end

  #This function is for showing the list of departments when a livia admin selects a company
  def list
    authorize!(:list,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    session[:company_id] = params[:company_id]
    if current_user.role?:lawfirm_admin
      @company=current_user.company_id  
    end
    @company=Company.find(params[:company_id])
    @departments = Department.company_id(@company.id).all(:include => [:employees])
  end
 
  # GET /departments/new
  # GET /departments/new.xml
  #This function is for providing the data related to create a new department
  def new
    authorize!(:new,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company = Company.find(session[:company_id]) if session[:company_id].present?
    @department = Department.new
    @sub_departments=Department.sub_departments(session[:company_id])
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @department }
    end
  end
  
  #showing sub departments via jquery
  def sub_department
    authorize!(:sub_department,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    params[:company_id] = current_user.company_id if current_user.role?:lawfirm_admin
    @sub_departments=Department.sub_departments(params[:company_id])
  end

  # GET /departments/1/edit
  def edit
    authorize!(:edit,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @department = Department.find(params[:id])
    @sub_departments = Department.sub_departments_id(@department.id,@department.company_id)
    @company = Company.find(session[:company_id]) if session[:company_id].present?
  end

  # POST /departments
  # POST /departments.xml
  #This function is for creating a new department
  def create
    authorize!(:create,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @department = Department.new(params[:department])
    @department.company_id = current_user.company_id if current_user.role?:lawfirm_admin
    @department.company_id = session[:company_id] if current_user.role?:livia_admin
    @companies = Company.company(current_user.company_id)
    respond_to do |format|
      if @department.save        
        flash[:notice] ="#{t(:text_department)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(departments_url) }
        format.xml  { render :xml => @department, :status => :created, :location => @department }
      else
        @company = Company.find(@department.company_id) if session[:company_id].present?
        @sub_departments=Department.sub_departments(session[:company_id])
        format.html { render :action => "new" }
        format.xml  { render :xml => @department.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /departments/1
  # PUT /departments/1.xml
  #This function is used to update the selected department details
  def update
    authorize!(:update,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @department = Department.find(params[:id])
    respond_to do |format|
      if @department.update_attributes(params[:department])
        flash[:notice] = "#{t(:text_department)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(departments_url) }
        format.xml  { head :ok }
      else
        @sub_departments=Department.sub_departments_id(@department.id,@department.company_id)
        @company = Company.find(session[:company_id]) if session[:company_id].present?
        format.html { render :action => "edit" }
        format.xml  { render :xml => @department.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /departments/1
  # DELETE /departments/1.xml
  #This function is used to delete the selected department
  def destroy
    authorize!(:destroy,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @department = Department.find(params[:id])
    @department.destroy
    respond_to do |format|
      format.html { redirect_to(departments_url) }
      format.xml  { head :ok }
    end
  end

  #This function is for providing the data required for showing the chart of the departments
  def view_chart
    authorize!(:view_chart,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @company, @orgdata, @orgempdata, @empdata = Department.get_department_data_chart(params[:id])
  end

end
