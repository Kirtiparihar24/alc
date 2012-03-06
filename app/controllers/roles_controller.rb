class RolesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  before_filter :get_role, :only => [:edit, :update]

  layout 'admin'

  def index
    @roles = Role.all_wfm.paginate :page => params[:page], :per_page => 20
  end

  def new
    @role = Role.new
    @categories = Category.all
  end

  def create
    @role = Role.new(params[:role])
    @role.for_wfm = true
    @categories = Category.all
    respond_to do |format|
      if @role.save
        flash[:notice] = 'Role was successfully created.'
        format.html { redirect_to roles_url }
        format.xml  { render :xml => @role, :status => :created, :location => @role }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:notice] = 'Role was successfully updated.'
        format.html { redirect_to roles_url }
        format.xml  { head :ok }
      else
        @categories = Category.all
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  private
  def get_role
    @role = Role.find(params[:id])
  end
  
end
