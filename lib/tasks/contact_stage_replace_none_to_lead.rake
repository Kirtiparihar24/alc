namespace :contact_stage do
  task :replace_none_to_lead => :environment do
    companies = Company.all
    companies.each do |company|
      if company.contact_stages.find_by_lvalue('Lead').try(:id).blank?
        comp_contact_stage_id = company.contact_stages.find(:first).id
      else
        comp_contact_stage_id = company.contact_stages.find_by_lvalue('Lead').try(:id)
      end
      Contact.find_with_deleted(:all,:conditions => ["company_id = ? and contact_stage_id is null",company.id],:order => "id").each do |contact|
        contact.update_attribute(:contact_stage_id ,comp_contact_stage_id )
      end
      #Contact.find_all_by_company_id(company.id,:select=>'distinct contact_stage_id')
      
#      Contact.find_all_by_company_id(3,:select=>'distinct contact_stage_id').each do |con|
#            stage = CompanyLookup.find_with_deleted(:all,:conditions=>["id=?",con.contact_stage_id])
#            puts stage.type
#            if stage.type!='ContactStage'
#            puts 'not'
#            #puts stage.inspect
#            #puts comp_contact_stage_id
#            else
#            puts 'find'
#            end
#        end

      Contact.find_all_by_company_id(company.id,:select=>'distinct contact_stage_id').each do |con|
        stage = CompanyLookup.find_with_deleted(:all,:conditions=>["id=?",con.contact_stage_id])
        if stage.collect(&:type).to_s!='ContactStage'
          con_stage_id = stage.collect(&:id).to_s.to_i
          comp_id = company.id
          puts comp_id.class
          puts con_stage_id.class
          puts "for company --- #{company.id}"
          puts "wrong value is --- #{con_stage_id}"
          puts "Need to be update with --#{comp_contact_stage_id}"
          
          Contact.find_with_deleted(:all,:conditions => ["company_id = ? and contact_stage_id = ?",company.id,con_stage_id],:order => "id").each do |contact|

            #contact.update_attribute(:contact_stage_id ,comp_contact_stage_id )
              contact.contact_stage_id = comp_contact_stage_id
#              contact.save(false)
              contact.send(:update_without_callbacks)
              puts "Contact to be updated have id is #{contact.id}"
          end
        end
      end


    end
  end
end

