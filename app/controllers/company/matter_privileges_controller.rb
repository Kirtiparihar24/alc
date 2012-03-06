class Company::MatterPrivilegesController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('matter_privileges')",:only=>:index

  layout "admin"
  
  def index
  end

  def new
    @matter_privilege = @company.matter_privileges.new
    render :layout=>false
  end  
  
  def create
    matter_privileges = @company.matter_privileges
    matter_privilegescount = matter_privileges.count
    if matter_privilegescount > 0
      params[:matter_privilege][:sequence] = matter_privilegescount+1
    end
    lvalue = params[:matter_privilege][:lvalue].blank? ? params[:matter_privilege][:alvalue] : params[:matter_privilege][:lvalue]
    @matter_privilege = MatterPrivilege.new(params[:matter_privilege].merge(:lvalue=>lvalue))
    if @matter_privilege.valid? && @matter_privilege.errors.empty?
      matter_privileges << @matter_privilege      
    end
    render :update do |page|
      unless !@matter_privilege.errors.empty?
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice',"Matter Privilege was successfully created")
        page<<"window.location.href='#{manage_company_utilities_path('matter_privileges')}';"
      else
        page.call('show_msg','nameerror',@matter_privilege.errors.on(:alvalue))
      end
    end
  end

  def edit
    @matter_privilege = MatterPrivilege.find_by_id params[:id]
    render :layout=>false
  end
  
  def update
    @matter_privilege = MatterPrivilege.find(params[:id])
    lvalue = params[:matter_privilege][:lvalue].blank? ? params[:matter_privilege][:alvalue] : params[:matter_privilege][:lvalue]
    @matter_privilege.attributes = params[:matter_privilege].merge(:lvalue=>lvalue)
    if @matter_privilege.valid? && @matter_privilege.errors.empty?
      @matter_privilege.save
    end
    
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@matter_privilege.errors.empty?
            active_deactive = find_model_class_data('matter_privileges')
            page.replace_html("list", :partial => "company/list", :locals => {:active_entries => active_deactive[0], :deactive_entries => active_deactive[1], :table_id => 'matter_privileges', :header=>"Matter Privileges", :modelclass=> 'matter_privileges'})
            page<< 'tb_remove();'
            page<<"window.location.href='#{manage_company_utilities_path('matter_privileges')}';"
            page.call('common_flash_message_name_notice',"Matter Privilege was successfully updated")
          else
            page.call('show_msg','nameerror',@matter_privilege.errors.on(:alvalue))
          end
        end
      }
    end
  end

  # This action is specially added for activating the deactivated record.
  # CRUD :: is used for avoiding the extra actions in routes and controller. as the show actions are already not used in the portal.
  # Supriya Surve - 24th May 2011 - 08:17
  def show
    @matter_privilege = @company.matter_privileges.find_only_deleted(params[:id])
    unless @matter_privilege.blank?
      @matter_privilege.update_attribute(:deleted_at, nil)      
      set_sequence_for_lookups(@company.matter_privileges)
    end
    respond_to do |format|
      flash[:notice] = "Matter Privilege '#{@matter_privilege.lvalue}' is successfully activated."
      format.html { redirect_to(manage_company_utilities_path('matter_privileges')) }
      format.xml  { head :ok }
    end
  end

  # This action is specially used for de-activating the record.
  # Supriya Surve - 24th May 2011 - 08:17
  def destroy
    matter_privilege = @company.matter_privileges.find(params[:id])
    documentslength = Document.find(:all, :conditions => ["company_id = #{@company.id} and privilege = '#{params[:id]}'"]).length    
    if documentslength > 0
      message = false
    else
      message = true
      matter_privilege.destroy
      set_sequence_for_lookups(@company.matter_privileges)
    end
    respond_to do |format|
      if message
        flash[:notice] = "Matter Privilege '#{matter_privilege.lvalue}' is successfully deactivated."
      else
        flash[:error] = "Matter Privilege '#{matter_privilege.lvalue}' can not be deactivated, #{documentslength} documents linked."
      end
      format.html { redirect_to(manage_company_utilities_path('matter_privileges')) }
      format.xml  { head :ok }
    end
  end
  
end
