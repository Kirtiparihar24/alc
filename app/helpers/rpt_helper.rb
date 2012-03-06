#Methods added to this Module are almost common among all the RptControllers.
module RptHelper

  public

  def create_favourite
    params[:report_favourite][:selected_options] = params[:report_favourite][:selected_options] || {}
    params[:report_favourite].merge!({:company_id => get_company_id,:employee_user_id => get_employee_user_id , :created_by_user_id => current_user.id })
    CompanyReport.create(params[:report_favourite])
    @favourites = CompanyReport.find(:all,:conditions => ["company_id = ? and employee_user_id = ? and report_type = ?",get_company_id,get_employee_user_id,params[:report_favourite][:report_type]])
    @div_update = params[:report_favourite][:report_type] + "_fav"
    render "rpt_partials/create_favourite.js"
  end
  
  def add_favourite
     
    render :partial => "rpt_partials/favourite"
  end

  def send_pdf_data_to_email(file)
    send_report(file,params)
    render :update do |page|
      flash[:notice] = "Mail sent succsessfully"
      page << "tb_remove();"
      page.replace_html "altnotice", :partial => '/common/common_flash_message'
    end
  end

  def send_xls_data_to_email(file)
    send_report(file,params)
    render :update do |page|
      flash[:notice] = "Mail sent succsessfully"
      page << "tb_remove();"
      page.replace_html "altnotice", :partial => '/common/common_flash_message'
    end
  end

  def send_report(file,params)
    email = params[:email][:to]
    subject=params[:email][:subject]
    report_type=params[:report][:report_type]
    begin
      user = current_user
      LiviaMailConfig::email_settings(user.company)
      mail_body = params[:email][:description]
      mail = Mail.new do
        from user.email
        to email
        subject subject
        part :content_type => "multipart/alternative"  do |prt|
          prt.html_part do
            content_type 'text/html; charset=UTF-8'
            body  "<pre>#{mail_body}</pre>"
          end
        end
      end
      report_type.eql?('Pdf') ?  file = File.read(file) :  file = file
      mail.attachments[subject+'.'+report_type] = file
      mail.deliver
    rescue Timeout::Error => err
      logger.info "Timeout Error"
    rescue Exception => exec
      logger.info "Error while trying to send email"
      logger.info  exec.message
    end
  end

  def destroy_favourite
    # Need to refactor following code .
    company_report = CompanyReport.find(params[:id])
    case company_report.report_type
    when "Contact"
      controller = "rpt_contacts"
      action = "current_contact"
    when "Account"
      controller = "rpt_accounts"
      action = "current_account"
    when 'Opportunity'
      controller = "rpt_opportunities"
      action = "opportunity_pipe"
    when 'Matter'
      controller = "rpt_matters"
      action = "matter_master"
    when 'TimeAndExpense'
      controller = "rpt_time_and_expenses"
      action = "time_accounted"
    when 'Campaign'
      controller = "rpt_campaigns"
      action = "campaign_status"
    end
    company_report.destroy
    flash[:notice] = "Report was successfully removed from favorite list."
    redirect_to :action =>action ,:controller => controller
  end

  def send_email_rpt
    render :partial => "rpt_partials/email_rpt"
  end

  def display_report_sub_tab?(request)
    if request.xhr?
      if request.referer.match(/company_reports/) || request.referer.match(/rpt_/)
        true
      else
        false
      end
    else
      true
    end
  end

  private

  def get_favourites
    col = CompanyReport.find(:all,:conditions => ["company_id = ? and employee_user_id = ?",get_company_id,get_employee_user_id])
    account = t(:label_Account)
    col.group_by(&:report_type).each do|key,gcol|
      case key
      when 'Contact'
        @contacts_fav = gcol
      when account
        @accounts_fav = gcol
      when 'Opportunity'
        @opps_fav = gcol
      when 'Matter'
        @matters_fav = gcol
      when 'TimeAndExpense'
        @times_fav = gcol
      when 'Campaign'
        @campaigns_fav = gcol
      end
    end
    
    if request.xhr? and params[:load_popup]
      set_params_for_favorite
    end
  end

  #This method retrieves current lawyer,lawfirm and current_user details.
  def get_headers(r_name = nil)
    opts = {}
    if current_service_session
      opts[:l_firm] =  current_service_session.assignment.nil? ? current_service_session.user.company_full_name : current_service_session.assignment.user.company_full_name
      opts[:lawyer] = current_service_session.assignment.nil? ? current_service_session.user.try(:full_name) : current_service_session.assignment.try(:user).try(:full_name)
    else
      opts[:l_firm] = current_user.end_user.company.name
      opts[:lawyer] = current_user.end_user.try(:full_name)
    end
    opts[:r_name] = r_name
    opts[:user] = current_user.name.try(:capitalize) if current_user
    opts
  end

  #This method is used to set date conditions in search string
  def append_date_condition(search,r_name)
    if params[:date_selected]
      search += " AND created_at Between :start_date AND :end_date "
      r_name += " created between #{params[:date_start]} - #{params[:date_end]}"
    end
    [search,r_name]
  end

  # This method is used to Sort the Hash keys in the form of alphabatical order
  def sort_display_data
    if @total_data.has_key?("") or @total_data.has_key?(nil) and @total_data.length > 1
      @total_data = @total_data.sort do|a,b|
        a[0].to_s <=> b[0].to_s
      end
      deleted = @total_data.delete_at(0)
      @total_data.push(deleted)
    else
      @total_data = @total_data.sort
    end
    @total_data
  end


  def merge_date_selection    
    @filters.merge!({:date_selected => params[:date_selected] , :date_start => params[:date_start], :date_end => params[:date_end]}) if params[:report][:duration] == "range"
  end

  def merge_hash_with_date(conditions_hash = {})
    conditions_hash.merge!({:start_date => (params[:date_start] != "" and params[:date_start]) ? params[:date_start].to_time : "", :end_date => (params[:date_end] != "" and params[:date_end]) ? params[:date_end].to_time + (23.9*60*60): ""})
  end


  def set_params_for_favorite
    fav = CompanyReport.find_favorite(params[:fav_id],get_company_id)
    [:get_records,:date_selected,:date_start,:date_end].each do |sym|
      params[sym] = fav.send(sym)
    end
    params[:run_report] = true
    params[:report] = {}
    fav.selected_options.keys.each do |key|
      params[:report][key] = fav.selected_options[key]
    end
  end
end
