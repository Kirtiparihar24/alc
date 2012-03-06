class ProspectstatustypeInCompanyLookup < ActiveRecord::Migration
  def self.up
    companies = Company.find(:all, :conditions => ["id != 1"])

    companies.each do |company|
      execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('ProspectStatusType','Active',#{company.id},'Active');
            INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('ProspectStatusType','Inactive',#{company.id},'Inactive');"
    end

    companies.each do |company|
      active_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('ProspectStatusType','Active',company.id)
      inactive_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('ProspectStatusType','Inactive',company.id)
      active_lookup = Lookup.find_by_type_and_lvalue('ProspectStatusType','Active')
      inactive_lookup = Lookup.find_by_type_and_lvalue('ProspectStatusType','Inactive')
      contacts = Contact.find(:all,:conditions => ["company_id = ? and status_type is not null",company.id])

      contacts.each do |contact|
        if contact.status_type.to_i == active_lookup.id
          contact.update_attribute('status_type', active_cmplookup.id)
        elsif contact.status_type.to_i == inactive_lookup.id
          contact.update_attribute('status_type', inactive_cmplookup.id)
        end
      end

    end


  end

  def self.down
    companies = Company.find(:all, :conditions => ["id != 1"])

    companies.each do |company|
      active_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('ProspectStatusType','Active',company.id)
      inactive_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('ProspectStatusType','Inactive',company.id)
      active_lookup = Lookup.find_by_type_and_lvalue('ProspectStatusType','Active')
      inactive_lookup = Lookup.find_by_type_and_lvalue('ProspectStatusType','Inactive')
      contacts = Contact.find(:all,:conditions => ["company_id = ? and status_type is not null",company.id])

      contacts.each do |contact|
        if contact.status_type.to_i == active_cmplookup.id
          contact.update_attribute('status_type', active_lookup.id)
        elsif contact.status_type.to_i == inactive_cmplookup.id
          contact.update_attribute('status_type', inactive_lookup.id)
        end
      end

    end

    companies.each do |company|
      execute "delete from company_lookups  where type = 'ProspectStatusType' and  company_id = #{company.id};"
    end

  end
end
