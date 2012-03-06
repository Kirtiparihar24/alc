namespace :contact_update do
  task :contact_stage_id => :environment do
    Contact.connection.execute("delete from contacts where contact_stage_id is null")
    f = File.new("#{RAILS_ROOT}/public/contact_company_diff.txt", 'w+')
    f.write("The comparsion of the contact's company id \n \n")
    companies = Company.all
    companies.each do |company|
      f.write("Company Name :  #{company.name} \n \n")
      contacts = company.contacts
      contacts.each do |contact|
        f.write("Name :   #{contact.full_name }   ----------  Contact_id  :  #{contact.id}")
        f.write("Contact Stage Name :   #{contact.contact_stage.lvalue }   ----------  stage alvalue  :  #{contact.contact_stage.alvalue}  --- Stage id : #{contact.contact_stage.id} \n \n")
        f.write("Contact Company id :   #{contact.company_id }   ----------  stage company id  :  #{contact.contact_stage.company_id}  \n  \n")
        unless contact.company_id == contact.contact_stage.company_id
          l = CompanyLookup.find_by_company_id_and_lvalue(contact.company_id, contact.contact_stage.lvalue)
          Contact.update_all("contact_stage_id = #{l.id}", :id => contact.id)
          contact.reload
          f.write("After save Contact company  id:  #{contact.company_id} ----- stage company id : #{contact.contact_stage.company_id} \n  \n")
          f.write("stage id : #{contact.contact_stage.id} \n  \n")

        end
        f.write("------------------------------------------------------------------------------------------------------\n \n")
      end
    end
    f.close()
  end
end