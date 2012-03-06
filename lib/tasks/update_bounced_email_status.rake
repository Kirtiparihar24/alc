# Author Surekha
# Handling Bounce Email and updating reasons for the same
# 21 Dec 2010
namespace :update_bounced_email_status do
  task :update_status => :environment do

  require 'net/imap'

    #Set Email ----------------------

    @companies=CompanyEmailSetting.find_all_by_setting_type('POP3')
    puts @companies   
    @companies.each do |company|
         
      Mail.defaults do
        retriever_method :pop3, {
          :address => company.address, 
          :port => company.port,
          :user_name => company.user_name, 
          :password => company.password,
          :enable_ssl          =>  company.enable_ssl,
          :authentication=> :plain,
          :enable_starttls_auto => company.enable_starttls_auto
        }
      end

      emails = Mail.all
      #emails=Mail.find(:what => :last, :count => 25, :order => :desc)

	imap = Net::IMAP.new(company.address, 993, company.enable_ssl)
		imap.instance_eval { send_command('ID ("GUID" "1")') } 
		#imap.authenticate('LOGIN', USERNAME, PASSWORD)
		imap.login(company.user_name, company.password)
		imap.select('INBOX')
		if not imap.list('Mail/','Old-messages')
		    imap.create('Mail/Old-messages')
		  end
		count = 0

		# i specify who the emails are from here. i also specify a "since" date, as that seems to limit
		# my query and run faster.
		# ----- MODIFY THIS SEARCH CRITERIA -----
		imap.search(["BEFORE", "31-Dec-2011", "SINCE", "1-Jan-2011"]).each do |message_id|
		  count = count + 1
		  env = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
		  puts "#{env.from[0].name}: \t#{env.subject}"
		  imap.copy(message_id, 'Mail/Old-messages')
		  imap.store(message_id, "+FLAGS", [:Deleted])
		end
		imap.expunge

		puts "moved #{count} messages"

		imap.logout
		imap.disconnect
      CompanyEmailSetting.set_emails_status(emails,company)
    end
    mail = CompanyEmailSetting.find_by_setting_type_and_company_id('POP3',1)
      Mail.defaults do
        retriever_method :pop3, {
          :address => mail.address,
          :port => mail.port,
          :user_name => mail.user_name,
          :password => mail.password,
          :enable_ssl          =>  mail.enable_ssl,
          :authentication=> :plain,
          :enable_starttls_auto => mail.enable_starttls_auto
        }
      end

      @emails = Mail.all

	imap = Net::IMAP.new(mail.address, 993, mail.enable_ssl)
		imap.instance_eval { send_command('ID ("GUID" "1")') } 
		#imap.authenticate('LOGIN', USERNAME, PASSWORD)
		imap.login(mail.user_name, mail.password)
		imap.select('INBOX')
		if not imap.list('Mail/','Old-messages')
		    imap.create('Mail/Old-messages')
		  end
		count = 0

		# i specify who the emails are from here. i also specify a "since" date, as that seems to limit
		# my query and run faster.
		# ----- MODIFY THIS SEARCH CRITERIA -----
		imap.search(["BEFORE", "31-Dec-2011", "SINCE", "1-Jan-2011"]).each do |message_id|
		  count = count + 1
		  env = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
		  puts "#{env.from[0].name}: \t#{env.subject}"
		  imap.copy(message_id, 'Mail/Old-messages')
		  imap.store(message_id, "+FLAGS", [:Deleted])
		end
		imap.expunge

		puts "moved #{count} messages"

		imap.logout
		imap.disconnect
    list_id=@companies.collect{ |obj| obj.id }
    Company.find_in_batches(:conditions=>['id not in (?)',list_id]) do |companies|
    companies.each do |company|
      
      #emails=Mail.find(:what => :last, :count => 25, :order => :desc)
      CompanyEmailSetting.set_emails_status(@emails,company)
    end
   end
  end
end



