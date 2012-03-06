namespace :delete_matter_people do
  task :of_deleted_contacts => :environment do
    matters = Matter.all
    matters.each do |matter|
        matter_peoples = matter.matter_peoples.all
        matter_peoples.each do |matter_people|
          unless matter_people.contact_id.blank?            
            unless matter_people.contact.present?
              contact = Contact.find_by_sql("select * from contacts where id = #{matter_people.contact_id}")              
              if contact.blank?
               matter_people.destroy!
              end
            end
          end
        end
    end
  end
end