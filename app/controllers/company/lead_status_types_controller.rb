class Company::LeadStatusTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('lead_status_types')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @lead_status = @company.lead_status_types.new
    render :layout=>false
  end  
  
  def create
    lead_status_types = @company.lead_status_types
    lead_status_typescount = lead_status_types.count
    if lead_status_typescount > 0
      params[:lead_status_type][:sequence] = lead_status_typescount+1
    end
    lvalue = params[:lead_status_type][:lvalue].blank? ? params[:lead_status_type][:alvalue] : params[:lead_status_type][:lvalue]
    @lead_status = LeadStatusType.new(params[:lead_status_type].merge(:lvalue=>lvalue))
    if @lead_status.valid? && @lead_status.errors.empty?
      lead_status_types << @lead_status      
    end
    render :update do |page|
      unless !@lead_status.errors.empty?        
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Lead Status type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('lead_status_types')}';"
      else
        page.call('show_msg','nameerror',@lead_status.errors.on(:alvalue))
      end
    end
  end

  def edit
    @lead_status = LeadStatusType.find_by_id params[:id]
    render :layout=>false
  end
  
  def update
    @lead_status = LeadStatusType.find(params[:id])
    lvalue = params[:lead_status_type][:lvalue].blank? ? params[:lead_status_type][:alvalue] : params[:lead_status_type][:lvalue]
    @lead_status.attributes = params[:lead_status_type].merge(:lvalue =>lvalue)
    if @lead_status.valid? && @lead_status.errors.empty?
      @lead_status.save
    end
    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@lead_status.errors.empty?
            active_deactive = find_model_class_data('lead_status_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'lead_status_types', :header=>"Status", :modelclass=> 'lead_status_types'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('lead_status_types')}';"
            page.call('common_flash_message_name_notice',"Lead Status type was successfully updated")
          else
            page.call('show_msg','nameerror',@lead_status.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @lead_status = @company.lead_status_types.find_only_deleted(params[:id])
    unless @lead_status.blank?
      @lead_status.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.lead_status_types)
    end
    respond_to do |format|
      flash[:notice] = "Lead Status '#{@lead_status.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('lead_status_types')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    lead_status = LeadStatusType.find(params[:id])
    contactslength = lead_status.contacts.length
    if contactslength > 0
      message = false
    else
      message = true      
      lead_status.destroy
      set_sequence_for_lookups(@company.lead_status_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Lead Status '#{lead_status.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Lead Status '#{lead_status.lvalue}' can not be deactivated, #{contactslength} contacts linked."
      end
      format.html { redirect_to(manage_company_utilities_path('lead_status_types')) }
      format.xml  { head :ok }
    end
  end
  
end
