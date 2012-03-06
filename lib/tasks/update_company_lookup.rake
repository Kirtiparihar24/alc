namespace :companylookup do
  task :update_alvalue => :environment do
    @company_lookup = CompanyLookup.all
    @company_lookup.each do |company_lookup|
      if company_lookup.alvalue == "" || company_lookup.alvalue.nil?
        company_lookup.alvalue = company_lookup.lvalue
      end
    end
  end
end