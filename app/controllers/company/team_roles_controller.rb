class Company::TeamRolesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('team_roles')",:only=>:index

  layout "admin"
   
  def index
  end
  
  def new
    @team_role = @company.team_roles.new
    render :layout=>false
  end

  def create
    team_roles = @company.team_roles
    team_rolescount = team_roles.count
    if team_rolescount > 0
      params[:team_role][:sequence] = team_rolescount+1
    end
    @team_role = TeamRole.new(params[:team_role].merge(:lvalue=>params[:team_role][:alvalue]))
    @team_role.valid?
    if  @team_role.errors.empty?
      @company.team_roles << @team_role      
    end
    render :update do |page|
      unless !@team_role.errors.empty?
        page<< 'tb_remove();'
        
        page.call('common_flash_message_name_notice', "Role was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('team_roles',:linkage=>"matter_peoples")}';"
      else
        page.call('show_msg','nameerror',@team_role.errors.on(:alvalue))
      end
    end
  end

  def edit
    @team_role = TeamRole.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @team_role = TeamRole.find(params[:id])
    @team_role.attributes = params[:team_role].merge(:lvalue=>params[:team_role][:alvalue])
    @team_role.valid?
    if @team_role.errors.empty?
      @team_role.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@team_role.errors.empty?
            active_deactive = find_model_class_data('team_roles')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'team_roles', :header=>"Team Role", :modelclass=> 'team_roles',:linkage=>"matter_peoples"})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('team_roles',:linkage=>"matter_peoples")}';"
            page.call('common_flash_message_name_notice', "Role was successfully updated")
          else
            page.call('show_msg','nameerror',@team_role.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @team_role = @company.team_roles.find_only_deleted(params[:id])
    unless @team_role.blank?
      @team_role.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.team_roles)
    end
    respond_to do |format|
      flash[:notice] = "Team Role '#{@team_role.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('team_roles',:linkage=>"matter_peoples")) }
      format.xml  { head :ok }
    end
  end
  
end
