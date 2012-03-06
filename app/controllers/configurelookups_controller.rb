class ConfigurelookupsController < ApplicationController
  before_filter :authenticate_user!  
  layout "admin"

  def index
    @lookups = Lookup.all(:select => "type",:group => "type")
    unless params[:type].blank?
      list
    end
  end
  
  def list
    @lookuplist = Lookup.find_all_by_type(params[:type])
  end  
  
  def new
    @lookup = Lookup.find_by_type(params[:type])
    @lookup.type = params[:type]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup }
    end    
  end 
  
  def create
    lookuptype = params[:type].constantize
    @lookup = lookuptype.new(params[:lookup])
    respond_to do |format|
      if params[:lookup][:lvalue].present? && @lookup.save
        flash[:notice] = "#{t(:text_lookup)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html { redirect_to(configurelookups_url(:type=>@lookup.type)) }
        format.xml  { render :xml => @lookup, :status => :created, :location => @lookup }
      else
        flash[:error] = "Value can't be blank" if params[:lookup][:lvalue].blank?
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup.errors, :status => :unprocessable_entity }
      end
    end    
  end
  
  def edit
    @lookup = Lookup.find(params[:id])
  end
  
  def update
    @lookup =  Lookup.find(params[:id])
    respond_to do |format|
      if params[:lookup][:lvalue].present? && @lookup.update_attributes(params[:lookup])
        flash[:notice] = "#{t(:text_lookup)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html { redirect_to(configurelookups_url(:type=>@lookup.type)) }
        format.xml  { head :ok }
      else
        flash[:error] = "Value can't be blank" if params[:lookup][:lvalue].blank?
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup.errors, :status => :unprocessable_entity }
      end
    end    
  end
  
end
