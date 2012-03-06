class CompanyEmailSetting < ActiveRecord::Base
  belongs_to :company
  validates_presence_of :domain ,:if => Proc.new{ |x| x.setting_type=='SMTP'}
  validates_presence_of :port,:address,:user_name,:password
   
  def check_email_settings(params)
    begin
      Mail.defaults do
        delivery_method :smtp, {
          :address => "#{params[:address]}",
          :port => "#{params[:port]}",
          :domain => "#{params[:domain]}",
          :user_name => "#{params[:user_name]}",
          :password => "#{params[:password]}",
          :authentication => :plain,
          :enable_ssl => "#{params[:enable_ssl].present?}"
        }
      end
      
      mail = Mail.new do
        from "#{params[:user_name]}"
        to "#{params[:user_name]}"
        subject "Test Mail"
        body "Test Mail"
      end

      mail.to_s
      mail.deliver
    rescue Exception=>ex
	    self.errors.add('This','SMTP setting is invalid')
      return false
    end

    true
  end


  def check_pop3_settings(params)
    begin
      Mail.defaults do
        retriever_method :pop3, {
          :address => "#{params[:address]}",
          :port => "#{params[:port]}",
          :user_name => "#{params[:user_name]}",
          :password => "#{params[:password]}",
          :enable_ssl => "#{params[:enable_ssl].present?}",
          :authentication => :plain,
          :enable_starttls_auto => "#{params[:enable_starttls_auto].present?}"
        }
      end
      email=Mail.last
      parts=email.body

    rescue Exception=>ex
      self.errors.add('This','POP3 setting')
      return false
    end

    true
  end

  def self.set_emails_status(emails, last_message_read_company)
    #Last read message date to be ferched for checking mails after that only
    last_message_read = LastMessageRead.last(:conditions => ['company_id = ? ', last_message_read_company.id])
    last_message_read = last_message_read.nil? ? "2009-01-01 10:00:40" : last_message_read.message

    emails.each_with_index do |email, i|
      bounce = BounceEmail::Mail.new(email)
      from_address = email.from
      @company_ids = []
      @members = []
      campaign_id = get_campaign_id(email)
      CompanyLookup.all(:select => 'DISTINCT(company_id)',
        :conditions=>['type=? and lvalue=?','CampaignMemberStatusType','Contacted']).each do |company|        
        CampaignMember.all(:joins=> 'LEFT OUTER JOIN contacts on campaign_members.contact_id = contacts.id',
          :select=>'campaign_members.*,campaign_members.contact_id,contacts.email as contact_email_id,campaign_members.email as email_id',
          :conditions=>['campaign_member_status_type_id = ? AND campaign_members.campaign_id = ?',get_campaign_member_status('Contacted',company.company_id),campaign_id] ).each do |member|

          if bounce.isbounce && email.date > last_message_read.to_datetime
            email_addresses= get_final_recipients(email)
            if(bounce.code=="5.2.0" || bounce.code=="4.2.2"|| bounce.code=="4.4.1")
              status_id=get_campaign_member_status('Inbox Full',company.company_id)
            else
              status_id=get_campaign_member_status('Invalid Email',company.company_id)
            end
            reason= get_bounced_reason(bounce.code).nil? ? bounce.reason : get_bounced_reason(bounce.code)
            
            if email_addresses.include?(member.contact_email_id) || email_addresses.include?(member.email_id)
              member.update_attributes(:campaign_member_status_type_id=>status_id,:bounce_code=>bounce.code,:bounce_reason=>reason)
            end            
          else            
            if member.contact_email_id== from_address.to_s || member.email_id== from_address.to_s
              member.update_attributes(:campaign_member_status_type_id=>get_campaign_member_status('Out of Office',company.company_id),:bounce_code=>'0.0.0',:bounce_reason=>'Out Of Office')
            end            
          end
        end
      end
      
      #Code to update last mail
      if i==emails.length-1
        message_date=LastMessageRead.new
        message_date.message= email.date
        message_date.company_id= last_message_read_company.id
        message_date.save
      end
    end
  end

  def self.get_campaign_id(email)
    parts = email.body.to_s
    regexp =  /campaigns\/response_form\/(\d+)?/
    id = parts.match(regexp)
    if id
      id = $1
    end    
    id
  end

  def self.get_final_recipient(email)
    email.to_s
    parts=email.body.parts.to_a
    parts[1].to_s.split('Final-Recipient: rfc822;').last.split(' ').first
  end

  def self.get_final_recipients(email)
    email.to_s
    parts=email.body.parts.to_a
    email_str=parts[1].to_s
    regexp=/(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}/
    addrs=[]
    email_str.each do |e|
      unless e.match(regexp).nil?
        addrs << e.match(regexp).to_s
      end
    end
    xt  = addrs.collect {|e| e}

    xt.uniq
  end

  def self.get_campaign_member_status(type, company)
    CompanyLookup.find_by_type_and_lvalue_and_company_id('CampaignMemberStatusType',type,company).id
  end

  def self.get_bounced_reason(code)
    case code
   
    when "5.1.1"
      return  "The mailbox specified in the address does not exist"
    when "5.1.2"
      return  "unrouteable mail domain"
    when "5.2.2"
      return  "The mailbox is full"
    when "4.2.2"
      return "The mailbox is full"
    when "5.1.0"
      return "Address rejected"
    when "4.1.2"
      return  "The destination system specified in the address does not exist"
    when "4.2.0"
      return  "Mail not yet been delivered"
    when "5.2.0"
      return  "Destination mailbox error"
    when "5.4.4"
      return  "The necessary routing information was unavailable from the directory server"#"Unrouteable address"
    when "4.4.7"
      return  "retry timeout exceeded"
    when "5.2.0"
      return  "The account or domain may not exist, they may be blacklisted, or missing the proper dns entries."
    when "4.4.1"
      return  "The remote system was busy"
    when "5.5.0"
      return  "Delivery protocol error"
    when "5.5.4"
      return  "Arguments were out of range" #"554 delivery error"
    when "5.1.1"
      return  "This Gmail user does not exist"
    when "5.7.1"
      return  "The sender is not authorized to send to the destination"#"No such recipient"
    when "5.3.2"
      return  "The host on which the mailbox is resident is not accepting messages"
      ##"Technical details of permanent failure|Too many bad recipients ||
      #The recipient server did not accept our requests to connect || emailConnection was dropped by remote host"
    when "4.3.2"
      return "Connection was dropped by remote host"
    when "5.0.0"
      return  "Delivery to the following recipient failed permanently"
    else
      return "unknown"
    end
  end

end
# == Schema Information
#
# Table name: company_email_settings
#
#  id                   :integer         not null, primary key
#  setting_type         :string(255)
#  address              :text
#  port                 :integer
#  domain               :text
#  user_name            :text
#  password             :string(255)
#  company_id           :integer
#  enable_ssl           :boolean         default(FALSE), not null
#  enable_starttls_auto :boolean         default(FALSE), not null
#  created_at           :datetime
#  updated_at           :datetime
#

