namespace :accounts_website_phone_to_null  do
  desc "Set empty string to null for accounts: website and phone"
  task :set_empty_website_phone_to_null => :environment do
   #^(\s+)$ The Regular Expression
    accounts = Account.find(:all)
    accounts.each do |account|
      if !account.website.nil? && account.website.gsub(/\s+/,"").empty?
       account.update_attribute("website",nil)
      end
      if !account.phone.nil? && account.phone.gsub(/\s+/,"").empty?
         account.update_attribute("phone",nil)
      end
    end
  end
end

namespace :matters_id_to_null  do
  desc "Set empty string to null for matters: matter_no"
  task :set_empty_matter_id_to_null => :environment do
    matters = Matter.find(:all)
    matters.each do |matter|
      if !matter.matter_no.nil? && matter.matter_no.gsub(/\s+/,"").empty?
         matter.update_attribute("matter_no",nil)
      end
    end
  end
end