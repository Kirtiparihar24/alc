namespace :contact_phone do
  task :for_test => :environment do
    phne = ContactPhoneType.find_all_by_lvalue("Phone")
    phne.collect{|p| p.update_attribute('lvalue','Home')}
  end
end