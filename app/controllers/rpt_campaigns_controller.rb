#This controller handles generation of report in the form of HTML,PDF,CSV format
#This controller uses RptCampaign Helper for generation of search string and conditions_hash
#Calling require_user method for checking loged in user status active or not
#Author : Venkat Amarnath Surabhi
class RptCampaignsController < ApplicationController
  before_filter :authenticate_user!,:get_favourites
  acts_as_flying_saucer
  before_filter :current_service_session_exists, :get_base_data
  include RptCampaignsHelper
  include RptHelper
  authorize_resource :class=> :rpt_campaign
  
  layout 'left_with_tabs'

  #This method is used to make selected report link highlighted in reports selection box
  def campaign_status
    @pagenumber=103
    @campaign_status = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] :nil
    @reports_status = params[:report] ? params[:report][:status] :nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_status)}",{:controller => :rpt_campaigns , :action => :campaign_status}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash.
  def campaign_status_rpt
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @campaign_status = "selected"
    @pagenumber=103
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by] , :status => params[:report][:status]}}
    search,conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60): ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash,lookups = set_campaigns_conditions(conditions_hash)
    @r_name = set_report_name(1,@header_opts)
    search,@header_opts[:r_name] = append_date_condition(search,@r_name)
    @col = Campaign.find_for_rpt(search,conditions_hash, :include => [:members, :opportunities])
    @total_data,@table_headers,column_widths = group_campaign_status_rpt(@col,params,lookups)
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_status)}",{:controller => :rpt_campaigns , :action => :campaign_status_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    alignment= { 0 => :left, 1 => :center, 2 => :center , 3 => :center , 4 => :center , 5 => :center , 6 => :center ,7 => :left  }
    respond_to do|format|
      @total_data = sort_display_data
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_campaigns/campaign_status_rpt'}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_campaigns/campaign_status_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_campaigns/campaign_status_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@col.length,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
  def campaign_response
    @pagenumber=104
    @campaign_response = "selected"
    @report_status = params[:report] ? params[:report][:status] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_responsiveness)}",{:controller => :rpt_campaigns , :action => :campaign_response }
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of Array.
  def campaign_response_rpt
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @campaign_response = "selected"
    @pagenumber=104
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:status => params[:report][:status]}}
    search,conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60): ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash,lookups = set_campaigns_conditions(conditions_hash)
    @r_name = set_report_name(2,@header_opts)
    search,@header_opts[:r_name] = append_date_condition(search,@r_name)
    @col = Campaign.find_for_rpt(search,conditions_hash, :include => [:members, :opportunities, :user])
    @col.each do|obj|
      clength = obj.members.length
      response = obj.get_response
      olength = obj.opportunities.length
      @data << [obj.name, lookups[obj.campaign_status_type_id], clength,response, (clength != 0 and response != 0) ? ((response/clength.to_f) * 100).roundf2(2).to_s + " %" : " ", olength, (clength != 0 and olength != 0 )? ((olength/clength.to_f) * 100).roundf2(2).to_s + "%" : "", rounding(obj.get_total_revenue), obj.get_assigned_to]
    end
    @table_headers = [t(:text_campaign),t(:text_status),t(:label_contacts),"#{t(:text_response)} #{t(:text_received)}","#{t(:text_response)} %",t(:text_opportunities),"#{t(:text_opportunities)} %",t(:text_value_d),t(:text_owner)]
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_responsiveness)}",{:controller => :rpt_campaigns , :action => :campaign_response_rpt }
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    column_widths = { 0 => 130, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80 , 5 => 80 , 6 => 80 ,7 => 60 , 8 => 80 }
    alignment = { 0 => :left, 1 => :center, 2 =>:center , 3 => :center , 4 => :center , 5 => :center , 6 => :center ,7 =>:center , 8 => :left }
    respond_to do|format|
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_campaigns/campaign_response_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_campaigns/campaign_response_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_campaigns/campaign_response_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,conditions)
          send_xls_data_to_email(xls_file)
        end
      end
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
  def campaign_members
    @pagenumber=105
    @campaign_members = "selected"
    @reports_summarize_by = params[:report] ? params[:report][:summarize_by] : nil
    params[:report] = {}
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_contacts)}",{:controller => :rpt_campaigns , :action => :campaign_members}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of hash if summarized by option is account.
  #If summarized by option is contact then data is stored in the form of array
  def campaign_members_rpt
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @campaign_members = "selected"
    @pagenumber=105
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end],:report => {:summarize_by => params[:report][:summarize_by]}}
    search,conditions,@data,@total_data = '',{},[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60): ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search = set_contact_act_conditions(params[:get_records])
    @r_name = set_report_name(3,@header_opts)
    search,@header_opts[:r_name] = append_date_condition(search,@r_name)
    if params[:report][:summarize_by] == "contact"
      col = Contact.find_for_rpt(search,conditions_hash, {:include => [:accounts,:members]})
      @data,@table_headers = get_contact_members(col)
    else
      col = Account.find_for_rpt(search,conditions_hash,{:include=>[{:contacts => :members}]})
      @total_data,@table_headers = get_account_members(col)
      unless @total_data.blank?
        # total record report summarised by account
        tot = 0
        @total_data.collect { |label, col|  tot = tot + col.length.to_i  }
      end
      @length =tot
      @total_data = sort_display_data
    end
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_contacts)}",{:controller => :rpt_campaigns , :action => :campaign_members_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    respond_to do|format|
      format.html{render :layout=>false }
      format.js{render :file => 'rpt_campaigns/campaign_members_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_campaigns/campaign_members_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls{
        if params[:report][:summarize_by] == "contact"
          conditions[:table_width] = 600
          column_widths = { 0 => 100, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80 , 5 => 80 , 6 => 80  }
          data = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
        else
          column_widths = { 0 => 120, 1 => 100,2 => 80 , 3 => 80 , 4 => 80, 5 => 80}
          data = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@length,@header_opts,conditions)
        end
        send_data(data,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
      }
      format.email{
        render :update do |page|
          if report_type.eql?('Pdf')
            pdf_file_path = render_pdf :file => 'rpt_campaigns/campaign_members_rpt.pdf.erb',:clean=>true,:send_to_client=>false
            send_pdf_data_to_email(pdf_file_path)
          else
            if params[:report][:summarize_by] == "contact"
              conditions[:table_width] = 600
              column_widths = { 0 => 100, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80 , 5 => 80 , 6 => 80  }
              xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@data.length,@header_opts,conditions)
            else
              column_widths = { 0 => 120, 1 => 100,2 => 80 , 3 => 80 , 4 => 80, 5 => 80}
              xls_file = LiviaExcelReport.generate_report_with_hash(@total_data,@table_headers,@length,@header_opts,conditions)
            end
            send_xls_data_to_email(xls_file)
          end
        end
      }
    end
  end

  #This method is used to make selected report link highlighted in reports selection box
  def campaign_revenue
    @pagenumber=106
    @campaign_revenue = "selected"
    params[:report] = {}
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_revenue)}",{:controller => :rpt_campaigns , :action => :campaign_revenue}
    respond_to do |format|
      format.html
      format.js{render :layout=>false}
    end
  end

  # This method handles generation of report in html,pdf,csv fromat.
  # Generate search conditions string calling Helper methods based on parameters selected by user.
  # Retrieving Col from DB passing search string and conditions_hash in find(:all) method.
  # Grouping Col by using group_by method passing :column_name as a block and storing data in the form of data.
  def campaign_revenue_rpt
    params[:fav_id] ? self.instance_variable_set("@report#{params[:fav_id]}", "selected") : @campaign_revenue = "selected"
    @pagenumber=106
    @filters = {:get_records => params[:get_records] , :date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end]}
    search,conditions,lookups,@data,@total_data = '',{},[],[],{}
    conditions_hash = {:assign_to => @emp_user_id , :company_id => @company.id ,  :start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60): ""}
    #getting headers
    @header_opts = get_headers(@r_name)
    search,conditions_hash,lookups = set_campaigns_conditions(conditions_hash)
    @r_name = set_report_name(4,@header_opts)
    search,@header_opts[:r_name] = append_date_condition(search,@r_name)
    @col = Campaign.find_for_rpt(search, conditions_hash, :include => [:opportunities])
    if @col.length != 0
      lookup = @company.opportunity_stage_types.find_by_lvalue("Closed/Won").id
    end
    @col.each do|obj|
      opp_detail = obj.get_opp_closed_and_revenue(lookup)
      @data << [obj.name, lookups[obj.campaign_status_type_id], opp_detail[0], rounding(opp_detail[1]),obj.get_assigned_to]
    end
    @table_headers = [t(:text_campaign),t(:text_status),"#{t(:text_opportunities)} #{t(:text_closed)}",t(:text_value_d),t(:text_owner)]
    add_breadcrumb "#{t(:text_campaigns)} #{t(:text_reports)} : #{t(:text_campaign_revenue)}",{:controller => :rpt_campaigns , :action => :campaign_revenue_rpt}
    report_type=params[:report][:report_type] if params[:report] && params[:report][:report_type]
    conditions[:table_width] = 600
    column_widths = { 0 => 260, 1 => 80, 2 => 80 , 3 => 80 , 4 => 80 , 5 => 80 }
    alignment = { 0 => :left, 1 => :left, 2 => :center , 3 => :center , 4 => :left , 5 => :left }
    respond_to do|format|
      format.html{render :layout=>false}
      format.js{render :file => 'rpt_campaigns/campaign_revenue_rpt'}
      format.csv {}
      format.pdf do
				@template.template_format = :html
				@format = "pdf"
				render_pdf :file => 'rpt_campaigns/campaign_revenue_rpt.pdf.erb',:clean=>true, :send_file => { :filename => 'livia_report.pdf' }
			end
      format.xls do
        xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,conditions)
        send_data(xls_file,:filename => "livia_report.xls", :type => 'application/xls', :disposition => 'inline')
			end
      format.email do
        @template.template_format = :html
        if report_type.eql?('Pdf')
          @format = "pdf"
          pdf_file_path = render_pdf :file => 'rpt_campaigns/campaign_revenue_rpt.pdf.erb',:clean=>true,:send_to_client=>false
          send_pdf_data_to_email(pdf_file_path)
        else
          xls_file = LiviaExcelReport.generate_report_with_array(@data,@table_headers,@col.length,@header_opts,conditions)
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
