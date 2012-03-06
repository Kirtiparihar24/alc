
namespace :add_account_id_values do
  desc "Add account id values for blank account ids where contact_id is present and account associated with it"
  task :fill_account_ids => :environment do
    matters = Matter.find_by_sql('select * from matters where deleted_at is null and contact_id in (select contact_id from account_contacts )')
    matters.each do |matter|
      matter.update_attributes(:account_id=> matter.contact.accounts.map(&:id)[0])      
    end
  end
end