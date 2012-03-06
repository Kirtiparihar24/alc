class Company::OpportunityStageTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('opportunity_stage_types')",:only=>:index

  layout "admin"
  
  def index
  end

  def new
    @opportunity_stage = @company.opportunity_stage_types.new
    render :layout=>false
  end  
  
  def create
    opportunity_stage_types = @company.opportunity_stage_types
    opportunity_stage_typescount = opportunity_stage_types.count
    if opportunity_stage_typescount > 0
      params[:opportunity_stage_type][:sequence] = opportunity_stage_typescount+1
    end
    lvalue = params[:opportunity_stage_type][:lvalue].blank? ? params[:opportunity_stage_type][:alvalue] : params[:opportunity_stage_type][:lvalue]
    @opportunity_stage = OpportunityStageType.new(params[:opportunity_stage_type].merge(:lvalue=>lvalue))
    if @opportunity_stage.valid? && @opportunity_stage.errors.empty?
      opportunity_stage_types << @opportunity_stage      
    end
    render :update do |page|
      unless !@opportunity_stage.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Opportunity Stage was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('opportunity_stage_types')}';"
      else        
        format_ajax_errors(@opportunity_stage, page, 'nameerror')
      end
    end
  end

  def edit
    @opportunity_stage = OpportunityStageType.find_by_id params[:id]
    render :layout=>false
  end
  
  def update
    @opportunity_stage = OpportunityStageType.find(params[:id])
    lvalue = params[:opportunity_stage_type][:lvalue].blank? ? params[:opportunity_stage_type][:alvalue] : params[:opportunity_stage_type][:lvalue]
    @opportunity_stage.attributes = params[:opportunity_stage_type].merge(:lvalue=>lvalue)
    if @opportunity_stage.valid? && @opportunity_stage.errors.empty?
      @opportunity_stage.save
    end    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@opportunity_stage.errors.empty?
            active_deactive = find_model_class_data('opportunity_stage_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'opportunity_stage_types', :header=>"Stage Type", :modelclass=> 'opportunity_stage_types'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('opportunity_stage_types')}';"
            page.call('common_flash_message_name_notice',"Opportunity Stage was successfully updated")
          else
            format_ajax_errors(@opportunity_stage, page, 'nameerror')
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @opportunity_stage = @company.opportunity_stage_types.find_only_deleted(params[:id])
    unless @opportunity_stage.blank?
      @opportunity_stage.update_attribute(:deleted_at, nil)
      company = @opportunity_stage.company
      set_sequence_for_lookups(company.opportunity_stage_types)
    end
    respond_to do |format|
      flash[:notice] = "Opportunity Stage '#{@opportunity_stage.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('opportunity_stage_types')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    opportunity_stage = @company.opportunity_stage_types.find(params[:id])
    oppslength = opportunity_stage.opportunities.length
    if oppslength > 0
      message = false
    else
      message = true
      company = opportunity_stage.company
      opportunity_stage.destroy
      set_sequence_for_lookups(company.opportunity_stage_types)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Opportunity Stage '#{opportunity_stage.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Opportunity Stage '#{opportunity_stage.lvalue}' can not be deactivated, #{oppslength} opportunities linked."
      end
      format.html { redirect_to(manage_company_utilities_path('opportunity_stage_types')) }
      format.xml  { head :ok }
    end
  end
    
end
