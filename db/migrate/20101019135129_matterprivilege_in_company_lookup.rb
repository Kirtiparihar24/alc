class MatterprivilegeInCompanyLookup < ActiveRecord::Migration
  def self.up
    companies = Company.find(:all, :conditions => ["id != 1"])
    
    companies.each do |company|
      ["Not privileged","Atty Work product","Atty-client","Atty-client and Attywork product"].each do |matterprivilege|
        execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('MatterPrivilege','#{matterprivilege}',#{company.id},'#{matterprivilege}');"
      end
    end

    companies.each do |company|
      ["Not privileged","Atty Work product","Atty-client","Atty-client and Attywork product"].each do |matterprivilege|
        cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id("MatterPrivilege","#{matterprivilege}",company.id)
        lookup = Lookup.find_by_type_and_lvalue("MatterPrivileges","#{matterprivilege}")
        documents = Document.find(:all,:conditions => ["company_id = ? and privilege = '#{lookup.id}'",company.id])
        documents.each do |document|
           document.privilege = cmplookup.id
           document.send(:update_without_callbacks)
        end
      end
    end
    
    admin_cmplookups = CompanyLookup.find_all_by_type_and_company_id("MatterPrivileges",1)
    admin_cmplookups.each do |mp|
       execute "update company_lookups set type = 'MatterPrivilege' where id = #{mp.id} "
    end
  
  end

  def self.down
    companies = Company.find(:all, :conditions => ["id != 1"])
    
    companies.each do |company|
      ["Not privileged","Atty Work product","Atty-client","Atty-client and Attywork product"].each do |matterprivilege|
        cmplookup = CompanyLookup.find_by_type_and_lvalue_and_company_id("MatterPrivilege","#{matterprivilege}",company.id)
        lookup = Lookup.find_by_type_and_lvalue("MatterPrivileges","#{matterprivilege}")
        documents = Document.find(:all,:conditions => ["company_id = ? and privilege = '#{cmplookup.id}'",company.id])
        documents.each do |document|
           document.privilege = lookup.id
           document.send(:update_without_callbacks)
        end
      end
    end    

    companies.each do |company|
      execute "delete from company_lookups  where type = 'MatterPrivilege' and  company_id = #{company.id};"
    end
    
    admin_cmplookups = CompanyLookup.find_all_by_type_and_company_id("MatterPrivilege",1)
    admin_cmplookups.each do |mp|
       execute "update company_lookups set type = 'MatterPrivileges' where id = #{mp.id} "
    end
    
  end
  
end
