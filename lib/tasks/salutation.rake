namespace :salutation_type do
  # This task-1 is for inserting data regarding salutation types into company-lookups - Rahul P 3/5/2011
  # This task-2 is for inserting salutation_ids into contacts table previous it have salutation new salutation_id column added - Rahul P 4/5/2011
  # This task-3 is for inserting salutation_ids into matter_peoples table previous it have salutation new salutation_id column added - Rahul P 11/5/2011
  task :create_salutation_type => :environment do
    companies=Company.all
    companies.each do |company|
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Dr.','Dr.',company.id)
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Miss','Miss',company.id)
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Mr.','Mr.',company.id)
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Mrs.','Mrs.',company.id)
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Ms.','Ms.',company.id)
      SalutationType.find_or_create_by_lvalue_and_alvalue_and_company_id('Prof.','Prof.',company.id)
    end
  end

  task :add_salutation_id_to_contacts => :environment do
    companies = Company.all
    companies.each do |company|
      Contact.find_with_deleted(:all,:conditions => ["company_id = ?",company.id],:order => "id").each do |contact|
        if !contact.salutation.nil? and !contact.salutation.empty?
          if contact.salutation.eql?('Dr.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Dr.').id)
          elsif contact.salutation.eql?('Miss.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Miss').id)
          elsif contact.salutation.eql?('Mr.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Mr.').id)
          elsif contact.salutation.eql?('Mrs.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Mrs.').id)
          elsif contact.salutation.eql?('Ms.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Ms.').id)
          elsif contact.salutation.eql?('Prof.')
            contact.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Prof.').id)
          end
        end
      end
    end
  end

  task :add_salutation_id_to_matter_peoples => :environment do
    companies = Company.all
    companies.each do |company|
      MatterPeople.find_with_deleted(:all,:conditions => ["company_id = ?",company.id],:order => "id").each do |mt_ppl|
        if !mt_ppl.salutation.nil? and !mt_ppl.salutation.empty?
          if mt_ppl.salutation.eql?('Dr.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Dr.').id)
          elsif mt_ppl.salutation.eql?('Miss.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Miss').id)
          elsif mt_ppl.salutation.eql?('Mr.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Mr.').id)
          elsif mt_ppl.salutation.eql?('Mrs.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Mrs.').id)
          elsif mt_ppl.salutation.eql?('Ms.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Ms.').id)
          elsif mt_ppl.salutation.eql?('Prof.')
            mt_ppl.update_attribute(:salutation_id ,company.salutation_types.find_by_lvalue('Prof.').id)
          end
        end
      end
    end
  end
end
