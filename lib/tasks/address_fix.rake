# Author Surekha
# For address related fixes.
namespace :address_fix do
  task :set_company_id => :environment do
    # Clean up the old entries which have wrong company_id.
    addresses=Address.all
    addresses.each do |address|
      address.update_attribute(:company_id,address.account.company_id) if address.account
      address.update_attribute(:company_id,address.contact.company_id) if address.contact
    end
  end
end
