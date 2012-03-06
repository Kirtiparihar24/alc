#This controller handles generation of report in the form of HTML,PDF,CSV format
#This controller uses Reports,RptContacts Helpers for generation of search string and conditions_hash
#Calling require_user method for checking loged in user status active or not
#Calling get_favourites method to retrieve all the (User or Organization) Added Favorites
#Storing user selected parameters(to generate report) into @filters hash
#@filters hash is used to generate link to export data into pdf,xls,csv format. It is also used for adding report to Myfavorite.
#Author : Venkat Amarnath Surabhi
class RptContactsController < ApplicationController
  before_filter :authenticate_user!  ,:get_favourites
	acts_as_flying_saucer
	before_filter :current_service_session_exists, :get_base_data
	include GeneralFunction
	include RptContactsHelper
	include RptHelper
	authorize_resource :class=> :rpt_contact
	layout 'left_with_tabs'

  #This method is used to make selected report link highlighted in reports selection box
	def current_contact
		@pagenumber=82
		@current_contact = "selected"
    @report_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
		params[:report] = {}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,xls and csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash.
	def current_contact_rpt
		@filters = {:report => {:summarize_by => params[:report][:summarize_by]},:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end]}
    # To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @current_contact = "selected"
		@pagenumber=82
    #getting headers
		@header_opts = get_headers
		search = set_contacts_conditions(params[:get_records])
		set_report_name(1,@header_opts)
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : '' , :company_id => @company.id }
		if params[:date_selected]
			merge_hash_with_date(conditions_hash)
			search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
		end
    # Getting required Lookups  in the form of hash ; sources[20] = Campaign
		sources,stages,status_l = ReportsHelper.get_contacts_lookups(current_company)
		col = Contact.find_for_rpt(search,conditions_hash,:include => [:accounts,:assignee])
    #Grouping Col
		column_widths,alignments = group_current_contact(col,sources,stages,status_l)
		@conditions[:col_length] = col.length
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		respond_to do|format|
			@total_data = sort_display_data
			format.html{render :layout=>false}
      format.js {render :file => 'rpt_contacts/current_contact_rpt' }
			format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_contacts/current_contact_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
			format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,col.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
			format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_contacts/current_contact_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,col.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
	def recent_contact
		@pagenumber=83
		@recent_contact = "selected"
    @report_duration =  params[:report] ? params[:report][:duration] : nil
		params[:report] = {}
		add_breadcrumb "#{t(:text_business)} #{t(:text_contacts)} #{t(:text_reports)} : #{t(:text_recently_added_contacts)}",{:controller => :rpt_contacts , :action => :recent_contact}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
	def recent_contact_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @recent_contact = "selected"
		@pagenumber=83
		@filters = {:report => {:duration => params[:report][:duration]},:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end]}
		@data,conditions = [],{}
    # Getting required Lookups  in the form of hash sources[20] = Campaign
		sources,stages,status_l = ReportsHelper.get_contacts_lookups(current_company)
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "", :company_id => @company.id }
		display_data = ReportsHelper.set_start_time(params,conditions_hash)
		search = ''
		search = set_contacts_conditions(params[:get_records])
		search += " AND created_at Between :start AND :end"
		r_name = "Recently added #{t(:text_contacts)} #{display_data}"
		@header_opts = get_headers(r_name)
		set_report_name(2,@header_opts)
		col = Contact.find_for_rpt(search,conditions_hash,{:include => [:accounts,:assignee]})
		cstatus = ''
		col.each do|contact|
			@data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.to_time.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id] ]
		end
		add_breadcrumb "#{t(:text_business)} #{t(:text_contacts)} #{t(:text_reports)} : #{t(:text_recently_added_contacts)}",{:controller => :rpt_contacts , :action => :recent_contact_rpt}
		@table_headers = ["#{t(:text_contact)}",t(:label_Account),t(:label_phone),t(:label_email),t(:text_source),t(:label_rating),t(:text_created),t(:text_owner),t(:text_stage)]
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		conditions[:table_width] = 750
		column_widths = { 0 => 100, 1 => 100, 2 => 80 , 3 => 140 , 4 => 60 , 5 => 40 ,7 => 40 , 8 => 110 , 9 => 40 }
		alignments = { 0 => :left, 1 => :left, 2 => :left , 3 => :left , 4 => :left , 5 => :center  ,7 => :left , 8 => :left,9=>:center }
		respond_to do|format|
      format.html{render :layout=>false}
      format.js {render :file => 'rpt_contacts/recent_contact_rpt' }
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_contacts/recent_contact_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_contacts/recent_contact_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
		end
	end

  #This method is used to make selected report link highlighted in reports selection box
	def contact_account
		@pagenumber=84
		@contact_account = "selected"
    @report_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
		params[:report] = {}
		add_breadcrumb "#{t(:text_business)} #{t(:text_contacts)} #{t(:text_reports)} : #{t(:text_contacts_linked_to_accounts)}",{:controller => :rpt_contacts , :action => :contact_account}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
	end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash.
	def contact_account_rpt
		# To highlight selected report link in view.
		params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @contact_account = "selected"
		@pagenumber=84
		@filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by]}}
    # Getting required Lookups  in the form of hash sources[20] = Campaign
		sources,stages,status_l = ReportsHelper.get_contacts_lookups(current_company)
		search = set_contacts_conditions(params[:get_records])
		@header_opts = get_headers
		set_report_name(3,@header_opts)
		conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => @company.id}
		if params[:date_selected]
			merge_hash_with_date(conditions_hash)
			search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
		end
		col = Contact.find_for_rpt(search,conditions_hash,{:include=>[{:accounts => :assignee},:assignee]})
    #Getting those contacts which are linked to Accounts
		column_widths,alignments = group_contact_account_rpt(col,sources,stages,status_l)
		add_breadcrumb "#{t(:text_business)} #{t(:text_contacts)} #{t(:text_reports)} : #{t(:text_contacts_linked_to_accounts)}",{:controller => :rpt_contacts , :action => :contact_account_rpt}
		report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
		respond_to do|format|
			@total_data = sort_display_data
			format.html{render :layout=>false}
			format.js {render :file => 'rpt_contacts/contact_account_rpt' }
      format.pdf {
				#Passing data to below class method to generate PDF with required parameters
        @template.template_format = :html
				@format = "pdf"
        render_pdf :file => 'rpt_contacts/contact_account_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			}
      format.xls {
				if params[:report][:summarize_by] == "account"
					data = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
				else
					data = LiviaExcelReport.generate_report_with_hash_in_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
				end
				send_data(data,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			}
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_contacts/contact_account_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          if params[:report][:summarize_by] == "account"
            xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
          else
            xls_file = LiviaExcelReport.generate_report_with_hash_in_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
          end
          send_xls_data_to_email(xls_file)
        end
      end
		end
	end

  def get_base_data
    @company  ||= current_company
    @emp_user_id ||= get_employee_user_id
    add_breadcrumb t(:text_menu_rnd), "/rpt_contacts/current_contact"
  end

end