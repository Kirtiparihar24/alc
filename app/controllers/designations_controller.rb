class DesignationsController < ApplicationController
  # GET /designations
  # GET /designations.xml
 
  layout 'admin'
  #This function is used to provide the list of designation records if the logged in person is a lawfirm admin
  #and if the logged in person is a livia admin the list of copanies is provided for company dropdown
  def index  
    authorize!(:index,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    !params[:company_id].blank?? session[:company_id] = params[:company_id] : params[:company_id] = session[:company_id]
    if current_user.role?:lawfirm_admin
      params[:company_id]=current_user.company_id
      @designations ||= CompanyLookup.company_and_type(params[:company_id],'Designation')
    else
      @companies ||= Company.company(current_user.company_id)
      @designations ||= CompanyLookup.company_and_type(params[:company_id],'Designation')
    end
    @company ||= Company.find(params[:company_id]) unless params[:company_id].nil?
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @designations }
    end
  end

  #This function is used to provide the list of designations of the selected company only if the logged in person is a livia admin
  def list
    authorize!(:list,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    session[:company_id] = params[:company_id]
    if current_user.role?:lawfirm_admin
      @company=current_user.company_id
      @designations =  CompanyLookup.company_and_type(@company,'Designation')
    else
      @company = Company.find(params[:company_id])
      @designations =  CompanyLookup.company_and_type(@company.id,'Designation')
    end
  end

  # GET /designations/new
  # GET /designations/new.xml
  #This function is used to provide the data required for creating a form for new designation creation for a selected company
  def new
    authorize!(:new,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @designation = Designation.new
    @company = Company.find(params[:id]) if params[:id].present?
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @designation }
    end
  end

  # GET /designations/1/edit
  def edit
    authorize!(:edit,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @designation = Designation.find(params[:id])
    @company = Company.find(@designation.company_id)
 
  end

  # POST /designations
  # POST /designations.xml
  #This function is used to create a new designation
  def create
    authorize!(:create,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @designation = Designation.new(params[:designation])
    @designation.company_id=params[:id]
    respond_to do |format|
      if @designation.save 
        flash[:notice] ="#{t(:text_designation)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        expire_fragment :designations
        format.html { redirect_to(designations_url) }
        format.xml  { render :xml => @designation, :status => :created, :location => @designation }
      else
        @company = Company.find(params[:id]) if params[:id].present?
        format.html { render :action => "new" }
        format.xml  { render :xml => @designation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /designations/1
  # PUT /designations/1.xml
  #This function is used to update a selected designation details
  def update
    authorize!(:update,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @designation = CompanyLookup.find(params[:id])
    respond_to do |format|
      if @designation.update_attributes(params[:designation])   
        flash[:notice] = "#{t(:text_designation)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        expire_fragment :designations
        format.html { redirect_to(designations_url) }
        format.xml  { head :ok }        
      else
        @company = Company.find(@designation.company_id)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @designation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /designations/1
  # DELETE /designations/1.xml
  #This function is used to delete the selected designation
  def destroy
    authorize!(:destroy,current_user) unless current_user.role?:lawfirm_admin or current_user.role?:livia_admin
    @designation = CompanyLookup.find(params[:id])
    @designation.destroy
    respond_to do |format|
      expire_fragment :designations
      format.html { redirect_to(designations_url) }
      format.xml  { head :ok }
    end
  end
 
end
