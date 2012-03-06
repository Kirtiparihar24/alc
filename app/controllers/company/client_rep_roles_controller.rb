class Company::ClientRepRolesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('client_rep_roles')",:only=>:index

  layout "admin"
  
  def index
  end
  
  def new
    @client_rep_role = @company.client_rep_roles.new
    render :layout=>false
  end

  def create
    @client_rep_role = ClientRepRole.new(params[:client_rep_role])
    @client_rep_role.valid?
    if  @client_rep_role.errors.empty?
      @company.client_rep_roles << @client_rep_role
    end
    render :update do |page|
      unless !@client_rep_role.errors.empty?
        page.replace_html('list', :partial =>"/company/client_rep_roles/list")
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Role was successfully created")
      else
        page.call('show_msg','nameerror',@client_rep_role.errors.on(:alvalue))
      end
    end
  end

  def edit
    @client_rep_role = ClientRepRole.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @client_rep_role = ClientRepRole.find(params[:id])
    @client_rep_role.attributes = params[:client_rep_role]
    @client_rep_role.valid?
    if @client_rep_role.errors.empty?
      @client_rep_role.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@client_rep_role.errors.empty?
            page.replace_html('list', :partial =>"/company/client_rep_roles/list")
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Role was successfully updated")
          else
            page.call('show_msg','nameerror',@client_rep_role.errors.on(:alvalue))
          end
        end
      }
    end
  end
  
end
