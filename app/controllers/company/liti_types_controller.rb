class Company::LitiTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('liti_types')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @liti_type = @company.liti_types.new
    render :layout=>false
  end

  def create
    liti_types = @company.liti_types
    liti_typescount = liti_types.count
    if liti_typescount > 0
      params[:liti_type][:sequence] = liti_typescount+1
    end
    @liti_type = TypesLiti.new(params[:liti_type].merge(:lvalue=>params[:liti_type][:alvalue]))
    if  @liti_type.errors.empty?
      liti_types << @liti_type
    end
    render :update do |page|
      unless !@liti_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Litigation was successfully created")
        
        page<<"window.location.href='#{manage_company_utilities_path('liti_types',:linkage=>"matters")}';"
      else
        page.call('show_msg','nameerror',@liti_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @liti_type = TypesLiti.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @liti_type = TypesLiti.find(params[:id])
    @liti_type.attributes = params[:liti_type].merge(:lvalue=>params[:liti_type][:alvalue])
    @liti_type.valid?
    if @liti_type.errors.empty?
      @liti_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@liti_type.errors.empty?
            active_deactive = find_model_class_data('liti_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'liti_types', :header=>"Litigation", :modelclass=> 'liti_types',:linkage=>'matters'})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Litigation was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('liti_types',:linkage=>"matters")}';"
          else
            page.call('show_msg','nameerror',@liti_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @liti_type = @company.liti_types.find_only_deleted(params[:id])
    unless @liti_type.blank?
      @liti_type.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.liti_types)
    end
    respond_to do |format|
      flash[:notice] = "Litigation '#{@liti_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('liti_types',:linkage=>"matters")) }
      format.xml  { head :ok }
    end
  end
end
