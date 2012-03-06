class RptTimeAndExpensesController < ApplicationController
  before_filter :authenticate_user!  ,:get_favourites
  acts_as_flying_saucer
  before_filter :current_service_session_exists, :get_base_data
  include RptHelper
  include RptTimeAndExpensesHelper
  before_filter :get_duration_setting,:only=>[:time_accounted_rpt,:matter_accounting_rpt,:contact_accounting_rpt]
  authorize_resource :class => :rpt_time_and_expense
  add_breadcrumb "Reports & Dashboards", "/rpt_contacts/current_contact"
  layout 'left_with_tabs'

  def time_accounted
    @pagenumber=99
    @time_accounted = "selected"
    @matters = []
	  @contacts = []
    if params[:report]
      if !params[:report][:contact_id].blank?
        params[:contact_id] = params[:report][:contact_id]
        params[:matter_id] = params[:report][:matter_id]
        get_contacts
        get_all_new_matters
      elsif !params[:report][:matter_id].blank? or params[:report][:selected] == "matter"
        get_matters
      elsif params[:report][:selected] == "contact"
        get_contacts
      end
    else
      params[:report] = {}
    end
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_time_accounted)}",{:controller => '/rpt_time_and_expenses' , :action => :time_accounted}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def get_contacts
    @contacts = Contact.find_for_rpt("company_id = :company_id", {:company_id => @company.id})
  end

  def get_matters
    @matters = Matter.team_matters(@emp_user_id, @company.id ).uniq
  end

  def get_all_new_matters
    if params[:contact_id].blank?
      @matters = Matter.team_matters(@emp_user_id, @company.id).uniq
    else
      @matters = Matter.employee_contact_matters(@emp_user_id, @company.id,params[:contact_id].to_i,nil)
    end
    @matter_id = params[:matter_id].blank? ? '' : params[:matter_id].to_i
  end

  def time_accounted_rpt
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:selected => params[:report][:selected] , :duration => params[:report][:duration],:contact_id => params[:report][:contact_id],:matter_id => params[:report][:matter_id]}}
    @pagenumber=99
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @time_accounted = "selected"
    search,@conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id }
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash = set_time_accounted_conditions(conditions_hash)
    @r_name = set_report_name(1,@header_opts)
    search,@header_opts[:r_name] = append_time_expense_date_cond(search,@r_name,conditions_hash)
    @col = Physical::Timeandexpenses::TimeEntry.find_for_rpt(search,conditions_hash, {:include => [{:matter => :contact}, :performer, :contact]})
    if  params[:report][:selected] == "all" or params[:report][:selected] == "internal"
      @data,@conditions,@table_headers,column_widths, alignment = group_time_accounted_array(params,@col)
    else
      @total_data,@conditions,@table_headers,column_widths = group_time_accounted_hash(params,@col)
      @total_data = sort_display_data
    end
    @conditions[:select],@conditions[:time_accounted_rpt] = params[:report][:selected],true
    @matters = []
	  @contacts = []
    if !params[:report][:contact_id].blank?
      params[:contact_id] = params[:report][:contact_id]
      params[:matter_id] = params[:report][:matter_id]
      get_contacts
      get_all_new_matters
    elsif !params[:report][:matter_id].blank? or params[:report][:selected] == "matter"
      get_matters
    elsif params[:report][:selected] == "contact"
      get_contacts
    end
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_time_accounted)}",{:controller => '/rpt_time_and_expenses' , :action => :time_accounted_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    
    respond_to do|format|
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_time_and_expenses/time_accounted_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_time_and_expenses/time_accounted_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        if  params[:report][:selected] == "all" or params[:report][:selected] == "internal"
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,@conditions)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,@conditions)
        end
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_time_and_expenses/time_accounted_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          if  params[:report][:selected] == "all" or params[:report][:selected] == "internal"
            xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,@conditions)
          else
            xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,@conditions)
          end
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def time_billed
    @pagenumber=100
    @time_billed = "selected"
    @report_duration = nil
    @report_duration = params[:report][:duration] if params[:report]
    params[:report] = {}
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_time_billed_p)}",{:controller => '/rpt_time_and_expenses' , :action => :time_billed }
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def time_billed_rpt
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:duration => params[:report][:duration]}}
    @pagenumber=100
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @time_billed = "selected"
    search,@conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_date : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_date : ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search = set_time_billed_conditions(params[:get_records])
    @r_name = set_report_name(2,@header_opts)
    search,@header_opts[:r_name] = append_time_expense_date_cond(search,@r_name,conditions_hash)
    @col = Physical::Timeandexpenses::TimeEntry.find_for_rpt(search,conditions_hash)
    @total_data, @conditions, @table_headers, column_widths, alignment = group_time_billed(@col)
    @total_data = sort_display_data
    len = @total_data.first[1].length rescue 0
    @conditions[:time_billed_rpt] = true
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_time_billed_p)}",{:controller => '/rpt_time_and_expenses' , :action => :time_billed_rpt }
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    
    respond_to do|format|
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_time_and_expenses/time_billed_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_time_and_expenses/time_billed_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data, @table_headers, len, @header_opts, @conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_time_and_expenses/time_billed_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data, @table_headers, len, @header_opts, @conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_accounting
    @pagenumber=101
    @matter_accounting = "selected"
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_matterid = params[:report] ? params[:report][:matter_id] : nil
    get_matters
    params[:report] = {}
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_matter_accounting)}",{:controller => '/rpt_time_and_expenses' , :action => :matter_accounting}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_accounting_rpt
    get_matters
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:matter_id => params[:report][:matter_id],:duration => params[:report][:duration] }}
    @matters = Matter.team_matters(@emp_user_id, @company.id ).uniq
    @pagenumber=101
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_accounting = "selected"
    search,@conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id }
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash = set_matter_acct_conditions(conditions_hash)
    @r_name = set_report_name(3,@header_opts)
    search,@header_opts[:r_name] = append_time_expense_date_cond(search,@r_name,conditions_hash)
    @col = Physical::Timeandexpenses::TimeEntry.find_for_rpt(search,conditions_hash)
    search.gsub!("time_entry_date","expense_entry_date") #In Expense Entry table date is stored in expense_entry_date column
    @expensecol = Physical::Timeandexpenses::ExpenseEntry.find_for_rpt(search,conditions_hash)
    @total_data,@total_expenses,@conditions = group_matter_accounting_rpt(@col,@expensecol)
    @total_data = sort_display_data
    unless params[:format] == "html" # will execute when report type is not html
      @table_headers = ["Date","Lawyer","Duration(hrs)","Activity type","Billable","Rate/hr($)","Bill Amount","Discount(%)","Override amount($)","Final bill amount($)"]
      @conditions[:table_headers] = ["Date","Lawyer","Expense type","Billable","Expense amount","Discount(%)","Override amount($)","Markup(%)","Final bill amount($)"]
      column_widths = { 0 => 60, 1 => 70, 2 => 60 , 3 => 80 , 4 => 50 , 5 => 60 , 6 => 70 ,7 => 70 , 8 => 70 , 9 => 70, 10 => 80}
      @conditions[:column_widths] =  { 0 => 60, 1 => 70, 2 => 70 , 3 => 60 , 4 => 90 , 5 => 70 , 6 => 100,7 => 70, 8 => 100}
      @conditions[:select] = "matter"
    end
    @conditions[:matter_accounting_rpt]=true
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_matter_accounting)}",{:controller => '/rpt_time_and_expenses' , :action => :matter_accounting_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    alignment = { 0 => :center, 1 => :left, 2 => :right , 3 => :left , 4 => :center , 5 => :right , 6 => :right ,7 => :right , 8 => :right , 9 => :right}
    respond_to do|format|
      from=params[:action]
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_time_and_expenses/matter_accounting_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_time_and_expenses/matter_accounting_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_for_time_expenses(@total_data,@total_expenses,@table_headers,@col.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_time_and_expenses/matter_accounting_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_for_time_expenses(@total_data,@total_expenses,@table_headers,@col.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def contact_accounting
    @pagenumber=102
    @contact_accounting = "selected"
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_contact_id = params[:report] ? params[:report][:contact_id] : nil
    get_contacts
    if params[:report] && params[:report][:contact_id].present?
      params[:contact_id] = params[:report][:contact_id]
      params[:matter_id] = params[:report][:matter_id]
      get_all_new_matters
    end
    params[:report] = {}
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_contact_accounting)}",{:controller => '/rpt_time_and_expenses' , :action => :contact_accounting}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def contact_accounting_rpt
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:contact_id => params[:report][:contact_id], :matter_id => params[:report][:matter_id], :duration => params[:report][:duration] }}
    @pagenumber=102
    get_contacts
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @contact_accounting = "selected"
    search,@conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_date : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_date : ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash = set_contact_acct_conditions(conditions_hash)
    @r_name = set_report_name(4,@header_opts)
    search,@header_opts[:r_name] = append_time_expense_date_cond(search,@r_name,conditions_hash)
    @col = Physical::Timeandexpenses::TimeEntry.find_for_rpt(search, conditions_hash)
    search.gsub!("time_entry_date","expense_entry_date") #In Expense Entry table date is stored in expense_entry_date column
    @expensecol = Physical::Timeandexpenses::ExpenseEntry.find_for_rpt(search, conditions_hash)
    @total_data,@total_expenses,@conditions = group_contact_accounting_rpt(@col,@expensecol)
    @total_data = sort_display_data
    unless params[:format] == "html"  # will execute when report type is not html
      @table_headers = ["Date","Lawyer","Matter Name","Duration(hrs)","Activity Type","Billable","Rate/hr($)","Bill Amount","Discount(%)","Override Amount($)","Final Bill Amount($)"]
      @conditions[:table_headers] = ["Date","Lawyer","Matter Name","Expense Type","Billable","Expense Amount($)","Discount(%)","Override Amount($)","Markup(%)","Final Bill Amount($)"]
      column_widths = { 0 => 60, 1 => 70, 2 => 70 , 3 => 80 , 4 => 60 , 5 => 60 , 6 => 60 ,7 => 90 , 8 => 60 , 9 => 60,10 => 60}
      @conditions[:column_widths] =  { 0 => 70, 1 => 70, 2 => 70 , 3 => 70 , 4 => 70 , 5 => 70 , 6 => 70, 7 => 70,8 => 70,9=>70}
      @conditions[:select] = "contact"
    else
      unless params[:report][:contact_id].blank?
        params[:contact_id] = params[:report][:contact_id]
        params[:matter_id] = params[:report][:matter_id]
        get_all_new_matters
      else
        @matters = []
      end
    end
    unless params[:report][:contact_id].blank?
      params[:contact_id] = params[:report][:contact_id]
      params[:matter_id] = params[:report][:matter_id]
      get_all_new_matters
    end
    @conditions[:contact_accounting_rpt]=true
    add_breadcrumb "#{t(:text_time_and_expense)} #{t(:text_reports)} : #{t(:text_contact_accounting)}",{:controller => '/rpt_time_and_expenses' , :action => :contact_accounting_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    alignment = { 0 => :center, 1 => :left, 2 => :left , 3 => :center , 4 => :left , 5 => :center , 6 => :center ,7 => :center , 8 => :center , 9 => :center,10 => :center}
    respond_to do|format|
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_time_and_expenses/contact_accounting_rpt' }
      format.csv {}
      format.pdf do
        @template.template_format = :html
        @format = "pdf"
        render_pdf :file => 'rpt_time_and_expenses/contact_accounting_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
      end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_for_time_expenses(@total_data,@total_expenses,@table_headers,@col.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
      end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_time_and_expenses/contact_accounting_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_for_time_expenses(@total_data,@total_expenses,@table_headers,@col.length,@header_opts,@conditions)
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

  private

  def get_duration_setting
    @dur_setng_is_one100th = @company.duration_setting.setting_value == "1/100th"
  end
end