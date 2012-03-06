class AccountsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :current_service_session_exists
  before_filter :get_base_data
  before_filter :get_report_favourites ,:only => [:index,:new,:edit,:comments]

  rescue_from ActionController::UnknownAction, :with => :no_action_handled_accounts
  rescue_from ActiveRecord::RecordNotFound, :with => :show_action_error_handled_accounts

  load_and_authorize_resource :except=>[:account_notes,:activate_account,:remove_contact,:contacts_to_activate,:activate_contacts,:edit, :activate_account_with_primary,:destroy]
  verify :method => :post , :only => [:create, :save_primary_contact] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  helper_method :remember_past_path,:remember_past_edit_path
  layout 'full_screen'

  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'accounts.name', :dir => 'up', :search_item => 'true')
    end
    params[:search] ||= {} #Added to reduce the conditions in feature 9718 for dropdown in filter search -- Kushal.Dongre
    sort_column_order
    set_params_filter
    @ord = @ord.nil?? 'accounts.name ASC':@ord
    @pagenumber=130
    if(params[:mode_type] == nil)
      params.merge!(:mode_type => 'MY')
    end
    @mode_type =  params[:mode_type]
    @accounts = Account.get_accounts(params,current_company, @emp_user_id, @ord)
  end

  def show
    @account = @company.accounts.find(params[:id])
    if params[:fetch].eql?("opportunities")
      sort_column_order
      @ord = @ord.nil? ? 'name DESC':@ord
      contacts = @account.contact_ids
      @opportunities = Opportunity.get_open_opportunities_in_order(contacts,current_company.id,@ord)
      render :action => :show_opportunities, :layout =>false
    else
      sort_column_order
      @ord = @ord.nil? ? 'contacts.last_name DESC':@ord
      @contacts=@account.contacts.find(:all, :select => 'contacts.*', :order => @ord)
      render :action=>:show_contacts, :layout =>false
    end
  end

  def new
    @account = Account.new
    @parent_accounts = @company.accounts.all
    @employees =  User.find_user_not_admin_not_client(get_company_id)
    @contact = Contact.new
    @pagenumber= 28
    #sorted_contacts
    @account.shippingaddresses.build
    @account.billingaddresses.build
    add_breadcrumb "#{t(:text_new)} #{t(:text_account)}", new_account_path
    respond_to do |format|
      format.html 
      format.xml { render xml => @account }
    end
  end

  def edit
    @account = @company.accounts.find(params[:id],:include=>:contacts)
    @pagenumber = 29
    #    if @account.deleted_at.blank?
    session[:search] = params[:search]
    all_childs = get_all_childs(@account)
    @parent_accounts = @company.accounts.all - all_childs.flatten
    @shippingaddress = @account.shippingaddresses.find_or_create_by_address_type('shipping')
    @billingaddress = @account.billingaddresses.find_or_create_by_address_type('billing')
    @contact = Contact.new
    @total_open_invoices = Account.get_open_account_tne_invoices(@company,@account)
    @employees = User.find_user_not_admin_not_client(get_company_id)
    add_breadcrumb "#{t(:text_edit)} #{t(:text_account)}", edit_account_path(@account)
    #    else
    #      flash[:error] = "#{t(:flash_account_has_been_deactivated)}"
    #      redirect_to :action => "index"
    #    end
  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(:action => 'index')
  end

  def add_contact
    if request.xhr? && request.get?
      @contact = Contact.new
      render :partial => 'add_contact'
    else
      params.merge!(Account.params_to_add_contact(params,@emp_user_id,@current_user.id,@company.id))
      @account = Account.find(params[:id])
      if params[:contact].has_key?(:id) && params[:contact][:id].present?
        @contact = Contact.find(params[:contact][:id])
        @account.contacts << @contact
        if @account.save
          flash[:notice] = "Contact Added Successfully to Account #{@account.name.capitalize}"
        end
      else
        params[:contact].delete(:id)
        @contact = Contact.new(params[:contact])
        if unique_email(@contact,params) and @contact.valid?
          if @contact.save
            @account.contacts << @contact
            if @account.save
              flash[:notice]="Contact Added Successfully to Account #{@account.name.capitalize}"
            end
          end
        end
      end
      respond_to do |format|
        format.js {
          render :update do |page|
            unless @contact.errors.present? or @same_contacts.present?
              page << "tb_remove();"
              page << "window.location.reload()"
            else
              page << "jQuery('#loader').show();"
              if @same_contacts.present?
                page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
                page << "jQuery('#loader').hide();"
              else
                if params[:contact].has_key?(:first_name)
                  errs = "<ul>" + @contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                  page << "show_error_msg('add_contact_errors','#{errs}','message_error_div');"
                else
                  page << "show_error_msg('add_contact_errors','Please select an Existing Contact or Create new Contact','message_error_div');"
                end
                page<< "jQuery('#loader').hide();"
              end
              page << "jQuery('#account_contact_submit').show();"
              page << "jQuery('#account_contact_hidden').hide();"
              page << "jQuery('#loader').hide();"
            end
          end
        }
      end
    end
  end

  # This action display matters linked to particular account
  def matters_linked_to_account
    account = Account.find(params[:id])
    ccompany = current_company
    default_status_id = ccompany.matter_statuses.find_all_by_lvalue('Open',:order => 'sequence asc', :select => "id")[0].id
    @matter_status_id = params[:matter_status] || default_status_id
    account_matters = account.matters(@matter_status_id)
    @matter_statuses = ccompany.matter_statuses.collect! {|e|[e.alvalue, e.id]}
    @matter_statuses = [["All", 0]] + @matter_statuses
    render :partial => 'matters_linked_to_account', :locals => {:account_matters => account_matters}
  end

  def create
    @pagenumber= 28
    #    if params[:allow_activate].to_i==1
    #      account = Account.find_only_deleted(:first, :conditions => ["name ilike ?", "#{params[:account][:name].strip}"])
    #      if account.activate_account(current_user.id,account)
    #        flash[:notice] =  "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
    #      end
    #      redirect_to accounts_path
    #    else
    data=params
    data.merge!(Account.params_to_create_account(data,@emp_user_id,@current_user.id,@company.id))
    @employees =  User.find_user_not_admin_not_client(@company)
    @account = Account.new(data[:account])
    @contact=Contact.new(data[:contact])
    @parent_accounts= @company.accounts.all
    if (unique_name(@account) && unique_email(@contact,data)  &&  @account.save_with_contact(data,@company.id) )
      flash[:notice] = "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
      redirect_if(params[:button_pressed].eql?("save"), edit_account_path(@account))
      redirect_if(params[:button_pressed].eql?("save_exit"), accounts_path)
    else
      @contact_stage=@company.contact_stages
      @lead_status=true
      render :action => 'new'
    end
    #    end
  end

  def update
    data=params
    data.merge!(Account.params_to_update_account(data,@emp_user_id,@current_user.id,@company.id))
    @account = Account.find(data[:id])   
    all_childs=get_all_childs(@account)
    @parent_accounts=  @company.accounts.all - all_childs.flatten
    @contact = Contact.new()
    @shippingaddress=@account.shippingaddresses.find_by_address_type('shipping')
    @billingaddress=@account.billingaddresses.find_by_address_type('billing')    
    @employees =  User.find_user_not_admin_not_client(@company.id)
    if  @account.update_with_contact(data,@company.id)
      flash[:notice] = "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"      
      redirect_if(params[:button_pressed].eql?("save"), (remember_past_edit_path(@account)))
      redirect_if(params[:button_pressed].eql?("save_exit"), (remember_past_path))
      session[:search] = nil if params[:button_pressed].eql?("save_exit")
    else
      respond_to do |format|
        format.html{ render :action => "edit", :locals=>{:parent_accounts => @parent_accounts,:shippingaddress => @shippingaddress, :billingaddress => @billingaddress}}
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  def contacts_to_activate
    @account=Account.find_with_deleted(params[:id])
    @contacts=[]
    acc_cnt=AccountContact.find_with_deleted(:all, :conditions => {:account_id => @account.id})
    acc_cnt.each do |ac|
      @contacts << Contact.find_with_deleted(ac.contact_id)
      @primarycnt = Contact.find_with_deleted(@account.primary_contact_id) #Contact.find_with_deleted(ac.contact_id) if ac.priority==1
    end
    render :layout =>false
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  #This method reoves a contact from an account
  def remove_contact
    Account.transaction do
      contact = Contact.find params[:id]
      unless contact.has_matters?      
        @account_contact.destroy! if @account_contact= AccountContact.find_by_account_id_and_contact_id(params[:account_id], params[:id])
        flash[:notice] = "#{t(:text_contact)} #{t(:flash_was_successful)} #{t(:text_deleted)}  For This #{t(:text_account)}"
      else
        flash[:error] = "This contact has Matter(s) associated"
      end
      if request.xhr?
        render :nothing=>true
      else
        redirect_to:back
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  #This method is used to render the new contacts partial while generating a new account
  def populatecontactfields
    #This code is for solving the Edit accounts crash - 14-06-2010
    @account= (params[:account_id].present??  Account.find(params[:account_id]) : Account.new())    
    @contact = Contact.new()
    @contact_stage=@company.contact_stages
    @lead_status=true
    render :partial=>'/common/newcontact',:object=>@contact
  end

  #This method is used to render the existing contacts dropdown partial while generating a new account
  def populatecombo    
    sorted_contacts
    render :partial=>'/common/existingcontact',:object=>account_contacts
  end

  #This method is used to change the primary contact of the account
  def change_primary_contact
    Account.transaction do
      @account||=Account.find(params[:id])
      if request.get?
        @primary_contact = Contact.find(@account.primary_contact_id) if @account.primary_contact_id       
        render :action=>:change_primary_contact, :layout =>false
      end
      if request.put?
        begin         
          @account.update_attribute(:primary_contact_id,  params[:new_account_contact][:id])
        rescue
        end        
        flash[:notice] ="Primary #{t(:text_contact)} #{t(:text_updated)} For #{@account.name}"
        redirect_to :back
      end
    end
  end

  #This method is used to save the updated primary contact.
  def save_primary_contact
    Account.transaction do
      data=params
      @account=Account.find(data[:id])      
      unless data[:commit]=='Cancel'
        @primary_contact = @account.update_attributes(:primary_contact_id =>  params[:new_account_contact][:id])       
        flash[:notice] = "Primary Contact Updated For #{@account.name}"
      end
      redirect_to edit_account_path(@account)
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end  

  def destroy
    Account.transaction do
      @account = @company.accounts.find_with_deleted(params[:id])
      @account.update_attribute('updated_by_user_id',@current_user.id)
      contactsids = false
      unless params[:contact_ids].blank?
        contacts_to_deactivate = Contact.find_with_deleted(params[:contact_ids])
        contactsids = true
      end
      rest_contacts = contactsids ? @account.contacts - contacts_to_deactivate : @account.contacts
      if params[:commit]=='Delete'
        if contactsids
          for contact in contacts_to_deactivate
            contact.account_contacts.each do|acc_cont|
              acc_cont.update_attribute(:updated_by_user_id,@current_user.id)
              acc_cont.destroy
            end
            contact.update_attribute(:updated_by_user_id , @current_user.id)
            contact.destroy
          end
        end
        for contact in rest_contacts
          @account.update_attribute(:primary_contact_id,nil) if @account.primary_contact_id == contact.id
          contact.account_contacts.each do|acc_cont|
            acc_cont.update_attribute(:updated_by_user_id,@current_user.id)
            acc_cont.destroy!
          end
        end
        @account.destroy
        flash[:notice] = "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_deactivated)}"
      else
        if contactsids
          for contact in contacts_to_deactivate
            contact.account_contacts.each do|acc_cont|
              acc_cont.destroy!
            end
            contact.destroy!
          end
          for contact in rest_contacts
            contact.account_contacts.each do|acc_cont|
              acc_cont.destroy!
            end
          end
        else
          AccountContact.find_with_deleted(:all,:conditions=>["account_id=#{@account.id}"]).each do |acc_cont|
            acc_cont.destroy!
          end
        end
        @account.destroy!
        flash[:notice] = "#{t(:text_account)} " "#{t(:flash_was_successful)} " "deleted"
      end
    end
    respond_to do |format|
      format.html{
        redirect_to :back
      }
      format.js{
        render :update do |page|
          page << "tb_remove()"
          page << "window.location.reload()"
        end
      }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  def select_contacts
    @account = @company.accounts.find_with_deleted(params[:id])
    @delete =params[:delete]
    render :layout => false
  end

  #This method is used to search an account
  def search_account
    data=params
    search_result =[]
    unless data[:q].blank?
      search_result = @company.accounts.search data[:q], :star => true, :limit => 10000
    else
      search_result = @company.accounts.all(:order => 'name ASC')
    end
    render :partial=> 'account_auto_complete', :locals => {:search_result => search_result}
  end

  # Used for displaying the result of the search
  def display_selected_account
    params[:search] ||= {} #to set params[:search] if params is nil Bug 9871
    data=params
    accounts =[]
    @mode_type = params[:mode_type] #passed from the application.js to set the mode type in view
    unless data[:q].blank?
      accounts = @company.accounts.search data[:q], :star => true, :page => data[:page], :per_page => params[:per_page]
    else
      accounts = @company.accounts.paginate(:page => data[:page], :per_page => params[:per_page], :order=>'name ASC')
    end
    render :partial => 'account', :locals => {:accounts => accounts}
  end

  #Used for search in accounts
  def common_account_search
    if params[:q].strip == ''
      matching_accounts = @company.accounts.all(:order=>'name ASC')
    else
      matching_accounts = @company.accounts.search params[:q], :star => true, :limit => 10000
    end
    render :partial=> 'common_account_search', :locals => {:matching_accounts => matching_accounts}
  end

  def get_report_favourites
    account = t(:label_Account)
    @accounts_fav = CompanyReport.all(:conditions => ["company_id = ? AND employee_user_id = ? AND report_type = ?", @company.id, @emp_user_id, account])
  end

  def get_all_childs(account)
    account.self_and_all_children
  end

  def get_base_data
    @company  ||= current_company
    @emp_user_id ||= get_employee_user_id
    add_breadcrumb t(:text_accounts), :accounts_path
  end

  def validate_new_contact    
    params[:contact].merge!(:employee_user_id=>@emp_user_id,
      :created_by_user_id=>@current_user.id,:company_id=>@company.id, :assigned_to_employee_user_id=>@emp_user_id)
    @contact = current_company.contacts.new(params[:contact])
    if unique_email(@contact,params) and @contact.valid?
      respond_to do |format|
        format.js {
          render :update do |page|
            if @contact.save
              params[:contact][:id] = @contact.id
              if params[:account_id].present?
                acc = Account.find(params[:account_id])
                acc.contacts << @contact
              end
              page << "validAccountContact()"
              page << "tb_remove();"
              page << "jQuery('#_contact_ctl').val('#{@contact.full_name}')"
              page << "jQuery('#_contactid').val('#{@contact.id}')"
              if params[:account_id].present?
                page.reload
                flash[:notice]="Contact Created Successfully."
              end
            else
              errs = "<ul>" + @contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('nameerror','#{errs}','message_error_div')"
            end
          end
        }
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            if @same_contacts.present?
              page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
            else
              errs = "<ul>" + @contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('nameerror','#{errs}','message_error_div')"
            end
            page << "jQuery('#loader').hide();"
            page << "jQuery('#contact_submit').val('Save');"
            page << "jQuery('#contact_submit').attr('disabled','');"
          end
        }
      end
    end
  end

  def no_action_handled_accounts
    redirect_to :action => "index"
  end

  def show_action_error_handled_accounts
    flash[:error] = "Record does not exists"
    redirect_to :action => "index"
  end

  def activate_account_with_primary
    data = params
    if request.get?
      params[:id] = params[:acnt_id]
      @contact=Contact.new
      @account = Account.find_with_deleted(params[:id])
      @account_contacts = []
      @account.account_contacts.find_only_deleted(:all).each{|acc_cont|
        cont = Contact.find_with_deleted(acc_cont.contact_id)
        @account_contacts << cont if cont.deleted?}
      render :layout => false
    else
      @contact = Contact.new(data[:contact])
      account = Account.find_with_deleted(params[:id])
      account_activated,contact_errors = account.activate_account(current_user.id,data)
      if account_activated
        respond_to do |format|
          format.js{
            render :update do |page|
              flash[:notice] =  "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
              page << "tb_remove();"
              page << "window.location.reload()"
            end
          }
        end
      else
        respond_to do |format|
          format.js{
            render :update do |page|
              if @same_contacts.present?
                page << "jQuery('#same_contact_errors').html('#{same_contacts_show}')"
              else
                if params[:contact][:salutation_id].nil? and params[:contact][:id].blank?
                  page << "show_error_msg('activate_account_errors','Please select an Existing Contact or Create new contact','message_error_div');"
                else
                  errs = "<ul>" + contact_errors.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                  page << "show_error_msg('activate_account_errors','#{errs}','message_error_div');"
                end
              end
              page << "jQuery('#account_contact_hidden').hide();"
              page << "jQuery('#account_contact_submit').show();"
            end
          }
        end
      end
    end
  end

  def activate_account
    account = @company.accounts.find_only_deleted(params[:id])
    account_contacts = account.account_contacts.find_only_deleted(:all)
    contacts = []
    account.account_contacts.find_only_deleted(:all).each{|acc_cont| contacts << Contact.find_only_deleted(acc_cont.contact_id)}
    Account.transaction do
      account.update_attribute(:updated_by_user_id,@current_user.id)
      contacts_to_activate = Contact.find_with_deleted(params[:contact_ids])
      rest_contacts = contacts - contacts_to_activate
      for contact in contacts_to_activate
        contact.account_contacts.find_only_deleted(:all).each do|acc_cont|
          acc_cont.update_attributes(:updated_by_user_id => @current_user.id , :deleted_at => nil)
        end
        contact.update_attributes(:updated_by_user_id => @current_user.id, :deleted_at => nil)
      end
      for contact in rest_contacts
        contact.account_contacts.find_only_deleted(:all).each do|acc_cont|
          acc_cont.update_attribute(:updated_by_user_id , @current_user.id)
          acc_cont.destroy!
        end
        account.update_attribute(:primary_contact_id,nil) if account.primary_contact_id == contact.id
      end
      account.update_attribute(:deleted_at,nil)
      if account.primary_contact_id.nil?
        account.update_attribute(:primary_contact_id,account.contacts[0].id) unless account.contacts[0].nil?
      end
      flash[:notice] =  "#{t(:text_account)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
      redirect_to accounts_path(:account_status => "inactive")
    end
  end

  def manipulate_params
    unless params[:selected_list_box].blank?
      if params[:selected_list_box] == 'Lead' || params[:called_from]=='accounts'
        params[:contact][:status_type] = params[:contact][:lead_status]
        params[:contact].delete_if{|key, value| key=="prospect_status"}
      else
        params[:contact].delete_if{|key, value| key=="lead_status"}
        params[:contact][:status_type] = params[:contact][:prospect_status]
      end
    else
      if params[:called_from]=='accounts'
        params[:contact].delete_if{|key, value| key=="prospect_status"}
        params[:contact][:status_type] = params[:contact][:lead_status]        
      else
        params[:contact].delete_if{|key, value| key=="lead_status"}
        params[:contact][:status_type] = params[:contact][:prospect_status]
      end
    end
  end

end
