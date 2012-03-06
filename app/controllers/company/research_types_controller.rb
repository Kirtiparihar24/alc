class Company::ResearchTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('research_types')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @research_type = @company.research_types.new
    render :layout=>false
  end

  def create
    research_types = @company.research_types
    researchcount = research_types.count
    if research_types.count > 0
      params[:research_type][:sequence] = researchcount+1
    end
    @research_type = ResearchType.new(params[:research_type].merge(:lvalue=>params[:research_type][:alvalue]))
    @research_type.valid?
    if  @research_type.errors.empty?
      research_types << @research_type      
    end
    render :update do |page|
      unless !@research_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Research Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('research_types',:linkage=>"matter_researches")}';"
      else
        page.call('show_msg','nameerror',@research_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @research_type = ResearchType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @research_type = ResearchType.find(params[:id])
    @research_type.attributes = params[:research_type].merge(:lvalue=>params[:research_type][:alvalue])
    @research_type.valid?
    if @research_type.errors.empty?
      @research_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@research_type.errors.empty?
            active_deactive = find_model_class_data('research_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'research_types', :header=>"Research Type", :modelclass=> 'research_types',:linkage=>"matter_researches"})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Research Type was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('research_types',:linkage=>"matter_researches")}';"
          else
            page.call('show_msg','nameerror',@research_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @research_type = @company.research_types.find_only_deleted(params[:id])
    unless @research_type.blank?
      @research_type.update_attribute(:deleted_at, nil)
      company = @research_type.company
      set_sequence_for_lookups(company.research_types)
    end
    respond_to do |format|
      flash[:notice] = "Research Type '#{@research_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('research_types',:linkage=>"matter_researches")) }
      format.xml  { head :ok }
    end
  end
  
end