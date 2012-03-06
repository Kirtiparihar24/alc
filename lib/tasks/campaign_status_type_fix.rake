# Author Anil
# For making campaign status type value consistent in database
desc "For making campaign status type value consistent in database"
task :campaign_status_type_fix => :environment do
  CompanyLookup.update_all("lvalue = 'Inprogress'","lvalue = 'In Progress' and type = 'CampaignStatusType'")
end