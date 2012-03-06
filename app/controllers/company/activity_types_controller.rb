class Company::ActivityTypesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('activity_types')",:only=>:index

  layout "admin"

  def index
    @activity_types = @company.activity_types
  end

  def new
    @activity_type = @company.activity_types.new
    render :layout=>false
  end

  def create
    activity_types = @company.activity_types
    activity_typescounts = activity_types.count
    if activity_typescounts > 0
      params[:activity_type][:sequence] = activity_typescounts+1
    end
    @activity_type = Physical::Timeandexpenses::ActivityType.new(params[:activity_type].merge(:lvalue=>params[:activity_type][:alvalue]))
    @activity_type.valid?
    if  @activity_type.errors.empty?
      activity_types << @activity_type      
    end
    render :update do |page|
      unless !@activity_type.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Activity Type was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('activity_types',:linkage=>"time_entries")}';"
      else
        page.call('show_msg','nameerror',@activity_type.errors.on(:alvalue))
      end
    end
  end

  def edit
    @activity_type = Physical::Timeandexpenses::ActivityType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @activity_type = Physical::Timeandexpenses::ActivityType.find(params[:id])
    @activity_type.attributes = params[:activity_type].merge(:lvalue=>params[:activity_type][:alvalue])
    @activity_type.valid?
    if @activity_type.errors.empty?
      @activity_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@activity_type.errors.empty?
            active_deactive = find_model_class_data('activity_types')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'activity_types', :header=>"Activity Type", :modelclass=> 'activity_types',:linkage=>"time_entries"})
            page<< 'tb_remove();'
            raw page.call('common_flash_message_name_notice', "Activity Type was successfully updated")            
            page<<"window.location.href='#{manage_company_utilities_path('activity_types',:linkage=>"time_entries")}';"
          else
            page.call('show_msg','nameerror',@activity_type.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @activity_type = @company.activity_types.find_only_deleted(params[:id])
    unless @activity_type.blank?
      @activity_type.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.activity_types)
    end
    respond_to do |format|
      flash[:notice] = "Activity Type '#{@activity_type.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('activity_types',:linkage=>"time_entries")) }
      format.xml  { head :ok }
    end
  end

end
