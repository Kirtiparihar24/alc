class Company::OtherRolesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('other_roles')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @other_role = @company.other_roles.new
    render :layout=>false
  end

  def create
    other_roles = @company.other_roles
    other_rolescount = other_roles.count
    if other_rolescount > 0
      params[:client_role][:sequence] = other_rolescount+1
    end
    @other_role = OtherRole.new(params[:client_role])
    @other_role.valid?
    if  @other_role.errors.empty?
      other_roles << @other_role
    end
    render :update do |page|
      unless !@other_role.errors.empty?
        page.replace_html('list', :partial =>"/company/other_roles/list")
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Role was successfully created")
      else
        page.call('show_msg','nameerror',@other_role.errors.on(:alvalue))
      end
    end
  end

  def edit
    @other_role = OtherRole.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @other_role = OtherRole.find(params[:id])
    @other_role.attributes = params[:client_role]
    @other_role.valid?
    if @other_role.errors.empty?
      @other_role.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
        unless !@other_role.errors.empty?
          page.replace_html('list', :partial =>"/company/other_roles/list")
          page<< 'tb_remove();'
          page.call('common_flash_message_name_notice', "Role was successfully updated")
        else
            page.call('show_msg','nameerror',@other_role.errors.on(:alvalue))
          end
        end
      }
    end
  end
  
end
