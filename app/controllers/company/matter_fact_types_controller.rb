class Company::MatterFactTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('matter_fact_types')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @matter_fact_types = @company.matter_fact_types.new
    render :layout=>false
  end  
  
  def create
    matter_fact_types = @company.matter_fact_types
    matter_fact_typescount = matter_fact_types.count
    if matter_fact_typescount > 0
      params[:matter_fact_type][:sequence] = matter_fact_typescount+1
    end
    @matter_fact_types = MatterFactType.new(params[:matter_fact_type].merge(:lvalue =>params[:matter_fact_type][:alvalue]))
    if @matter_fact_types.valid? && @matter_fact_types.errors.empty?
      matter_fact_types << @matter_fact_types     
    end
    render :update do |page|
      unless !@matter_fact_types.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Matter Fact Type was successfully created")        
        page<<"window.location.href='#{manage_company_utilities_path('matter_fact_types',:linkage=>'matter_fact_types')}';"
      else
        page.call('show_msg','nameerror',@matter_fact_types.errors.on(:alvalue))
      end
    end
  end

  def edit
    @matter_fact_types = MatterFactType.find_by_id params[:id]
    render :layout=>false
  end
  
  def update
    @matter_fact_types = MatterFactType.find(params[:id])
    @matter_fact_types.attributes = params[:matter_fact_type].merge(:lvalue=>params[:matter_fact_type][:alvalue])
    if @matter_fact_types.valid? && @matter_fact_types.errors.empty?
      @matter_fact_types.save
    end    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@matter_fact_types.errors.empty?
            active_deactive = find_model_class_data('matter_fact_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'matter_fact_types', :header=>"Matter Fact Type", :modelclass=> 'matter_fact_types',:linkage=>'matter_fact_types'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('matter_fact_types',:linkage=>'matter_fact_types')}';"
            page.call('common_flash_message_name_notice',"Matter Fact Type was successfully updated")
          else
            page.call('show_msg','nameerror',@matter_fact_types.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @matter_fact_type = @company.matter_fact_types.find_only_deleted(params[:id])
    unless @matter_fact_type.blank?
      @matter_fact_type.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.matter_fact_types)
    end
    respond_to do |format|
      flash[:notice] = "Matter Fact Type '#{@matter_fact_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('matter_fact_types',:linkage=>'matter_fact_types')) }
      format.xml  { head :ok }
    end
  end
  
end
