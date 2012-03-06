class Company::ProspectStatusTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('prospect_status_types')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @prospect_status = @company.prospect_status_types.new
    render :layout=>false
  end  

  def create
    prospect_status_types = @company.prospect_status_types
    prospect_status_typescount = prospect_status_types.count
    if prospect_status_typescount > 0
      params[:prospect_status_type][:sequence] = prospect_status_typescount+1
    end
    lvalue = params[:prospect_status_type][:lvalue].blank? ? params[:prospect_status_type][:alvalue] : params[:prospect_status_type][:lvalue]
    @prospect_status = ProspectStatusType.new(params[:prospect_status_type].merge(:lvalue =>lvalue))
    if @prospect_status.valid? && @prospect_status.errors.empty?
      prospect_status_types << @prospect_status
    end
    render :update do |page|
      unless !@prospect_status.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Prospect Status type was successfully created")        
        page<<"window.location.href='#{manage_company_utilities_path('prospect_status_types')}';"
      else
        page.call('show_msg','nameerror',@prospect_status.errors.on(:alvalue))
      end
    end
  end
  
  def edit
    @prospect_status = ProspectStatusType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @prospect_status = ProspectStatusType.find(params[:id])
    lvalue = params[:prospect_status_type][:lvalue].blank? ? params[:prospect_status_type][:alvalue] : params[:prospect_status_type][:lvalue]
    @prospect_status.attributes = params[:prospect_status_type].merge(:lvalue =>lvalue)
    if @prospect_status.valid? && @prospect_status.errors.empty?
      @prospect_status.save
    end    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@prospect_status.errors.empty?
            active_deactive = find_model_class_data('prospect_status_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'prospect_status_types', :header=>"Status", :modelclass=> 'prospect_status_types'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('prospect_status_types')}';"
            page.call('common_flash_message_name_notice',"Prospect Status type was successfully updated")
          else
            page.call('show_msg','nameerror',@prospect_status.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @prospect_status = @company.prospect_status_types.find_only_deleted(params[:id])
    unless @prospect_status.blank?
      @prospect_status.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.prospect_status_types)
    end
    respond_to do |format|
      flash[:notice] = "Prospect Status '#{@prospect_status.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('prospect_status_types')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    prospect_status = @company.prospect_status_types.find(params[:id])
    contactslength = prospect_status.contacts.length
    if contactslength > 0
      message = false
    else
      message = true
      prospect_status.destroy
      set_sequence_for_lookups(@company.prospect_status_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Prospect Status '#{prospect_status.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Prospect Status '#{prospect_status.lvalue}' can not be deactivated, #{contactslength} contacts linked."
      end
      format.html { redirect_to(manage_company_utilities_path('prospect_status_types')) }
      format.xml  { head :ok }
    end
  end
  
end
