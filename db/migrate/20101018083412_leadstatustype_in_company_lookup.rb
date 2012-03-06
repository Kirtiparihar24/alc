class LeadstatustypeInCompanyLookup < ActiveRecord::Migration
  def self.up
    companies = Company.find(:all, :conditions => ["id != 1"])
    
    companies.each do |company|
      execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('LeadStatusType','New',#{company.id},'New');
            INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('LeadStatusType','Contacted',#{company.id},'Contacted');"
    end
    
    companies.each do |company|
      contacted_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('LeadStatusType','Contacted',company.id)
      new_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('LeadStatusType','New',company.id)      
      contacted_lookup = Lookup.find_by_type_and_lvalue('LeadStatusType','Contacted')
      new_lookup = Lookup.find_by_type_and_lvalue('LeadStatusType','New')      
      contacts = Contact.find(:all,:conditions => ["company_id = ? and status_type is not null",company.id])
      
      contacts.each do |contact|
        if contact.status_type.to_i == new_lookup.id
          contact.update_attribute('status_type', new_cmplookup.id)
        elsif contact.status_type.to_i == contacted_lookup.id
          contact.update_attribute('status_type', contacted_cmplookup.id)
        end
      end
      
    end
    
    
  end

  def self.down
    companies = Company.find(:all, :conditions => ["id != 1"])
    companies.each do |company|
      contacted_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('LeadStatusType','Contacted',company.id)
      new_cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id('LeadStatusType','New',company.id)      
      contacted_lookup = Lookup.find_by_type_and_lvalue('LeadStatusType','Contacted')
      new_lookup = Lookup.find_by_type_and_lvalue('LeadStatusType','New')      
      contacts = Contact.find(:all,:conditions => ["company_id = ? and status_type is not null",company.id])
      
      contacts.each do |contact|
        if contact.status_type.to_i == new_cmplookup.id
          contact.update_attribute('status_type', new_lookup.id)
        elsif contact.status_type.to_i == contacted_cmplookup.id
          contact.update_attribute('status_type', contacted_lookup.id)
        end
      end
    end
    
    companies.each do |company|
      execute "delete from company_lookups  where type = 'LeadStatusType' and  company_id = #{company.id};"
    end
    
  end
end
