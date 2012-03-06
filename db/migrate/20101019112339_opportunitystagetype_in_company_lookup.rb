class OpportunitystagetypeInCompanyLookup < ActiveRecord::Migration
  def self.up
    companies = Company.find(:all, :conditions => ["id != 1"])
    stage_types=Lookup.find_all_by_type('OpportunityStageType')
    companies.each do |company|
      stage_types.each do |stage|
        execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('#{stage.type}','#{stage.lvalue}',#{company.id},'#{stage.lvalue}');"
      end
    end
    companies.each do |company|
      stage_types.each do |stage|
        cmp_lookup=CompanyLookup.find_by_type_and_lvalue_and_company_id("#{stage.type}","#{stage.lvalue}","#{company.id}")
        @opportunities = Opportunity.find(:all,:conditions => ["company_id = ? and stage=?",company.id,stage.id])
        @opportunities.each do |opp|
          execute "update opportunities set stage=#{cmp_lookup.id} where id=#{opp.id}"
        end
      end
    end


  end

  def self.down
    companies = Company.find(:all, :conditions => ["id != 1"])
    stage_types=Lookup.find_all_by_type('OpportunityStageType')
    companies.each do |company|
      stage_types.each do |stage|
        lookup=Lookup.find_by_type_and_lvalue("#{stage.type},#{stage.lvalue}")
        opportunities = Opportunity.find(:all,:conditions => ["company_id = ? and stage=?",company.id,stage.id])
        opportunities.each do |opp|
          execute "update opportunities set stage=#{lookup.id} where id=#{opp.id}"
        end
      end
    end

    companies.each do |company|
      execute "delete from company_lookups  where type = 'OpportunityStageType' and  company_id = #{company.id};"
    end

  end
end
