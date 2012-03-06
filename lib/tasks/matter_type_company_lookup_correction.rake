namespace :matter_type do
  task :update => :environment do
    companies = Company.all
    first_company_lookup = []
    companies.each do |company|
      nonliti_types = company.nonliti_types
      liti_types = company.liti_types
      liti_types_id = liti_types.collect{|lt| lt.id}
      nonliti_types_id = nonliti_types.collect{|lt| lt.id}      
      if company.id == 1
        first_company_lookup << nonliti_types_id
        first_company_lookup << liti_types_id
        first_company_lookup = first_company_lookup.flatten
      end
      matters = company.matters
      matters.each do |matter|
        matter_type = matter.matter_type_id
        new_type_id = nil
        unless matter_type.blank?
          if matter.matter_category.eql?("litigation")
            unless liti_types_id.include?(matter_type)
              matter_lvalue = CompanyLookup.find(matter_type).lvalue
              new_type_id = liti_types.find_by_lvalue(matter_lvalue).try(:id)
            end
          elsif matter.matter_category.eql?("non-litigation")
            unless nonliti_types_id.include?(matter_type)
              matter_lvalue = CompanyLookup.find(matter_type).lvalue
              new_type_id = nonliti_types.find_by_lvalue(matter_lvalue).try(:id)
            end
          end
          unless new_type_id.nil?
            matter.update_attribute('matter_type_id', new_type_id)
          else
            if first_company_lookup and (matter.company_id!=1)
              if first_company_lookup.include?(matter_type)
                matter.update_attribute('matter_type_id', nil)
              end
            end
          end
        end
      end
    end
  end
end