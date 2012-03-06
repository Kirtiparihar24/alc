class FactmatterInCompanyLookup < ActiveRecord::Migration
  def self.up
    companies = Company.find(:all)
    execute "Update lookups set type='MatterFactType' where type='FactMatter'"
    matter_fact_types=Lookup.find_all_by_type('MatterFactType')

    companies.each do |company|
      matter_fact_types.each do |status|
        execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('#{status.type}','#{status.lvalue}',#{company.id},'#{status.lvalue}');"
      end
    end
    companies.each do |company|
      matter_fact_types.each do |stage|
        cmp_lookup=CompanyLookup.find_by_type_and_lvalue_and_company_id("#{stage.type}","#{stage.lvalue}","#{company.id}")
        factmatters = MatterFact.find(:all,:conditions => ["company_id = ? and status_id=?",company.id,stage.id])
        factmatters.each do |fact|
          execute "update matter_facts set status_id=#{cmp_lookup.id} where id=#{fact.id}"
        end
      end
    end
  end

  def self.down
    companies = Company.find(:all)
    companies.each do |company|
      matter_fact_types=CompanyLookup.find_all_by_type_and_company_id('MatterFactType',"#{company.id}")
      matter_fact_types.each do |stage|
        lookup=Lookup.find_by_type_and_lvalue("#{stage.type}","#{stage.lvalue}")
        factmatters = MatterFact.find(:all,:conditions => ["company_id = ? and status_id=?",company.id,stage.id])
        factmatters.each do |fact|
          execute "update matter_facts set status_id=#{lookup.id} where id=#{fact.id}"
        end
      end
    end
    companies.each do |company|
      execute "delete from company_lookups  where type = 'MatterFactType' and  company_id = #{company.id};"
    end
    execute "update lookups set type='FactMatter' where type='MatterFactType'"
  end
end
