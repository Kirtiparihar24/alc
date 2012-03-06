#This controller handles generation of report in the form of HTML,PDF,CSV format
#This controller uses Reports,RptAccounts Helpers for generation of search string and conditions_hash
#Calling require_user method for checking loged in user status active or not
#Calling get_favourites method to retrieve all the (User or Organization) Added Favorites
#Storing user selected parameters(to generate report) into @filters hash
#@filters hash is used to generate link to export data into pdf,xls,csv format. It is also used for adding report to Myfavorite.
#Author : Venkat Amarnath Surabhi

#Modifications done for Bug #11256 to display proper filter in favorite reports, in rpt controllers and view.Need to refactor - Kirti
class RptAccountsController < ApplicationController
  before_filter :authenticate_user!,:get_favourites
  acts_as_flying_saucer
	before_filter :current_service_session_exists, :get_base_data
	include RptAccountsHelper
	include RptHelper
	authorize_resource :class => :rpt_account
	
	layout 'left_with_tabs'

  #This method is used to make selected report link highlighted in reports selection box
	def current_account
		@pagenumber=85
		@current_account = "selected"
		params[:report] = {}
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_current_accounts)}",{:controller => :rpt_accounts , :action => :current_account}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
	def current_account_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @current_account = "selected"
		@pagenumber=85
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end]}
		@data,conditions_hash,conditions = [],{},{}
		search = set_accounts_conditions(params[:get_records])
		@header_opts = get_headers
		set_report_name(1,@header_opts)
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => @company.id}
		if params[:date_selected]
			merge_hash_with_date(conditions_hash)
			search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
		end
		col = Account.find_for_rpt(search,conditions_hash,{:include=>[:contacts,:assignee,{:account_contacts => [:contact]}]})
		col.each do |account|
			@data << [account.get_assigned_to, account.name, account.phone.blank? ? account.toll_free_phone : account.phone, account.contacts.length, account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "", account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : ""]
		end
		@table_headers = ["Owner",t(:label_Account),"Phone","Contacts","Primary Contact","Created"]
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_current_accounts)}",{:controller => :rpt_accounts , :action => :current_account_rpt}
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		column_widths = { 0 => 120, 1 => 120, 2 => 120 , 3 => 120 , 4 => 120 , 5 => 120 }
		alignments = {0 => :left, 1 => :left, 2 => :center , 3 => :center , 4 => :center , 5 => :center}
		conditions[:table_width] = 750
		respond_to do|format|
      format.html{render :layout=>false }
      format.js {render :file => 'rpt_accounts/current_account_rpt' }
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_accounts/current_account_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
			format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
			format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_accounts/current_account_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
		end
	end

  #This method is used to make selected report link highlighted in reports selection box
	def recent_account
		@pagenumber=86
		@recent_account = "selected"
    @report_duration = nil
    @report_duration = params[:report][:duration] if params[:report]
		params[:report] = {}
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_recently_added_accounts)}",{:controller => :rpt_accounts , :action => :recent_account}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
	def recent_account_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @recent_account = "selected"
		@pagenumber=86
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:duration => params[:report][:duration]}}
		@data,conditions,conditions_hash = [],{},{}
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => @company.id }
		display_data = ReportsHelper.set_start_time(params,conditions_hash)
		search = ''
		search = set_accounts_conditions(params[:get_records])
		search += " AND created_at Between :start AND :end"
		r_name = "Recently added #{t(:label_accounts)} #{display_data}"
		@header_opts = get_headers(r_name)
		set_report_name(2,@header_opts)
		col = Account.find_for_rpt(search,conditions_hash,{:include => [:contacts,:assignee]})
		col.each do|account|
			@data << [account.get_assigned_to,account.name,account.phone,account.contacts.length,account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "",account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : ""]
		end
		@table_headers = ["Owner",t(:label_Account),"Phone","Contacts","Primary Contact","Created"]
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_recently_added_accounts)}",{:controller => :rpt_accounts , :action => :recent_account_rpt}
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		conditions[:table_width] = 750
		column_widths = { 0 => 120, 1 => 120, 2 => 120 , 3 => 120 , 4 => 120 , 5 => 120 }
		alignments = {0 => :left,1 => :left, 2=> :center , 3 => :center , 4 => :center , 5 => :center}
		respond_to do|format|
      format.js {render :file => 'rpt_accounts/recent_account_rpt' }
			format.html{render :layout=>false }
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_accounts/recent_account_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
			format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
			format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_accounts/recent_account_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
		end
	end

  #This method is used to make selected report link highlighted in reports selection box
	def account_contact
		@pagenumber=87
		@account_contact = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
		params[:report] = {}
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_contacts_linked_to_accounts)}",{:controller => :rpt_accounts , :action => :account_contact}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash if summarized by option is account.
  #If summarized by option is owner then data is stored in the form of hash in hash
	def account_contact_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @account_contact = "selected"
		@pagenumber=87
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by]}}
		search = set_accounts_conditions(params[:get_records])
		@header_opts = get_headers
		set_report_name(3,@header_opts)
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => @company.id}
		if params[:date_selected]
			merge_hash_with_date(conditions_hash)
			search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
		end
		col = Account.find_for_rpt(search,conditions_hash,{:include=>[{:contacts => :assignee},:assignee]})
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_contacts_linked_to_accounts)}",{:controller => :rpt_accounts , :action => :account_contact_rpt}
    #Grouping
		@table_headers = group_account_cont_report(col)
		@conditions[:account_cont_report] = true
		@total_data = sort_display_data
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		column_widths = { 0 => 100, 1 => 80, 2 => 140 , 3 => 80 , 4 => 60 , 5 => 40 , 6 => 40 ,7 => 40 , 8 => 110 }
		alignments = {0 => :left, 1 => :left, 2 => :left , 3 => :center , 4 => :center , 5 => :center,6=>:center,7=>:center,8=>:left}
		respond_to do|format|
      format.html{render :layout=>false }
			format.js{render :file => 'rpt_accounts/account_contact_rpt'}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_accounts/account_contact_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        if params[:report][:summarize_by] == "account"
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:t_contacts],@header_opts,@conditions)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash_in_hash(@total_data,@table_headers,@conditions[:t_contacts],@header_opts,@conditions)
        end
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
			format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_accounts/account_contact_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          if params[:report][:summarize_by] == "account"
            xls_file =  LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:t_contacts],@header_opts,@conditions)
          else
            xls_file = LiviaExcelReport.generate_report_with_hash_in_hash(@total_data,@table_headers,@conditions[:t_contacts],@header_opts,@conditions)
          end
          send_xls_data_to_email(xls_file)
        end
      end
		end
	end

  #This method is used to make selected report link highlighted in reports selection box
	def in_active_account
		@pagenumber=88
		@in_active = "selected"
		params[:report] = {}
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_inactive_accounts)}",{:controller => :rpt_accounts , :action => :in_active_account}
		render :action => :in_active_account_rpt
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
	def in_active_account_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @in_active = "selected"
		@pagenumber=88
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:duration => params[:report][:duration]}}
		@data,@conditions = [],{}
		company_id = @company.id
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => company_id ,:start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60) : ""}
		search = set_accounts_conditions(params[:get_records])
		search += " AND created_at Between :date_start AND :date_end"
		@header_opts = get_headers
		set_report_name(4,@header_opts)
		search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
		set_accounts_time(conditions_hash)
		col = Account.find_for_rpt(search,conditions_hash,{:include=>[{:contacts => [:opportunities , :matters]}]})
		length = col.length
    #checking for inactive accounts
		if length != 0
			col,months = get_in_active_accounts(col,params)
			report_date=  params[:report][:duration]
			inact_per = ((col.length/length.to_f) * 100).round
			if col.length == 0
				@conditions[:table_name] = "None of the #{t(:label_accounts)} are Inactive since the last  #{months}"
			elsif report_date.eql?("range")
				@conditions[:table_name] = @header_opts[:r_name]
				col.each do |account|
					@data << [account.get_assigned_to,account.name,account.phone,account.contacts.length,account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "",account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : ""]
				end
			else @conditions[:table_name] = "#{inact_per}% of #{t(:label_accounts)} are Inactive since the last  #{months}"
        col.each do |account|
          @data << [account.get_assigned_to,account.name,account.phone,account.contacts.length,account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "",account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : ""]
        end
			end
		else
			@conditions[:table_name] = "No #{t(:label_accounts)} Found"
		end
		@conditions[:inactive_act] = true
		@table_headers = ["Owner",t(:label_Account),"Phone","Contacts","Primary Contact","Created"]
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_inactive_accounts)}",{:controller => :rpt_accounts , :action => :in_active_account_rpt}
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		column_widths = { 0 => 120, 1 => 120, 2 => 120 , 3 => 120 , 4 => 120 , 5 => 120 }
		alignments = {0 => :left, 1 => :left, 2 => :left , 3 => :center , 4 => :left , 5 => :center}
		respond_to do|format|
			pdf_file = LiviaReport.generate_report_with_array(@data,@table_headers,@data.length,column_widths,@header_opts,@conditions,alignments)
			xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,@conditions)
			format.html{render :file => 'rpt_partials/display_report_data.js' , :locals => {:title => "Inactive #{t(:label_accounts)}"} if request.xhr?}
			format.js{render :file => 'rpt_partials/display_report_data.js' , :locals => {:title => "Inactive #{t(:label_accounts)}"}}
			format.csv {}
			format.pdf {send_data(pdf_file,:filename => "livia_report.pdf", :type => 'application/pdf', :disposition => 'inline')}
			format.xls {send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')}
			format.email{send_data_from_reports(report_type, pdf_file, xls_file, email, report_name)}
		end
	end

  #This method is used to make selected report link highlighted in reports selection box
	def active_account
		@pagenumber=89
		@active = "selected"
		params[:report] = {}
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_active_accounts)}",{:controller => :rpt_accounts , :action => :active_account}
		render :action => :active_account_rpt
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
	def active_account_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @active = "selected"
		@pagenumber=89
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:duration => params[:report][:duration]}}
		@data,@conditions = [],{}
		company_id = @company.id
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => company_id , :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60) : ""}
		search = set_accounts_conditions(params[:get_records])
		search += " AND created_at Between :date_start AND :date_end"
		@header_opts = get_headers(@r_name)
		@r_name = set_report_name(5,@header_opts)
		search,@header_opts[:r_name] = append_date_condition(search,@r_name)
		set_accounts_time(conditions_hash)
		col = Account.find_for_rpt(search,conditions_hash,{:include => [{:contacts => [:opportunities , :matters]}]})
		length  = col.length
		if length != 0
			#checking for active accounts
			col,months = get_active_accounts(col,params)
			act_per = ((col.length.quo(length)) * 100).round
			report_date=  params[:report][:duration]
			if col.length == 0
				@conditions[:table_name] = "None of the #{t(:label_accounts)} are Active since the last  #{months}"
			elsif report_date.eql?("range")
				@conditions[:table_name] = @header_opts[:r_name]
				col.each do |account|
					@data << [account.get_assigned_to,account.name,account.phone,account.contacts.length,account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "",account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : "",account.get_opportunity_length,account.get_matter_length]
				end
			else
				@conditions[:table_name] = "#{act_per}% of #{t(:label_accounts)} are Active since the last  #{months}"
				col.each do |account|
					@data << [account.get_assigned_to,account.name,account.phone,account.contacts.length,account.get_primary_contact ? account.get_primary_contact.try(:full_name).try(:titleize) : "",account.created_at ? account.created_at.to_time.strftime('%m/%d/%y') : "",account.get_opportunity_length,account.get_matter_length]
				end
			end
		else
			@conditions[:table_name] = "No Accounts Found"
		end
		@conditions[:active_act] = true
		@table_headers = ["Owner",t(:label_Account),"Phone","Contacts","Primary Contact","Created","Opportunities","Matters"]
		add_breadcrumb "#{t(:text_accounts)} #{t(:text_reports)} : #{t(:label_active_accounts)}",{:controller => :rpt_accounts , :action => :active_account_rpt}
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		report_name=params[:report][:email_report_name] if params[:report] &&  params[:report][:email_report_name]
		email=params[:report][:email]if params[:report] &&  params[:report][:email]
		column_widths = { 0 => 120, 1 => 120, 2 => 120 , 3 => 60 , 4 => 120 , 5 => 60,6 => 80, 7=> 80 }
		alignments = {0 => :left, 1 => :left, 2 => :left , 3 => :center , 4 => :center , 5 => :center,6=>:center,7=>:center}
		@conditions[:table_width] = 750
		respond_to do|format|
			pdf_file = LiviaReport.generate_report_with_array(@data,@table_headers,@data.length,column_widths,@header_opts,@conditions,alignments)
			xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,@conditions)
			format.html{render :file => 'rpt_partials/display_report_data.js' , :locals => {:title => "Active Accounts"} if request.xhr?}
			format.js{render :file => 'rpt_partials/display_report_data.js' , :locals => {:title => "Active Accounts"}}
			format.csv {}
			format.pdf {send_data(pdf_file,:filename => "livia_report.pdf", :type => 'application/pdf', :disposition => 'inline')}
			format.xls {send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')}
			format.email{send_data_from_reports(report_type, pdf_file, xls_file, email, report_name)}
		end
	end

  def get_base_data
    @company  ||= current_company
    @emp_user_id ||= get_employee_user_id
    add_breadcrumb t(:text_menu_rnd), "/rpt_contacts/current_contact"
  end

end