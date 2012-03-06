namespace :campaign_member_status_type_create do
  task :create_status_type => :environment do
    companies=Company.all
    companies.each do |company|
    CampaignMemberStatusType.find_or_create_by_lvalue_and_alvalue_and_company_id('Inbox Full','Out of Office',company.id)
    CampaignMemberStatusType.find_or_create_by_lvalue_and_alvalue_and_company_id('Out of Office','Out of Office',company.id)
    end
  end
end