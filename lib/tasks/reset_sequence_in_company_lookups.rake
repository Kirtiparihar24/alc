# Feature 6323 :: added to update the sequence column in company_lookups
# can not directly add company_lookups as throws
# rake aborted!
# The single-table inheritance mechanism failed to locate the subclass: 'ClientStatusType'. This error is raised because the column 'type' is reserved for storing the class in case of inheritance. Please rename this column if you didn't intend it to be used for storing the inheritance class or overwrite CompanyLookup.inheritance_column to use another column for that information.
# So added types for which sequence needs to be updated in the array created.
# It make a constant and in loop if the record is blank or 0 it will append the index.
# This will not affect on sorting as this can me modified in the admin view.
#- Supriya Surve : 06/05/2011
namespace :company_type do
  task :reset_sequence => :environment do
    companies = Company.all
    arr = ["ContactStage", "LeadStatusType", "ProspectStatusType", "MatterPrivilege",
      "OpportunityStageType", "CompanySource", "Phase", "TypesLiti", "TypesNonLiti",
      "DocSource", "DocumentCategory", "Physical::Timeandexpenses::ActivityType",
      "Physical::Timeandexpenses::ExpenseType", "ResearchType", "CampaignMemberStatusType",
      "CampaignStatusType", "DocumentType", "ClientRole", "TeamRole", "MatterStatus",
      "MatterFactType", "OtherRole", "ClientRepRole", "RatingType",
      "Designation", "ResearchType", "ContactPhoneType", "DocumentSubCategory", "TneInvoiceStatus"]
      
    companies.each do |company|
      arr.each do |model_type|
        class_object = model_type.camelize.constantize
        model_object = class_object.find(:all, :conditions => ["company_id = #{company.id}"])
        if model_object.length > 0
          model_object.each_with_index do |obj_item, index|
            if obj_item.sequence.blank? || obj_item.sequence==0
              class_object.update_all({:sequence => index+1}, {:id => obj_item.id, :company_id => company.id})
            end
          end
        end
      end
    end

  end
end