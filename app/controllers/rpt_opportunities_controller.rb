#This controller handles generation of report in the form of HTML,PDF,CSV format
#This controller uses Reports,RptOpportunities Helpers for generation of search string and conditions_hash
#Calling require_user method for checking loged in user status active or not
#Calling get_favourites method to retrieve all the (User or Organization) Added Favorites
#Storing user selected parameters(to generate report) into @filters hash
#@filters hash is used to generate link to export data into pdf,xls,csv format. It is also used for adding report to Myfavorite.
#Author : Venkat Amarnath Surabhi
class RptOpportunitiesController < ApplicationController
  before_filter :authenticate_user!,:get_favourites
  acts_as_flying_saucer
  before_filter :current_service_session_exists, :get_base_data
  include RptOpportunitiesHelper
  include RptHelper
  
  layout 'left_with_tabs'
  authorize_resource :class => :rpt_opportunity

  #This method is used to make selected report link highlighted in reports selection box
  def opportunity_pipe
    @pagenumber=90
    @opp_pipe = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    @reports_status = params[:report] ? params[:report][:status] : nil
    @reports_probability = params[:report] ? params[:report][:probability] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_opportunity_pipeline)}",{:controller => :rpt_opportunities , :action => :opportunity_pipe}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash.
  def opportunity_pipe_rpt
    # To highlight selected report link in view.
    @pagenumber=90
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @opp_pipe = "selected"
    conditions_hash = {:assign_to => params[:get_records] == "My" ? @emp_user_id : "" , :company_id => get_company_id }
    @conditions = {:opportunity => true , :opportunity_pipe => true}
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by] , :status => params[:report][:status] , :probability => params[:report][:probability]}}
    @header_opts = get_headers
    search,conditions_hash = set_opp_pipe_conditions(conditions_hash)
    set_report_name(1,@header_opts)
    if params[:date_selected]
      merge_hash_with_date(conditions_hash)
      search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
    end
    col = Opportunity.find_for_rpt(search,conditions_hash,{:include => [{:contact => :accounts}, :assignee]})
    column_widths ,@conditions[:amount], alignment = group_opportunity_pipe_rpt(col)
    @conditions[:col_length] = col.length
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_opportunity_pipeline)}",{:controller => :rpt_opportunities , :action => :opportunity_pipe_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_opportunities/opportunity_pipe_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_opportunities/opportunity_pipe_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_opportunities/opportunity_pipe_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,col.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
  def opportunity_source
    @pagenumber=91
    @opp_source = "selected"
    @reports_status= params[:report] ? params[:report][:status] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_opportunity_source)}",{:controller => :rpt_opportunities , :action => :opportunity_source }
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of array.
  def opportunity_source_rpt
    # To highlight selected report link in view.
    @pagenumber=91
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @opp_source = "selected"
    @data = []
    @total_rec = 0
    conditions_hash   = { :assign_to => params[:get_records] == "My" ? @emp_user_id : "" ,:company_id => get_company_id }
    conditions = {:opportunity => true ,:opportunity_source => true,:table_width => 400 }
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:status => params[:report][:status]}}
    lookup_source = @company.company_sources
    sources = ReportsHelper.get_lookups(lookup_source)
    search,conditions_hash = set_opp_source_conditions(conditions_hash)
    @header_opts = get_headers(@r_name)
    @r_name = set_report_name(2,@header_opts)
    if params[:date_selected]
      merge_hash_with_date(conditions_hash)
      search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
    end
    tcol = Opportunity.find_for_rpt(search,conditions_hash,{:select => [:source]})
    nonval = 0
    len = tcol.length
    none = ["None",nonval,"0"]
    label,col= nil,nil
    tcol.group_by(&:source).each do |label,col|
      @total_rec += col.length
      if !label  or label.blank? or label.nil?
        nonval += col.length
        prob = (nonval.to_f * 100) / len.to_f
        none = ["None",nonval,prob.round.to_s + "%"]
      else
        prob = (col.length.to_f/len.to_f)*100
        @data << [sources[label].to_s,col.length,prob.round.to_s + "%"]
      end
      prob = (nonval.to_f * 100) / len.to_f
      none = ["None",nonval,prob.round.to_s + "%"]
      lookup_source.delete_if { |obj| obj.id  == label}
    end
    lookup_source.each do |obj|
      @data << [obj.lvalue.titleize,0,"0+%"]
    end
    @data = (@data.sort {|a,b| a[0] <=> b[0]} ) << none
    @table_headers = ["#{t(:label_opportunity)} #{t(:label_source)}","#{t(:text_records)}","#{t(:label_opportunity_percentage)}"]
    conditions[:opp_sources] = true
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_opportunity_source)}",{:controller => :rpt_opportunities , :action => :opportunity_source_rpt }
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    column_widths = { 0 => 450 , 1 => 40 , 3 => 50}
    alignment = { 0 => :left , 1 => :center , 2 => :center}
    respond_to do|format|
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_opportunities/opportunity_source_rpt' }
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_opportunities/opportunity_source_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@total_rec,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_opportunities/opportunity_source_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@total_rec,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
  def opportunity_open
    @pagenumber=92
    @opp_open = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_open_opportunity)}",{:controller => :rpt_opportunities , :action => :opportunity_open}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash.
  def opportunity_open_rpt
    # To highlight selected report link in view.
    @pagenumber=92
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @opp_open = "selected"
    @conditions = {:opportunity => true , :opportunity_open => true}
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by]}}
    second_val = []
    lookup_stages = @company.opportunity_stage_types
    stages = ReportsHelper.get_lookups(lookup_stages)
    stages[""] , stages[nil] = "",""
    search = set_opp_open_conditions
    @header_opts = get_headers
    set_report_name(3,@header_opts)
    #ShowOnlyOpen
    obj = nil
    second_val = lookup_stages.collect do |obj|
      obj.id if ["Prospecting","Negotiation","Proposal","Final Review"].include?(obj.lvalue)
    end
    search += " AND stage IN (:s_arr) "
    conditions_hash = {:assign_to => @emp_user_id , :company_id => get_company_id , :s_arr => second_val.compact}
    if params[:date_selected]
      merge_hash_with_date(conditions_hash)
      search,@header_opts[:r_name] = append_date_condition(search,@header_opts[:r_name])
    end
    col = Opportunity.find_for_rpt(search,conditions_hash,{:include => [{:contact=>:accounts} , :assignee]})
    @conditions[:col_length] = col.length
    column_widths,alignament = group_opportunity_open_rpt(col,stages)
    add_breadcrumb "#{t(:text_opportunities)} #{t(:text_reports)} : #{t(:text_open_opportunity)}",{:controller => :rpt_opportunities , :action => :opportunity_open_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_opportunities/opportunity_open_rpt' }
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_opportunities/opportunity_open_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_opportunities/opportunity_open_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:col_length],@header_opts,@conditions)
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