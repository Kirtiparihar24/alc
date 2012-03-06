class Company::NonlitiTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('nonliti_types')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @nonliti_type = @company.nonliti_types.new
    render :layout=>false
  end

  def create
    nonliti_types = @company.nonliti_types
    nonliti_typescount = nonliti_types.count
    if nonliti_typescount > 0
      params[:nonliti_type][:sequence] = nonliti_typescount+1
    end
    @nonliti_type = TypesNonLiti.new(params[:nonliti_type].merge(:lvalue=>params[:nonliti_type][:alvalue]))
    @nonliti_type.valid?
    if  @nonliti_type.errors.empty?
      nonliti_types << @nonliti_type      
    end
    render :update do |page|
      unless !@nonliti_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Non-Litigation was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('nonliti_types',:linkage=>'matters')}';"
      else
        page.call('show_msg','nameerror',@nonliti_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @nonliti_type = TypesNonLiti.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @nonliti_type = TypesNonLiti.find(params[:id])
    @nonliti_type.attributes = params[:nonliti_type].merge(:lvalue=>params[:nonliti_type][:alvalue])
    @nonliti_type.valid?
    if @nonliti_type.errors.empty?
      @nonliti_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@nonliti_type.errors.empty?
            active_deactive = find_model_class_data('nonliti_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'nonliti_types', :header=>"Non Litigation", :modelclass=> 'nonliti_types',:linkage=>'matters'})
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Non-Litigation was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('nonliti_types',:linkage=>'matters')}';"
          else
            page.call('show_msg','nameerror',@nonliti_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @nonliti_type = @company.nonliti_types.find_only_deleted(params[:id])
    unless @nonliti_type.blank?
      @nonliti_type.update_attribute(:deleted_at, nil)
      company = @nonliti_type.company
      set_sequence_for_lookups(company.nonliti_types)
    end
    respond_to do |format|
      flash[:notice] = "Non-Litigation '#{@nonliti_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('nonliti_types',:linkage=>'matters')) }
      format.xml  { head :ok }
    end
  end
  
end
