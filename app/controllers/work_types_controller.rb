class WorkTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_categories
  before_filter :get_worktype, :only =>[:show,:edit,:update,:destroy]
  
  layout 'admin'

  def index
    unless params[:filter]
      @work_types = WorkType.all
    else
      @work_types = params[:filter].eql?('Back Office') ? WorkType.back_office_work_types : WorkType.livian_work_types
    end
    @work_types = @work_types.paginate :page => params[:page], :per_page => 20
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @work_types }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @work_type }
    end
  end

  def new
    @work_type = WorkType.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @work_type }
    end
  end

  def edit
  end

  def create
    @work_type = WorkType.new(params[:work_type])
    respond_to do |format|
      if @work_type.save
        flash[:notice] = 'WorkType was successfully created.'
        format.html { redirect_to(work_types_path) }
        format.xml  { render :xml => @work_type, :status => :created, :location => @work_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @work_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @work_type.update_attributes(params[:work_type])
        flash[:notice] = 'WorkType was successfully updated.'
        format.html { redirect_to(work_types_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @work_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @work_type.destroy
    respond_to do |format|
      format.html { redirect_to(work_types_url) }
      format.xml  { head :ok }
    end
  end

  private

  def get_categories
    @categories = Category.all
  end

  def get_worktype
    @work_type = WorkType.find(params[:id])
  end
  
end
