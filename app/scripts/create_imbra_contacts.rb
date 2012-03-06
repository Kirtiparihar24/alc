#TODO Might be used after some time
# Create a logger object to write in seperate file

ZIMBRA_CONTACT_LOG = AuditLogger.new("#{RAILS_ROOT}/log/zimbra_contact_#{Time.now.strftime("%Y%m%dT%H%M%S")}.log")

# Get all companies
companies = Company.find(:all)

# Loop through each company and it's contact
companies.each { |company|
	contacts = Contact.find(:all, :conditions => "company_id = #{company.id} and (status_type != 12 or status_type is null)")
  #contacts.update_attributes()	
  contacts.each { |contact|
    begin
      contact.zimbra_contact_id = nil
      contact.save(false)
#      Contact.update_all({:zimbra_contact_id => nil},{:id => contact.id})
#       contact.save(false)
		rescue => e
			ZIMBRA_CONTACT_LOG.error "Contact : #{contact.id} and Company : #{contact.company_id} : #{e}"
		end
	}
}
	
