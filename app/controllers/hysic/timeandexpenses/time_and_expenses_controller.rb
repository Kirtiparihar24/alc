class Physical::Timeandexpenses::TimeAndExpensesController < ApplicationController
	before_filter :authenticate_user!		
	authorize_resource :class => :time_and_expense
	before_filter :current_time_entry , :except=>[:new]
	before_filter :employee_user_id
	before_filter :check_for_matter_acces, :only=>[:matter_view]
	before_filter :get_user, :only => [:matter_view]
  before_filter :get_duration_setting,:only=>[:matter_view,:new,:new_time_entry,:new_time_entry_home,:calendar,:approval_awaiting_entry,:create,:add_more_expenses]
	layout 'full_screen', :except => ["calendar", "matter_view"]

	add_breadcrumb I18n.t(:label_time_amp_expense), :physical_timeandexpenses_calendar_path, :except => [:matter_view]
	include GeneralFunction
	helper_method :time_flash_message,:remember_past_path

	def employee_user_id
		@employee_user_id = get_employee_user_id
	end

  # Internal Work Hours
  # i/p : contact_id
	def internal
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'created_at', :dir => 'up')
    end
    sort_column_order
		set_page_number(192,193,71,params[:status])
		session[:referer] = nil
		data=params
		approved_or_billed_time_and_expense_entry(data)
		session[:current_time_entry] = nil
		get_matters_and_contacts
		unless data[:start_date].nil?
			if (!data[:start_date].blank? && !data[:end_date].blank?)
				start_date = data[:start_date].to_date if data[:start_date]
				end_date = data[:end_date].to_date if data[:end_date]
				if start_date <= end_date
					get_receiver_and_provider
					if data[:col]&& data[:dir]
						order = data[:dir].eql?("up") ? "#{data[:col]+ ' '+ 'asc'}" : "#{data[:col]+ ' '+ 'desc'}"
						@icon = data[:dir].eql?("up") ? 'sort_asc':'sort_desc'
					else
						order = "created_at asc"
					end
					conditions = "is_internal and company_id = #{@receiver.company_id} and time_entry_date between '#{data[:start_date]}' and '#{data[:end_date]}'"
				  @saved_time_entries_new =  Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => conditions, :order=>order)
          unless params[:status].blank?
						conditions += " and status = '#{params[:status]}'"
					end
					@saved_time_entries = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => conditions, :order=>order)

          conditions = "is_internal and company_id = #{@receiver.company_id} and expense_entry_date between '#{data[:start_date]}' and '#{data[:end_date]}'"
					@saved_expense_entries_new = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions => conditions, :order =>order)

          unless params[:status].blank?
						if params[:status]=='Billed'
							conditions += " and status = '#{params[:status]}' and tne_invoice_id is not null"
						else
							conditions += " and status = '#{params[:status]}'"
						end
					end
					@saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions => conditions, :order =>order)

          get_total_hours_for_all_status
          get_expense_details_for_status
          get_total_billable_time_amount_status
          @grand_total_open = @total_amount_open + @total_expenses_open
          @grand_total_approved =  @total_amount_approved + @total_expenses_approved
          @grand_total_billed = @total_amount_billed + @total_expenses_billed
          @total_hours = @total_hours_open + @total_hours_approved + @total_hours_billed
          @total_amount = @total_amount_open + @total_amount_approved + @total_amount_billed
          @grand_total_expense = @total_expenses_open + @total_expenses_approved + @total_expenses_billed
          @grand_total = @grand_total_open + @grand_total_approved + @grand_total_billed
				else
					flash[:error] = t(:flash_end_date_start_date)
				end
			else
				flash[:error] = t(:flash_enter_date)
			end
		end
		params[:current_tab]=params[:current_tab].nil? ? 'fragment-1' : params[:current_tab]
		@current_stage=params[:current_tab]
		add_breadcrumb "Internal", :physical_timeandexpenses_internal_path

    #Following code added for Feature #8234 - export to excel in all view pages in T & E
    ##Params are stored in instance variable for the generating link for generating excel report
		@status = params[:status]			
		@start_date= params[:start_date]
		@end_date = params[:end_date]
		@current_tab = params[:current_tab]
		@row_headers = ["T/E","Date","Lawyer Designation / Non-User","Time(HH:MM)","Dur(Hrs)","Rate($)","Activity","Description","Billable (Y/N)","Final Bill Amt($)","Status"]
		@report_heads = [params[:start_date],params[:end_date]]
		respond_to do|format|
			format.html{}
			format.xls {
				send_data(LiviaExcelReport.generate_xls_for_time_expenses(@saved_time_entries,@saved_expense_entries,@row_headers,@report_heads,"internal",@dur_setng_is_one100th),:filename => "time_expense.xls", :type => 'application/xls', :disposition => 'inline')
			}
		end

	end

  # Contact Specific View for time and expense entries.
  # i/p : contact_id
	def contact_view
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'created_at', :dir => 'up')
    end
    sort_column_order
		set_page_number(190,191,70,params[:status])
    session[:referer] = nil
		data=params
		approved_or_billed_time_and_expense_entry(data)
  	session[:current_time_entry] = nil
		get_all_contacts#get_matters_and_contacts
		load_time_and_expense_entry("contact",data)
  	add_breadcrumb "Non-Matter Related", :physical_timeandexpenses_contact_view_path

    #Following code added for Feature #8234 - export to excel in all view pages in T & E
    ##Params are stored in instance variable for the generating link for generating excel report
		@row_headers = ["T/E","Date","Lawyer Designation / Non-User","Time(HH:MM)","Dur(Hrs)","Rate($)","Activity","Description","Billable (Y/N)","Final Bill Amt($)","Status"]
		contact = "#{@contact.try(:first_name)} #{@contact.try(:last_name)}".strip
		@report_heads = [contact,params[:start_date],params[:end_date]]
    @contact = @object
		respond_to do|format|
			format.html{}
			format.xls {
				send_data(LiviaExcelReport.generate_xls_for_time_expenses(@saved_time_entries,@saved_expense_entries,@row_headers,@report_heads,"contact_view",@dur_setng_is_one100th),:filename => "time_expense.xls", :type => 'application/xls', :disposition => 'inline')
			}
		end
	end

  # Matter Specific View for time and expense entries.
  # i/p : matter_id
	def matter_view
    if params[:col].blank? && params[:dir].blank?
      params.merge!(:col => 'created_at', :dir => 'up')
    end
    sort_column_order
		set_page_number(188,189,69,params[:status])
		session[:referer] = nil
		data=params
    # If approved or billed in time or expense entry
		approved_or_billed_time_and_expense_entry(data)
		session[:current_time_entry] = nil
    # get active team matter
    if(is_access_matter?)
      @matters = Matter.all(:conditions=>"company_id=#{current_company.id}",:order=>"name asc")
    else
      get_matters
    end
    #load time and expense entry
		load_time_and_expense_entry("matter",data)

    if params[:from].eql?("matters")
			@object = current_company.matters.find(params[:matter_id]) if !params[:matter_id].blank?
			add_breadcrumb "Matters", matters_path
			add_breadcrumb t(:text_menu_tne), :physical_timeandexpenses_matter_view_path
		else
			add_breadcrumb t(:text_menu_tne), :physical_timeandexpenses_calendar_path
			add_breadcrumb "Matter Related", :physical_timeandexpenses_matter_view_path
		end
    @matter = @object
      
    #Following code added for Feature #8234 - export to excel in all view pages in T & E
    ##Params are stored in instance variable for the generating link for generating excel report
		@row_headers = ["T/E","Date","Lawyer Designation / Non-User","Time(HH:MM)","Dur(Hrs)","Rate($)","Activity","Description","Billable (Y/N)","Final Bill Amt($)","Status"]
		@report_heads = [@matter.try(:name),params[:start_date],params[:end_date]]
		respond_to do|format|
			format.html{}
			format.xls {
				send_data(LiviaExcelReport.generate_xls_for_time_expenses(@saved_time_entries,@saved_expense_entries,@row_headers,@report_heads,"matter_view",@dur_setng_is_one100th),:filename => "time_expense.xls", :type => 'application/xls', :disposition => 'inline')
			}
		end
    if params[:from]=="matters"
      render :layout => "left_with_tabs"
    else
      render :layout => "full_screen"
    end
	end

  # Time and expense entry details over a calendar view.
  # Displays Monthly, Weekly and Daily entry details.
	def calendar
		@pagenumber=154
		data=params
		session[:referer] = nil
		get_report_favourites
		set_date_and_month_for_calendar(data)
		@calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), :month)
		get_receiver_and_provider
		@calendar.time_entries  = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and (time_entry_date BETWEEN ? and ? ) and matter_people_id is null', @receiver.id, @calendar.startdt, @calendar.enddt ])
		if request.xhr?			
			render :partial=> "content"
		else
			render :layout => "left_with_tabs"
		end
	end

  # Displays time and expense entries done on specific date.
  # i/p : date
	def new
		@pagenumber=72
		session[:current_time_entry] = nil
		@current_user = nil
		@time_entry = current_company.time_entries.new
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		get_receiver_and_provider
		@time_entry.performer = @receiver
		@time_entry.created_by = @provider
		@expense_entry.performer = @receiver
		@expense_entry.created_by = @provider
		get_unexpired_matters(params[:time_entry_date],@receiver.id)			
		get_all_contacts
		get_saved_entries
		get_expense_entries

    #Feature 11298
    #to get the time and expense entry for all status
    get_total_hours_for_all_status
    get_expense_details_for_status
    get_total_billable_time_amount_status
    @grand_total_open = @total_amount_open + @total_expenses_open
    @grand_total_approved =  @total_amount_approved + @total_expenses_approved
    @grand_total_billed = @total_amount_billed + @total_expenses_billed
    @total_hours = @total_hours_open + @total_hours_approved + @total_hours_billed
    @total_amount = @total_amount_open + @total_amount_approved + @total_amount_billed
    @grand_total_expense = @total_expenses_open + @total_expenses_approved + @total_expenses_billed
    @grand_total = @grand_total_open + @grand_total_approved + @grand_total_billed
	
		add_breadcrumb "Time and Expense Entries", :new_physical_timeandexpenses_time_and_expense_path
	end

  # Returns all matters and contacts for current company.
	def get_matters_and_contacts
		get_matters
		get_all_contacts
	end

	def get_matters
		@matters = Matter.active_team_matters(get_employee_user_id)
		@matters = @matters.sort{|x,y| x.name <=>y.name}
	end

	def get_unexpired_matters(date,employee_user_id)
    @matters = Matter.unexpired_team_matters(employee_user_id, get_company_id, date)
	end
  
	def time_entry_matter_search
		if params[:search_for].present?
			@search_for = params[:search_for]
			@matching_matters = Contact.all(:conditions => "(first_name ILIKE '#{params[:value].strip}%' OR last_name ILIKE '#{params[:value].strip}%' OR middle_name ILIKE '#{params[:value].strip}%') AND company_id=#{params[:company_id]}", :include => :company, :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') ASC")
		else
			@matching_matters = Matter.search_team_matters(params[:employee_id], params[:company_id], params[:entry_date], params[:value].strip)
		end
		render :partial => 'time_entry_matter_search', :object => @matching_matters
	end
	def unexpired_matters
		matter = get_unexpired_matters(params[:time_entry_date],params[:time_entry_employee_user_id])
	end

	def get_contacts
		@contacts = Contact.find_all_by_company_id(get_company_id,:include=>:company,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")		
	end

  #added order by last_name asc,first_name asc in find
	def get_all_contacts
		#@contacts = Contact.find_with_deleted(:all, :conditions=>["company_id=?", get_company_id], :order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
    #Bug 11593 Deleted contacts are displayed in Drop down.
    @contacts = Contact.find(:all, :conditions=>["company_id=?", get_company_id], :order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
  end

  # Displays new time entry form.
	def new_time_entry
    @pagenumber =68
		authorize!(:new_time_entry,current_user) unless current_user.has_access?('Time & Expense')
		data=params
		flash[:notice] = nil
		@time_entry = current_company.time_entries.new
		condition_str = "users.company_id = #{current_company.id}"
    unless data[:physical_timeandexpenses_time_entry].blank?
			@entry_date = data[:physical_timeandexpenses_time_entry][:time_entry_date]
		else
			@entry_date = data[:time_entry_date] || Time.zone.now.to_date.strftime('%m/%d/%Y')
		end
		if(params[:from] == "matters" && !params[:matter_id].blank?)
			@matter = Matter.find(params[:matter_id],:conditions => ["company_id = ? ",current_company.id])
			get_lawyers(@matter)
    else
      @lawyers = User.all(:joins => "inner join employees on employees.user_id = users.id", :conditions => [condition_str])
		end
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		@note_id=params[:id]
		@note_name=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:id],assigned_user) if params[:id]
		@time_entry.employee_user_id = get_employee_user_id
		get_unexpired_matters(@entry_date,@time_entry.employee_user_id)
		get_contacts
		add_breadcrumb  'Add Time Entry' , request.request_uri unless params[:height]			
		default_activity_type_id = CompanyActivityType.find(:first,:conditions=>"company_id=#{current_company.id}").id
		@time_entry.activity_rate = @time_entry.actual_activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, default_activity_type_id, get_user_designation_id,@time_entry.employee_user_id))
    if params[:timer_value].present?
      secs = params[:timer_value].to_i
      secs = (secs > 30 && secs < 60) ? 60 : secs
      min = (secs/60)
      @time_entry.actual_duration = min
    end
		render :layout => false if params[:height]
	end

  # Displays new time entry form.
	def new_time_entry_home
		authorize!(:new_time_entry_home,current_user) unless current_user.has_access?('Time & Expense')
		data=params
		flash[:notice] = nil
		@time_entry = current_company.time_entries.new
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		unless data[:physical_timeandexpenses_time_entry].blank?
			@entry_date = data[:physical_timeandexpenses_time_entry][:time_entry_date]
		else
			@entry_date = data[:time_entry_date] || Time.zone.now.to_date.strftime('%m/%d/%Y')
		end
		@note_id=params[:id]
		@note_name=StickyNote.find(params[:id],:conditions=>{:assigned_to_user_id=>assigned_user}) if params[:id]
		@time_entry.employee_user_id = get_employee_user_id
		@lawyers = current_company.users.find(:all, :joins => [:employee], :conditions => ["users.id = employees.user_id"])
		get_unexpired_matters(@entry_date,@time_entry.employee_user_id)
		get_contacts
		unless params[:commit].nil?
			add_breadcrumb params[:commit].include?('Add') ? params[:commit].gsub('Add', 'New') : params[:commit] , {:controller=>"physical/timeandexpenses/time_and_expenses",:action=>"new_time_entry"} unless params[:height]
		end
		unless params[:commit].nil?
			if params[:commit].eql?("Add Expense Entry")
				add_breadcrumb params[:commit].include?('Add') ? params[:commit].gsub('Add', 'New') : params[:commit] , request.request_uri unless params[:height]
			elsif params[:commit].eql?("Add Time Entry")
				add_breadcrumb params[:commit].include?('Add') ? params[:commit].gsub('Add', 'New') : params[:commit] , request.request_uri unless params[:height]
			end
		end
		render :action =>"add_expense_entry" ,:locals=>{:expense_entry_date => @entry_date} and return  if params[:commit] == "Add Expense Entry"
		default_activity_type_id = CompanyActivityType.find(:first,:conditions=>"company_id=#{current_company.id}").id
		@time_entry.activity_rate = @time_entry.actual_activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, default_activity_type_id, get_user_designation_id,get_employee_user_id))
		@time_entry.activity_rate = @time_entry.actual_activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, default_activity_type_id, get_user_designation_id,@time_entry.employee_user_id))
		render :layout => false if params[:height]
	end

  # def uplad_document and def upload methods are now moved to document_homes controller with feature #7991. - Rahul Patil 9th Aug 2011
  # Creates new time entry.
	def create
		@pagenumber=1
    @current_user=current_user
		@t_start_time = params[:physical_timeandexpenses_time_entry][:start_time]
		@t_end_time = params[:physical_timeandexpenses_time_entry][:end_time]
		matter_name = !params[:physical_timeandexpenses_time_entry][:matter_id].blank? ? Matter.find_by_id(params[:physical_timeandexpenses_time_entry][:matter_id]).name : ""
		contact_name = !params[:physical_timeandexpenses_time_entry][:contact_id].blank? ? Contact.find_by_id(params[:physical_timeandexpenses_time_entry][:contact_id]).full_name : ""
		@matter_contact_hash = {:matter_name=>matter_name,:contact_name=>contact_name}
    params[:physical_timeandexpenses_time_entry][:actual_activity_rate] = params[:physical_timeandexpenses_time_entry][:actual_activity_rate].gsub(',','') if params[:physical_timeandexpenses_time_entry][:actual_activity_rate]
	  params[:physical_timeandexpenses_time_entry][:final_billed_amount] = params[:physical_timeandexpenses_time_entry][:final_billed_amount].gsub(',','') if params[:physical_timeandexpenses_time_entry][:final_billed_amount]   
		data=params
    file = data[:physical_timeandexpenses_time_entry][:file]
		@document_home={}
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		@time_entry = session[:current_time_entry] ? current_time_entry : Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])
		@time_entry.start_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ params[:physical_timeandexpenses_time_entry][:start_time])
		@time_entry.end_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ params[:physical_timeandexpenses_time_entry][:end_time])
		if @time_entry.employee_user_id.nil?
			@time_entry.employee_user_id = get_employee_user_id
		end
		@time_entry.matter_people_id=params[:physical_timeandexpenses_time_entry][:matter_people_id]
		if (params[:nonuser].present? && @time_entry.matter_people_id.present?)
			matter = Matter.find(@time_entry.matter_id)
			@time_entry.employee_user_id = matter.employee_user_id
		end
		@lawyers = @time_entry.matter_id ? get_lawyers(@time_entry.matter) : []
		get_unexpired_matters(@time_entry.time_entry_date,@time_entry.employee_user_id)
		get_contacts
		@time_entry.performer = User.find(@time_entry.employee_user_id)
		@time_entry.created_by = @current_user
		@time_entry.company_id = get_company_id
		@time_entry.check_actual_duration_explictly_entered
    @time_entry.actual_duration = @time_entry.actual_duration.to_f * 60
		Physical::Timeandexpenses::ExpenseEntry.transaction do
			if @time_entry.valid?
				if file.present?
					#initialize_params_for_docs
					document_home ={:company_id=>@time_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @time_entry.employee_user_id, :mapable_type=>"Physical::Timeandexpenses::TimeEntry", :upload_stage=>1, :access_rights=> 2,:owner_user_id=>@current_user.id}
					@doc_home =DocumentHome.new(document_home)
					@doc_home.documents.build(:data=>file, :name=> file.original_filename, :company_id=>@time_entry.company_id,:created_by_user_id=> @current_user.id, :employee_user_id=> @time_entry.employee_user_id,:description=>'' )
					if @doc_home.valid?
						@com_notes_entry=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:note_id],assigned_user) if params[:note_id]
						@com_notes_entry.destroy if @com_notes_entry
						@time_entry.save!
						@doc_home.mapable_id=@time_entry.id
						@doc_home.save
						save_time_entry_details
					else
						@time_entry.errors.add(:file_size,"should be between 1(actually 1KB) - 15 MB ")
					end
				else
					if @time_entry.save
						@com_notes_entry=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:note_id],assigned_user) if params[:note_id]
						@com_notes_entry.destroy if @com_notes_entry
					else
						respond_to do |format|
							format.js{
								render :update do |page|
									format_ajax_errors(@matter_task, page, "error_notice")
								end
							}
						end
					end					
				end
        if data[:button_pressed] == "save_and_add_expense"
					save_and_add_expense
					unless params[:called_from_home]
						render :action=>"save_and_add_expense" and return
					end
				end
			end
		end
		time_expense_entry_response(data)
	end

  #create time entry from home
	def create_new_home
		@t_start_time = params[:physical_timeandexpenses_time_entry][:start_time]
		@t_end_time = params[:physical_timeandexpenses_time_entry][:end_time]		
		data=params
		@document_home={}
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		@time_entry = session[:current_time_entry] ? current_time_entry : Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])
		@time_entry = Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])		
		if @time_entry.employee_user_id.nil?
			@time_entry.employee_user_id = get_employee_user_id
		end
		if (params[:nonuser].present? && @time_entry.matter_people_id.present?)
			matter = Matter.find(@time_entry.matter_id)
			@time_entry.employee_user_id = matter.employee_user_id
		end
		get_unexpired_matters(@time_entry.time_entry_date,@time_entry.employee_user_id)
		get_contacts
		get_receiver_and_provider
		@time_entry.performer = User.find(@time_entry.employee_user_id)
		@time_entry.created_by = current_user
		@time_entry.company_id = get_company_id
		unless (params[:physical_timeandexpenses_time_entry][:start_time]=="00:00 PM" || params[:physical_timeandexpenses_time_entry][:end_time]=="00:00 PM")
			@time_entry.start_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ params[:physical_timeandexpenses_time_entry][:start_time])
			@time_entry.end_time = Time.parse(@time_entry.time_entry_date.to_s + ' '+ params[:physical_timeandexpenses_time_entry][:end_time])
		end

		Physical::Timeandexpenses::ExpenseEntry.transaction do
      if @time_entry.valid?
        @time_entry.actual_duration = @time_entry.actual_duration.to_f * 60
				if data[:physical_timeandexpenses_time_entry][:file].present?
					#initialize_params_for_docs
					document_home ={:company_id=>@time_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @time_entry.employee_user_id, :mapable_type=>'TimeEntry', :upload_stage=>1, :access_rights=> 2    }
					@doc_home =DocumentHome.new(document_home)
					@doc_home.documents.build(:data=>data[:physical_timeandexpenses_time_entry][:file], :name=> 'Time entry Document', :company_id=>@time_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @time_entry.employee_user_id  )
					if @doc_home.valid?
						@com_notes_entry=StickyNote.find(params[:note_id]) if params[:note_id]
						@com_notes_entry.destroy if @com_notes_entry
						@time_entry.save!
						@doc_home.mapable_id = @time_entry.id
						@doc_home.save
						save_time_entry_details
					else
						@time_entry.errors.add(:file_size,"should be between 1 KB - 15 MB ")
					end
				else
					@time_entry.save					
				end
			end
		end
		responds_to_parent do
			render :update do |page|
				unless @time_entry.errors.empty?
					errs = "<ul>" + @time_entry.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"						
					page<<"show_error_msg('modal_new_entry_errors','#{errs}','message_error_div');"
					page<< "jQuery('#modal_new_entry_errors').show();"
					page << "enableAllSubmitButtons('time_and_expense');"
					page << "jQuery('input[name=save_and_add_expense]').val('Save & Exit');"
					page << "jQuery('#loader').hide();"
				else
					page << "parent.tb_remove();"
					if params[:note_id].present?
						page.call "deleteStickyNote",params[:note_id]
					end
				end

			end
		end

	end

  # Renders expense entry form.
	def add_expense_entry
		@pagenumber=75
		@company_id = get_company_id
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		@lawyers = current_company.users.find(:all, :joins => [:employee], :conditions => ["users.id = employees.user_id"])
		@expense_entry.employee_user_id = get_employee_user_id
		unless params[:physical_timeandexpenses_time_entry].blank?
			@entry_date = params[:physical_timeandexpenses_time_entry][:expense_entry_date]
		else
			@entry_date = params[:expense_entry_date] || Time.zone.now.to_date.strftime('%m/%d/%Y')
		end
		get_unexpired_matters(@entry_date,@expense_entry.employee_user_id)
		get_contacts
		add_breadcrumb  'Add Expence Entries' , request.request_uri unless params[:height]
	end

	def add_expense_entry_home
    @company_id = get_company_id
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		condition_str = "users.company_id = #{current_company.id}"
		if(params[:from] == "matters" && !params[:matter_id].blank?)
      @matter = Matter.find(params[:matter_id],:conditions => ["company_id = ? ",current_company.id])
			if(@matter && !MatterPeople.is_part_of_matter_and_matter_people?(@matter.id, current_user.id))
        @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ["matter_peoples.matter_id=? AND matter_peoples.employee_user_id !=? AND ((matter_peoples.end_date >= '#{Date.today}' AND matter_peoples.start_date <= '#{Date.today}') or (matter_peoples.start_date <= '#{Date.today}' and matter_peoples.end_date is null))", @matter.id, get_employee_user_id] )
      else
        @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ['matter_peoples.matter_id=?', @matter.id] )        
			end
    else
      @lawyers = User.all(:joins => "inner join employees on employees.user_id = users.id", :conditions => [condition_str])
		end
		@expense_entry.employee_user_id = get_employee_user_id
		get_unexpired_matters(Date.today,@expense_entry.employee_user_id)
		get_contacts
		render :layout => false
	end

  # Get employee all matters/contact specific employee matters and updates contact.
  # This action is used for time entry.
	def get_all_matters
		data=params
		get_comp_id=get_company_id
		@time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:time_entry_id])
		get_emp_usr_id = @time_entry.employee_user_id
		@matter_id = data[:matter_id].blank? ? '' : data[:matter_id].to_i
		unless  data[:contact_id].blank?
			@contact =Contact.find(data[:contact_id])
			@time_entry.update_attributes({:is_internal => false, :contact_id=> @contact.id, :matter_id => ''})
			@expense_entries = @time_entry.expense_entries
			for expense_entry in @expense_entries
				expense_entry.update_attributes({:is_internal => false, :contact_id=> @contact.id, :matter_id => ''})				
			end
			flash[:notice] =  "#{t(:text_time_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
		end
		@matters = data[:contact_id].blank? ? Matter.unexpired_team_matters(get_emp_usr_id, get_comp_id, @time_entry.time_entry_date) : Matter.employee_contact_matters(get_emp_usr_id, get_comp_id, @contact.id, @time_entry.time_entry_date)
	end

  # Get all contacts/matter specific contacts and updates matter.
  # This action is used for time entry.
	def get_matters_contact
		data=params
		@time_entry =  Physical::Timeandexpenses::TimeEntry.find(data[:time_entry_id])		
		unless data[:matter_id].blank?
			@matter = Matter.find(data[:matter_id])
			@contact = @matter.contact
			@time_entry.update_attributes({:is_internal => false,:matter_id => @matter.id, :contact_id => @contact.id})
			@expense_entries = @time_entry.expense_entries
			for expense_entry in @expense_entries
				expense_entry.update_attributes({:is_internal => false,:is_billable => true,:matter_id => @matter.id, :contact_id => @contact.id})
			end
			flash[:notice] = "#{t(:text_time_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
			@contact_id = @matter.contact.id
		else			
			@contact_id = data[:contact_id].blank? ? '' : data[:contact_id].to_i
		end
	end

  # Get employee all matters/contact specific employee matters and updates contact.
  # This action is used for expense entry.
	def get_all_expense_matters
		data=params
		get_comp_id=get_company_id
		@expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:expense_entry_id])
		get_emp_usr_id = @expense_entry.employee_user_id
		unless  data[:contact_id].blank?
			@contact =Contact.find(data[:contact_id])
			@expense_entry.update_attributes({:contact_id => @contact.id, :matter_id => '', :is_internal => false})
			flash[:notice] = "#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
		end
		@matters = data[:contact_id].blank? ? Matter.unexpired_team_matters(get_emp_usr_id, get_comp_id, @expense_entry.expense_entry_date) : Matter.employee_contact_matters(get_emp_usr_id, get_comp_id, @contact.id, @expense_entry.expense_entry_date)
		@matter_id = data[:matter_id].blank? ? '' : data[:matter_id].to_i
	end

  # Get all contacts/matter specific contacts and updates matter.
  # This action is used for expense entry.
	def get_expense_matters_contact
		data=params
		@expense_entry =  Physical::Timeandexpenses::ExpenseEntry.find(data[:expense_entry_id])
		get_contacts
		unless data[:matter_id].blank?			
			@matter = Matter.find(data[:matter_id])
			@contact = @matter.contact
			@expense_entry.update_attributes({:matter_id => @matter.id, :contact_id => @matter.contact.id, :is_internal => false})
			flash[:notice] = "#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
			@contact_id = @matter.contact.id
		else
			@contact_id = data[:contact_id].blank? ? '' : data[:contact_id].to_i
		end
	end

  # Returns matter specific contacts, used in new time entry form.
	def get_new_matters_contact
		data=params
		get_contacts
		unless data[:matter_id].blank?			
			@matter = Matter.find(data[:matter_id])
			@contact = @matter.contact
			@matter_people_others = @matter.matter_peoples.other_related.for_allow_time_entry
      params[:employee_user_id] = params[:employee_user_id].to_i == 0 ? get_employee_user_id : params[:employee_user_id].to_i
      get_laywer_html_options(@matter,params[:employee_user_id])
      @activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, params[:activity_type_id], get_user_designation_id,params[:employee_user_id]))
		else
			@contact_id = data[:contact_id].blank? ? '' : data[:contact_id].to_i
		end
	end

  def set_matters_contact
		data=params
		get_contacts
		unless data[:matter_id].blank?
			@matter = Matter.find(data[:matter_id])
			@contact = @matter.contact			
		else
			@contact_id = data[:contact_id].blank? ? '' : data[:contact_id].to_i
		end
	end

  # Get employee all matters/contact specific employee matters and updates contact.
  # This action is used in new time entry form.
	def get_all_new_matters
		data=params
		get_comp_id=get_company_id
		get_emp_user_id=get_employee_user_id
		@contact =Contact.find(data[:contact_id]) unless  data[:contact_id].blank?
		@matters = data[:contact_id].blank? ? Matter.unexpired_team_matters( get_emp_user_id, get_comp_id, data[:time_entry_date]) : Matter.employee_contact_matters( get_emp_user_id, get_comp_id, @contact.id, data[:time_entry_date])
		@matter_id = data[:matter_id].blank? ? '' : data[:matter_id].to_i
    matter =  @matters && @matters.size > 0 ?  @matters[0] : nil
    params[:employee_id] = params[:employee_id].to_i == 0 ? get_employee_user_id : params[:employee_id].to_i
    get_laywer_html_options(matter,params[:employee_id])
    @activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, params[:activity_type_id], get_user_designation_id,params[:employee_id]))
    @activity_rate = "0.00" if matter.nil?
  end

  # Returns matter specific contacts, used in expense entry form.
	def get_new_matters_contact_for_expenses
		data=params			
		unless data[:matter_id].blank?			
			@matter = Matter.find(data[:matter_id])
			@contact  = @matter.contact
			@contact_id = @matter.contact.id
			@matter_people_others = @matter.matter_peoples.other_related.for_allow_time_entry
      get_laywer_html_options(@matter,params[:employee_id])
		else
			@contact_id = data[:contact_id].blank? ? '' : data[:contact_id].to_i
		end
    @matter_people_others ||= []
	end

  # Get employee all matters/contact specific employee matters and updates contact.
  # This action is used in expense entry form.
	def get_all_new_matters_for_expenses
		data=params
		get_emp_user_id=get_employee_user_id
		get_comp_id=get_company_id
		@contact =Contact.find(data[:contact_id]) unless  data[:contact_id].blank?
		@matters = data[:contact_id].blank? ? Matter.unexpired_team_matters(get_emp_user_id, get_comp_id, data[:expense_entry_date]) : Matter.employee_contact_matters(get_emp_user_id, get_comp_id, @contact.id, data[:expense_entry_date])			
		@matter_id = @matters.blank? ? '' : @matters[0].id
    matter = @matters && @matters.size > 0 ? @matters[0] : nil
    get_laywer_html_options(matter)
	end

  # Returns time difference between start time and end time, used in time entry form.
	def get_time_difference
		@time_entry = Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])
		@time_difference =@time_entry.get_time_difference
		respond_to do |format|
			format.js do
				if @time_difference.kind_of? Float
					@actual_activity_rate = @time_entry.actual_activity_rate ? @time_entry.actual_activity_rate : 0
					@billed_amount = @time_difference * @actual_activity_rate
					@time_entry.actual_duration = @time_difference
					@final_billed_amount = @time_entry.calculate_final_billed_amt
					@errorgenerated=false
				else
					@errorgenerated=true
					flash[:error] = @time_difference
				end
			end
		end
	end

  # Returns an activity rate, used in time entry form.
	def get_activity_rate
		@activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, params[:activity_type_id], get_user_designation_id, params[:employee_id]))
	end

	def get_billing_activity_rate
		@activity_rate = rounding(Physical::Timeandexpenses::TimeEntry.get_billing_rate(get_company_id, get_employee_user_id, params[:activity_type_id], get_user_designation_id, params[:employee_id]))
		render :text => @activity_rate
	end

  # Updates values after changing the value of discount in time entry form.
	def get_billing_percent
		@time_entry = Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])
		@billing_percent = @time_entry.calcuate_billing_percent
		respond_to do |format|
			format.js
		end
	end

  # Updates values of billing details after updating billing percent.
	def calculate_billing_amount_per_duration
		data=params
		@time_entry =  Physical::Timeandexpenses::TimeEntry.new(data[:physical_timeandexpenses_time_entry])
		@billing_percent = @time_entry.calcuate_billing_percent unless data[:physical_timeandexpenses_time_entry][:billing_percent].nil?
		@billed_amount = @time_entry.calculate_billed_amount
		@final_billed_amount = @time_entry.calculate_final_billed_amt
		respond_to do |format|
			format.js
		end
	end

	def add_more_expenses
		@pagenumber=74
		session[:referer] = session[:referer].blank? ? request.env["HTTP_REFERER"] : session[:referer]
		@time_entry = Physical::Timeandexpenses::TimeEntry.find(params[:id])
		document_home={}
		@entry_date = @time_entry.time_entry_date
		session[:current_time_entry] = @time_entry.id
		get_unexpired_matters(@time_entry.time_entry_date,@time_entry.employee_user_id)
		get_contacts
		get_receiver_and_provider
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		if params[:from].eql?("matters")
			@matter = @time_entry.matter if @time_entry
			add_breadcrumb "Add More Associated Expenses", {:controller=> "physical/timeandexpenses/time_and_expenses", :action=>"add_more_expenses", :from => "matters", :matter_id => @matter.id}
		else
			add_breadcrumb "Add More Associated Expenses", {:controller=> "physical/timeandexpenses/time_and_expenses", :action=>"add_more_expenses"}
		end
	end

  # Saves time entry and saves list of associated expenses.
	def save_and_add_expense
		data=params
		if params[:time_entry].present?
			@time_entry = Physical::Timeandexpenses::TimeEntry.find(params[:time_entry])
			@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new
		end

		@expense_entry_date = data[:physical_timeandexpenses_time_entry][:time_entry_date]
		get_contacts
		begin
			ActiveRecord::Base.transaction do
				if @time_entry.valid?
					@flag = 1
					unless session[:current_time_entry]
						if data[:physical_timeandexpenses_time_entry][:file].present?
							#initialize_params_for_docs
							document_home ={:company_id=>get_company_id,:created_by_user_id=> @provider, :employee_user_id=> @time_entry.employee_user_id, :mapable_type=>'TimeEntry', :upload_stage=>1, :access_rights=> 2    }
							@doc_home =DocumentHome.new(document_home)
							@doc_home.documents.build(:data=>data[:physical_timeandexpenses_time_entry][:file], :name=> 'Time entry Document', :company_id=>get_company_id,:created_by_user_id=> @provider, :employee_user_id=> @time_entry.employee_user_id  )
							if @doc_home.valid?
								if data[:called_from_home]
									@expense_save_result= data.rehash.each_pair do |key,value|
										@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new(value[:expense_entry])
										@expense_entry.performer = @receiver
										@expense_entry.created_by = @provider
										@expense_entry.is_internal = @time_entry.is_internal
										@expense_entry.matter_id=@time_entry.matter_id
										@expense_entry.contact_id= @time_entry.contact_id
										@expense_entry.expense_entry_date= @time_entry.time_entry_date
										@expense_entry.company_id = get_company_id
										if  @expense_entry.valid?
											@time_entry.expense_entries <<  @expense_entry
										else
											@time_entry.errors.add(' ',"Expense entry #{key} is invalid")

										end
									end
								end
								@time_entry.save
								@com_notes_entry=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:note_id],assigned_user) if params[:note_id]
								@com_notes_entry.destroy if @com_notes_entry
								@doc_home.mapable_id=@time_entry.id
								@doc_home.save
								time_flash_message(@time_entry,"#{t(:text_saved)}")								
							else
								flash[:error]="#{t(:text_document)} " "#{t(:flash_cannot_greaterthan_15mb)}"
								render :action=>'new_time_entry'
							end
						else
							if data[:called_from_home]
								@expense_save_result= data.rehash.each_pair do |key,value|
									@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new(value[:expense_entry])
									@expense_entry.performer = @receiver
									@expense_entry.created_by = @provider
									@expense_entry.expense_entry_date= @time_entry.time_entry_date
									@expense_entry.company_id = get_company_id
									if @expense_entry.valid?
										@time_entry.expense_entries <<  @expense_entry
									else
										@time_entry.errors.add(' ',"Expense entry #{key} is invalid")
									end
								end
							end
							@time_entry.save
							@com_notes_entry=StickyNote.find_by_note_id_and_assigned_to_user_id(params[:note_id],assigned_user) if params[:note_id]
							@com_notes_entry.destroy if @com_notes_entry						
							time_flash_message(@time_entry, "#{t(:text_created)}")
						end
					end
					session[:current_time_entry] ||= @time_entry.id
				else
					flash[:error] = @time_entry.errors.full_messages
					data[:activity_rate] = data[:physical_timeandexpenses_time_entry][:actual_activity_rate]
					@flag = 0
					new_time_entry and return
				end
			end
		rescue Exception => ex
			logger.info "DB Error #{ex.message}"
			raise ex
		end
		add_breadcrumb "Add More Associated Expenses", {:controller=> "physical/timeandexpenses/time_and_expenses", :action=>"add_more_expenses", :id=>@time_entry.id}
	end

  # Saves list of expenses from expense entry form.
	def save_all_expense_entries
		data=params
		document_home={}
		cnt = 0
		is_single_entry_msg = "Enter At Least One Single Entry For Expense"
		err = []
		physical_timeandexpenses_time_entry = {}			
		@flag = 0
		name_arr =[]
		str = "#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "created for"
		@expense_save_result= data.rehash.each_pair do |key,value|
			if !value[:expense_entry].nil?
				is_single_entry_msg = ""
				@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new(value[:expense_entry])
				if @expense_entry.employee_user_id.nil?
					@expense_entry.employee_user_id = get_employee_user_id
				end
				if (data[key+'_nonuser'].present? && value[:expense_entry][:matter_people_id].present?)
					matter = Matter.find(@expense_entry.matter_id)
					@expense_entry.employee_user_id = matter.employee_user_id
				end
				@expense_entry.matter_people_id=value[:expense_entry][:matter_people_id]
				@expense_entry.performer = User.find(@expense_entry.employee_user_id)
				@expense_entry.created_by = current_user

				@expense_entry.company_id = get_company_id
				@expense_entry.time_entry_id =  session[:current_time_entry] || nil
        @expense_entry.matter_people_id = @expense_entry.time_entry.matter_people_id if @expense_entry.time_entry_id
				ActiveRecord::Base.transaction do
					if @expense_entry.valid?
						if value[:expense_entry][:file].present?
							document_home ={:company_id=>@expense_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @expense_entry.employee_user_id, :mapable_type=>'Physical::Timeandexpenses::ExpenseEntry', :upload_stage=>1, :access_rights=> 2    }
							@doc_home =DocumentHome.new(document_home)
              
              file=value[:expense_entry][:file]
							@doc_home.documents.build(:data=>value[:expense_entry][:file], :name=> file.original_filename, :company_id=>@expense_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @expense_entry.employee_user_id  )
							if @doc_home.valid?
								@expense_entry.save
								@flag = 1 # Mandeep -- 1941 (v 2.0.0.0)
								@doc_home.mapable_id=@expense_entry.id    
                @doc_home.save
								name = expense_flash_message(@expense_entry)
							else
								@flag = 2
							end
						else
							@expense_entry.save
							@flag = 1
							name = expense_flash_message(@expense_entry)
						end
						unless name_arr.include?(name)
							name_arr << name
						end
					else
						err << @expense_entry.errors.full_messages.to_s
					end
				end
			end
		end
		if err.size > 0 && @flag ==0
			flash[:error] = err[0]
		else
      flash[:notice] = str + " #{name_arr.join(', ')}."
		end
		referer =  session[:referer].blank? ? nil : session[:referer]
		session[:referer] = nil
		if referer
			if @flag.to_i == 0
				session[:referer] = referer
				redirect_to :action => "add_more_expenses" , :id => session[:current_time_entry], :from => (params[:from].eql?("matters") ? "matters" : "" )
			else
				redirect_to referer
			end

		else

			if session[:current_time_entry].nil?
				if @flag.to_i == 1
					redirect_to :action => "new" , :time_entry_date => data['1'][:expense_entry][:expense_entry_date],:activity_rate => data[:activity_rate]
				else
					if @flag.to_i == 2
						flash[:error]=""
						flash[:error]="Document size cannot be more than 15 MB."
					end
					redirect_to :action =>"new_time_entry" , :time_entry_date => data['1'][:expense_entry][:expense_entry_date],:activity_rate => data[:activity_rate], :commit => "Add Expense Entry"
				end
			else
				if @flag.to_i == 1
					redirect_to :action => "new" , :time_entry_date => data['1'][:expense_entry][:expense_entry_date],:activity_rate => data[:activity_rate]
				else
					time_entry = session[:current_time_entry] ? current_time_entry : Physical::Timeandexpenses::TimeEntry.new(params[:physical_timeandexpenses_time_entry])
					physical_timeandexpenses_time_entry[:time_entry_date] = data['1'][:expense_entry][:expense_entry_date]
					redirect_to :action=>"save_and_add_expense", :time_entry =>time_entry ,:physical_timeandexpenses_time_entry=>physical_timeandexpenses_time_entry
					return
				end
			end
		end
	end

	def expense_flash_message(expense_entry)
		if (expense_entry.employee_user_id != get_employee_user_id.to_i && expense_entry.matter_people_id.blank?)
			expense_entry.performer.full_name
		elsif !expense_entry.matter_people_id.blank?
			expense_entry.matter_people.get_name
		elsif current_user.id != get_employee_user_id
      get_employee_user.full_name
    else
			current_user.full_name
		end
	end

	def save_all_expense_entries_home
    data=params
		document_home={}
		get_receiver_and_provider
		cnt = 0
		errs = []
		errs << "<ul>"
		@expense_save_result = data.rehash.each_pair do |key,value|
			if value[:expense_entry].nil?
			elsif value[:expense_entry][:expense_amount].blank? and value[:expense_entry][:description].blank?
				cnt += 1
			else
				@expense_entry = Physical::Timeandexpenses::ExpenseEntry.new(value[:expense_entry])
				if @expense_entry.employee_user_id.nil?
					@expense_entry.employee_user_id = get_employee_user_id
				end
				if (data[key+'_nonuser'].present? && value[:expense_entry][:matter_people_id].present?)
					matter = Matter.find(@expense_entry.matter_id)
					@expense_entry.employee_user_id = matter.employee_user_id
				end
				@expense_entry.performer = User.find(@expense_entry.employee_user_id)
				@expense_entry.created_by = current_user
				@expense_entry.company_id = get_company_id
				ActiveRecord::Base.transaction do
					if @expense_entry.valid? && @expense_entry.errors.empty?
						if value[:expense_entry][:file].present?
							document_home ={:company_id=>@expense_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @expense_entry.employee_user_id, :mapable_type=>'Physical::Timeandexpenses::ExpenseEntry', :upload_stage=>1, :access_rights=> 2    }
							@doc_home =DocumentHome.new(document_home)
							@doc_home.documents.build(:data=>value[:expense_entry][:file], :name=> 'Expense entry Document', :company_id=>@expense_entry.company_id,:created_by_user_id=> current_user.id, :employee_user_id=> @expense_entry.employee_user_id  )
							if @doc_home.valid?
								@expense_entry.save
								flash[:notice]="#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"
								@doc_home.mapable_id=@expense_entry.id
								@doc_home.save
							else
								errs << "<li>Document size cannot be more than 15 MB.</li>"
							end
						else
							@expense_entry.save
							flash[:notice]="#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_saved)}"
						end
					else
						errs << @expense_entry.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ")
					end
				end
			end
		end
		if cnt == 3
			errs += "<li>Please enter atleast one expense entry.</li>"
		end
    errs = errs.uniq.to_s
		errs += "</ul>"
		responds_to_parent do
			render :update do |page|
				unless errs == "<ul></ul>"
					page << "jQuery('#expense_loader').hide();"
					page << "enableAllSubmitButtons('time_and_expense');"
					page << "jQuery('input[name=save_and_add_expense]').val('Save & Exit');"
					page << "show_error_msg('modal_expense_entry_errors','#{errs}','message_error_div');"
					page<< "jQuery('#modal_expense_entry_errors').show();"
					page << "jQuery('#expense_loader').hide();"
				else
					if params[:from].eql?("matters")
						flash[:notice] =  "#{t(:text_expense_entry)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
						page << "tb_remove();"
						page << "window.location.reload();"						
					else
						page << "parent.tb_remove();"
						page << "jQuery('#altnotice').html('#{escape_javascript(render(:partial => 'common/common_flash_message'))}')";
					end
					if params[:note_id].present?
						page.call "deleteStickyNote",params[:note_id]
					end
				end
			end
		end
	end

  # Updates value of status through in line editing feature of time entry.
	def set_time_entry_status
		data=params
    @time_entry = Physical::Timeandexpenses::TimeEntry.find(data[:id],:include=>[:expense_entries])
		previous_val = @time_entry.status
    if previous_val=='Billed'
      flash[:error] = "This Time Entry is already Billed";
    else
      @time_entry.update_attribute( :status, data[:value])
      if ((previous_val.nil? or previous_val == 'Open') && @time_entry.status == 'Approved') || ((previous_val.nil? or previous_val == 'Approved') && @time_entry.status == 'Open')
        send_tne_status_update_mail(current_user, @time_entry)
      end
      respond_to do |format|
        format.js
      end
    end
	end
  
  # Updates value of status through in line editing feature of expense entry.
	def set_expense_entry_status
		data=params
		@expense_entry = Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
		@expense_entry.update_attribute( :status, data[:value])
  	respond_to do |format|
			format.js
		end
	end

  # display the div for split duration
	def split_entries_div
		id = params[:split_entryid].to_i
		split_entry = Physical::Timeandexpenses::TimeEntry.find(id)
		render :partial => "split_entries", :locals => {:entry_id=> id, :old_duration => split_entry.actual_duration.to_f}, :layout => false
	end
    
  # update_split_duration removed : ShripadJ
    
  # split duration
	def split_entries
		data = params
		@time_entry = Physical::Timeandexpenses::TimeEntry.find(data[:old_id].to_i)
		@time_entry.update_attributes(
      :actual_duration=>data[:old_duration].to_f,
      :final_billed_amount => data[:old_finalbilled_amt].to_f)
    redirect_to :back
	end

	def destroy
		success = false
		begin
			@tne_entry = params[:entry_type].eql?("expense_entry") ? Physical::Timeandexpenses::ExpenseEntry.find(params[:id]) : Physical::Timeandexpenses::TimeEntry.find(params[:id])
			if !@tne_entry.blank? and @tne_entry.status.eql?("Open")
				if @tne_entry.destroy
					success = true
				end
			end
			if success
				flash[:notice] = "Record successfully deleted"
			else
				flash[:error] = "Record not found"
			end
		rescue
			flash[:error] = "Record not found"
		end
		redirect_to :back
	end

	def get_lawyers_matters_contacts
		user = User.find(params[:user_id])
		@contacts = Contact.find_all_by_company_id(user.company_id,:order=>"coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc")
		matter_peoples = MatterPeople.find_matter_people(params[:user_id])
		@matters = get_unexpired_matters(params[:date],params[:user_id])
		render :update do |page|
			if(params[:expense_id]=='0')
				page.replace_html 'lawyer_matters', :partial=>'show_matters', :locals=>{:matters=>@matters,:contacts=>@contacts, :employee_user_id => user.id}
			else
				page.replace_html "#{params[:expense_id]}_matter_dropdown_entry_id", :partial=> '/physical/timeandexpenses/expense_entries/show_matters',:locals=>{:expense_entry=>params[:expense_id], :employee_user_id => user.id}
			end
		end
	end

	def approval_awaiting_entry
		@pagenumber=69
		company_id = get_company_id
    if(is_access_matter?)
      matters = Matter.all(:conditions=>"company_id=#{company_id}")
    else
      matters = Matter.team_matters(get_employee_user_id, company_id)
    end
		@matter_time_entries = Physical::Timeandexpenses::TimeEntry.unapproved_matter_entries(matters.map(&:id))
		@time_entries = Physical::Timeandexpenses::TimeEntry.unapproved_contact_entries(company_id)
	end

	def approve_entries
		if params[:matter_id].present?
			matter = Matter.find(params[:matter_id])
			matter.time_entries.unapproved_entries.each do |time_entry|
				time_entry.update_attribute( :status, 'Approved' )
				expense_entries = time_entry.expense_entries
				for expense_entry in expense_entries
					expense_entry.update_attribute( :status, 'Approved')
				end
			end
		end

		if params[:contact_id].present?
			contact = Contact.find(params[:contact_id])
			contact.time_entries.unapproved_entries.without_matter.each do |time_entry|
				time_entry.update_attribute( :status, 'Approved' )
				expense_entries = time_entry.expense_entries
				for expense_entry in expense_entries
					expense_entry.update_attribute( :status, 'Approved')
				end
			end
		end
		flash[:notice] = 'Entry approved successfully'
		redirect_to :action => 'approval_awaiting_entry'
	end

	private


	def get_report_favourites
		@times_fav = CompanyReport.find(:all,:conditions => ["company_id = ? and employee_user_id = ? and report_type = ?",get_company_id,get_employee_user_id,'TimeAndExpense'])
	end

  # Saves time entry details and creates a session.
	def save_time_entry_details
		data=params
		session[:current_time_entry] = @time_entry.id
		time_flash_message(@time_entry,"#{t(:text_saved)}" )		
	end

  # Returns time entries for specific day.
  # i/p : date
	def get_saved_entries
		data=params
		unless @receiver.nil?
			@saved_time_entries = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date)])
      @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ['employee_user_id = ? and time_entry_date = ? and matter_people_id IS NULL and is_billable = ?', @receiver.id, (!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), true])
		else
			@saved_time_entries = []
      @saved_time_entries_new = []
		end
	end

  # Returns expense entries for specific day.
  # i/p : date
	def get_expense_entries
		data=params
		unless @receiver.nil?
			@saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date)])
      @saved_expense_entries_new = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions =>['employee_user_id =? and expense_entry_date =? and matter_people_id IS NULL and is_billable = ?',@receiver.id,(!data[:time_entry_date].blank? ? data[:time_entry_date] : Time.zone.now.to_date), true])
		end
	end

  #Feature 11298
  def get_total_hours_for_all_status
    @total_hours_open = 0.0
    @total_hours_billed = 0.0
    @total_hours_approved = 0.0
		unless @saved_time_entries_new.empty?
      #to get total hours for all the status
			@saved_time_entries_new.each do |saved_entry|
        duration= @dur_setng_is_one100th ? one_hundredth_timediffernce(saved_entry.actual_duration) : one_tenth_timediffernce(saved_entry.actual_duration)				
        if saved_entry.status == "Open"
          @total_hours_open += duration.to_f
        end
        if saved_entry.status == "Approved"
          @total_hours_approved += duration.to_f
        end
        if saved_entry.status == "Billed"
          @total_hours_billed += duration.to_f
        end
			end
			@total_hours_open = @total_hours_open.to_f.roundf2(2)
      @total_hours_approved = @total_hours_approved.to_f.roundf2(2)
      @total_hours_billed = @total_hours_billed.to_f.roundf2(2)
      @total_hours = @total_hours_open + @total_hours_approved + @total_hours_billed
		end
		return @total_hours_open || 0,  @total_hours_approved || 0,  @total_hours_billed || 0, @total_hours || 0
  end

  #Returns total amount for all the status
  def get_total_billable_time_amount_status
		@total_amount_open = 0.0
    @total_amount_approved = 0.0
    @total_amount_billed = 0.0
		@billed_time = 0.0
		unless @saved_time_entries_new.empty?      
			@saved_time_entries_new.each do |saved_tme|        
        if(saved_tme.status == "Open" )
          @total_amount_open += saved_tme.final_billed_amount
			  end
        if(saved_tme.status == "Approved")
          @total_amount_approved += saved_tme.final_billed_amount
			  end
        if(saved_tme.status == "Billed" && saved_tme.final_billed_amount)
          @total_amount_billed += saved_tme.final_billed_amount
			  end
			end
		end
		@total_amount_open = @total_amount_open.to_f.roundf2(2)
		@total_amount_approved = @total_amount_approved.to_f.roundf2(2)
    @total_amount_billed = @total_amount_billed.to_f.roundf2(2)
		return @total_amount_open || 0.0, @total_amount_approved || 0.0,  @total_amount_billed || 0.0
	end

  #Returns total expenses for all status.
	def get_expense_details_for_status
		@total_expenses_open = 0.0
    @total_expenses_approved = 0.0
    @total_expenses_billed = 0.0
		@expense_entries = {}
		@expense_entries = @saved_expense_entries_new
		unless @expense_entries.empty?
			@expense_entries.each do |expe_entry|
		 		if(expe_entry.status == "Open")
          @total_expenses_open += expe_entry.final_expense_amount
			  end
        if(expe_entry.status == "Approved")
          @total_expenses_approved += expe_entry.final_expense_amount
			  end
        if(expe_entry.status == "Billed")
          @total_expenses_billed += expe_entry.final_expense_amount
			  end
      end
		end
    @total_expenses_open = @total_expenses_open.to_f.roundf2(2)
    @total_expenses_approved = @total_expenses_approved.to_f.roundf2(2)
    @total_expenses_billed = @total_expenses_billed.to_f.roundf2(2)
    return @total_expenses_open || 0.0, @total_expenses_approved || 0.0, @total_expenses_billed || 0.0
	end

  # Returns total number of hours for which the time entry has been done for specific date.
	def get_working_hours_total
		@total_hours = 0.0
		unless @saved_time_entries.empty?
			@total_hours =  @saved_time_entries.map(&:actual_duration).inject(0) do |total,duration|
        duration= @dur_setng_is_one100th ? one_hundredth_timediffernce(duration) : one_tenth_timediffernce(duration)
				total.to_f.roundf2(2) + duration.to_f
			end
			@total_hours = @total_hours.to_f.roundf2(2)
		end
		@total_hours || 0.0
	end

  # Returns total amount for which the time entry has been done for specific date.
	def get_total_billable_time_amount
		@total_amount = 0.0
		@billed_time = 0.0
		unless @saved_time_entries.empty?
			@total_amount =  @saved_time_entries.map(&:final_billed_amount).inject(0) do |total,amount|
				total + amount
			end
			@billed_time = @saved_time_entries.inject(0) do | total, time_entry|
        actual_duration= @dur_setng_is_one100th ? one_hundredth_timediffernce(time_entry.actual_duration) : one_tenth_timediffernce(time_entry.actual_duration)
				time_entry.is_billable ? total + actual_duration.to_f : total
			end
			@total_amount = @total_amount.to_f.roundf2(2)
		end
		@total_amount || 0.0
	end

  # Returns total expenses and billed expenses for specific date.
	def get_expense_details
		@total_expenses = 0.0
		@billed_expenses = 0.0
		@expense_entries = {}
		@expense_entries = @saved_expense_entries
		for time_entry in @saved_time_entries
			@expense_entries += time_entry.expense_entries
		end
		unless @expense_entries.empty?
			@total_expenses =  @expense_entries.map(&:expense_amount).inject(0) do |total,amount|
				total + amount
			end
			@billed_expenses =  @expense_entries.map(&:final_expense_amount).inject(0) do |total,amount|
				total + amount
			end
			@billed_expenses = @billed_expenses.to_f.roundf2(2)
		end
	end

  # Returns employee and service provider objects.
	def get_receiver_and_provider
		cur_usr=current_user
		cur_ser_sess=current_service_session
		unless cur_ser_sess.nil?
			@receiver = cur_ser_sess.assignment.nil? ? cur_ser_sess.user : cur_ser_sess.assignment.user
			@provider = cur_usr
		else
			@receiver =  cur_usr
			@provider = cur_usr
		end
	end
  
	def initialize_params_for_docs
		@document_home={}
		@document_home['access_rights']=2
		@document_home['mapable_type']='TimeEntry'
		@document_home['company_id']=current_company.id
		@document_home['created_by_user_id']= current_user.id
		@document_home['employee_user_id']= get_employee_user_id
		@document_home['name']= 'Time entry Document'
		@document_home['bookmark']=0
		@document_home['phase']=nil
		@document_home['privilege']=nil
		@document_home['description']= 'Time entry Document'
		@document_home['author']=current_user.full_name
		@document_home['source']='Other'
	end

	protected
  # Returns current time entry form which is exists in session.
	def current_time_entry
		if session[:current_time_entry]
			@current_time_entry = Physical::Timeandexpenses::TimeEntry.find(session[:current_time_entry])
		end
	end

	def time_expense_entry_response(data)
		#modified by kalpit
		unless @time_entry.errors.empty?
			if params[:called_from_home]
				responds_to_parent do
					render :update do |page|
						errors = "<ul>" + @time_entry.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
						page << "jQuery('#loader').hide();"
						if params[:from].eql?("matters")
							page << "show_error_msg('from_matters_error_notice','#{errors}','message_error_div');"
						else
							page << "show_error_msg('error_notice','#{errors}','message_error_div');"
						end
						page<<  "enableAllSubmitButtons('time_and_expense');"						
					end
				end
			else
				respond_to do |format|
					format.html{
						flash[:error] = @time_entry.errors.full_messages
						render :action => "new_time_entry", :activity_rate => data[:physical_timeandexpenses_time_entry][:activity_rate]
					}
				end
			end
		else
			if params[:matter_task_edit_url]
				respond_to do |format|					
					time_flash_message(@time_entry, "#{t(:text_created)}")
					format.html { redirect_to params[:matter_task_edit_url] }
				end
			elsif params[:called_from_home]
				responds_to_parent do
					render :update do |page|
						if params[:from].eql?("matters")							
							time_flash_message(@time_entry, "#{t(:text_created)}")
							page << "tb_remove();"
							page.redirect_to("#{physical_timeandexpenses_matter_view_path(:view=>params[:view],:status=>'Open', :from=>'matters', :matter_id => params[:matter_id])}")
						else							
							time_flash_message(@time_entry, "#{t(:text_created)}")
							page << "tb_remove();"
							page << "window.location.reload();"
						end
					end
				end
			elsif params[:from].eql?('calendars')
				respond_to do |format|					
					time_flash_message(@time_entry, "#{t(:text_created)}")
					format.html{redirect_to :back}
				end
			else
				respond_to do |format|
					format.html{						
						time_flash_message(@time_entry, "#{t(:text_created)}")
						redirect_to :action =>'new' , :activity_rate => data[:physical_timeandexpenses_time_entry][:activity_rate] , :time_entry_date  => data[:physical_timeandexpenses_time_entry][:time_entry_date]
					}
				end
			end
		end
	end

  # Updates value of status through in line editing feature of expense entry.
	def set_expense_entry_status
		data=params
		@i = Physical::Timeandexpenses::ExpenseEntry.find(data[:id])
		@i.update_attribute( :status, data[:value])
		render :text => ''
	end


	def time_flash_message(time_entry, saved)		
		str = "#{t(:text_time_entry)} #{t(:flash_was_successful)} #{saved}"
		if (time_entry.employee_user_id != get_employee_user_id.to_i && time_entry.matter_people_id.blank?)
			other_emp_name = time_entry.performer.full_name
			str+= " for #{other_emp_name} "
		elsif !time_entry.matter_people_id.blank?
			str += " for #{time_entry.matter_people.get_name}"
		end
		flash[:notice] = str
	end

	private
  # set year and month
	def set_date_and_month_for_calendar(data)
		if data[:year] and data[:year].to_i > 1900
			@year = data[:year].to_i
			@month = data[:month].to_i if data[:month] and data[:month].to_i > 0 and data[:month].to_i < 13
		end
		@year ||= Time.zone.now.to_date.year
		@month ||= Time.zone.now.to_date.month
	end

  # Common method in contact_view and matter_view
  # it is usefull whentime or expense enrty is approved or billed in bunch
	def approved_or_billed_time_and_expense_entry(data)
		data[:checked_time_entries]= data[:checked_time_entries]? data[:checked_time_entries] : []
		data[:checked_expense_entries]= data[:checked_expense_entries]? data[:checked_expense_entries] : []
		if data[:commit]=='Approve' || data[:commit]=='Bill'
			#Change Status for Time Entries to open to approved or approved to bill
			status= params[:status]=='Open' ? 'Approved' : 'Billed'				
			unless data[:checked_time_entries].nil?
				data[:checked_time_entries].each do|entry|
					time_entry = Physical::Timeandexpenses::TimeEntry.find(entry,:include=>:expense_entries)
					previous_val = time_entry.status
					time_entry.update_attribute(:status, status )
          #update all expense entries related to that time entry
					time_entry.expense_entries.each do |expense_entry|
						expense_entry.update_attribute(:status, status)
					end
					if ((previous_val.nil? or previous_val == 'Open') && time_entry.status == 'Approved') || ((previous_val.nil? or previous_val == 'Approved') && time_entry.status == 'Open')
						send_tne_status_update_mail(current_user, time_entry)
					end
				end
			end
      #Change Status for Expense Entry
			unless data[:checked_expense_entries].nil?
				data[:checked_expense_entries].each do|entry|
					exp = Physical::Timeandexpenses::ExpenseEntry.find(entry)
					exp.update_attribute(:status, status)
				end
			end
			if (!data[:checked_expense_entries].blank? or !data[:checked_time_entries].blank?)
				flash[:notice] = "#{t(:text_time_and_expense_entries)} #{t(:flash_update)} "
			else
				flash[:error] = "#{t(:text_please_select)} #{t(:text_time_and_expense_entries)}"
			end
		end
	end
  
  # set page no for internal matter_view contact_view
	def set_page_number(approved_no,billed_no,other_no,status)
		if status.eql?("Approved")
			@pagenumber=approved_no
		elsif status.eql?("Billed")
			@pagenumber=billed_no
		else
			@pagenumber=other_no
		end
	end

  # Load time and expense entry for matter or contact view
  # object_type can be matter or contact
  # data is params
  # it's a combination of contact_view and matter_view combination condition
  # slightly change like now @matter or @contact refer as object rest is same
  # TO follow dry principle method is extracted from matter_view and contact_view
	def load_time_and_expense_entry(object_type,data)
		unless data[:status].nil?
			object_id = "#{object_type}_id"
			data_object_id =data[object_id]
			if !data["#{object_type}_id"].blank?
				if object_type == "contact"
					@object = Contact.find_with_deleted(data[:contact_id].to_i)
				else
					@object = Matter.find_with_deleted(data[:matter_id].to_i)
				end
				get_receiver_and_provider
				if data[:col]&& data[:dir]
					order = data[:dir].eql?("up") ? "#{data[:col]+ ' '+ 'asc'}" : "#{data[:col]+ ' '+ 'desc'}"
					@icon = data[:dir].eql?("up") ? 'sort_asc':'sort_desc'
				else
					order = "created_at asc"
				end
				if object_type == "contact"
					t_conditions = "#{object_id} =  #{data_object_id} and matter_id is null and company_id = #{@object.company_id}"
					e_conditions = "#{object_id} =  #{data_object_id} and matter_id is null and company_id = #{@object.company_id}"
				elsif object_type == "matter"
					mp = MatterPeople.find(:first, :conditions=>["employee_user_id=? and matter_id = ?", @receiver.id,data_object_id])					
					if(mp !=nil)
						id = mp.matter_team_role_id.to_i
						if(id == 0 || is_access_t_and_e? || (!mp.matter_team_role_id.nil? && mp.matter_team_role.alvalue.eql?("Lead Lawyer")) || mp.can_change_status_time_and_expense?)
							t_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id}"
							e_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id}"
						else
							t_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id} and employee_user_id = #{@receiver.id}"
							e_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id} and employee_user_id = #{@receiver.id}"
						end
					else
						t_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id}"
						e_conditions = "matter_id = #{data_object_id} and company_id = #{@receiver.company_id}"
					end
				end				
				if (!data[:start_date].blank? && !data[:end_date].blank?)
					start_date = data[:start_date].to_date if data[:start_date]
					end_date = data[:end_date].to_date if data[:end_date]
					if start_date <= end_date
						t_conditions += " and time_entry_date between '#{data[:start_date]}' and '#{data[:end_date]}'"
						e_conditions += " and expense_entry_date between '#{data[:start_date]}' and '#{data[:end_date]}'"
					else
						flash[:error] = t(:flash_end_date_start_date)
						return
					end
				end

        t_condition_new = t_conditions + "and is_billable = true"  #to get time entry for all status
        e_condition_new = e_conditions + "and is_billable = true" #to get expense entry for all status

        unless params[:status].blank?
					if params[:status]=='Billed'
						t_conditions += " and status = '#{params[:status]}' and tne_invoice_id is not null"
						e_conditions += " and status = '#{params[:status]}' and tne_invoice_id is not null"
					else
						t_conditions += " and status = '#{params[:status]}'"
						e_conditions += " and status = '#{params[:status]}'"
					end
				else
					t_conditions += " and status = 'Open'"
					e_conditions += " and status = 'Open'"
				end
				@saved_time_entries = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => t_conditions, :order=>order)			                                                               
        @saved_expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => e_conditions, :order =>order)
        #get_working_hours_total
				#get_total_billable_time_amount
				#get_expense_details

        #Feature 11298
        #to get the time and expense entry for all status
        @saved_time_entries_new = Physical::Timeandexpenses::TimeEntry.find(:all,:include=>[:expense_entries,:acty_type,:created_by,:performer,:matter],:conditions => t_condition_new, :order=>order)
        @saved_expense_entries_new = Physical::Timeandexpenses::ExpenseEntry.find(:all,:include=>[:expense,:created_by,:performer,:matter],:conditions => e_condition_new, :order =>order)
        get_total_hours_for_all_status
        get_expense_details_for_status
        get_total_billable_time_amount_status
        @grand_total_open = @total_amount_open + @total_expenses_open
        @grand_total_approved =  @total_amount_approved + @total_expenses_approved
        @grand_total_billed = @total_amount_billed + @total_expenses_billed       
        @total_hours = @total_hours_open + @total_hours_approved + @total_hours_billed
        @total_amount = @total_amount_open + @total_amount_approved + @total_amount_billed
        @grand_total_expense = @total_expenses_open + @total_expenses_approved + @total_expenses_billed
        @grand_total = @grand_total_open + @grand_total_approved + @grand_total_billed
        
			else
				flash[:warning] = t(:"flash_select_#{object_type}")
			end
		end
		data[:current_tab]=data[:current_tab].nil? ? 'fragment-1' : data[:current_tab]
		@current_stage=params[:current_tab]
		@current_tab = params[:tab]
		@status = data[:status]
		@contact_id = object_id
		@start_date= data[:start_date]
		@end_date = data[:end_date]
	end

  private

  def get_lawyers(matter)
    if(matter && !MatterPeople.is_part_of_matter_and_matter_people?(matter.id, get_employee_user_id))
      entry_date = params[:time_entry_date] ? params[:time_entry_date] : params[:expense_entry_date]
      entry_date = Time.now if entry_date.blank?
      @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ["matter_peoples.matter_id=? AND matter_peoples.employee_user_id !=? AND ((matter_peoples.end_date >= '#{entry_date}' AND matter_peoples.start_date <= '#{entry_date}') or (matter_peoples.start_date <= '#{entry_date}' and matter_peoples.end_date is null))", matter.id, get_employee_user_id] )
    else
      @lawyers =  User.all(:joins=>"inner join matter_peoples on matter_peoples.employee_user_id = users.id",:conditions => ['matter_peoples.matter_id=?', matter.id] )
    end
    @lawyers
  end

  def get_laywer_html_options(matter,employee_id=nil)
    @html_options_str =""
    lawyers = []
    lawyers= get_lawyers(matter) if matter
    lawyers.each do |lawyer|
      selected = employee_id.to_i == lawyer.id ? "selected='selected'" : ''
      @html_options_str << "<option value='#{lawyer.id}' #{selected} matter_id ='#{matter.id}'>#{lawyer.full_name}</option>"
    end
    @html_options_str
  end
 
  def get_duration_setting
    @dur_setng_is_one100th = current_company.duration_setting.setting_value == "1/100th"
  end
  
end
