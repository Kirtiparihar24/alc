# This controller handles some core matter related tasks.
# The reports related to matter are generated in this controller.
# Some core backend entries in matter people table are also created here.
# Eg:
# * Matter client's entry.
# * Lead lawyer's entry.
# * If lead lawyer was not current lawyer, then his entry with a given role.
# Creating a matter from opportunity (which is closed) is also handled here.

class MattersController < ApplicationController
  include GeneralFunction
  before_filter :authenticate_user!
  before_filter :get_company
  before_filter :current_service_session_exists  
  load_and_authorize_resource
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}  
  before_filter :check_cancel_submit
  before_filter :get_report_favourites ,:only => [:index,:new,:edit]
  before_filter :get_employees, :only => [:new, :create, :edit, :update]
  before_filter :get_matter, :only => [:edit, :update, :save_retainer_fees, :new_lead_lawyer]
  before_filter :check_access_to_matter, :only => [:edit, :update]
  before_filter :get_user, :only => [:save_retainer_fees]
  add_breadcrumb I18n.t(:text_matters), :matters_path
  helper_method :remember_past_path,:remember_past_edit_path
  
  layout 'full_screen', :except => [:edit]

  include GeneralFunction
  include MatterSequenceBinarySearch

  def get_account_contacts
    account_contacts = []
    new_val = true
    if params[:rollback].blank?
      new_val = false
      account_contacts = params[:account_id].present? ? Account.find(params[:account_id]).contacts.find(:all, :order=> "contacts.id desc") : Contact.find_by_sql('select * from contacts where deleted_at is null and id not in (select contact_id from account_contacts ) order by first_name')
    end
    render :update do |page|
      page.replace_html 'contacts', :partial => 'account_contacts', :locals => {:new => new_val,:account_contacts => account_contacts }
    end
  end

  def get_contact_accounts
    render :update do |page|
      if params[:rollback].blank?
        contact_account = Contact.find(params[:id_val]).accounts
        page.replace_html 'accounts', :partial => 'accounts/createnew_selectexisting', :locals => {:new => false, :contact_account => contact_account }
        page << "jQuery('#account_id').val(#{contact_account[0].id})" if contact_account.present?
      else
        page.replace_html 'accounts', :partial => 'accounts/createnew_selectexisting', :locals => {:new => true}
      end
    end
  end

  def matter_client_comments      
    euid = get_employee_user_id        
    tasks = @matter.comment_accessible_matter_tasks(euid)
    comments = tasks.collect! {|e| e.comments}
    comments = comments.flatten.uniq.find_all {|e| e.matter_client_comment?}
    unread = []
    read = []
    comments.each {|e|
      if e.is_read.nil? or e.is_read == false
        unread << e
      else
        read << e if (e.created_at >= (Time.zone.now-1.day))
      end
    }   
    render :partial => "physical/clientservices/home/client_comments", :locals => {:client_comments_unread => unread, :client_comments_read => read, :n => 5, :title => "Client Comments"}
  end

  def all_matter_client_comments
    euid = get_employee_user_id
    comments = Comment.all(:conditions => ["m.deleted_at IS NULL AND mt.deleted_at IS NULL AND mp.company_id = ? AND comments.company_id = ? AND mp.employee_user_id = ? AND commentable_type = 'MatterTask' AND ((mt.assigned_to_matter_people_id = mp.id OR mp.additional_priv & 2 = 2 or mp.employee_user_id = m.employee_user_id)  AND (mp.start_date is not null and mp.start_date <= '#{Time.zone.now.to_date}' and (mp.end_date is null OR mp.end_date > '#{Time.zone.now.to_date}' ))) AND (title='MatterTask Client' OR title = 'MatterTask CGC')", get_company_id, get_company_id, euid], :joins => "INNER JOIN matter_tasks mt ON commentable_id=mt.id INNER JOIN matters m ON mt.matter_id = m.id INNER JOIN matter_peoples mp ON m.id = mp.matter_id")
    unread = []
    read = []
    comments.each {|e|
      if e.is_read.nil? or e.is_read == false
        unread << e
      else
        read << e if (e.updated_at >= (DateTime.now-1.day))
      end
    }
    render :partial => "physical/clientservices/home/client_comments", :locals => {:client_comments_unread => unread, :client_comments_read => read, :n => 5, :title => "Client Comments"}
  end

  def matter_client_docs
    client_docs = @matter.get_client_docs(current_user.id,is_access_matter?)
    render :partial => "physical/clientservices/home/client_docs", :locals => {:matter => @matter, :client_docs =>client_docs, :title => "Client Documents"}
  end

  def all_matter_client_docs
    matters = Matter.team_matters(get_employee_user_id, @company.id)
    client_docs = []
    matters.each do|e|
      client_docs << e.client_document_homes
    end
    render :partial => "physical/clientservices/home/client_docs", :locals => {:matter => @matter, :client_docs => client_docs.flatten, :title => "Client Documents"}
  end  

  def new_lead_lawyer
    @pagenumber = 203
    emp_user_id = get_employee_user_id
    all_activities = is_access_matter? ? @matter.firm_manager_tasks("matter_tasks.created_at ASC") : @matter.my_matter_tasks(emp_user_id, "matter_tasks.created_at ASC")
    @open_activities = all_activities.select{|task| (task.open?)}
    my_matter_people_id=@matter.matter_peoples.lawteam_members.find_by_employee_user_id(@matter.employee_user_id).id
    @open_issues = @matter.matter_issues.select{|open_issue| open_issue.assigned_to_matter_people_id == my_matter_people_id}
    matter_docs= @matter.document_homes.all(:conditions => ["sub_type IS NULL AND wip_doc IS NULL"])
    all_document=matter_docs.find_all{|e| e.upload_stage != 2 && ((e.access_rights == 1 && e.owner_user_id == emp_user_id ) || e.access_rights != 1 && !e.access_rights.nil?)}
    @other_document=all_document.select{|doc|doc.access_rights != 1 && doc.owner_user_id == @matter.employee_user_id}
    @private_document= all_document.select{|doc|doc.access_rights==1}
    @elligible_lawyers = @matter.matter_peoples.lawteam_members.all(:conditions => ["employee_user_id != ?", @matter.employee_user_id])
    @available_roles = @company.client_roles.reject {|e| e.lvalue.eql?("Matter Client") || e.lvalue.eql?("Lead Lawyer")}
    render :layout => "left_with_tabs"
  end
  
  def change_lead_lawyer
    out = nil
    new_id = params[:new_lead_lawyer]
    new_role = params[:new_lead_role]
    # Name: Mandeep Singh
    # Date: Sep 9, 2010
    # Transaction purpose: Take the entry for the lead lawyer and either change it's role
    #  or delete it's entry from matter peoples. Create new matter people entry as lead lawyer
    #  for selected lawyer. If old lead lawyer is deleted, then, assign his tasks and issues
    #  to the newly created lead lawyer.
    # Tables affected: matter_peoples, matter_tasks, matter_issues
    Matter.transaction do
      lead_role_id = @matter.company.client_roles.array_hash_value('lvalue','Lead Lawyer','id')
      old_lead = @matter.matter_peoples.first(:conditions => ["employee_user_id IS NOT NULL AND employee_user_id = ? AND matter_team_role_id = ?", @matter.employee_user_id, lead_role_id])
      @matter = @company.matters.find(params[:matter_id])
      matter_docs= @matter.document_homes.all(:conditions=> ["sub_type IS NULL AND wip_doc IS NULL"])
      @all_document = matter_docs.find_all{|e| e.upload_stage !=2 && ((e.access_rights == 1 && e.owner_user_id == get_employee_user_id) || e.access_rights != 1)}
      # Create new entry for new Lead Lawyer in matter peoples.
      new_lead_lawyer = @matter.matter_peoples.find(new_id)
      new_lead_lawyer.update_attributes({
          :updated_by_user_id => current_user.id,
          :is_active => true,
          :matter_team_role_id => lead_role_id,
          :start_date => @matter.matter_start_date,
          :end_date => nil
        })
      if new_role.blank?
        # Transfer documents...
        set_lead_lawyer_docs(old_lead, new_lead_lawyer,params,@all_document )
        # Transfer old Lead Lawyer's assignments to new Lead Lawyer...
        user_id = new_lead_lawyer.employee_user_id
        new_user = User.find(user_id )
        if params[:open_activities]=="true"
          old_lead.matter_tasks.with_order('created_at ASC').find_with_deleted(:all).each do|e|
            e.assigned_to_user_id = user_id
            e.assigned_to_matter_people_id = new_id
            e.lawyer_name = new_user.full_name
            e.lawyer_email = new_user.email
            e.responsible_person_changed
            e.update_into_zimbra
            e.send(:update_without_callbacks)
          end
        end
        if params[:open_issues]=="true"
          old_lead.matter_issues.each do|e|
            e.update_attribute(:assigned_to_matter_people_id, new_lead_lawyer.id)
          end
        end
        old_lead.update_attribute('end_date', Date.today)
        matter_access_period = {:matter_id => old_lead.matter_id,:start_date => old_lead.start_date,:end_date => old_lead.end_date, :company_id => old_lead.company_id, :employee_user_id => old_lead.employee_user_id, :is_active => old_lead.is_active}
        old_lead.matter_access_periods.first.update_attributes(matter_access_period)
        new_lead_lawyer.matter_access_periods.destroy_all
        new_lead_lawyer.matter_access_periods.build(:matter_id => new_lead_lawyer.matter_id,:start_date => new_lead_lawyer.start_date,:end_date => new_lead_lawyer.end_date, :company_id => new_lead_lawyer.company_id, :employee_user_id => new_lead_lawyer.employee_user_id, :is_active => new_lead_lawyer.is_active).save!
        out = "home"
      else
        old_lead.update_attributes({:matter_team_role_id => new_role})
        matter_access_period = {:matter_id => old_lead.matter_id,:start_date => old_lead.start_date,:end_date => old_lead.end_date, :company_id => old_lead.company_id, :employee_user_id => old_lead.employee_user_id, :is_active => old_lead.is_active}
        old_lead.matter_access_periods.first.update_attributes(matter_access_period)
        new_lead_lawyer.matter_access_periods.build(:matter_id => new_lead_lawyer.matter_id,:start_date => new_lead_lawyer.start_date,:end_date => new_lead_lawyer.end_date, :company_id => new_lead_lawyer.company_id, :employee_user_id => new_lead_lawyer.employee_user_id, :is_active => new_lead_lawyer.is_active).save!
        out = "edit"
      end
      # Finally we update the Lead Lawyer in the matter.
      @matter.update_attribute(:employee_user_id, new_lead_lawyer.employee_user_id)
    end
    render :text => out
  end

  private
  
  # Get employee list for lead lawyer select.
  def get_employees
    @employees =  User.find_user_not_admin_not_client(get_company_id)
  end

  # Get the matter for edit/update.
  def get_matter
    @company.matters.find(params[:id])
  end

  # Get the current company
  def get_company
   @company ||= current_company
  end
  
  # Used to check if the submit button was actually for cancel action.
  def check_cancel_submit
    redirect_to matters_path if params[:cancel]
  end

  public

  def save_retainer_fees
    authorize!(:save_retainer_fees,@user) unless @user.has_access?('Billing & Retainer')
    respond_to do |format|
      if @matter.update_attributes(params[:matter])
        flash[:notice] = "#{t(:text_retainer_fees)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      else
        flash[:error] = @matter.errors.full_messages  #t(:flash_matter_retainer_updated_failed)
      end
      format.html { redirect_to bill_retainers_matter_matter_billing_retainers_path(@matter) }
    end
  end

  # Used for create contact form on matter/new page.
  def populatecombo
    respond_to do |format|
      format.html {render :partial => 'common/existingcontact'}
      format.js {render :partial => 'common/existingcontact'}
    end
  end

  # Used for create contact form on matter/new page.
  def populatecontactfields
    @contact = Contact.new
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Client'])
    @lead_status = false
    render :partial=>'common/newcontact', :object=>@contact
  end

  # Returns matters for index page, filters based on my/all criteria.
  # MY - Where current employee is Lead Lawyer.
  # ALL - Where current employee is part of the law team.
  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'matters.name', :dir => 'up', :search_item => 'true')
    end
    params[:search] ||= {} #Added to reduce the conditions in feature 9718 for dropdown in filter search -- Kushal.Dongre
    session[:search] = params[:search]
    sort_column_order
    set_params_filter
    data = params.clone
    ccompany = @company
    @letter_selected = data[:letter]
    @pagenumber= 133
    @perpage = data[:per_page].present? ? data[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
    unless data[:matter_status].blank?
      if data[:matter_status].eql?("0")
        @matter_status_id = 0
        @matter_status_value = "All"
      else
        status = ccompany.matter_statuses.find(data[:matter_status])
        @matter_status_id = status.id
        @matter_status_value = status.lvalue
      end
    else
      @matter_status_id = ccompany.matter_statuses.find_all_by_lvalue('Open',:order => 'sequence asc')[0].id
      @matter_status_value  = "Open"
    end
    if data[:matter_status].eql?("0")
      data[:matter_status] = ccompany.matter_statuses.collect(&:id)
    else
      data[:matter_status] = [data[:matter_status]] if data[:matter_status].present?
    end
    if(data[:mode_type] == nil)
      data.merge!(:mode_type=>'MY')
    end
    @matters = Matter.matters_index(data, ccompany.id, get_employee_user_id, @perpage, @ord)
    @mode_type     =(data[:mode_type].eql?("ALL")|| data[:mode_type].nil?)? 'ALL': (data[:mode_type].eql?("MY")? 'MY' : 'MY_ALL')
    #@matter_statuses.collect{|stage|[stage.lvalue, stage.id]}
    @matter_statuses = ccompany.matter_statuses.collect! {|e|[e.alvalue, e.id]}
    #@matter_statuses.inspect
    @matter_statuses = [["All", 0]] + @matter_statuses
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matters }
    end
  end


  def new
    @matter = Matter.new
    @contact = Contact.new
    #@company = current_company
    @pagenumber=46
    @matter_flag_id="false"
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Client'])
    #to set lead as default stage
    @client_stage_value = @company.contact_stages.first(:conditions=>["alvalue= ?" , "Lead"])
    @notes = []
    cid = @company.id
    # In case this action was called from opportunity edit page.
    session[:opportunity_id] = params[:opportunity_id]
    @matter.contact = @company.opportunities.find(params[:opportunity_id]).contact if params[:opportunity_id]
    @contact_from_opportunity= @company.opportunities.find(params[:opportunity_id]).contact if params[:opportunity_id]
    @matter.set_opportunity(cid, session[:opportunity_id])
  
    # Get all matter for primary matter select.
    #@all_matters = Matter.scoped_by_company_id(get_company_id)
    completed = Matter.with_status(MatterStatus.find_by_lvalue_and_company_id('Completed', cid))
    @all_matters = Matter.team_matters(get_employee_user_id, cid) - completed
    @documentabale = @matter
    @matter.matter_litigations.build    
    basecon = ActiveRecord::Base.connection
    if basecon.sequence_exists?('company'+cid.to_s+'_seq')
      generate_matter_id
    end
    basecon=nil
    add_breadcrumb "#{t(:text_new)} #{t(:text_matter)}", new_matter_path
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @matter }
    end
  end
 
  def edit
    cid = @company.id
    @is_litigation_matter = @matter.matter_category.eql?("litigation")
    completed = Matter.with_status(MatterStatus.find_all_by_lvalue_and_company_id('Completed',cid))
    completed -= [@matter.parent] if @matter.parent and @matter.parent.completed?
    @all_matters = Matter.team_matters(get_employee_user_id, cid) - [@matter] - @matter.children - completed
    @notes = @matter.comments || []
    @opposite_contacts = @matter.opposite_primary_contacts
    @pagenumber=38
    @matter.matter_litigations.build unless @matter.matter_litigations.present?
    @law_team_member_ids = @matter.matter_peoples.lawteam_members.collect{|ltm| ltm.employee_user_id}
    @other_contacts  = get_other_contacts(@matter)
    add_breadcrumb "#{t(:text_edit)} #{t(:text_matter)}", edit_matter_path(@matter)
    render :layout => "left_with_tabs"
  end

  private

  # This function returns the available contacts for setting as primary contacts, from matter edit page.
  def get_other_contacts(matter)
    client_contacts = matter.client_contacts
    client_contacts << matter.primary_matter_contact
    client_contacts.compact
  end

  public
  def generate_matter_id   
    if session[:matter_sess_seq_no].nil?
      seq_id=@company.sequence_no
      mat_id=find_next_seq_no(seq_id)
      session[:matter_sess_seq_no] = mat_id
      @company.update_attributes(:sequence_no=>mat_id)
    else
      mat_id=session[:matter_sess_seq_no]
    end
    @matter_no_seperator=@company.sequence_seperator
    @sequence_format=@company.format
    @matter_no_without_format=mat_id
    @matter_no=mat_id        
  end

  def create
    params[:matter][:account_id] = params[:account][:id] if params[:account].present?
    if params[:account].present?
      if params[:account][:name].eql?('Create New') || params[:account][:name].eql?('Select Existing')
        params[:account] = ""
      end
    end
    @pagenumber=46
    data = params
    @contact = Contact.new
    completed = Matter.with_status(MatterStatus.find_by_lvalue_and_company_id('Completed', @company.id))
    @all_matters = Matter.team_matters(euid=get_employee_user_id, @company.id) - completed
    @documentabale = @matter
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Client'])
    @lead_status = false
    matter_category = params[:matter][:matter_category]
    if matter_category=="non-litigation"
      data[:matter].delete(:matter_litigations_attributes)
      data[:matter].merge!(:matter_type_id => params[:matter][:matter_type_nonliti] )
    else
      data[:matter].merge!(:matter_type_id => params[:matter][:matter_type_liti] )
    end
    respond_to do |format|
      unless unique_email(Contact.new(data[:contact]), data)
        render :action => "new"
        return
      end
      @matter, success = Matter.save_with_contact_and_opportunity(data, euid, session[:opportunity_id])
      if success
        session[:matter_sess_seq_no] = nil
        session[:opportunity_id] = nil
        Account.create_account_with_contact(params[:account][:name], params[:matter][:contact_id], @matter, current_user.id) if params[:account].present?
        flash[:notice] = "#{t(:text_matter)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          # Take out of matter if no role was selected for current lawyer.
          if @matter.employee_user_id != euid
            if @matter.matter_peoples.lawteam_members.find_by_employee_user_id(euid).nil? and data[:button_pressed].eql?("save")
              redirect_to  edit_matter_path(@matter)
              return
            end
          end
          user = User.exists?(:username=> params[:contact][:email])
          if(!user && params[:matter][:client_access])
            user = User.new
            user.email=params[:contact][:email]
            user.first_name=@matter.contact.try(:first_name)
            user.last_name=@matter.contact.try(:last_name)
            user.username=params[:contact][:email]
            user.sign_in_count=0
            user.company_id=@matter.contact.company_id
            user.save(false)
            user.errors.full_messages.each {|e| p e}
            role=Role.find_by_name('client')
            userrole = UserRole.find_or_create_by_user_id_and_role_id(user.id,role.id)
            User.generate_and_mail_new_password_from_matter(user.username,user.email,User.current_lawyer)
            matter_user=@matter.user
            send_notification_to_lead_lawyer(matter_user,@matter,User.current_lawyer)
            @matter.contact.update_attributes(:user_id=>user.id,:email=>user.email)
          end
          redirect_if(data[:button_pressed].eql?("save"), edit_matter_path(@matter))
          redirect_if(data[:button_pressed].eql?("save_exit"), matters_path())
        }
        format.xml  { render :xml => @matter, :status => :created, :location => @matter }
      else
        @matter_flag_id="true"
        @matter.matter_litigations.build if params[:matter][:matter_category]=="non-litigation"
        @contact = @matter.contact || Contact.new
        #to set lead as default stage if error
        @client_stage_value = @company.contact_stages.first(:conditions=>["alvalue= ?" , "Lead"])
        format.html { render :action => "new" }
        format.xml  { render :xml => @matter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates the primary contact for the matter properly if it was changed.
  def update_primary_contact(matter, params)
    new_contact_id = (params[:matter][:contact_id] ||matter.contact_id).to_i
    # Check if the primary matter contact was changed during matter edit.
    if new_contact_id != matter.contact_id.to_i
      old_primary_matter_contact = matter.primary_matter_contact
      new_primary_matter_contact = matter.matter_peoples.find(:first, :conditions => ["people_type = 'client_contact' AND contact_id = ?", new_contact_id])
      # To avoid invalid data - Milind/Pratik
      # Used obj.save to avoid the callback relatd to phone and email
      # because here we are only updating the people_type and member_role_id
      # Update their respective roles.
      new_primary_matter_contact.people_type = "matter_client"
      new_primary_matter_contact.can_access_matter =params[:matter][:client_access]  unless params[:matter][:client_access].nil?
      unless old_primary_matter_contact.blank?
        new_primary_matter_contact.matter_team_role_id = old_primary_matter_contact.matter_team_role_id.nil? ? @matter.company.client_roles.find_by_lvalue('Matter Client').id : old_primary_matter_contact.matter_team_role_id
      else
        new_primary_matter_contact.matter_team_role_id = @matter.company.client_roles.find_by_lvalue('Matter Client').id
      end
      new_primary_matter_contact.save(false)
      old_primary_matter_contact.people_type = "client_contact"
      old_primary_matter_contact.matter_team_role_id = nil
      old_primary_matter_contact.save(false)
    else
      unless matter.primary_matter_contact.blank?
        old_primary_matter_contact = matter.primary_matter_contact
        old_primary_matter_contact.can_access_matter = params[:matter][:client_access]  unless params[:matter][:client_access].nil?
        old_primary_matter_contact.save(false)
      end
    end
  end

  def update
    euid = get_employee_user_id
    # added because unchecked checkbox do not come in params hash
    params[:matter][:client_access] ||= false
    matter_category =params[:matter][:matter_category]
    @is_litigation_matter = @matter.matter_category.eql?("litigation")
    completed = Matter.with_status(MatterStatus.find_by_lvalue_and_company_id('Completed',@company.id))
    @all_matters = Matter.team_matters(get_employee_user_id, @company.id) - [@matter] - @matter.children - completed
    @law_team_member_ids = @matter.matter_peoples.lawteam_members.collect{|ltm| ltm.employee_user_id}
    @notes = @matter.comments
    @opposite_contacts = @matter.opposite_primary_contacts
    @other_contacts  = get_other_contacts(@matter)
    # This condition is added for missing matter_type_id  Bug Ref:9602
    if matter_category=="non-litigation"
      params[:matter].merge!(:matter_type_id => params[:matter][:matter_type_nonliti] )
    else
      params[:matter].merge!(:matter_type_id => params[:matter][:matter_type_liti])
    end
    update_primary_contact(@matter, params)
    set_role_for_lawyer(@matter, params,euid)
    respond_to do |format|
      @matter, success = Matter.update_with_lead_lawyer(params, get_employee_user_id)
      if success
        if @matter.employee_user_id != euid
          if @matter.matter_peoples.lawteam_members.find_by_employee_user_id(euid).nil? and params[:button_pressed].eql?("save")
            redirect_to  edit_matter_path(@matter)
            return
          end
        end
        user = User.exists?(:username=> params[:contact][:email])
        if(!user && params[:matter][:client_access])
          user = User.new
          user.email=params[:contact][:email]
          user.first_name=@matter.contact.try(:first_name)
          user.last_name=@matter.contact.try(:last_name)
          user.username=params[:contact][:email]
          user.sign_in_count=0
          user.company_id=@matter.contact.company_id
          user.save(false)
          role=Role.find_by_name('client')
          userrole = UserRole.find_or_create_by_user_id_and_role_id(user.id,role.id)
          User.generate_and_mail_new_password_from_matter(user.username,user.email,User.current_lawyer)
          matter_user=@matter.user
          send_notification_to_lead_lawyer(matter_user,@matter,User.current_lawyer)
          #To avoid call_back create_new_user on contact.rb
          #Due to Which duplicate user was created : BY : Pratik AJ 10-05-2011
          Contact.update_all({:user_id=>user.id,:email=>user.email}, {:id => @matter.contact_id})
        end
        flash[:notice] = "#{t(:text_matter)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html {
          redirect_if(params[:button_pressed].eql?("save"), remember_past_edit_path(@matter))
          redirect_if(params[:button_pressed].eql?("save_exit"), remember_past_path)
          session[:search]=nil if params[:button_pressed].eql?("save_exit")
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @matter.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @matter = Matter.scoped_by_company_id(get_company_id).find(params[:id])
    # It's a soft delete, since we are using acts_as_paranoid.
    @matter.delete
    respond_to do |format|
      format.html { redirect_to(matters_url) }
      format.xml  { head :ok }
    end
  end

  # Used for comment form facebox in Add Comment on edit page.
  def comment_form
    #data = params
    @comment_user_id = current_user.id
    @comment_commentable_id = params[:id]
    @comment_commentable_type = 'Matter'
    @comment_title = 'Comment'
    @matter_id = params[:matter_id]
    respond_to do |format|
      format.html {render :partial => "matters/comment_form"}
    end
  end

  private
  def matter_search
    q = params[:q]
    cid = get_company_id
    if q.present?      
      Matter.search_results(cid,get_employee_user_id,q,true,params[:matter_status],params[:mode_type]).uniq
    else     
      case params[:mode_type].downcase
      when "all"
        @company.matters.find(:all, :conditions => ["status_id = ?", params[:matter_status]], :order => "name")
      when "my_all"
        Matter.team_matters(get_employee_user_id, cid,params[:matter_status], 'matters.name', true).uniq
      when "my"
        get_employee_user.matters.find(:all, :conditions => ["status_id = ?", params[:matter_status]], :order => "name")
      end
    end
  end

  public
  
  # This function is used to show selected matter on page.
  def display_selected_matter
    params[:search] ||= {} #to set params[:search] if params is nil Bug 9871
    @matters =[]
    @mode_type = params[:mode_type] #passed from the application.js to set the mode type in view
    data = params
    @matters = matter_search # Common search
    @perpage = params[:per_page].present? ? params[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
    @matters = @matters.paginate :page => data[:page], :per_page => @perpage
    respond_to do |format|
      format.js {render :partial=> 'matter'}
    end
  end

  # This function is used search into matter
  # It returns drop down of search text box with matched matter.
  def search_matter
    cid = @company.id
    @search_result =[]
    @search_result = matter_search # Common search
    respond_to do |format|
      format.js { render :partial=> 'matter_auto_complete', :object => @search_result }
      format.html { render :partial=> 'matter_auto_complete', :object => @search_result }
    end   
  end

  def common_matter_search
    cid = @company.id
    unless  params[:q].blank?
      @matching_matters = Matter.search_results(cid,get_employee_user_id, params[:q],true, nil, 'my_all', false)
    else
      @matching_matters = Matter.team_matters(get_employee_user_id, cid, nil, nil, false)
    end
    render :partial=> 'common_matter_search', :object => @matching_matters
  end

  # it links the issues with other modules - Supriya Surve/ Mandeep
  def linked_issues
    @matter = Matter.find(params[:id])
    @matter_issues = @matter.matter_issues
    @issue_type = params[:issue_type]
    @path = params[:path]
    case @issue_type
    when 'matter_research'
      object = MatterResearch.find(params[:matter_research_id])
    when 'matter_fact'
      object = MatterFact.find(params[:matter_fact_id])
    when 'matter_risk'
      object = MatterRisk.find(params[:matter_risk_id])
    when 'document_home'
      object = DocumentHome.find(params[:matter_document_id])
    end
    @submodel = object
    @matter_issueid = object.matter_issues.find(:all, :select => ['id']).collect{|a| a.id}
    if params[:link]      
      object.link_submodule(params, :matter_issue_ids)
      redirect_to params[:path]
    else
      render :partial => "linked_issues", :layout => false
    end
  end

  # it links the facts with other modules - Supriya Surve/ Mandeep
  def linked_facts
    @matter = Matter.find(params[:id])
    @matter_facts = @matter.matter_facts
    @fact_type = params[:fact_type]
    @path = params[:path]
    case @fact_type
    when 'matter_research'
      object = MatterResearch.find(params[:matter_research_id])
    when 'document_home'
      object = DocumentHome.find(params[:matter_document_id])
    end
    @submodel = object
    @matter_factid = object.matter_facts.find(:all, :select => ['id']).collect{|a| a.id}
    if params[:link]
      object.link_submodule(params, :matter_fact_ids)
      redirect_to params[:path]
    else
      render :partial => "linked_facts", :layout => false
    end
  end

  # it links the risks with other modules - Supriya Surve/ Mandeep
  def linked_risks
    @matter = Matter.find(params[:id])
    @matter_risks = @matter.matter_risks
    @risk_type = params[:risk_type]
    @path = params[:path]
    case @risk_type
    when 'matter_research'
      object = MatterResearch.find(params[:matter_research_id])
    when 'document_home'
      object = DocumentHome.find(params[:matter_document_id])
    end
    @submodel = object
    @matter_riskid = object.matter_risks.find(:all, :select => ['id']).collect{|a| a.id}
    if params[:link]
      object.link_submodule(params, :matter_risk_ids)
      redirect_to params[:path]
    else
      render :partial => "linked_risks", :layout => false
    end
  end

  # it links the tasks with other modules - Supriya Surve/ Mandeep
  def linked_tasks
    @matter = Matter.find(params[:id])
    @matter_tasks = @matter.matter_tasks
    @task_type = params[:task_type]
    @path = params[:path]
    case @task_type
    when 'matter_research'
      object = MatterResearch.find(params[:matter_research_id])
    when 'document_home'
      object = DocumentHome.find(params[:matter_document_id])
    end
    @submodel = object
    @matter_taskid = object.matter_tasks.find(:all, :select => ['id']).collect{|a| a.id}
    if params[:link]
      object.link_submodule(params, :matter_task_ids)
      redirect_to params[:path]
    else
      render :partial => "linked_tasks", :layout => false
    end
  end
  #This function is for providing the information related for creating the new client by proving a form for new client creation
  def new_client
    @contact = Contact.find(params[:contact_id])
    render :layout => 'false'
  end

  def get_client_contact
    @contact = Contact.find(params[:contact_id])
    @matter_people=MatterPeople.find(:first,:conditions=>["contact_id=? and matter_id=?",params[:contact_id],params[:matter_id]])
    @matter=Matter.find(params[:matter_id]) unless params[:matter_id].blank?
    respond_to do |format|
      format.js {
        render :update do |page|
          if @contact.email.present?
            page<<"jQuery('#contact_email').val('#{@contact.email}');"
          else
            page<<"jQuery('#contact_email').val('');"
          end
          if @matter.present? and @matter_people.can_access_matter
            page<<"jQuery('#matter_client_access').attr('checked', true);"
            page<<"jQuery('#contact_email').addClass('selected');"
          else
            page<<"jQuery('#matter_client_access').attr('checked', false);"
          end
        end
      }
    end
  end
  def validate_email
    user = User.exists?(:username=> params[:email_id])
    err= user ? "A member with the same e-mail id already present in the system" : nil
    respond_to do |format|
      format.json { render :json => {:exists=>user,:msg=>err }}
    end
  end

  def delete_matter
    company_id = params[:company_id].blank? ? get_company_id : params[:company_id]
    @matter = Matter.scoped_by_company_id(company_id).find(params[:id])
    matter = @matter
    matter_name = @matter.name
    user = current_user
    @matter.delete_matter
    send_notification_to_lead_lawyer_after_matter_delete(matter,user)
    respond_to do |format|
      flash[:notice] = "#{t(:text_matter)} " "\"#{matter_name}\" " "#{t(:flash_was_successful)} " "deleted."
      return_path = params[:company_id].blank? ? matters_path(:page=>params[:page],:mode_type=> params[:mode_type]) : matter_documents_companies_path(:page => params[:page], :company_id => company_id)
      format.html{ redirect_to return_path}
    end
  end
  
  private
  
  def get_report_favourites
    @matters_fav = CompanyReport.find(:all,:conditions => ["company_id = ? and employee_user_id = ? and report_type = ?",get_company_id,get_employee_user_id,'Matter'])
  end

  def set_lead_lawyer_docs(old_lead,new_lead,params,matter_document)
    employee_user_id = get_employee_user_id
    selective_doc = matter_document.select{|doc| doc.access_rights != 1}
    if params[:for_private] == "transfer_workspace"
      private_doc = matter_document.select{|doc| doc.access_rights == 1}
      private_doc.each do |doc_home|
        doc_home.update_attributes({:mapable_type=>"User",:mapable_id=> employee_user_id})
      end
    elsif params[:for_private] == "transfer_ownership"
      private_doc = matter_document.select{|doc| doc.access_rights == 1 && params[:private_document_ids].include?("#{doc.id}")}
      unless params[:for_private]=="transfer_workspace"
        private_doc.each do |doc_home|
          doc_home.update_attributes({:owner_user_id=> new_lead.employee_user_id})
        end
      end
    end
    if params[:other_documents]=="true"
      selective_doc.each do |sel_dh|
        if sel_dh.owner_user_id==employee_user_id
          sel_dh.update_attributes({:owner_user_id=> new_lead.employee_user_id})
        end
        DocumentAccessControl.create(:matter_people_id=> new_lead.id, :document_home_id=> sel_dh.id, :company_id=> sel_dh.company_id)
      end
    else
      matter_people_ids =[]
      select_view_doc = selective_doc.find_all{|doc| doc.access_rights==4}
      select_view_doc.each do |sel_dh|
        matter_people_ids = sel_dh.matter_people_ids
        new_lead_mp_id = @matter.matter_peoples.find_by_employee_user_id(new_lead.employee_user_id).id
        if !matter_people_ids.include?(new_lead_mp_id )
          matter_people_ids << new_lead_mp_id
        end
        sel_dh.update_attributes({:matter_people_ids => matter_people_ids })
      end
    end
    DocumentAccessControl.destroy_all "matter_people_id=#{old_lead.id}"
  end
  
  private

  def set_role_for_lawyer(matter, params, euid)
    if !params[:lawyer].blank? and !params[:lawyer][:role].blank?
      lawyer = matter.matter_peoples.new({
          :employee_user_id => euid,
          :people_type => 'client',
          :created_by_user_id => matter.created_by_user_id,
          :is_active => true,
          :matter_team_role_id => params[:lawyer][:role],
          :start_date => matter.matter_start_date,
          :company_id => matter.company_id
        })
      lawyer.save!
    end
  end
  
end
