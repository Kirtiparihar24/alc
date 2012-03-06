class CampaignMailer < ActionMailer::Base
  #This method is used to set the first mail attributes of a campaign
  def send_first_mail(url, campaign, recipient, subject, email, signature, attachment, current_company, current_user, response_token)
    @current_company=current_company
    @company = CompanyEmailSetting.find_by_company_id_and_setting_type(@current_company.id, 'SMTP')
    @company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(@current_company.id, 'POP3')
    if @company.nil?
      @company = CompanyEmailSetting.find_by_company_id_and_setting_type(1, 'SMTP')
      @company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(1, 'POP3')
    end
    camp_email = ENV["HOST_NAME"].include?('liviaservices') ? "campaigns@liviaservices.com" : "campaigns.test@liviatech.com"
    CampaignMailer.smtp_settings = {
      :address               => @company.address ,
      :port                  => @company.port,
      :domain                => @company.domain,
      :user_name             => @company.user_name,
      :password              => @company.password,
      :authentication => :plain,
      :enable_ssl          =>  @company.enable_ssl,
      :enable_starttls_auto  => @company.enable_starttls_auto
    }
    @subject    = subject
    @body       = {}
    @bcc = recipient
    @from       = current_user.blank? ? camp_email : current_user  #@company_pop.user_name
    @headers['Reply-To'] = camp_email
    @sent_on = Time.zone.now.to_date
    part "text/html" do |p|
      @email=email
      @email_signature = signature
      p.body = render_message 'send_first_mail.html.erb',
        :response_link=> (response_token.blank? ? "#{url}/campaigns/response_form/#{campaign}" :  "#{url}/campaigns/response_form/#{campaign}?response_token=#{response_token}")
    end
    
    unless attachment.nil?
      docs = Document.find(attachment)      
      docs.each do |attach|
        attachment  "application/octet-stream" do |a|
          a.body = File.read("#{attach.data.path}")
          a.filename= "#{attach.name}"
        end
      end
    end

  end

  #This method is used to set the second mail attributes of a campaign
  def send_reminder_mail(url, campaign, recipient, subject, email, signature, attachment, current_company, current_user, response_token)
    @current_company=current_company
    @company = CompanyEmailSetting.find_by_company_id_and_setting_type(@current_company.id, 'SMTP')
    @company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(@current_company.id, 'POP3')
    if @company.nil?
      @company = CompanyEmailSetting.find_by_company_id_and_setting_type(1, 'SMTP')
      @company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(1, 'POP3')
    end

    camp_email = ENV["HOST_NAME"].include?('liviaservices') ? "campaigns@liviaservices.com" : "campaigns.test@liviatech.com"
    CampaignMailer.smtp_settings = {
      :address               => @company.address ,
      :port                  => @company.port,
      :domain                => @company.domain,
      :user_name             => @company.user_name,
      :password              => @company.password,
      :authentication => :plain,
      :enable_ssl          =>  @company.enable_ssl,
      :enable_starttls_auto  => @company.enable_starttls_auto
    }
    @subject    = subject
    @body       = {}
    @bcc = recipient
    @from       = current_user.blank? ? camp_email : current_user  #@company_pop.user_name
    @headers['Reply-To'] = camp_email
    @content_type = "text/html"
    @sent_on = Time.zone.now.to_date
    @email=email
    @email_signature = signature
    part "text/html" do |p|
      p.body = render_message 'send_reminder_mail.html.erb',
        :response_link=>"#{url}/campaigns/response_form/#{campaign}?response_token=#{response_token}"
    end

    unless attachment.nil?
      docs = Document.find(attachment)      
      docs.each do |attach|
        attachment  "application/octet-stream" do |a|
          a.body = File.read("#{attach.data.path}")
          a.filename= "#{attach.name}"
        end
      end
    end
  end

end
