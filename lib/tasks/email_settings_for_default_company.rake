# Author Surekha
# Task to create default email configuration

namespace :email_settings do
  task :create_email_settings => :environment do
    email_settings=CompanyEmailSetting.find_by_company_id(1)
    if email_settings.nil?
      CompanyEmailSetting.create(:setting_type=>'SMTP',:company_id=>1,:address=>'lvmail01.livialegal.com',:port=>25,:domain => 'lvmail01.livialegal.com', :user_name=>'support@liviatech.com',:password=>'Accounts@2011',:enable_ssl=>'false',:enable_starttls_auto=>'true')
      CompanyEmailSetting.create(:setting_type=>'POP3',:company_id=>1,:address=>'lvmail01.livialegal.com',:port=>995,:domain=>'lvmail01.livialegal.com',:user_name=>'support@liviatech.com',:password=>'Accounts@2011',:enable_ssl=>'true',:enable_starttls_auto=>'false')
    else
      puts 'Email Settings already configured for default company'
    end
    
    CompanyEmailSetting.connection.execute("TRUNCATE TABLE delayed_jobs;")
  end
end
