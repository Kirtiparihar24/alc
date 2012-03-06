class Company::ClientRolesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('client_roles')",:only=>:index

  layout "admin"

  def index
  end
  
  def new
    @client_role = @company.client_roles.new
    render :layout=>false
  end

  def create   
    client_roles = @company.client_roles
    clientrole_count = client_roles.length
    if clientrole_count > 0
      params[:client_role][:sequence] = clientrole_count+1
    end
    lvalue = ClientRole.check_and_assign_lvalue(params[:client_role],params[:original_lvalue])
    @client_role = ClientRole.new(params[:client_role].merge(:lvalue=>lvalue))
    @client_role.valid?
    if  @client_role.errors.empty?
      @company.client_roles << @client_role      
    end
    render :update do |page|
      unless !@client_role.errors.empty?        
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Role was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('client_roles')}';"
      else
        page.call('show_msg','nameerror',@client_role.errors.on(:alvalue))
      end
    end
  end

  def edit
    @client_role = ClientRole.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @client_role = ClientRole.find(params[:id])
    lvalue = ClientRole.check_and_assign_lvalue(params[:client_role],params[:original_lvalue])
    @client_role.attributes = params[:client_role].merge(:lvalue=>lvalue)
    @client_role.valid?
    if @client_role.errors.empty?
      @client_role.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@client_role.errors.empty?          
          active_deactive = find_model_class_data('client_roles')
          page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'client_roles', :header=>"Client Role", :modelclass=> 'client_roles'})
          page<< 'tb_remove();'          
          page<<"window.location.href='#{manage_company_utilities_path('client_roles')}';"
          page.call('common_flash_message_name_notice', "Role was successfully updated")
        else
            page.call('show_msg','nameerror',@client_role.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @client_role = @company.client_roles.find_only_deleted(params[:id])
    unless @client_role.blank?
      @client_role.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.client_roles)
    end
    respond_to do |format|
      flash[:notice] = "Client Role '#{@client_role.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('client_roles')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    client_role = @company.client_roles.find(params[:id])
    peoplelength = MatterPeople.find(:all, :conditions => ["company_id = #{@company.id} and matter_team_role_id=#{params[:id]}"]).length
    if peoplelength > 0
      message = false
    else
      message = true
      client_role.destroy
      set_sequence_for_lookups(@company.client_roles)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Client Role '#{client_role.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Client Role '#{client_role.lvalue}' can not be deactivated, #{peoplelength} Matter People linked."
      end
      format.html { redirect_to(manage_company_utilities_path('client_roles')) }
      format.xml  { head :ok }
    end
  end
  
end
