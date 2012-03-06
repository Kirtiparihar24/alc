class Company::CampaignStatusTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('campaign_status_types')",:only=>:index

  layout "admin"
  
  def index    
  end
  
  def new
    @campaign_status_type = @company.campaign_status_types.new
    render :layout=>false
  end

  def create
    campaign_status_types = @company.campaign_status_types
    campaign_status_typescount = campaign_status_types.count
    if campaign_status_typescount > 0
      params[:campaign_status_type][:sequence] = campaign_status_typescount+1
    end
    lvalue = params[:campaign_status_type][:lvalue].blank? ? params[:campaign_status_type][:alvalue] : params[:campaign_status_type][:lvalue]
    @campaign_status_type = @company.campaign_status_types.new(params[:campaign_status_type].merge(:lvalue=>lvalue))
    if @campaign_status_type.valid? && @campaign_status_type.errors.empty?
      campaign_status_types << @campaign_status_type      
    end
    render :update do |page|
      unless !@campaign_status_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Campaign Status Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('campaign_status_types')}';"
      else
        page.call('show_msg','nameerror',@campaign_status_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @campaign_status_type = @company.campaign_status_types.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @campaign_status_type = @company.campaign_status_types.find(params[:id])
    lvalue = params[:campaign_status_type][:lvalue].blank? ? params[:campaign_status_type][:alvalue] : params[:campaign_status_type][:lvalue]
    @campaign_status_type.attributes = params[:campaign_status_type].merge(:lvalue=>lvalue)
    if @campaign_status_type.valid? && @campaign_status_type.errors.empty?
      @campaign_status_type.save
    end
    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@campaign_status_type.errors.empty?
            active_deactive = find_model_class_data('campaign_status_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'campaign_status_types', :header=>"Campaign Status", :modelclass=> 'campaign_status_types'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('campaign_status_types')}';"
            page.call('common_flash_message_name_notice',"Campaign Status Type was successfully updated")
          else
            page.call('show_msg','nameerror',@campaign_status_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @campaign_status_type = @company.campaign_status_types.find_only_deleted(params[:id])
    unless @campaign_status_type.blank?
      @campaign_status_type.update_attribute(:deleted_at, nil)
      set_sequence_for_lookups(@company.campaign_status_types)
    end
    respond_to do |format|
      flash[:notice] = "Campaign Status Type '#{@campaign_status_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('campaign_status_types')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    campaign_status_type = @company.campaign_status_types.find(params[:id])
    mresearchlength = campaign_status_type.campaigns.length
    if mresearchlength > 0
      message = false
    else
      message = true
      campaign_status_type.destroy
      set_sequence_for_lookups(@company.campaign_status_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Campaign Status Type '#{campaign_status_type.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Campaign Status Type '#{campaign_status_type.lvalue}' can not be deactivated, #{mresearchlength} matter researches linked."
      end
      format.html { redirect_to(manage_company_utilities_path('campaign_status_types')) }
      format.xml  { head :ok }
    end
  end

end
