# Author Anil
# For Trimming names from all tables
desc "For Trimming names from all tables"
task :trim_names => :environment do
  Account.update_all("name = trim(name)")
  Contact.update_all("first_name = trim(first_name), last_name=trim(last_name)")
  Opportunity.update_all("name = trim(name)")
  Matter.update_all("name = trim(name)")
  Campaign.update_all("name = trim(name)")
end