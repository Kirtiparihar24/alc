#Campaigns : This is a email campaign used for advertising.
# Email Address (Contacts) records are selected from the Lists. One or more lists can be included in a campaign.
# Even partial lists can be included. Extensive address filters are incorporated for target marketing and email
#  personalization (mail merge) purposes.

class CampaignsController < ApplicationController

  require 'mail'
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}
  before_filter :authenticate_user!  , :except => [:response_form, :response_submit]
  before_filter :get_base_data, :except => [:response_form, :response_submit]
  before_filter :parent_compaigns, :only => [:new, :create]
  before_filter :current_service_session_exists, :except => [:response_form, :response_submit]
  layout 'full_screen', :except =>[:response_form, :response_submit,:show_response, :show_help, :change_status, :unattented_list]
  before_filter :get_report_favourites ,:only => [:index,:new,:edit]  
  add_breadcrumb I18n.t(:text_campaigns), :campaigns_path
  @@status_hash = {"Inprogress" => "@inprogress","Planned" => "@planned","Completed" => "@completed","Aborted" => "@aborted"}
  helper_method :remember_past_path,:remember_past_edit_path
  
  def index
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'campaigns.name', :dir => 'up')
    end
    @pagenumber=155
    authorize!(:index,@current_user) unless @current_user.has_access?(:Campaigns)
    set_params_filter    
    # Below code will return order params.
    sort_column_order
    params[:order] = @ord.nil?? 'campaigns.name ASC':@ord
    # Below code will execute depenading on params[:mode_type] 1.e "MY" or "ALL"
    cuser = get_employee_user
    if    cuser.employee.my_campaign == true
      @mode_type = (params[:mode_type]= 'MY')
      flash[:notice]="You are configured to view details only of My Campaigns"
    elsif(params[:mode_type] == nil)
      @mode_type= 'MY'
      params.merge!(:mode_type=>'MY')
    else
      @mode_type= params[:mode_type]
    end
    lookup_stages = @company.campaign_status_types
    @camp_stage = params[:stage] = params[:stage].blank? ? '' : params[:stage]
    params.merge!({:per_page => 25}) unless params[:per_page]
    @campaigns = Campaign.get_campaigns(params, @company.id, @emp_user.id)
    @first_mail_date_arr = Campaign.get_all_first_mail_date(@company, @campaigns)
    lookup_stages = lookup_stages.collect{|stage|[stage.try(:alvalue), stage.try(:id)]}
    @lookup_stages = Campaign.count_stage_wise_campaigns(@company, params[:stage], @mode_type,@emp_user_id, lookup_stages)
    @letter_selected  = params[:letter]
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace 'campaigns', :partial => 'searched_campaigns'
        end
      }
    end
  end  

  #Used to search new contacts and add to existing campaign
  def search
    data = params
    search = data[:search]
    @campaign = @company.campaigns.find(data[:campaign_id])
    search[:name] = search[:name].strip if search[:name]
    search[:status_type] = search[:status_type].strip if search[:status_type]
    search[:address] = search[:address].strip if search[:address]
    added_contacts_id = [0]  # added id 0 to avoid if condition and archive performance (Why 0 :  since 0 is never going to be used as an id in any table)    
    if (search[:name] || search[:status_type] || search[:address]) && request.post?
      if search[:status_type].eql?('All')
      	contact_stages_id = @company.contact_stages.collect(&:id).join(",")
      else
        contact_stages_id = search[:status_type]
      end
      condition ="contacts.email is not NULL and contact_stage_id IN (#{contact_stages_id}) and contacts.id not in (#{added_contacts_id.join(',')})"
      contact_condition = condition +" and do_not_call is false"
      call_condition = condition +" and do_not_call is true"
      name_condition, address_condition = '', ''
      include_arr = [:contact_stage,:accounts]
      include_arr << :address if search[:address].present?
      name_condition = " and  (first_name ||' ' || coalesce(middle_name,'') ||' '|| coalesce(last_name,'') ilike '%#{search[:name]}%' or" +
        " coalesce(last_name,'') ||' '||first_name ||' '|| coalesce(middle_name,'') ilike '%#{search[:name]}%' )"  if search[:name].present?
      address_condition = " and (addresses.street ilike '%#{search[:address]}%' or" +
        " addresses.city ilike '%#{search[:address]}%' or" +
        " addresses.country ilike '%#{search[:address]}%' or" +
        " addresses.zipcode ilike '%#{search[:address]}%' or" +
        " addresses.state ilike '%#{search[:address]}%') "   if search[:address].present?
      @contacts = @company.contacts.find(:all, :include=> include_arr,
        :conditions => (contact_condition + address_condition + name_condition),
        :order => "contacts.email ASC")
      @do_not_call_contacts = @company.contacts.find(:all, :include=>include_arr,
        :conditions => (call_condition + address_condition + name_condition),
        :order => "contacts.email ASC")
      respond_to  do |format|
        format.js
      end
    end
  end

  #This method is used to add or delete members from a campaign
  #Added first_name,last_name and email while inserting records in campaign_mebers for last name wise sorting
  def contacts_campaign
    authorize!(:contacts_campaign,@current_user) unless @current_user.has_access?(:Campaigns)
    data=params    
    data[:selected_records] = data[:selected_records] ? data[:selected_records] : []
    data[:delete_records] = data[:delete_records] ? data[:delete_records] : []
    @campaign = @company.campaigns.find(data[:campaign_id])
    @campaign_contacts = @company.campaign_members
    @status_types = @current_company.campaign_status_types    
    get_employees
    unless data[:submit_action]=='Delete'
      rejected_leads= 0
      unless data[:selected_records].blank?
        data[:selected_records].each do|contact|          
          contact_object = @company.contacts.find(contact)
          unless @company.campaign_members.find_by_campaign_id_and_contact_id(data[:campaign_id],contact) && contact_object.email
            member = @company.campaigns.find(data[:campaign_id]).members.create(:contact_id => contact, :campaign_member_status_type_id => @current_company.campaign_member_status_types.find_by_lvalue('New').id, :employee_user_id => @emp_user_id, :created_by_user_id => @current_user.id, :company_id => @company.id, :salutation_id => contact_object.salutation_id, :last_name => contact_object.last_name, :first_name => contact_object.first_name, :middle_name => contact_object.middle_name, :email => contact_object.email, :alt_email => contact_object.alt_email)
          else
            rejected_leads = rejected_leads + 1
            flash[:notice] = rejected_leads.to_s + ' members are already part of this campaign.'
          end
        end
      else
        flash[:error] = "Please select the contacts"
      end
    else
      data[:delete_records].each do|member|
        @member =@company.campaign_members.find(member)
        @member.destroy
      end
      flash[:notice]=data[:delete_records].length.to_s + ' members removed from campaign.'
    end
    @tabselected='fragment-1'
    redirect_to "#{remember_past_edit_path(@campaign)}#fragment-1"
  end
  
  def show
    authorize!(:show,@current_user) unless @current_user.has_access?(:Campaigns)
    @campaign = @company.campaigns.find(params[:id])    
    @comment = Comment.new
    render :layout =>false
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :xml)
  end

  # As the name suggests this method is used to activate a deactivated campaign
  def activate_camp
    @campaign = @company.campaigns.find_with_deleted(params[:id])
    begin
      Campaign.transaction do
        @campaign.update_attribute(:deleted_at,nil)
        @campaign.comments<< Comment.new(:title=>'Campaign Activated',
          :created_by_user_id=> @current_user.id,
          :commentable_id => @campaign.id,:commentable_type=> 'Campaign',
          :comment =>  "Campaign Activated",
          :company_id=> @campaign.company_id )
        @campaign.save
      end
      flash[:notice] = "#{t(:text_campaign)} " "#{t(:flash_was_successful)} " "#{t(:text_activated)}"
      redirect_to :back
    rescue Exception => exc
      logger.info("Error in activating campaign: #{exc.message}")
      flash[:error] = "DB Store Error: #{exc.type}"
    end
  end

  # Used to display the search results
  def display_selected_campaign
    params[:search] ||= {} #to set params[:search] if params is nil Bug 9871
    @campaigns =[]
    @mode_type = params[:mode_type] #passed from the application.js to set the mode type in view
    data=params    
    unless data[:q].blank?
      if get_employee_user.employee.my_campaign == true
        @campaigns = @company.campaigns.search "*" + data[:q] + "*",:with =>{:employee_user_id => @current_user.id}, :limit => 10000, :select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id)  as opportunity, (select sum(amount) from opportunities where campaign_id = campaigns.id)  as opportunity_amount"
      else
        @campaigns = @company.campaigns.search "*" + data[:q] + "*", :limit => 10000, :select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{current_company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id)  as opportunity, (select sum(amount) from opportunities where campaign_id = campaigns.id)  as opportunity_amount"
      end      
    else
      inprogress = CampaignStatusType.inprogress(@current_company)[0].id
      planned    = CampaignStatusType.planned(@current_company)[0].id
      if get_employee_user.employee.my_campaign == true        
        @campaigns = @company.campaigns.find_my_campaign(@current_user.id, params, @current_company)       
      else
        @campaigns = @company.campaigns.all(:select => "campaigns.*,(SELECT first_mailed_date FROM campaign_members WHERE first_mailed_date IS NOT NULL AND campaign_id = campaigns.id LIMIT 1) AS first_mailed_date, (SELECT alvalue FROM company_lookups WHERE id = campaigns.campaign_status_type_id) AS campaign_status, (SELECT username FROM users WHERE id = campaigns.owner_employee_user_id) AS username,(SELECT COUNT(*) FROM campaign_members WHERE campaign_id = campaigns.id) AS member_count, (SELECT COUNT(responded_date) FROM campaign_members WHERE campaign_id = campaigns.id AND responded_date IS NOT NULL) AS responded_date, (SELECT COUNT(campaign_member_status_type_id) FROM campaign_members WHERE campaign_id = campaigns.id AND campaign_member_status_type_id = (SELECT id FROM company_lookups WHERE company_id = #{current_company.id} AND type = 'CampaignMemberStatusType' AND lvalue = 'Responded')) AS campaign_member_status_type_id, (SELECT COUNT(*) FROM opportunities WHERE campaign_id = campaigns.id) AS opportunity, (SELECT SUM(amount) FROM opportunities WHERE campaign_id = campaigns.id) AS opportunity_amount", :conditions => ["campaign_status_type_id IN (?, ?)", inprogress, planned], :order => 'created_at DESC')
      end      
    end
    @perpage = params[:per_page].present? ? params[:per_page] : 25 # added for changing pagination limit - do not remove -- Supriya
    @campaigns=@campaigns.paginate :per_page=> @perpage, :page => data[:page]
    render :partial => 'searched_campaigns'
  end

  #Used to search a campaign
  def sphinx_search_campaign
    @search_result =[]
    cuser = get_employee_user
    usermy_campaigns = cuser.employee.my_campaign == true
    unless params[:q].blank?
      if usermy_campaigns
        @search_result = @company.campaigns.search "*" + params[:q] + "*",:with =>{:owner_employee_user_id=>@current_user.id}, :limit => 10000
      else
        @search_result = @company.campaigns.search "*" + params[:q] + "*" , :limit => 10000
      end
    else
      inprogress = CampaignStatusType.find_all_by_lvalue_and_type_and_company_id('Inprogress', 'CampaignStatusType', @current_company).collect{|p| p.id}
      planned    = CampaignStatusType.find_all_by_lvalue_and_type_and_company_id('Planned','CampaignStatusType', @current_company).collect{|p| p.id}
      if usermy_campaigns
        @search_result = @company.campaigns.all(:conditions => ["owner_employee_user_id = ? AND campaign_status_type_id IN (?,?)",@current_user.id, inprogress, planned], :order => 'created_at DESC')
      else
        @search_result = @company.campaigns.all(:conditions => ["campaign_status_type_id IN (?,?)", inprogress, planned], :order => 'created_at DESC')
      end
    end
    render :partial=> 'campaign_auto_complete', :object => @search_result
  end  
  
  # GET /campaigns/new
  # GET /campaigns/new.xml                                                 AJAX
  #----------------------------------------------------------------------------
  def new         
    authorize!(:new,@current_user) unless @current_user.has_access?(:Campaigns)     
    @campaign = @company.campaigns.new(:camp_radio=>"1")
    @status_types= @current_company.campaign_status_types
    @users = User.except(@current_user).all
    @pagenumber=76
    @employees =  User.find_user_not_admin_not_client(@company.id)
    add_breadcrumb "#{t(:text_new)} #{t(:text_campaign)}", new_campaign_path

  end

  # GET /campaigns/1/edit                                                  AJAX
  #----------------------------------------------------------------------------
  def edit
    sort_column_order
    @ord = @ord.nil? ? "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') DESC":@ord
    @pagenumber=77
    authorize!(:edit,@current_user) unless @current_user.has_access?(:Campaigns)    
    data=params
    session[:reason_changed]=false
    @tab_index= data[:tabindex] ? data[:tabindex] : 0
    @campaign = @company.campaigns.find(data[:id], :include => [:opportunities, :members, :campaign_mails])
    @notes = Comment.scoped_by_commentable_type('Campaign').scoped_by_commentable_id(data[:id]).find_with_deleted(:all, :order => "created_at DESC")
    mails=@campaign.campaign_mails
    members=@campaign.members   
    @document_homes = @campaign.document_homes
    @status_types= @company.campaign_status_types
    @contact_stages= @company.contact_stages
    @campaign_first_email = mails.first(:conditions => ["mail_type = 'first'"])
    @campaign_first_email = @campaign_first_email ? @campaign_first_email : @campaign.campaign_mails.new
    @document_home_first = @campaign_first_email.document_homes.reverse   
    @campaign_second_email = mails.first(:conditions => ["mail_type = 'reminder'"])
    @campaign_second_email = @campaign_second_email ? @campaign_second_email : @campaign.campaign_mails.new
    @document_home_second = @campaign_second_email.document_homes    
    responded_id = current_company.campaign_member_status_types.find_by_lvalue("Responded").id 
    @campaign_unattended_responses = members.all(:conditions => ['campaign_member_status_type_id = ? AND company_id = ?', responded_id, current_company])
    @campaign_attended_responses = members.all(:conditions => ["campaign_member_status_type_id != ? AND response != ''and company_id =? ",responded_id,current_company])   
    @campaign_suspended_list = @campaign.members.all(:conditions => ['campaign_member_status_type_id = ?', current_company.campaign_member_status_types.find_by_lvalue("Suspended").id])
    @users = User.except(@current_user).all
    @campaign_contacts = members.all(:order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    @campaign_opportunities = @campaign.opportunities
    @employees =  User.find_user_not_admin_not_client(@company.id)
    # Feature 6407 - Supriya Surve - 9th May 2011 for appending more email-id's to employees email's array
    @from_emailids = @employees.collect{|cnt|[cnt.email]}
    @from_emailids << @company.campaign_mailer_emails.collect{|obj| obj.setting_value}
    @from_emailids = @from_emailids.flatten.sort unless @from_emailids.blank?
    add_breadcrumb "#{t(:text_edit)} #{t(:text_campaign)}", edit_campaign_path(@campaign)
    render :layout => "left_with_tabs"
    if data[:previous] =~ /(\d+)\z/
      @previous = Campaign.find($1)
    end       
  rescue ActiveRecord::RecordNotFound
    @previous ||= $1.to_i
    respond_to_not_found(:js) unless @campaign
  end

  # POST /campaigns
  # POST /campaigns.xml                                                    AJAX
  #----------------------------------------------------------------------------
  def create    
    authorize!(:create,@current_user) unless @current_user.has_access?(:Campaigns)
    data=params    
    @pagenumber=76
    data[:campaign][:created_by_user_id] = @current_user.id
    data[:campaign][:employee_user_id] = @emp_user_id
    data[:campaign][:company_id] = @company.id
    data[:campaign][:current_user_name] = @current_user.full_name
    data[:campaign][:name] = data[:campaign][:name].strip
    @status_types = @current_company.campaign_status_types
    @users = User.except(@current_user).all
    @employees = User.find_user_not_admin_not_client(@company.id)
    begin
      Campaign.transaction do
        if data[:campaign][:camp_radio] == '1'  && data[:campaign][:parent_id].present?
          @copy_campaign = @company.campaigns.find(data[:campaign][:parent_id])
          data[:campaign][:parent_id] = @copy_campaign.id
        end
        @campaign = Campaign.new(data[:campaign])
        if @campaign.save
          @campaign.comments << Comment.create(:title=> 'Campaign Created', :created_by_user_id=> @current_user.id, :commentable_id =>@campaign.id,:commentable_type=> 'Campaign', :comment => 'Campaign created', :company_id => @company.id )
          if  !data[:campaign][:copy].nil? &&  !data[:campaign][:copy].eql?("0") &&  @copy_campaign
            @copy_campaign.members.each do |member|
              @campaign.members.create(:contact_id => member.contact_id, :status => CampaignMemberStatusType.find_by_lvalue_and_company_id('New',@company.id), :company_id => @company.id, :employee_user_id => @emp_user_id, :created_by_user_id => @current_user.id, :salutation_id => member.salutation_id,:first_name=> member.first_name, :last_name => member.last_name, :email => member.email, :alt_email => member.alt_email, :phone => member.phone, :website => member.website, :mobile => member.mobile, :fax =>member.fax,:title =>member.title, :nickname => member.nickname)
            end
          end
          #copying mails here
          if @copy_campaign
            @copy_campaign.campaign_mails.each do |mail|
              @campaign.campaign_mails.create(:content=> mail.content,
                :company_id => @company.id, :mail_type => mail.mail_type, :subject =>
                  mail.subject, :signature => mail.signature) if (@copy_campaign && @copy_campaign.campaign_mails.first.present?)
            end
          end

          if data[:campaign][:camp_radio] == '1'  && data[:campaign][:parent_id].present?            
            copy_email = @copy_campaign.campaign_mails.first(:conditions => ["mail_type = 'first'"])
            copy_campaign_second_email  = @copy_campaign.campaign_mails.first(:conditions => ["mail_type='reminder'"])            
            campaign_email = @campaign.campaign_mails.first(:conditions => ["mail_type = 'first'"])
            campaign_second_email = @campaign.campaign_mails.first(:conditions => ["mail_type = 'reminder'"])
            # copying attachments here
            Campaign.copy_attachments_from_campgs(copy_email, @current_user.id,campaign_email.id,get_employee_user_id,current_company.id) if copy_email
            Campaign.copy_attachments_from_campgs(copy_campaign_second_email, @current_user.id,campaign_second_email.id,get_employee_user_id,current_company.id) if copy_campaign_second_email
          end

          flash[:notice] =  "#{t(:text_campaign)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          redirect_if(data[:button_pressed].eql?("save"), "#{edit_campaign_path(@campaign)}#fragment-6")
          redirect_if(data[:button_pressed].eql?("save_exit"), campaigns_path)

        else
          @copy = data[:campaign][:copy]
          render :action=> 'new'    
        end
      end   
    rescue Exception => exc
      logger.info("Error in activating campaign: #{exc.message}")
      flash[:error] = "DB Store Error: #{exc.type}"
    end
  end

  # This method is used to create a campaign from an existing campaign-------------Manish Puri
  def search_campaign
    data=params    
    cuser = get_employee_user
    usermy_campaigns = cuser.employee.my_campaign == true
    if usermy_campaigns
      @campaigns = Campaign.all(:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{@company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, (select sum(amount) from opportunities where campaign_id = campaigns.id)  as opportunity_amount",:conditions=>["campaigns.owner_employee_user_id in (?)", @emp_user_id],:order=>params[:order])
    else
      @campaigns = @company.campaigns.find_all_campaign(params,current_company)
    end    
    @campaign = data[:parent_id].nil? ? @company.campaigns.new : @company.campaigns.find(data[:parent_id])
    @campaign.name='Copy Of ' + @campaign.name
    @campaign.starts_on =nil
    @campaign.parent_id= data[:parent_id]
    @campaign.ends_on =nil
    @campaign.campaign_status_type_id = CampaignStatusType.find_by_lvalue('InProgress')
    @status_types= @current_company.campaign_status_types
    @users = User.except(@current_user).all
    @msg=true
    @employees =  User.find_user_not_admin_not_client(@company.id)
    render :partial=>'create'
  end

  #This method is used for the comments view on the index page
  def comments
    id= params[:id]
    campaign = @company.campaigns.find_with_deleted(id)
    @notes = campaign.comments.find_with_deleted(:all, :conditions => "title in ('Comment','Note')", :order => "created_at DESC")
    @comment = Comment.new
    @commentable = campaign
    @return_path = campaigns_path
    render :partial => "common/comment", :locals => {:type => "Campaign"}, :layout => false
  end

  #Used to create an opportunity after a positive response from the member
  def create_opportunity   
    @pagenumber = 201
    data = params    
    @campaigns = @company.campaigns
    @campaign_member =  @company.campaign_members.find(data[:id])
    @campaign = @campaign_member.campaign
    @opportunity = Opportunity.new(:assigned_to_employee_user_id => @campaign.owner_employee_user_id, :company_id => @company.id)
    @contact = @campaign_member.contact if @campaign_member.contact_id
    @campaign_contact = @campaign_member    
    @employees = User.find_user_not_admin_not_client(@company.id)
    if request.post?
      @campaign = @company.campaigns.find(data[:opportunity][:campaign_id])
      data[:opportunity][:source] = CompanySource.find_by_lvalue_and_company_id('Campaign',current_company).id
      data[:opportunity][:company_id] = @company.id
      data[:opportunity][:employee_user_id] =  @emp_usr_id
      data[:opportunity][:follow_up] = Time.zone.parse("#{data[:opportunity][:follow_up]}T#{data[:opportunity][:follow_up_time]}").getutc      
      contact_stage_id = @company.contact_stages.find_by_lvalue('Prospect').id
      Campaign.transaction do
        @opportunity = Opportunity.new(data[:opportunity])
        unless data[:contact][:id].present?
          @contact = Contact.scoped_by_company_id(@campaign.company_id).first(:conditions => ['first_name = ? AND middle_name = ? AND last_name = ? AND email = ?', data[:contact][:first_name], data[:contact][:middle_name], data[:contact][:last_name], data[:contact][:email]])
          if @contact.present?
            data[:contact][:id] =@contact.id
          else            
            @contact=  Contact.new(data[:contact].merge!(:company_id=> @company.id, :employee_user_id =>data[:opportunity][:assigned_to_employee_user_id],:assigned_to_employee_user_id =>data[:opportunity][:assigned_to_employee_user_id],:created_by_user_id =>get_employee_user_id,:contact_stage_id=>contact_stage_id,:source=>data[:opportunity][:source]))
            if @contact.save
              data[:contact][:id] =@contact.id
            end
          end          
        end
        @opportunity.current_user_name=get_user_name
        if @opportunity.save_with_contact(data)
          flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
          @campaign_member.update_attributes(:opportunity_id=>@opportunity.id, :campaign_member_status_type_id=>current_company.campaign_member_status_types.find_by_lvalue("Opportunity").id,:updated_by_user_id=>@current_user.id)
          redirect_to "#{remember_past_edit_path(@campaign)}#{params[:fragment]}"
        else
          render :action=>'create_opportunity'
        end
      end
    end
  end

  # This method is used for the email template-This method sends,saves first and reminder email in the campaign
  ########### Campaign Mailer is being sent batch wise instead of one-by-one using find_in_batches methos ######
  def campaign_email
    data = params    
    url = url_link
    @campaign = @company.campaigns.find(data[:campaign_id], :include => [:members, :campaign_mails])
    campaign_id = @campaign.id
    @campaign_contacts =  @campaign.members.limit_size
    @campaign_first_email = @campaign.campaign_mails.first(:conditions => ["mail_type = ?", "first"])
    @campaign_first_email = @campaign_first_email.present? ? @campaign_first_email : @campaign.campaign_mails.new
    @document_home_first = @campaign_first_email.document_homes
    @campaign_second_email= @campaign.campaign_mails.first(:conditions => ["mail_type = ?", "reminder"])
    @campaign_second_email= @campaign_second_email.present? ? @campaign_second_email : @campaign.campaign_mails.new
    @document_home_second = @campaign_second_email.document_homes
    @employees =  User.find_user_not_admin_not_client(@company.id)
    data[:email][:first_email] = data[:first_email]
    data[:email][:second_email] = data[:second_email]
    session[:default_email] = data[:email][:owners_email]

    if data[:send_test_email].present?
      attachment = @document_home_first.collect(&:id)
      CampaignMailer.deliver_send_first_mail(url,campaign_id,data[:email][:owners_email],data[:email][:subject], data[:campaign_first_email],data[:email][:signature],attachment,current_company,params[:email][:from_user_id], '')
      flash[:notice] = t(:flash_testmail)
      
    elsif data[:send_first_email].present?
      campaign_contacts = @campaign_contacts.collect(&:id)
      document_homes_first = @document_home_first.collect(&:id)
      Resque.enqueue(CampaignEmail, 'first', url,campaign_id,data[:email][:subject],params[:campaign_first_email],data[:email][:signature],document_homes_first, campaign_contacts,@company.id, @emp_user.email,@emp_user.id,current_company.id,params[:email][:from_user_id],current_user.id,params[:format_style])
      flash[:notice] = t(:flash_campaigns_first_mail)
      
    elsif data[:send_reminder_email].present?
      campaign_contacts = @campaign_contacts.collect(&:id)
      document_homes_second =  @document_home_second.collect(&:id)
      Resque.enqueue(CampaignEmail, 'reminder', url,campaign_id,data[:email][:subject],params[:campaign_second_email],data[:email][:signature],document_homes_second, campaign_contacts,@company.id, @emp_user.email,@emp_user.id,current_company.id,params[:email][:from_user_id],current_user.id,params[:format_style])
      flash[:notice] = t(:flash_campaigns_reminder_mail)
      
    elsif data[:save_first_email].present?     
      if @campaign_first_email && !params[:campaign_first_email].nil?
        @campaign_first_email.update_attributes('campaign_id'=> data[:campaign_id], 'created_by_user_id'=> @current_user.id, :signature=> data[:email][:signature],:mail_type=>'first', :subject=> data[:email][:subject],:content => Campaign.get_content(params[:campaign_first_email],url),:updated_by_user_id=>@current_user.id,:company_id => @company.id )
      else
        @campaign.campaign_mails.create( 'created_by_user_id'=> @current_user.id, :signature=> data[:email][:signature],:mail_type=>'first', :subject=> data[:email][:subject],:content => data[:first_email],:created_by_user_id=>@current_user.id,:company_id=>@company.id )
      end

      if data[:additional_documents].present?  #CODE FOR ATTACHMENT TO BE SENT FOR FIRST MAIL
        document = data[:additional_documents][:document_attributes]
        error,add_doc,doc = Campaign.save_docs(document,data[:additional_documents],@campaign_first_email,@emp_user_id,get_employee_user_id,@company.id,current_company.id,@current_user.id)
        flash[:notice] = set_flash_for_update_mail(error,add_doc,doc,"FIRST")
      end

      flash[:notice] = t(:flash_campaigns_first_mail_saved)
    elsif data[:save_reminder_email].present?      
      if @campaign_second_email
        @campaign_second_email.update_attributes('campaign_id'=> data[:campaign_id], 'created_by_user_id'=> @current_user.id, :signature=> data[:email][:signature],:mail_type=>'reminder', :subject=> data[:email][:subject],:content => Campaign.get_content(params[:campaign_second_email],url),:updated_by_user_id=>@current_user.id,:company_id=>@company.id  )
      else
        @campaign.campaign_mails.create( 'created_by_user_id'=> @current_user.id, :signature=> data[:email][:signature],:mail_type=>'reminder', :subject=> data[:email][:subject],:content => data[:second_email],:created_by_user_id=>@current_user.id,:company_id=>@company.id   )
      end
      
      if data[:additional_documents_second].present?  #CODE FOR ATTACHMENT TO BE SENT
        document = data[:additional_documents_second][:document_attributes]
        document_error,additional_documents,document = Campaign.save_docs(document,data[:additional_documents_second],@campaign_second_email,@emp_user_id,get_employee_user_id,@company.id,current_company.id,@current_user.id)
        flash[:notice] = set_flash_for_update_mail(document_error,additional_documents,document,"REMINDER")
      end
    end
    respond_to_parent do
      render :update do|page|
        page << "window.location.reload();"
      end
    end
  end

  #CRUD method generated from scaffold used to update a campaign
  def update
    data=params    
    @campaign = @company.campaigns.find(data[:id])
    mails = @campaign.campaign_mails    
    @campaign_opportunities = @campaign.opportunities
    @notes = @campaign.comments
    members = @campaign.members
    @contact_stages = @company.contact_stages
    @document_homes = @campaign.document_homes
    @campaign_first_email = mails.first(:conditions => ["mail_type = ?", "first"])
    @campaign_first_email = @campaign_first_email ? @campaign_first_email : @campaign.campaign_mails.new
    @campaign_second_email = mails.first(:conditions => ["mail_type = ?", "reminder"])
    @campaign_second_email = @campaign_second_email ? @campaign_second_email : @campaign.campaign_mails.new
    responded_id = CampaignMemberStatusType.find_by_lvalue("Responded").id
    @campaign_responses = members.all(:conditions => ["responded_date IS NOT NULL"]) 
    @campaign_unattended_responses = members.all(:conditions => ['campaign_member_status_type_id = ?', responded_id])
    @campaign_attended_responses = members.all(:conditions => ["campaign_member_status_type_id != ? and response != '' ", responded_id])
    @campaign_suspended_list = members.all(:conditions => ['campaign_member_status_type_id = ?', CampaignMemberStatusType.find_by_lvalue("Suspended").id])
    @status_types = @current_company.campaign_status_types
    @campaign_contacts = members
    @campaign.write_attribute('reason',data[:campaign][:reason])
    @employees = User.find_user_not_admin_not_client(@company.id)
    data[:campaign][:updated_by_user_id] = @current_user.id
    data[:campaign][:name] = data[:campaign][:name].strip
    if @campaign.update_attributes(data[:campaign])
      flash[:notice] = "#{t(:text_campaign)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"      
      redirect_if(data[:camp_button_pressed].eql?("save"), "#{remember_past_edit_path(@campaign)}#fragment-6")
      redirect_if(data[:camp_button_pressed].eql?("save_exit"), remember_past_path)
    else
      render :action =>'edit'
    end
  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml)
  end

  # DELETE /campaigns/1
  # DELETE /campaigns/1.xml                                       HTML and AJAX
  #----------------------------------------------------------------------------
  def destroy
    msg = "#{t(:text_campaign)} " "#{t(:flash_was_successful)} "
    @campaign = @company.campaigns.find_with_deleted(params[:id])
    Campaign.transaction do
      @campaign.comments << Comment.new(:title=>'Campaign Deleted',
        :created_by_user_id=> @current_user.id,
        :commentable_id => @campaign.id,:commentable_type=> 'Campaign',
        :comment =>  "Campaign Deleted",
        :company_id=> @campaign.company_id )
      @campaign.destroy
      msg += "deleted"
    end   
    flash[:notice] = msg
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

  # Used for the change status view in campaigns module at the link in the index page
  def change_status    
    @campaigntemp = @company.campaigns.find(params[:id])
    @campaign =  @company.campaigns.find(params[:id])
    @status_types=current_company.campaign_status_types.reject{|item|( item.lvalue==@campaign.status.lvalue)}
  end

  #Used to update the status of a campaign from the link on the index page
  def save_status
    data=params    
    @campaign = @company.campaigns.find(data[:campaign][:id])
    @status_types=current_company.campaign_status_types.all(:order =>'id').reject{|item|( item.lvalue==@campaign.status.lvalue)}    
    if  @campaign.update_attributes(:campaign_status_type_id=> data[:campaign][:campaign_status_type_id].to_i,:updated_by_user_id=>@current_user.id, :reason=> data[:campaign][:reason])
      flash[:notice] = "#{t(:text_campaign)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      respond_to do |format|
        format.js {
          render :update do |page|
            page << "tb_remove();"
            page << "window.location.reload()"
          end
        }
      end
    else
      errs = "<ul>" + @campaign.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
      respond_to do |format|
        format.js {
          render :update do |page|
            page << "show_error_msg('nameerror','#{errs}','message_error_div');"
            page<< "jQuery('#loader').hide();"
          end
        }
      end      
    end
  end

  # Used to update a campaign member status as rejected
  def reject_member_status   
    @member = @company.campaign_members.find(params[:id])
    @member.update_attributes(:campaign_member_status_type_id=>current_company.campaign_member_status_types.find_by_lvalue("Rejected").id,:updated_by_user_id=>@current_user.id)
    flash[:notice]='Member rejected sucessfully'
    redirect_to "#{remember_past_edit_path(@member.campaign_id)}##{params[:fragment]}"
  end

  #Used to update a campaign member status as suspended
  def suspend_member_status
    @member = @company.campaign_members.find(params[:id])
    @member.update_attributes(:campaign_member_status_type_id => current_company.campaign_member_status_types.find_by_lvalue("Suspended").id, :updated_by_user_id => @current_user.id)
    flash[:notice]='Member suspended sucessfully'
    redirect_to "#{remember_past_edit_path(@member.campaign_id)}#fragment-3"
  end 

  #Used for the View which a contact gets to send a campaign response
  def response_form
    @contact = Contact.new
    @campaign = Campaign.find(params[:id])
    if @campaign.nil?
      flash[:error] = "#{t(:text_campaign)} not found"
      redirect_to campaigns_path
    else
      @campaign_response=@campaign.members.new
    end
  end

  #Used for the View which a contact gets to send a campaign response
  #Used for the View which a contact gets to send a campaign response
  def response_submit
    data = params
    @campaign = Campaign.find_with_deleted(data[:response][:campaign_id])
    @campaign_response = @campaign.members.new
    found = false
    if data[:response][:response].blank? or data[:contact][:first_name].blank? or data[:contact][:email].blank?
      @campaign_response.errors.add("Please enter ","all the details")
      render :action=>'response_form'
    else
      @members = @campaign.members.find_all_by_response_token(params[:response_token])
      if !@members.blank? or params[:response_token].eql?('Test Email')
        @response_member = @members.first
        @members.each do |member|
          if member.contact_id
            if member.contact.email==data[:contact][:email].strip
              @campaign_response = CampaignMember.find(member.id)
              found=true
            end
          elsif member.email
            if member.email==data[:contact][:email]
              @campaign_response= CampaignMember.find(member.id)
              found=true
            end
          end
        end

        unless found
          @contact = Contact.scoped_by_company_id(@campaign.company_id).first(:conditions => ['first_name = ? AND middle_name = ? AND last_name = ? AND email = ?', data[:contact][:first_name], data[:contact][:middle_name], data[:contact][:last_name], data[:contact][:email]])
          if @contact.nil?
            @member = @campaign.members.new(:first_name => data[:contact][:first_name], :middle_name => data[:contact][:middle_name],:last_name => data[:contact][:last_name], :email => data[:contact][:email],:company_id => @campaign.company_id, :employee_user_id => @campaign.employee_user_id, :created_by_user_id => @campaign.employee_user_id)
            if @member.save
              @campaign_response= @member
              @campaign_response.update_attributes(:response => data[:response][:response], :responded_date => Time.zone.now.to_date, :campaign_member_status_type_id => @campaign.company.campaign_member_status_types.find_by_lvalue("Responded").id)
            else
              flash[:error] = @member.errors.full_messages
              render :action => 'response_form'
            end
          else
            @campaign.members.create(:contact_id=> @contact.id,:campaign_id=>@campaign.id,:company_id=>@campaign.company_id, :employee_user_id=>@campaign.employee_user_id,:created_by_user_id=>@campaign.employee_user_id)
            @campaign_response= @campaign.members.find_by_contact_id(@contact.id)
            @campaign_response.update_attributes(:response=>data[:response][:response], :responded_date=> Time.zone.now.to_date, :campaign_member_status_type_id=>@campaign.company.campaign_member_status_types.find_by_lvalue("Responded").id)
          end
          @response_member.update_attributes(:response_token => nil) unless @response_member.blank?
        else
          @campaign_response.update_attributes(:response_token => nil, :response=>data[:response][:response], :responded_date=> Time.zone.now.to_date, :campaign_member_status_type_id=>@campaign.company.campaign_member_status_types.find_by_lvalue("Responded").id)
          render :action=>'response_submit'
        end
      else
        flash[:error] ='Invalid Response Token'
        render :action => 'response_form'
      end
    end
  end

  #This method is for the popup view which we get which viewing a campaign response
  def show_response
    @campaign_response = @company.campaign_members.find(params[:id])
  end

  #This link is used to download the sample file while importing the contacts to a campaign.
  def show_help
    send_file RAILS_ROOT+'/public/sample_import_files/campaign_import_file.csv', :type => "application/csv"#, :length=>69
  end

  def show_xls_help
    send_file RAILS_ROOT+'/public/sample_import_files/campaign_import_file.xls', :type => "application/xls"
  end
   
  def get_report_favourites
    @campaigns_fav = CompanyReport.get_report_fav(@company,@emp_user_id,'Campaign')
  end

  def common_campaign_search
    unless  params[:q].blank?
      @matching_campaigns =  @company.campaigns.search "*" + params[:q] + "*"
    else
      @matching_campaigns = @company.campaigns.all(:order => 'name ASC')
    end
    render :partial => 'common_campaign_search', :object => @matching_campaigns
  end

  def get_base_data
    @company= @company || current_company
    @current_company = @current_company || current_company
    @emp_user_id = @emp_user_id || get_employee_user_id
    @current_user= @current_user || current_user
    @emp_user = @emp_user || get_employee_user
  end

  def unattented_list
    sort_column_order
    @ord = @ord.nil? ? "contacts.last_name ASC":@ord
    @campaign = @company.campaigns.find(params[:id], :include=>[:opportunities, :members])
    members=@campaign.members    
    responded_id= current_company.campaign_member_status_types.find_by_lvalue("Responded").id
    @campaign_unattended_responses= members.find(:all, :include => :contact, :conditions=>['campaign_member_status_type_id=?', responded_id],:order => @ord)
    render :partial => "campaigns/campaign_responses", :locals => {:responses=>@campaign_unattended_responses, :popup => true}
  end

  def suspended_list
    sort_column_order
    @ord = @ord.nil? ? "contacts.last_name ASC":@ord
    @campaign = @company.campaigns.find(params[:id], :include=>[:opportunities, :members])
    @campaign_suspended_list= @campaign.members.find(:all, :include => :contact, :conditions=>['campaign_member_status_type_id=?', current_company.campaign_member_status_types.find_by_lvalue("Suspended").id], :order => @ord)
    render :partial => "campaigns/campaign_suspended"
  end
  def show_reason
    render :layout=>false
  end

  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    # replace all none alphanumeric, underscore or perioids
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_')
  end

  #Parent Campaigns list
  def parent_compaigns
    cuser = get_employee_user
    usermy_campaigns = cuser.employee.my_campaign == true
    if usermy_campaigns
      @campaigns = Campaign.all(:select => "campaigns.*,(select first_mailed_date from campaign_members where first_mailed_date is not null and campaign_id = campaigns.id limit 1) as first_mailed_date,(select alvalue from company_lookups where id = campaigns.campaign_status_type_id) as campaign_status ,(select username from users where id = campaigns.owner_employee_user_id) as username,(select count(*) from campaign_members where campaign_id = campaigns.id and deleted_at is null) as member_count, (select count(responded_date) from campaign_members where campaign_id = campaigns.id and responded_date is not null)  as responded_date, (select count(campaign_member_status_type_id) from campaign_members where campaign_id = campaigns.id and campaign_member_status_type_id = (select id from company_lookups where company_id = #{@company.id} and type ='CampaignMemberStatusType' and lvalue = 'Responded')) as campaign_member_status_type_id, (select count(*) from opportunities where campaign_id = campaigns.id and deleted_at is null)  as opportunity, (select sum(amount) from opportunities where campaign_id = campaigns.id)  as opportunity_amount",:conditions=>["campaigns.owner_employee_user_id in (?)", @emp_user_id],:order=>params[:order])
    else
      @campaigns = @company.campaigns.find_all_campaign(params,@company)
    end
  end

  def check_if_authorize
    authorize!(:check_if_authorize,@current_user) unless @current_user.has_access?(:Campaigns)
  end

  def delete_attachment
    Document.find(params[:doc_id]).document_home.destroy
    respond_to do |format|
      format.js
    end
  end

  private
  # used from campaigns model to set the params
  def set_flash_for_update_mail(document_error,additional_documents,document,mail_order)
    if  mail_order == "FIRST"
      flash = t(:flash_campaigns_first_mail_saved)
    else
      flash = t(:flash_campaigns_reminder_mail_saved)
    end
    unless document_error > 0
      flash += " and #{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_uploaded)}"
    else
      error += 1
      additional_documents.errors.add(" ", "#{document.errors.full_messages}")
    end

    flash
  end
  
end
