class Physical::Clientservices::HomeController < ApplicationController
  include DashboardHelper
  before_filter :authenticate_user!, :only => [:show, :edit, :update,:search_result,:index]
  authorize_resource :class => :home ,:only => [:create_favourite, :view_matter_tasks, :new_matter_task,:new_opportunity, :create_opportunity]
  before_filter :get_service_session , :only => ['index']
  before_filter :get_base_data, :except => [:upload_documents,:check_logout, :about]
  skip_before_filter :verify_authenticity_token, :only=> [:upload_documents]
  skip_before_filter :check_if_changed_password, :only => :index
  
  acts_as_flying_saucer

	def view_matter_tasks
    @typ = params[:task_type]
    cid = current_user.company.id
		user_id=current_user.id
    @user_setting = current_user.upcoming || Upcoming.create(:user_id => user_id, :setting_type => 'Upcoming', :setting_value => 7, :company_id => cid.to_i)
    @upcoming_opportunity = current_user.upcoming_opportunity || UpcomingOpprotunity.create(:user_id => user_id, :setting_type => 'UpcomingOpportunity', :setting_value => 7, :company_id => cid.to_i)
    if  can? :manage, MatterTask
	    matter_tasks_count(get_company_id, get_employee_user_id)
    end
    zimbra_activities_count(get_employee_user_id)
    all_activities = []
    all_activities << @all_tasks
    all_activities << @activities
    all_activities = all_activities.flatten
    get_task_and_appointment_series(all_activities, true)
    if params[:search].eql?('date_range') or !params[:column_name].blank?
      respond_to do |format|
        format.js{
          render :update do |page|
            page.replace_html("TB_ajaxContent", :file => "physical/clientservices/home/view_matter_tasks.html");
          end
        }
      end
    else
      render :layout => false
    end
  end

  # Feature 8635: Below action is created to display the last updated setting_value for upcoming opportunity and called from home/_alert.html.erb by Ajax - Kirti
  def get_opp_upcoming_setting_value
    render :text=> UpcomingOpportunity.find(params[:upcoming_opportunity_id]).setting_value
  end
  
  def sort_columnof_tasks_modal
    euid = get_employee_user_id
    all_tasks = []
    task_todo =[]
    task_appt =[]
    sort_order = "#{params[:column_name]}  #{params[:dir]}"
    matters = Matter.team_matters(euid, get_company_id,nil,sort_order)
    matters.each {|e| all_tasks << e.view_all_tasks(e.employee_matter_people_id(euid))}
    all_tasks = all_tasks.flatten
    task_todo << Matter.get_based_on_category(all_tasks,"todo") unless all_tasks.blank?
    task_appt << Matter.get_based_on_category(all_tasks,"appointment") unless all_tasks.blank?
    task_todo = task_todo.flatten
    task_appt = task_appt.flatten
    @category = 
      if params[:column_name]=="matter_peoples.name"
      if params[:dir].eql?("ASC")
        task_todo = task_todo.sort {|a,b| a.matter.try(:contact).try(:full_name) <=> b.matter.try(:contact).try(:full_name)}
        task_appt = task_todo.sort {|a,b| a.matter.try(:contact).try(:full_name) <=> b.matter.try(:contact).try(:full_name)}
      else
        task_todo = task_todo.sort {|a,b| b.matter.try(:contact).try(:full_name) <=> a.matter.try(:contact).try(:full_name)}
        task_appt = task_todo.sort {|a,b| b.matter.try(:contact).try(:full_name) <=> a.matter.try(:contact).try(:full_name)}
      end
    end
    @dir = params[:dir].eql?("ASC")? "DESC" : "ASC"
    case params[:task_type]      
    when "all"
      @task_todo = task_todo
      @task_appt = task_appt
      @title = "All Open Task"
      @type = "All_open_tasks"
      @typ = 'all'
    when "overdue"
      @task_todo = task_todo.find_all {|e| e.overdue?}
      @task_appt = task_appt.find_all {|e| e.overdue?}
      @title = "Overdue Tasks"
      @type = "Overdue"
      @typ = 'overdue'
    when "today"
      @task_todo = task_todo.find_all {|e| e.today?}
      @task_appt = task_appt.find_all {|e| e.today?}
      @title = "Todays' Tasks"
      @type = "Todays_task"
      @typ = 'today'
    when "upcoming"
      @user_setting = Upcoming.find_by_user_id_and_setting_type(euid,'Upcoming')
      @task_todo = task_todo.find_all {|e| e.upcoming?}
      @task_appt = task_appt.find_all {|e| e.upcoming?}
      @title = "Upcoming Tasks"
      @type = "upcoming_task"
      @typ = 'upcoming'
    end
  end
  
  def update_user_setting
    if params[:category] == "todo" || params[:category] == "appointment"
      user_setting = Upcoming.find(params[:setting_id])
    else
      user_setting = UpcomingOpportunity.find(params[:setting_id])
    end
    respond_to do |format|
      format.js{
        render :update do |page|
          if user_setting.update_attributes(:setting_value => params[:setting_value])
            page << "tb_remove();"
            page << "window.location.reload();"
          else
            if params[:category] == "todo" || params[:category] == "appointment"
              page <<  "jQuery('#upcoming_loader').remove();"
              errors = "<ul>" + user_setting.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('upcoming_tasks','#{errors}','message_error_div');"
            else
              page <<  "jQuery('#upcoming_opps_loader').remove();"
              errors = "<ul>" + user_setting.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('upcoming_opps','#{errors}','message_error_div');"
              page << "jQuery('.upcomingOpprtunity').removeAttr('disabled');"
              page << "jQuery('.upcomingOpprtunity').css('color', '');"
            end
          end
        end
      }
    end
  end

  # Below code is before_filter only for ['index']
  def get_service_session
    @sp_session = current_service_session
  end

  # Renders partial for t&e entry in lawyer's home.
  def time_expense_entry
    session[:current_time_entry] = nil
    @time_entry = Physical::Timeandexpenses::TimeEntry.new
    @expense_entry= Physical::Timeandexpenses::ExpenseEntry.new
    @team_matters = Matter.team_matters(get_employee_user_id, get_company_id)
    @my_contacts = Contact.find_all_by_company_id_and_employee_user_id(current_company.id, get_employee_user_id)
    respond_to do |format|
      format.html  { render :partial => "time_expense_entry" }
    end
  end

  def new_matter_task
    @matter_task = MatterTask.new # Phoney task!
    @team_matters = Matter.unexpired_team_matters(get_employee_user_id, get_company_id, Time.zone.now.to_date).uniq
    render :layout => false
  end

  def fav_form
    render :layout => false
  end

  def new_workspace
    respond_to do |format|
      format.html{
        render :file =>'physical/clientservices/home/display_new_workspace.js'
      }
    end
  end

  def move_to_workspace_rss
    begin
      # this part creates a pdf
      file_name=params[:document_home][:name]
      pdf_path= render_pdf(:url=>params[:document_home][:url],:send_to_client=>false)
      file=File.open(pdf_path,'r')
      document= params[:document_home][:document_attributes]= {:name=>file_name}
      document[:data]= file
      params[:document_home].merge!(:access_rights=>2, :employee_user_id=>@employee_user_id,
        :created_by_user_id=>@current_user.id,:company_id=>@company.id,
        :mapable_id=>@emp_user_id,:mapable_type=>'User',:upload_stage=>1,:user_ids=>[@emp_user_id])
      document_home = @current_employee_user.document_homes.new(params[:document_home])
      document=document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> @emp_user_id, :created_by_user_id=>@current_user.id ))
      document_home.folder_id = nil
      if document_home.save
        params[:msg] = "#{t(:text_document)} #{t(:flash_was_successful)} #{t(:text_created)}"
        file.close
      end
      show_rssfeed
    rescue Exception=>ex
      p ex.message()
    end
  end

  def show_rssfeed
    begin
      @feed= Feedzirra::Feed.fetch_and_parse(params[:url])
      render :layout => false
    rescue Exception=>ex
      p ex.message
    end
  end
  
  def new_repository
    @msg={:file=>false, :link=>true}
    @document_home=DocumentHome.new
    @link=Link.new
    company=current_company
    @categories= company.document_types.all(:select => 'id,alvalue')
    @sub_categories = current_company.document_sub_categories.find_all_by_category_id(@categories[0].id)    
    respond_to do |format|
      format.html{
        render :file =>'physical/clientservices/home/display_new_repository.js'
      }
    end 
  end

  def create_repository
    begin
      emp_user_id  =  get_employee_user_id
      company=current_company
      data = params[:document_home]
      data[:mapable_type]='Company'
      data[:mapable_id]=company.id
      data[:company_id] = company.id
      @categories= company.document_types.all(:select => 'id,alvalue')
      if params[:upload]=='file'
        #------Document file creation----------------
     
        @file_name=params[:document_home][:name]
        pdf_path= render_pdf(:url=>params[:document_home][:url],:send_to_client=>false)
        file=File.open(pdf_path,'r')
        #-----------End Document File creation-----------------
        data[:access_rights] = 2
        @msg={:file=>true, :link=>false}
        document= params[:document_home][:document_attributes]= {:data=>file,:category_id=>data[:category_id],:sub_category_id=>data[:sub_category_id]}
        document[:name]=@file_name
        document[:description]= params[:document_home][:description]
        @document_home = DocumentHome.new(data.merge!(
            :created_by_user_id => @current_user.id, :upload_stage => 1,
            :employee_user_id=>emp_user_id
          )
        )
        @document=@document_home.documents.build(document.merge(:company_id=>@company.id,  :employee_user_id=> emp_user_id, :created_by_user_id=>@current_user.id))
        @document_home.tag_list= params[:document_home][:tag_array].split(',') if params[:document_home][:tag_array]
        if @document_home.save
          file.close
          params[:msg] = "#{t(:text_document)} #{t(:flash_was_successful)} #{t(:text_created)}"
        end
      elsif params[:upload]=='link'
        @msg={:file=>false, :link=>true}
        @document_home =Link.new(data.merge!(:created_by_user_id => current_user.id,:created_by_employee_user_id=>emp_user_id))
        @document_home.tag_list= params[:document_home][:tag_array].split(',')
        if  @document_home.save
          params[:msg] = "Url #{t(:flash_was_successful)} #{t(:text_created)}"
        end
      end      
      show_rssfeed
    rescue Exception=>ex
      p ex.message()
    end
  end

  def show_favourites
    @favourites = EmployeeFavorite.find(:all,:conditions=>["company_id=? and employee_user_id=? and fav_type=?",current_company.id,get_employee_user_id,params[:fav_type]],:order=>'created_at desc')
    render :partial=>'change_to_favourites',:locals =>{:favourites=>@favourites}
  end

  def delete_favourite
    @favourite = EmployeeFavorite.find(params[:id])
    @favourite.destroy
    @favourites = EmployeeFavorite.find(:all,:conditions=>["company_id=? and employee_user_id=? and fav_type=?",current_company.id,get_employee_user_id,params[:fav_type]],:order=>'created_at desc')
    render :partial=>'change_to_favourites',:locals =>{:favourites=>@favourites}
  end
  
  def add_to_favourite
    obj = EmployeeFavorite.new(:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:name=>params[:fav_name],:url=>params[:fav_url],:fav_type=>'Internal')
    respond_to do |format|
      format.js{
        render :update do |page|
          if obj.save
            flash[:notice] = "The form is added to favorite successfully."
            page << "parent.tb_remove();"
            page << "jQuery('#add_fav_loader_container').html('');"
            page << "jQuery('fav_name').val('');"
            page << "window.location.reload();"
          else
            errs = "<ul>" + obj.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
            page <<  "jQuery('#add_fav_loader_container').html('');"
            page<<"show_error_msg('fav_nameerror','#{errs}','message_error_div');"
          end
        end
      }
    end
  end

  def add_to_fav
    render :layout => false
  end

  def edit_favourite
    @obj = EmployeeFavorite.find(:first, :conditions => {:id => params[:id], :company_id=>get_company_id,:employee_user_id=>get_employee_user_id})
    render :layout => false
  end

  def update_favourite
    obj = EmployeeFavorite.find(:first, :conditions => {:id => params[:edit_favorite_id], :company_id=>get_company_id,:employee_user_id=>get_employee_user_id} )
    if obj
      obj.name = params[:edit_favorite_name]
      respond_to do |format|
        format.js{
          render :update do |page|
            if obj.save
              page << "jQuery('#fav_loader_container').html('');"
              if obj.fav_type == 'RSSFeed'
                page << "jQuery('#favorite_item_#{obj.id}').text('#{truncate(obj.name, 20)}');" 
              else
                page << "jQuery('#favorite_item_#{obj.id}').text('#{truncate(obj.name, 20)}');"
              end
              page << "parent.tb_remove();"
            else
              errs = "<ul>" + obj.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page <<  "jQuery('#fav_loader_container').html('');"
              page << "jQuery('#favorite_edit_error_div').html('#{errs}');"
            end
          end
        }
      end
    end
  end

  def create_favourite
    feed=Feedzirra::Feed.fetch_and_parse(params[:url])
    if params[:fav_type]=='RSSFeed' && (feed.nil? || feed == 0 || feed == 403 || feed==401 || feed==404)
      respond_to do |format|
        format.js{
          render :update do |page|
            page<<"jQuery('#save').attr('disabled','')"
            page<<"jQuery('#save').val('Save')"
            if feed==403
              msg = "is Blocked."
            elsif feed==401
              msg = "requires authentication."
            else
              msg = "is not valid."
            end
            page<<"show_error_msg('nameerror','RSS Feed #{msg}','message_error_div');"
            page<<"jQuery('#loader').hide();"
          end
        }
      end
    else  
      @emp_errors=EmployeeFavorite.create(:company_id=>get_company_id,:employee_user_id=>get_employee_user_id,:name=>params[:name],:url=>params[:url],:fav_type=>params[:fav_type])
      @favourites = EmployeeFavorite.find(:all,:conditions=>["company_id=? and employee_user_id=? and fav_type=?",current_company.id,get_employee_user_id,params[:fav_type]],:order=>'created_at desc')
      respond_to do |format|
        format.js{
          render :update do |page|
            if @emp_errors.errors.present?
              errs = "<ul>" + @emp_errors.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('nameerror','#{errs}','message_error_div');"
              page<<"jQuery('#save').attr('disabled','')"
              page<<"jQuery('#save').val('Save')"
              page<<"jQuery('#loader').hide();"
            else
              page<< "Change_to_favourites('#{params[:fav_type]}','internal','add');"
              if params[:fav_type]=='RSSFeed'
                page << "show_error_msg('ajax_flash','RSS Feed Added Successfully','message_sucess_div');"
              elsif params[:fav_type]=='External'
                page << "show_error_msg('ajax_flash','My Links Added Successfully','message_sucess_div');"
              elsif params[:fav_type]=='Internal'
                page << "show_error_msg('ajax_flash','My Forms Added Successfully','message_sucess_div');"
              end
              page << "parent.tb_remove();"
            end
          end
        }
      end          
    end
  end

  def index
		#TODO Code is refactored by Amar
		# Remove unnecessary code and fix some association in
		unauthorized! unless current_user.role?:lawyer
    create_sessions(current_user.role.name,current_user) if session[:eu_session].nil?
    update_session
		#  if lawyer licence is expired or not present do not access portal page
    if !ProductLicenceDetail.getuserlicence(current_user.id).blank?
      #@lawyer_user = current_user
      @pagenumber=156
      #cid = current_user.company.id
      #user_id=current_user.id
      @notifications = current_user.one_time_notifications
      @unread_notification = current_user.open_notifications_count.open_notifications
      @home_page_dashboards,@method_name=[],[]
      @task_assigned = UserTask.get_task_assigned_to_secretary(current_user.id)
      @my_instructions = current_user.logged_notes.open_notes
      # Findout is acticate dashboard
      show_dashboard = CompanyDashboard.find(:all,:include=>[:dashboard_chart],:conditions=>["company_id =? and employee_user_id=? and show_on_home_page=? ", current_company.id, current_user.id,true], :order => 'dashboard_chart_id')
      @home_page_dashboards = show_dashboard.collect{|cd| cd.dashboard_chart }
      # findout its favourite links
      @favourites = EmployeeFavorite.paginate(:page => params[:page], :per_page => 10,:conditions=>["company_id=? and employee_user_id=? and fav_type='RSSFeed'",current_company.id, current_user.id],:order=>'created_at desc')
      @usersetting = current_user.upcoming || Upcoming.create(:user_id => current_user.id, :setting_type => 'Upcoming', :setting_value => 7, :company_id => current_company.id.to_i)
      @upcomingopportunity = current_user.upcoming_opportunity || UpcomingOpportunity.create(:user_id => current_user.id, :setting_type => 'UpcomingOpportunity', :setting_value => 7, :company_id => current_company.id.to_i)
    else
      render "layouts/noaccesspage" , :layout => false
    end
	end

  #For rendering dhome page dashboard
	def render_fusion_chart
    @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
	  @dashboard = Dashboard.new(params,get_employee_user_id,get_company_id)
    @dashboard.render_chart_data
    render(:file => "/xml_builder/#{ @dashboard.dashboard.xml_builder_name}")
	end

  # For displaying full view dashboard
	def display_full_view_of_dashboard

    @dashboard = Dashboard.new(params,get_employee_user_id,get_company_id)

    @type_of_chart = params[:type_of_chart]
    render :layout => false
	end

  #TODO make private or move to model
  def get_individual_dashboard(dashboard_id)
		dashboard = DashboardChart.find(dashboard_id)
    data = self.send(dashboard.template_name)
		[dashboard,data]
	end

  # Lawyers assign noted to secretary’s
  def create
    if current_user.service_provider_employee_mappings.count > 0
      note = Communication.new(params[:note].merge!(:created_by_user_id =>current_user.id,:assigned_by_employee_user_id =>get_employee_user_id,:company_id=>get_company_id))
      cnt=0
      unless note.description.blank?
        unless note.note_priority == 0
          note.note_priority = 2
        else
          note.note_priority = 1
        end
        cnt = cnt+1
        note.save
      end
    end
    if current_user.service_provider_employee_mappings.count  > 0
      if cnt >= 1
        flash[:notice]= "1 #{t(:text_instruction_was)} #{t(:text_successfully)} #{t(:text_assigned)}."
      else
        error=t(:flash_instructions_error)
      end
    else
      error=t(:flash_no_livian_assigned)
    end
    if error.blank?
      render :text => note.id
    else
      render :text =>  error
    end
  end

  # Blow code is used when add button on "Instructions to the LIVIAN" is clicked.
  # sorting order changed first_name to last_name
  def add_new_record
    @com_notes_entry= Communication.new
    @index = params[:index].to_i
    @cont = Contact.find(:all, :conditions=>["(law_firm_id = ? and status_type!='rejected')", get_law_firm_id], :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    render :partial => 'field'
  end

  def search_result
    @accounts =[]
    @contacts =[]
    @campaigns =[]
    @opportunities=[]
    @matters=[]
    access = (can? :manage,Account) || (can? :manage,Contact) || (can? :manage,Campaign) || (can? :manage,Opportunity) || (can? :manage,Matter)
    unless params[:q].blank?
      if access
        search_str = "*" + params[:q] + "*"
        @accounts = @company.accounts.search search_str, :limit => 10000
        @contacts = @company.contacts.search search_str, :limit => 10000
        @campaigns = @company.campaigns.search search_str, :limit => 10000
        @opportunities = @company.opportunities.search search_str, :limit => 10000
        @matters = @company.matters.search search_str, :limit => 10000        
      end
    else
      if access
        @accounts = @company.accounts.find(:all, :order=>'name ASC')
        comp_order = "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc"
        @contacts = @company.contacts.find(:all, :order => comp_order)
        inprogress = CampaignStatusType.inprogress(@current_company)[0].id
        planned    = CampaignStatusType.planned(@current_company)[0].id
        @campaigns = @company.campaigns.find(:all, :conditions => ["campaign_status_type_id in (?,?)", inprogress, planned], :order=> 'created_at desc')
        closed_won= current_company.opportunity_stage_types.find_by_lvalue('Closed/Won')
        closed_lost= current_company.opportunity_stage_types.find_by_lvalue('Closed/Lost')
        closed_array=[closed_won.id,closed_lost.id ]
        @opportunities = @company.opportunities.find(:all, :conditions => ["opportunities.stage NOT in (?)", closed_array])
        @matters = Matter.unexpired_team_matters(get_employee_user_id, get_company_id, Time.zone.now.to_date).uniq
      end
    end
    render :partial => 'searched_common'
  end

  def get_base_data
    @company=@company || current_company
    @current_employee_user=@current_employee_user ||  get_employee_user
    @emp_user_id= @emp_user_id || @current_employee_user.id
  end

  def get_available_campaigns_home
    campaigns_all=@company.campaigns
    @campaigns=[]
    campaigns_all.each do |campaign|
      if campaign.mail_sent
        @campaigns << campaign
      end
    end
  end

  def new_opportunity
    get_available_campaigns_home
    @company=@company || current_company
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Prospect','Client'])
    @opportunity = Opportunity.new(:stage => "#{current_company.opportunity_stage_types.find_by_lvalue('Prospecting').id}")
    @users = User.except(@current_user).all
    @employees =  User.find_user_not_admin_not_client(@company.id)
    sorted_contacts
    render :layout => false
  end

  def create_opportunity
    data=params
    data[:opportunity][:employee_user_id]=data[:contact][:employee_user_id]=@emp_user_id
    data[:opportunity][:created_by_user_id]= data[:contact][:created_by_user_id]= @current_user.id
    data[:opportunity][:company_id] = data[:contact][:company_id]=@company.id
    data[:opportunity][:current_user_name]= data[:contact][:current_user_name]=@current_user.full_name
    data[:opportunity][:employee_user_id], data[:contact][:via]=@emp_user_id,"Opportunity"
    data[:opportunity][:status_updated_on]=Time.zone.now
    data[:opportunity][:follow_up] = Time.zone.parse("#{data[:opportunity][:follow_up]}T#{data[:opportunity][:follow_up_time]}").getutc  unless data[:opportunity][:follow_up].blank?
    if data[:contact][:id].present?
      @contact=Contact.find(data[:contact][:id])
    else
      @contact=Contact.new(data[:contact])
    end
    sorted_contacts
    get_available_campaigns_home
    data[:opportunity][:contact]= @contact
    @comment= Comment.new
    @opportunity = @company.opportunities.new(data[:opportunity])
    respond_to do |format|
      format.js{
        render :update do |page|
          if @opportunity.save
            flash[:notice] = "#{t(:text_opportunity)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
            page << "tb_remove();"
            page << "window.location.reload();"
          else
            format_ajax_errors(@opportunity, page, "message_error_div")
            page <<  "jQuery('#message_error_div').show();"
            page <<  "jQuery('#loader').hide();"
            page <<  "jQuery('#save_opp').removeAttr('disabled');"
          end
        end
      }
    end
  end

  def create_contact
    data = params
    @contact = Contact.new
    @contact_additional_field=@contact.build_contact_additional_field(:company_id=> @company.id)
    @contact.build_address(:company_id=> @company.id)
    session[:opp] = data[:opportunity]
    respond_to do |format|
      format.js {
        render :file => 'physical/clientservices/home/create_contact.js'
      }
    end    
  end

  def validateOppContact
    get_available_campaigns_home
    @company=@company || current_company
    @contact_stage = get_contact_stages(@company.contact_stages.array_to_hash('lvalue'),['Prospect','Client'])
    @employees =  User.find_user_not_admin_not_client(@company.id)
    if params[:button_pressed] == "save"
      @contact = current_company.contacts.new(params[:contact])
      if @contact.valid?
        sorted_contacts
        respond_to do |format|
          format.js {
            render :update do |page|
              if @contact.save
                params[:contact][:id] = @contact.id
                @opportunity = @company.opportunities.new(session[:opp])
                page << "jQuery('#TB_ajaxWindowTitle').text('New Opportunity');"
                page.replace("TB_ajaxContent",render(:file => "physical/clientservices/home/new_opportunity"));
                page << "jQuery('#_contact_ctl').val('#{@contact.full_name}')"
                page << "jQuery('#_contactid').val('#{@contact.id}')"
              else
                errs = "<ul>" + @contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
                page << "jQuery('#message_error_div').html(\"#{errs}\")"
                page << "jQuery('#message_error_div').show()"
                page << "jQuery('#save_contact').val('Save');"
                page << "jQuery('#save_contact').attr('disabled','');"
              end
            end
          }
        end
      else
        respond_to do |format|
          format.js {
            render :update do |page|
              page << "jQuery('#save_contact').val('Save');"
              page << "jQuery('#save_contact').attr('disabled','');"
              format_ajax_errors(@contact, page, "message_error_div")
            end
          }
        end
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            @opportunity = @company.opportunities.new(session[:opp])
            page << "jQuery('#TB_ajaxWindowTitle').text('New Opportunity');"
            page.replace_html("TB_ajaxContent",render(:file => "physical/clientservices/home/new_opportunity"));
          end
        }
      end        
    end
  end

  #added last name wise sorting ganesh18052011
  def livian_instuction
    template_name_hash = {'fragment-2'=>'outstanding_task_details','fragment-3'=>"completed_action_details"}
    if params[:id] == 'fragment-2'
      params[:to_date] = (Date.today + 1.week).to_s
      @outstanding_tasks = UserTask.get_outstanding_tasks(current_user.id,is_secretary_or_team_manager?,params[:to_date])
    else
      @task_completed = UserTask.get_task_completed_to_secretary(current_user.id,is_secretary_or_team_manager?)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html params[:id], :partial=>template_name_hash[params[:id]]
        end
      }
    end
  end
  
  def about
    render  :layout=>false
  end

  def check_logout 
    unless current_user
      render :update do |page|
        page.redirect_to new_user_session_path
      end
    else
      render :nothing => true
    end
  end

  def upload_documents
    document_home = DocumentHome.new()
    params[:document_home]= {}
    if params[:Filedata]
      success_count = error_count=0
      params[:document_home].merge!(:access_rights=>1, :employee_user_id=>params[:employee_user_id],
        :created_by_user_id=>params[:current_user_id],:company_id=>params[:company_id],
        :mapable_id=>params[:note_id],:mapable_type=>'Communication',:upload_stage=>1,:user_ids=>[params[:employee_user_id]])
      note = Communication.find(params[:note_id])
      document_home = note.document_homes.new(params[:document_home])
      document=document_home.documents.build(:company_id=>params[:company_id],  :employee_user_id=> params[:employee_user_id], :created_by_user_id=>params[:current_user_id], :data => params[:Filedata], :name => params[:Filename], :share_with_client => true)
      if document_home.save
        success_count+=1
      else
        error_count+=1
      end
    end
    render :nothing => true
  end
  
end
