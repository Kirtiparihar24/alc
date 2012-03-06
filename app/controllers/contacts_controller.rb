# ContactsModule is responsible for managing the contacts of the lawyer. Contacts can be of type lead prospect and client
class ContactsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :current_service_session_exists
  before_filter :get_base_data
  rescue_from ActionController::UnknownAction, :with => :no_action_handled_contacts
  rescue_from ActiveRecord::RecordNotFound, :with => :check_show_error_contacts
  load_and_authorize_resource :except => [:activate_contact, :deactivate_contact,:contact_notes, :edit,:ask_activate_account]
  verify :method => :post , :only => [:create, :save_status] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  layout 'full_screen', :except =>[:new, :edit, :create, :update]
  before_filter :get_report_favourites ,:only => [:index,:new,:edit]
  before_filter :fetch_employee_user_id,:only=>[:index,:create,:update,:upload,:link_existing_or_created_account]
  before_filter :find_user_not_admin_not_client,:only=>[:new,:create,:edit,:update,:create_opportunity,:link_existing_or_created_account]
  add_breadcrumb I18n.t(:text_menu_contacts), :contacts_path
  before_filter :current_company_sources, :current_company_phone_type, :only => [:new, :create, :edit, :update]
  before_filter :current_company_contact_stages, :only => [:index, :new, :create, :edit, :update, :change_status, :modal_new_form, :display_selected_contact]
  helper_method :remember_past_path,:remember_past_edit_path  

  def create_matter_contact
    comp=current_company   
    params[:contact].merge!(:assigned_to_employee_user_id=> get_employee_user_id,
      :created_by_user_id => get_employee_user_id)
    @contact = comp.contacts.new(params[:contact])
    flag=unique_email(@contact,params)
    respond_to do |format|
      format.js {
        render :update do |page|         
          if flag && @contact.save
            page << "tb_remove();"
            if params[:account_id].present?
              AccountContact.find_or_create_by_contact_id_and_account_id(@contact.id, params[:account_id].to_i)
              account_contacts = Account.find(params[:account_id].to_i).contacts.find(:all, :order => "contacts.id desc")
              page.replace_html 'contacts', :partial => '/matters/account_contacts', :locals => {:new => false,:account_contacts => account_contacts }
            else
              page.replace_html 'contacts', :partial => '/matters/account_contacts', :locals => {:new => true }
              page << "savedMatterContact(#{@contact.id}, '#{escape_javascript(@contact.full_name)}')"
            end
          else
            if @same_contacts.present?
              unless @exist_but_deleted
                s = %Q!<div class="matter_contact_errors" style="width: 450px;height: 100px;overflow-y:auto;overflow-x:hidden;"><span class="fl">Following contacts already have same email address or phone number:</span><br class="clear"/><ul>!
                @same_contacts.each do|sec|
                  s += "<li>#{sec.full_name}- #{sec.email} #{sec.phone}</li>"
                end
                s += "</ul>"
                s += %Q!<input type="checkbox" value="1" name="allow_dup" style="width:15px;" /> Allow duplicate</div>!
              else
                s = %Q!<div class="message_warning_div"><span class="fl">Following contact already exist in the deactivated list  </span><br class="clear"/><ul>!
                @same_contacts.each do|sec|
                  s += "<li>#{sec.full_name}- #{sec.email} #{sec.phone}</li>"
                  s += "<li>#{sec.accounts[0].try(:name)}</li>" if sec.accounts.present?
                end
                s += "</ul>"
                s += %Q!<input type="hidden" value="#{@deleted_cnt_id}" name="deleted_contact_id" style="width:15px;"/>!
                s += %Q!<input type="checkbox" value="1" name="activate" style="width:15px;" /> Activate</div>!
              end              
              page << "show_error_msg('matter_contact_errors','#{escape_javascript(s)}','message_warning_div');"
            else
              s = "<ul>" + @contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_contact_errors','#{s}','message_error_div');"
            end            
            if @contact.email.present?
              page<<"jQuery('#contact_email').val('#{@contact.email}');"
            else
              page<<"jQuery('#contact_email').val('');"
            end
          end
          page<<"jQuery('#loader').hide();"
        end
      }
    end
  end

  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'contacts.last_name', :dir => 'up', :search_item => 'true')
    end
    params[:search] ||= {} #Added to reduce the conditions in feature 9718 for dropdown in filter search -- Kushal.Dongre
    cuser = get_employee_user
    if cuser.employee.my_contacts == true
      @mode_type = (params[:mode_type]= 'MY')
      flash[:notice]="You are configured to view details only of My Contacts"
    elsif(params[:mode_type] == nil)
      @mode_type= 'MY'
      params.merge!(:mode_type=>'MY')
    else
      @mode_type= params[:mode_type]
    end
    @icon = params[:dir].eql?("up") ? 'sort_asc':'sort_desc'
    sort_column_order
    set_params_filter        
    comp_order = "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc"
    params[:order] = @ord.nil?? comp_order : @ord
    @contacts = Contact.get_contacts(params, @company ,@employee_user_id)
    @pagenumber=128    
  end

  def attendees_autocomplete
    email = "#{params[:q]}"    
    if email.strip == ''
      @atnds_emails = []
      @company.contacts.all(:select => 'email').collect {|e| @atnds_emails << e.email}
      @company.users.all(:select => 'email').collect {|e| @atnds_emails << e.email}
      @attnds_emails.compact unless @attnds_emails.blank?
      render :text => @atnds_emails.join("\n")
    else      
      @atnds_emails = []     
      contact_email = @company.contacts.search email, :star => true, :limit => 10000
      contact_email.collect{|e| @atnds_emails << e.email unless e.blank?}
      email = "%#{email}%"
      @company.users.all(:conditions => ["email iLike ?", email], :select => :email).collect {|e| @atnds_emails << e.email}
      render :text => @atnds_emails.join("\n")
    end
  end

  def new    
    @contact = Contact.new
    @account =  Account.new
    @total_open_invoices = 0
    @contact_additional_field = @contact.build_contact_additional_field(:company_id=> @company.id)
    @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? ', "Lead"])
    @contact.build_address(:company_id=> @company.id)
    @pagenumber = 19
    add_breadcrumb "#{t(:text_new)} #{t(:text_contact)}", new_contact_path
    respond_to do |format|
      format.html {render :layout => "left_with_tabs"}
    end
  end  

  def create    
    params.merge!(Contact.params_to_create_contact(params,@employee_user_id,@current_user.id,@company.id))
    @contact = Contact.new(params[:contact])
    account_error = true
    if params[:account]      
      account = Account.new(params[:account])      
      account_error = unique_name(account)
    end
    if account_error && @contact.valid? && unique_email(@contact,params) && @contact.save_with_account(params, @employee_user_id)
      flash[:notice] = "#{t(:text_contact)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"   
      redirect_if(params[:button_pressed].eql?("save"), "#{edit_contact_path(@contact.id)}?#{params[:divid]}")
      redirect_if(params[:button_pressed].eql?("save_exit"), contacts_path)
    else
      @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? ', "Lead"])
      @account                   =  @contact.accounts.first || Account.new()
      respond_to do |format|
        format.html{  render :action=>"new" , :contact => @contact, :account => @account,:layout => "left_with_tabs"}
      end    
    end
  end

  def edit   
    @contact =  @company.contacts.find(params[:id])
    session[:contact_stage_id] = @contact.contact_stage_id
    session[:search] = params[:search]
    #    if @contact.deleted_at.blank?
    @account = @contact.get_account
    @contact.contact_additional_field =  ContactAdditionalField.find_or_create_by_contact_id_and_company_id(@contact.id, @company.id)
    @contact.address = Address.find_or_create_by_contact_id_and_company_id(@contact.id,@company.id)
    @non_matter_open_invoice,@matter_open_invoice,@total_open_invoices = Contact.get_open_invoices(@company,@contact)
    @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? ', "Lead"])
    @pagenumber = 19
    add_breadcrumb "#{t(:text_edit)} #{t(:text_contact)}", edit_contact_path(@contact)
    respond_to do |format|
      format.html {render :layout => "left_with_tabs"}
    end
    #    else
    #      flash[:error] ="#{t(:flash_contact_has_been_deactivated)}"
    #      redirect_to :action => "index"
    #    end
  end
  
  def update    
    params.merge!(Contact.params_to_update_contact(params,@employee_user_id,@current_user.id,@company.id))
    @contact = Contact.find(params[:id], :include => [:address, {:account_contacts => :account}, :comments])
    @account = @contact.get_account || Account.new
    account_uniq = true
    if params[:account]
      account = Account.new(params[:account])
      account_uniq = unique_name(account)
    end
    if account_uniq && unique_email(@contact,params) && @contact.update_with_account(params,@employee_user_id)
      flash[:notice] = "#{t(:text_contact)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      redirect_if(params[:button_pressed].eql?("save"), (remember_past_edit_path(@contact)))
      # Below logic contain hidden variable which passed from the edit view to identify the request_uri
      # as this page is access from accounts eit page and contact edit page
      # By Ajay Arsud on 15 th Sep 2010.
      redirect_if(params[:button_pressed].eql?("save_exit"), (remember_past_path))
      session[:contact_stage_id] = nil
      session[:search] = nil
    else
      @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? ', "Lead"])
      respond_to do |format|
        format.html{ render :action => 'edit', :contact => @contact, :account => @account, :layout => "left_with_tabs"}
      end
    end
  end

  #This method is used to change the status of contact
  def change_status
    session[:search] = params[:search]
    @contact=Contact.scoped_by_company_id(@company.id).find(params[:id], :include => :contact_stage)
    if request.get?   
      @status = @contact_stages.collect{|status| [status.alvalue,status.id] unless status.id == @contact.contact_stage_id}.compact
      render :layout => false
    else      
      status_type = params[:contact][:contact_stage_id].eql?(@company.contact_stages.array_hash_value('lvalue','Lead','id').to_s) ? current_company.lead_status_types.find_by_lvalue("New").id : current_company.prospect_status_types.find_by_lvalue("Active").id
      @contact.contact_stage_id = params['contact']['contact_stage_id'].to_i
      @contact.reason = params['notes']['comment'].strip
      @contact.updated_by_user_id = @current_user.id
      @contact.status_type = status_type
      if  params['notes']['comment'].strip.present? && @contact.save(false)
        flash[:notice] = "#{t(:text_status)} " "For #{@contact.name} Contact Is " "#{t(:flash_update)}"        
      end   
      respond_to do |format|
        format.html{redirect_to remember_past_path
          session[:search]=nil
        }
      end
    end
  end

  def deactivate_contact
    authorize!(:deactivate_contact,@current_user) unless @current_user.has_access?(:Contacts)
    @contact=Contact.scoped_by_company_id(@company.id).find_with_deleted(params[:id])
    unless params[:flag].present?
      @contact.deactivate_contact(current_user)
      flash[:notice] = "#{t(:text_contact)} " "#{t(:flash_was_successful)} " "Deleted."
      respond_to do |format|
        format.html{ redirect_to contacts_path(:mode_type=> params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:search_items => params[:search_items] , :q=>params[:q],:col=>params[:col],:dir=>params[:dir],:contact_type =>params[:contact_type])}
      end
    else
      @contact.delete_contact(current_user)
      flash[:notice] = "#{t(:text_contact)} " "#{t(:flash_was_successful)} " "Deleted."
      respond_to do |format|
        format.html{ redirect_to contacts_path(:mode_type=> params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search] ,:search_items => params[:search_items] , :q=>params[:q],:col=>params[:col],:dir=>params[:dir],:contact_type =>params[:contact_type],:contact_status=>params[:contact_status])}
      end
    end
  end

  #This method is used to activating the deactivate contacts
  def activate_contact
    authorize!(:activate_contact,@current_user) unless @current_user.has_access?(:Contacts)
    @contact = Contact.scoped_by_company_id(@company.id).find_with_deleted(params[:id],:include =>[:company, :contact_stage])
    retVal =  @contact.activate_contact(@current_user,params)
    if retVal.errors.blank?
      flash[:notice] = "#{t(:text_contact)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
    else
      errmsg = retVal.errors.full_messages.join("\n")
      flash[:error] =  errmsg
    end
    respond_to do |format|
      format.html{  redirect_to contacts_path(:contact_status=>'rejected',:mode_type=> params[:mode_type])}
      format.js{  redirect_to contacts_path(:contact_status=>'rejected',:mode_type=> params[:mode_type])}
    end
  end

  def ask_activate_account
    @contact = Contact.scoped_by_company_id(@company.id).find_with_deleted(params[:id],:include =>[:company, :contact_stage])
    @deleted_acc = Account.find_with_deleted(@contact.account_contacts.find_only_deleted(:first).account_id) if @contact.account_contacts.find_only_deleted(:first)
    render :layout => false
  end

  #This method creating contact from opportunity
  def create_opportunity
    if request.get?
      @campaigns = @company.campaigns.all(:select => 'id, name')
      @opportunity = Opportunity.new     
    end
    if request.post?
      params[:opportunity].merge!(:employee_user_id=>@employee_user_id,:company_id=>@company.id,:created_by_user_id=> @current_user.id)
      @opportunity = @company.opportunities.create(params[:opportunity])
      if @opportunity.errors.blank?
        flash[:notice] = "New #{t(:text_opportunity)} " " for #{ @opportunity.contact.name} " "Contact #{t(:flash_was_successful)} " "#{t(:text_created)}"
      else
        flash[:error] =  @opportunity.errors.full_messages.join("\n")
      end
    end
    request.get? ? (render :partial=>'create_opportunity') : (redirect_to :back)    
  end

  #This method used to display the contact search results
  def common_contact_search
    data=params
    @matching_contacts =[]
    query = data[:q]
    if data[:ctl] == 'accounts'
      if query.strip == ''
        id_list = AccountContact.all(:select => 'contact_id').collect{ |obj| obj.contact_id }        
        @matching_contacts = Contact.all(:conditions => ["id NOT IN (?) AND company_id = ?",id_list,@company.id], :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') ASC")
      else
        @matching_contacts = Contact.current_company(@company.id).search "*" + data[:q] + "*", :with => {:contact_account_id => 0}, :limit => 10000
      end
    else
      if query.strip == ''
        @matching_contacts = @company.contacts.all(:order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') ASC")
      else         
        @matching_contacts = @company.contacts.search "*" + data[:q] + "*",  :limit => 10000
      end
    end       
    render :partial=> 'common_contact_search', :object => @matching_contacts 
  end


  def link_account
    employee_user_id = get_employee_user_id
    @contact =  @company.contacts.find(params[:id])
    if request.post?
      params[:account].merge!(:current_user_name=> get_user_name,:employee_user_id=>@employee_user_id,:company_id=>current_company.id,:created_by_user_id=> current_user.id)
      @account=Account.new(params[:account]) if params[:account].has_key?(:name)
      respond_to do |format|
        format.js {
          render :update do |page|
            if ((params[:account].has_key?(:name) ?  (!@account.valid? && !@account.errors.on(:name)) : true) && @contact.save_with_account(params,employee_user_id))
              flash[:notice] = "Contact successfully linked with Account"
              page << "tb_remove()"
              page << "window.location.reload()"
            else         
              @contact.errors.add_to_base("This Account is already present in the system") if @account && @account.errors.present?
              show_errors_on_tb(@contact, page, "one_field_error_div")
            end
          end
        }
      end
    else
      render :layout=>false
    end
  end

  #Sphinx contact search method
  #TODO please change the scenario to find the record by the ID -- as per Srikanth Sir instruction these kind of changes
  def display_selected_contact
    params[:search] ||= {} #to set params[:search] if params is nil Bug 9871
    contacts =[]
    @mode_type = params[:mode_type] #passed from the application.js to set the mode type in view
    cuser = get_employee_user
    session[:sphinx]=params
    unless params[:q].blank?
      unless(params[:status]=='deactive')
        if cuser.employee.my_contacts == true
          contacts = @company.contacts.search("*" + params[:q].strip + "*", :with => {:assigned_to_employee_user_id => cuser.id}, :limit => 10000)
        else
          contacts = @company.contacts.search("*" + params[:q].strip + "*", :page => params[:page], :per_page => params[:per_page])
        end
      else
        contacts =@company.contacts.paginate(:only_deleted=>true,:conditions=>["first_name ||' ' || last_name ilike ? ","%#{params[:q]}%"],:page => 1, :per_page => 20)
      end
    else     
      comp_order =  'contacts.last_name asc,contacts.first_name asc'
      unless(params[:status]=='deactive')
        if cuser.employee.my_contacts == true
          contacts = @company.contacts.all(:conditions => {:assigned_to_employee_user_id => cuser.id}, :order => comp_order).paginate(:page => params[:page], :per_page => params[:per_page], :order => comp_order)
        else
          contacts = @company.contacts.paginate(:page => params[:page], :per_page => params[:per_page], :order => comp_order)
        end
      else
        contacts = @company.contacts.paginate(:only_deleted => true, :page => params[:page], :per_page => params[:per_page], :order => comp_order)
      end
    end
    params[:contact_status] = 'inactive' if params[:status].eql?("deactive")
    render :partial => 'contact', :locals => {:contacts => contacts, :params => params}
  end
  
  #This function search contacts and populate into drowdown of search box
  #TODO: please set the contacts status rather than delete for activate and deactivate
  #Added order by last_name in contacts search ganesh 18052011
  def search_contacts    
    @search_result =[]
    comp_order = "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc"
    unless params[:q].blank?
      unless(params[:status]=='deactive')   
        if get_employee_user.employee.my_contacts == true          
          @search_result = @company.contacts.search "*" + params[:q].strip + "*", :with => {:assigned_to_employee_user_id => current_user.id}, :limit => 10000, :order => 'last_name', :sort_mode => :asc
        else
          #raise "ok"
          @search_result = @company.contacts.search "*" + params[:q].strip + "*", :limit => 10000, :order => 'last_name', :sort_mode => :asc                   #:order => 'last_name',:sortable => true
         
        end
      else        
        @search_result = @company.contacts.find_only_deleted(:all, :conditions => ["first_name ILIKE ? OR last_name ILIKE ? OR middle_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"], :limit => 10000)
      end
    else    
      unless(params[:status]=='deactive')
        if get_employee_user.employee.my_contacts == true
          @search_result = @company.contacts.all(:conditions => {:assigned_to_employee_user_id => current_user.id}, :order => comp_order)
        else
          @search_result = @company.contacts.all(:order => comp_order)
        end 
      else
        @search_result = @company.contacts.find_only_deleted(:all, :conditions => ["first_name ILIKE ? OR last_name ILIKE ? OR middle_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"], :limit => 10000)
      end
    end   
    render :partial=> 'contact_auto_complete', :object => @search_result
  end

  def upload_document
    @mapable = @company.contacts.find(params[:id])
    @document_home=DocumentHome.new
    @document_homes = @mapable.document_homes
    @document= @document_home.documents.build
    @return_path = contacts_path
    @pagenumber= 21
    add_breadcrumb "Upload Document", upload_document_contact_path(@mapable)
    render :partial=> 'common/new_document', :layout => "application"
  end


  def upload
    @mapable = @company.contacts.find(params[:mapable_id])
    @document_homes = @mapable.document_homes
    @document_home = @mapable.document_homes.new
    @document= @document_home.documents.build
    if params[:document_home].present?
      document=params[:document_home][:document_attributes]
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>@employee_user_id,
        :created_by_user_id=>@current_user.id,:company_id=>@company.id,
        :mapable_id=> @mapable.id,:mapable_type=>'Contact',:upload_stage=>1)
      @document_home = @mapable.document_homes.new(params[:document_home])
      @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @employee_user_id, :created_by_user_id=>@current_user.id ))
      @return_path = contacts_path
      if @document_home.save
        flash[:notice]= "#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
        redirect_to :back
      else
        render :partial=> 'common/new_document', :layout => "application"
      end
    else
      render :partial=> 'common/new_document', :layout => "application"
    end
  end


  def download_format
    send_file RAILS_ROOT+'/public/sample_import_files/contacts_import_file.csv', :type => "application/csv"
  end
  def download_xls_format
    send_file RAILS_ROOT+'/public/sample_import_files/contacts_import_file.xls', :type => "application/xls"
  end
  def get_report_favourites
    @contacts_fav = CompanyReport.find_reports_favorites(get_company_id, get_employee_user_id, "Contact")    
  end
  
  def get_contacts_searchbox
    render :partial=>'zimbra_search_box'
  end

  def fetch_employee_user_id
    @employee_user_id||=get_employee_user_id
  end

  def find_user_not_admin_not_client
    @employees ||=  User.find_user_not_admin_not_client(@company.id)
  end

  def get_base_data
    @company ||= @company || current_company
    @current_user ||= @current_user || current_user
  end

  def modal_new_form
    @contact = Contact.new   
    contact_stages.compact! if  contact_stages.present?    
    @client_stage_value = @company.contact_stages.find(:all, :conditions=>['"company_lookups"."alvalue"= ? ', "Lead"])
    respond_to do |format|
      format.js {render :partial => "modal_new_contact_form", :locals => {:contact_stages => @contact_stages, :account_id => params[:account_id]}}
    end
  end

  def check_show_error_contacts
    flash[:error] = "Record does not exists"
    redirect_to :action => "index" 
  end

  def no_action_handled_contacts
    redirect_to :action => "index"
  end

  def current_company_sources
    @company_sources ||= @company.company_sources
  end

  def current_company_phone_type
    @contact_phone_type = @company.contact_phone_type
  end

  def current_company_contact_stages
    @contact_stages ||= @company.contact_stages
  end

  #stage id wise contact status added by ganesh 02062011
  def get_company_contact_stages
    lvalue=@company.contact_stages.find(params[:stage_id]).lvalue
    render :text=> lvalue
  end

end

