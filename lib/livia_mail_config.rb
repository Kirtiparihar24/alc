require 'mail'
#sets the default configuration settings for the mail gem
# lvmail01.livialegal.com

module LiviaMailConfig
  def self.email_settings(company=nil)
    current_company=company

    company_smtp = CompanyEmailSetting.find_by_company_id_and_setting_type(current_company.id,'SMTP')
    company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(current_company.id,'POP3')
    if company_smtp.nil?
    company_smtp = CompanyEmailSetting.find_by_company_id_and_setting_type(1,'SMTP')
    company_pop = CompanyEmailSetting.find_by_company_id_and_setting_type(1,'POP3')
    end
    
    Mail.defaults do
      delivery_method :smtp, {  :address => company_smtp.address,
        :port => company_smtp.port,
        :domain => company_smtp.domain,
        :user_name => company_smtp.user_name,
        :password => company_smtp.password,
        :authentication => :plain,
        :enable_starttls_auto => company_smtp.enable_starttls_auto
      }
    end
  
    Mail.defaults do
      retriever_method :pop3, {  :address => company_pop.address,
        :port => company_pop.port,
        :user_name => company_pop.user_name,
        :password => company_pop.password,
        :enable_ssl          =>  company_pop.enable_ssl,
        :authentication=> :plain,
        :enable_starttls_auto => company_pop.enable_starttls_auto
      }
    end
  end
end
