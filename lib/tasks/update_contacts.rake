namespace :contacts do
  task :update_assigned_to_employee_user_id=> :environment do
    @contact = Contact.find_all_by_company_id_and_assigned_to_employee_user_id_and_created_by_user_id(103,564,565)
    @contact.each do |contact|
     contact.update_attribute('assigned_to_employee_user_id', 565)
    end
   end
end
