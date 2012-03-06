class CampaignEmail
  include GeneralFunction
  @queue = :campaign_email_queue

  def self.perform(email_type, url_link, campaign_id, subject, email_content, email_signature,document_home_ids, campaign_contact_ids,company_id, emp_user_email,user_id,current_company_id, current_user,currently_logged_in_user,format_style = "formal")
    attachment = []
    document_home_first = []
    document_home_ids.each do |document_home|
      document_home_first << DocumentHome.find(document_home)
    end

    if document_home_first.present?
      document_home_first.each do |d|
        attachment << d.latest_doc.id
      end
    end
    
    campaign_contacts = []
    campaign_contact_ids.each do |campaign_contact_id|
      campaign_contacts << CampaignMember.find(campaign_contact_id)
    end
    
    company = Company.find(company_id)
    campaign_members =  Campaign.find(campaign_id).members.limit_size
    camp_mem_status = company.campaign_member_status_types
    camp_mem_status_hash = Hash[*camp_mem_status.collect {|cms| [cms.lvalue, cms.id] }.flatten]
    current_company = Company.find(current_company_id)
    self.send_email_to_members(email_content,campaign_members, camp_mem_status_hash, email_type,company, emp_user_email,user_id, format_style,url_link,campaign_id,subject,email_signature,attachment,current_company,current_user,currently_logged_in_user)

  end

  def self.send_email_to_members(email_content ,campaign_members, camp_mem_status_hash, email_type,company, emp_user_email, user_id,format_style,url_link,campaign_id,subject,email_signature,attachment,current_company,current_user_id,currently_logged_in_user)
    # setting the format style for the Liquid Parsing
    case format_style
    when "formal"
      email_content = email_content.gsub("contact.full_name","contact.formal_name")
    when  "informal"
      email_content = email_content.gsub("contact.full_name","contact.informal_name")
    end
    
    status_condition = camp_mem_status_hash["Contacted"].to_i if email_type == 'reminder'
    status_condition = camp_mem_status_hash["New"].to_i  if email_type == 'first'
    campaign_members.find_in_batches(:conditions =>  ["campaign_member_status_type_id = ?", status_condition ] ) do |members|
      members.each do | member, i|
        #email = member.contact.email.to_s if member.contact
        email = member.email.to_s
        alt_email_collection = nil
        if member.alt_email
          alt_email_collection = member.alt_email.to_s.split(",")
        end
        response_token = Devise.friendly_token
        # LIQUID FILTER CONTENT
        mail_content = self.parse_for_liquid(email_content,email,campaign_id)
        if email_type == 'first'
          CampaignMember.update_all({:response_token => response_token}, {:id => member.id})
          member.update_attributes(:first_mailed_date=> Time.zone.now.to_date, :campaign_member_status_type_id=> camp_mem_status_hash["Contacted"].to_i,:updated_by_user_id=> user_id)
          lead_status_types =  company.lead_status_types.find_by_lvalue('Contacted').id
          member.contact.update_attribute(:status_type, lead_status_types) if member.contact.try(:contact_stage).try(:lvalue) == 'Lead'
          # sending  email
          CampaignMailer.deliver_send_first_mail(url_link, campaign_id, email, subject, mail_content, email_signature, attachment, current_company, current_user_id, response_token)
          # set_campaign_first_email_sent_to_contact
          campaign = Campaign.find(campaign_id)
          campaign.update_attributes(:first_email_sent => true) unless campaign.first_email_sent == true

          if alt_email_collection
            alt_email_collection.each do |alt_email|
              CampaignMailer.deliver_send_first_mail(url_link, campaign_id, alt_email, subject, mail_content, email_signature, attachment, current_company, current_user_id, response_token)
            end
          end

        elsif email_type == 'reminder'
          member.update_attributes(:reminder_date=> Time.zone.now.to_date, :campaign_member_status_type_id=> camp_mem_status_hash["Contacted"].to_i,:updated_by_user_id=>user_id,:company_id=>company.id )
          CampaignMailer.deliver_send_reminder_mail(url_link,campaign_id,email,subject, mail_content, email_signature,attachment,current_company,current_user_id, response_token)
          if alt_email_collection
            alt_email_collection.each do |alt_email|
              CampaignMailer.deliver_send_reminder_mail(url_link, campaign_id, alt_email, subject, mail_content, email_signature, attachment, current_company, current_user_id, response_token)
            end
          end
        end
      end
    end
    
    if emp_user_email
      current_user = User.find(currently_logged_in_user)
      user = User.find(user_id)
      send_notification_for_campaign_mails(user,current_user)
    end

  end

  def self.parse_for_liquid(email,email_id,campaign_id)
    # requirements for Liquid
    campaign_contact = CampaignMember.find_by_email_and_campaign_id(email_id,campaign_id)
    contact = campaign_contact.contact if campaign_contact.contact.present?
    contact_address = company_address = company = nil
    # accessing the address and company(Account) details
    if contact
      company = contact.accounts.first if contact.accounts
      company_address = contact.accounts.first.try(:billingaddresses).try(:first)
    else
      # no address or company details
      contact = campaign_contact
    end
    contact_address = contact.try(:address)
    #Liquid method to parse the Email content
    mail_template = Liquid::Template.parse(email)

    mail_template.render( 'contact' => contact, 'persnl_add' => contact_address, 'company' => company, 'company_add' => company_address )
  end
end
