#This controller handles generation of report in the form of HTML,PDF,CSV format
#This controller uses Reports,RptMatters Helpers for generation of search string and conditions_hash
#Calling require_user method for checking loged in user status active or not
#Author : Venkat Amarnath Surabhi
class RptMattersController < ApplicationController
  before_filter :authenticate_user!  ,:get_favourites
  acts_as_flying_saucer
  before_filter :current_service_session_exists, :get_base_data
  include RptMattersHelper
  include RptHelper
  authorize_resource :class=> :rpt_matter
  
  layout 'left_with_tabs'

  def matter_time_spent
    @pagenumber=94
    @matter_time_spent = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    @reports_duration = params[:report] ? params[:report][:duration] : nil
    @reports_status = params[:report] ? params[:report][:status] :nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_time_spent)}",{:controller => :rpt_matters , :action => :matter_time_spent}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_master
    @pagenumber=93
    @matter_master = "selected"
    @reports_status = params[:report] ? params[:report][:status] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_master)}",{:controller => :rpt_matters , :action => :matter_master}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_master_rpt
    #TODO: The query need to be optimized - fetching matters very expensive way right now Implemented : observation by Dileep
    @pagenumber=93
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_master = "selected"
    @filters = {:get_records => params[:get_records],:date_selected => params[:date_selected],:date_start => params[:date_start], :date_end => params[:date_end], :report => {:status => params[:report][:status]}}
    if(is_access_matter? && params[:get_records] == "All")
      conditions_hash = {:company_id => @company.id}
    else
      conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    end
    @header_opts = get_headers(@r_name)
    search = set_matters_master_conditions(conditions_hash)
    @header_opts[:r_name] = set_report_name(6,@header_opts)
    @table_headers = [t(:label_matter_id),"#{t(:label_matter)} #{t(:label_description)}",t(:label_matter_name),t(:label_matter_date),t(:label_status),t(:label_ref_id),"#{t(:label_contact)}","#{t(:label_Account)}",t(:label_litigation_non_litigation)]
    @col = if params[:get_records] == "My"
      Matter.find_for_rpt(search,conditions_hash, {:include => [:matter_status, {:contact => :accounts}]})
    else
      matters = Matter.all(:select => "distinct(matters.*)", :conditions => [search, conditions_hash], :joins => "INNER JOIN matter_peoples mp ON matters.id = mp.matter_id", :include => [:matter_status, {:contact => :accounts}])
    end
    @data = []
    @col.each do |matter|
      @data << [matter.matter_no,matter.description,matter.name,livia_date(matter.matter_date),matter.matter_status ? matter.matter_status.alvalue : "",matter.ref_no,matter.contact.try(:full_name),"#{matter.try(:contact).accounts[0] && matter.try(:contact).accounts[0].name if matter.contact}",matter.matter_category]
    end
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_master)}",{:controller => :rpt_matters , :action => :matter_master_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    alignment={0=> :center,1=> :left,2=> :left,3=> :center,4=> :center,5=> :left,6=> :left,7=> :left,8=>:left}
    respond_to do|format|
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_master_rpt'}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_master_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,{})
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_master_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,{})
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_time_spent_rpt
    #TODO: The report logic need to be change --(code review / observation) -- by Dileep
    @pagenumber=94
    @dur_setng_is_one100th = @company.duration_setting.setting_value == "1/100th"
    @filters = {:get_records => params[:get_records],:report => {:summarize_by => params[:report][:summarize_by] , :duration => params[:report][:duration] , :status => params[:report][:status]}}
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_time_spent = "selected"
    merge_date_selection
    if(is_access_matter? && params[:get_records] == "All")
      conditions_hash = {:company_id => @company.id}
    else
      conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    end
    #getting headers
    @header_opts = get_headers(@r_name)
    search = set_matters_conditions(conditions_hash)
    @header_opts[:r_name] = set_report_name(1,@header_opts)
    search = append_matter_date_cond(search,conditions_hash)
    @col = if params[:get_records] == "My"
      Matter.find_for_rpt(search,conditions_hash,{:include => [:time_entries, :matter_status, :user, {:contact => :accounts}]})
    else
      matters = Matter.all(:select => "distinct(matters.*)", :conditions => [search,conditions_hash], :joins => "INNER JOIN matter_peoples mp ON matters.id = mp.matter_id", :include => [:matter_status, :time_entries, :user, {:contact => :accounts}])
    end
    #Grouping
    @total_data,@table_headers,@conditions,column_widths,alignment = group_matter_time_spent(@col)
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_time_spent)}",{:controller => :rpt_matters , :action => :matter_time_spent_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_time_spent_rpt' }
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_time_spent_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_time_spent_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_distribution
    @pagenumber=97
    @matter_distribution = "selected"
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_status = params[:report] ? params[:report][:status] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_distribution)}",{:controller => :rpt_matters , :action => :matter_distribution}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_distribution_rpt
    @filters = {:get_records => params[:get_records],:report => {:duration => params[:report][:duration] , :status => params[:report][:status]}}
    @pagenumber=97
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_distribution = "selected"
    merge_date_selection
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    #getting headers
    @header_opts = get_headers(@r_name)
    search = matters_dist_conditions(conditions_hash)
    @header_opts[:r_name] = set_report_name(4,@header_opts)
    search = append_matter_date_cond(search,conditions_hash)
    lawyers = User.find_for_rpt(search,conditions_hash).select do |user|
      user.role.name == "lawyer"
    end
    conditions_hash[:uids] = lawyers.collect(&:id)
    matter_peoples = MatterPeople.find_for_rpt("employee_user_id IS NOT NULL AND employee_user_id IN (:uids) AND is_active = :isactive", conditions_hash, {:include => [{:matter => [:matter_status, :user]}]})
    @data,@table_headers,@conditions = get_matter_distribution(lawyers,matter_peoples,conditions_hash)
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_distribution)}",{:controller => :rpt_matters , :action => :matter_distribution_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    column_widths = { 0 => 80, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80}
    @conditions[:matter_distribution] = true
    @conditions[:table_width] = 650
    respond_to do|format|
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_distribution_rpt'}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_distribution_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_distribution_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_task_status
    @pagenumber=95
    @matter_task_status = "selected"
    @report_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_task_status = params[:report] ? params[:report][:task_status] : nil
    @report_task_type = params[:report] ? params[:report][:task_type] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_task_status)}",{:controller => :rpt_matters , :action => :matter_task_status}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_task_status_rpt
    #debugger
    # : ToDo Add employeeid in matter_tasks table to avoid queries to get lawyer name
    @pagenumber=95
    @filters = {:get_records => params[:get_records],:report => {:summarize_by => params[:report][:summarize_by] , :duration => params[:report][:duration] , :task_status => params[:report][:task_status] , :task_type => params[:report][:task_type]}}
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_task_status = "selected"
    merge_date_selection
    
    if(is_access_matter? && params[:get_records] == "All")
      conditions_hash = {:company_id => @company.id}
    else
      conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    end
    #getting headers
    @header_opts = get_headers(@r_name)
    search = matter_task_status_cond(conditions_hash)
    @header_opts[:r_name] = set_report_name(2,@header_opts)
    status = @company.matter_statuses.detect {|obj| obj.lvalue == "Open"}
    conditions_hash[:status] = status.id
    col = if params[:get_records] == "My"
      Matter.find_for_rpt(search,conditions_hash, {:include => [:matter_status, {:matter_tasks => [{:matter_people => :assignee}] }, :user, {:contact => :accounts}]})
    else
      matters = Matter.find(:all,:select=>"distinct(matters.*)",:conditions =>[search,conditions_hash],:joins=>"INNER JOIN matter_peoples mp ON matters.id=mp.matter_id",:include=>[:user,:matter_status,{:contact => :accounts},{:matter_tasks => [{:matter_people => :assignee}]}])
    end
    #Grouping
    @total_data,@table_headers,@conditions,column_widths,alignment = group_matter_task_status(col)
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_task_status)}",{:controller => :rpt_matters , :action => :matter_task_status_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @conditions[:matter_task_status] = true
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_task_status_rpt'}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_task_status_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@total_data.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_task_status_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@total_data.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_team_tasks
    @pagenumber=96
    @matter_team_tasks = "selected"
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_task_status = params[:report] ? params[:report][:task_status] : nil
    @report_task_type = params[:report] ? params[:report][:task_type] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_tasks_legal_team)}",{:controller => :rpt_matters , :action => :matter_team_tasks}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_team_tasks_rpt
    # : ToDo Add employeeid in matter_tasks table to avoid queries to get lawyer name
    #TODO: The report logic need to be change --(code review / observation) -- by Dileep
    @pagenumber=96
    @filters = {:get_records => params[:get_records],:report => {:duration => params[:report][:duration] , :task_status => params[:report][:task_status] , :task_type => params[:report][:task_type]}}
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_team_tasks = "selected"
    merge_date_selection
    if(is_access_matter? && params[:get_records] == "All")
      conditions_hash = {:company_id => @company.id}
    else
      conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    end
    #getting headers
    @header_opts = get_headers(@r_name)
    search = matter_task_status_cond(conditions_hash)
    status = @company.matter_statuses.detect {|obj| obj.lvalue == "Open"}
    conditions_hash[:status] = status.id
    @header_opts[:r_name] = set_report_name(3,@header_opts)
    col = if params[:get_records] == "My"
      Matter.find_for_rpt(search,conditions_hash,{:include => [:matter_status, {:matter_tasks => [{:matter_people => :assignee}] }, :user, {:contact => :accounts}]})
    else
      matters = Matter.find(:all,:select=>"distinct(matters.*)",:conditions =>[search,conditions_hash],:joins=>"INNER JOIN matter_peoples mp ON matters.id=mp.matter_id",:include=>[:matter_status,:user,{:contact => :accounts},{:matter_tasks => [{:matter_people => :assignee}]}])
    end
    #Grouping
    @total_data,@table_headers,@conditions,column_widths,alignmnets = group_matter_team_tasks(col)
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    @conditions[:matter_team_tasks] = true
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_tasks_legal_team)}",{:controller => :rpt_matters , :action => :matter_team_tasks_rpt}
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_team_tasks_rpt'}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_team_tasks_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@total_data.length,@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_team_tasks_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@total_data.length,@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  def matter_duration
    @pagenumber=98
    @matter_duration = "selected"
    @report_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    @report_duration = params[:report] ? params[:report][:duration] : nil
    @report_status = params[:report] ? params[:report][:status] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_duration_ageing)}",{:controller => :rpt_matters , :action => :matter_duration}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  def matter_duration_rpt
    #TODO: The report logic need to be change --(code review / observation) -- by Dileep
    @filters = {:get_records => params[:get_records],:report => {:summarize_by => params[:report][:summarize_by] , :duration => params[:report][:duration] , :status => params[:report][:status]}}
    @pagenumber=98
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @matter_duration = "selected"
    merge_date_selection
    if(is_access_matter? && params[:get_records] == "All")
      conditions_hash = {:company_id => @company.id}
    else
      conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id}
    end
    #getting headers
    @header_opts = get_headers(@r_name)
    search = set_matters_conditions(conditions_hash)
    @header_opts[:r_name] = set_report_name(5,@header_opts)
    search = append_matter_duration_date_cond(search,conditions_hash)
    col = if params[:get_records] == "My"
      Matter.find_for_rpt(search,conditions_hash,{:include => [:user,:matter_status,{:contact => :accounts}]})
    else
      matters = Matter.find(:all,:select=>"distinct(matters.*)",:conditions =>[search,conditions_hash],:joins=>"INNER JOIN matter_peoples mp ON matters.id=mp.matter_id",:include=>[:user,:matter_status,{:contact => :accounts}])
    end
    #Grouping
    @total_data,@table_headers,@conditions,column_widths,alignment = group_matter_duration(col)
    @conditions[:total_records] = col.length
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_matter_duration_ageing)}",{:controller => :rpt_matters , :action => :matter_duration_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/matter_duration_rpt'}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/matter_duration_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:total_records],@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/matter_duration_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:total_records],@header_opts,@conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #Gets Matter report for revenue grouped by matter_type i.e Non-litigation / Litigation -Ketki 10/5/2011
  def revenue_by_matter_type
    @pagenumber=201
    @matter_revenue_by_matter_type = "selected"
    @matter_types = @company.get_all_matter_types
    @report_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_revenue_by_matter_type)}",{:controller => :rpt_matters , :action => :revenue_by_matter_type}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  #Gets Matter report for revenue grouped by matter_type i.e Non-litigation / Litigation -Ketki 10/5/2011
  def revenue_by_matter_type_rpt
    @pagenumber=201
    @matter_revenue_by_matter_type = "selected"
    @filters = {:get_records => params[:get_records],:date_selected => params[:date_selected],:date_start => params[:date_start], :date_end => params[:date_end], :report => {:summarize_by => params[:report][:summarize_by]}}
    @matter_types = @company.get_all_matter_types
    company_id = @company.id
    conditions_hash = { :company_id => company_id,:date_start => params[:date_start], :date_end => params[:date_end] }
    conditions_hash[:matter_type_id] = params[:report][:summarize_by] unless params[:report][:summarize_by].blank?
    if params[:date_selected].eql?("1")
      conditions_hash[:date_start] = params[:date_start]
      conditions_hash[:date_end] = params[:date_end]
    end
    @header_opts = get_headers(@r_name)
    search = set_matters_revenue_conditions(conditions_hash)
    @header_opts[:r_name] = set_report_name(7,@header_opts)
    if params[:get_records].eql?("Detail")
      @table_headers = [t(:label_matter_id),t(:label_matter_name),t(:label_matter_date), "No. of Bills",	"Total Bill value ($)", "Amount Received ($)", "Settlement Discount ($)", "Amount Outstanding ($)"]
    else
      @table_headers = ["Matter Type", "No. of Matters","No. of Bills",	"Total Bill value ($)", "Amount Received ($)", "Settlement Discount ($)", "Amount Outstanding ($)"]
    end
    @col =  Matter.find_for_rpt(search,conditions_hash, {:include => [:matter_status, {:contact => :accounts}]})
    @total_data, @conditions , alignment= MatterBilling.find_for_rpt(company_id, @matter_types, params[:get_records], @col)
    add_breadcrumb "#{t(:text_matters)} #{t(:text_reports)} : #{t(:text_revenue_by_matter_type)}",{:controller => :rpt_matters , :action => :revenue_by_matter_type}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_matters/revenue_by_matter_type_rpt' , :locals => {:title => "Matter Duration & Ageing"}}
      format.csv {render :layout => false}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_matters/revenue_by_matter_type_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:total_length],@header_opts,@conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_matters/revenue_by_matter_type_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@conditions[:total_length],@header_opts,@conditions)
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
