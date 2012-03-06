# Author Mandeep
# Task to create access control entries for old ToE documents for all the matters.

namespace :update_opportunity_stage do
  task :opportunity_stage => :environment do    
    Opportunity.find_by_sql("select * from opportunities where source is not null").each do |opp|
      #p opp.source
      lookups = Lookup.find_by_id(opp.source.to_i)
        #p lookups.lvalue unless lookups.nil?
        p "----- Updating for Opportunity Id - #{opp.id}"
        unless lookups.nil?
          complookup = CompanySource.find_by_lvalue_and_company_id(lookups.lvalue, opp.company_id)
          p "Previous id/source/lvalue--#{lookups.id}/#{opp.source}/#{lookups.lvalue}, Current id/lvaue--#{complookup.id}/#{complookup.lvalue}"
          opp.update_attribute('source',complookup.id)
        else
          comp = CompanySource.find_by_id(opp.source.to_i)
          complookup = CompanySource.find_by_lvalue_and_company_id(comp.lvalue, opp.company_id)
          p "Previous id/source --#{comp.id}/#{opp.source}, Current id/lvaue--#{complookup.id}/#{complookup.lvalue}"
          opp.update_attribute('source', complookup.id)
        end
    end
  end
end

