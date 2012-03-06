# Feature 6464 : Creator v/s Owner for document creation
# owner_user_id column added to document_homes folder
# run rake db_migrate:up VERSION=20110526064456 before this rake file.
# Supriya Surve : 26th May 2011, 13:44
namespace :update_owner do
  task :for_document_homes => :environment do
  document_homes = DocumentHome.find_with_deleted(:all, :conditions => ["owner_user_id is null"])
  start_time = Time.now
    document_homes.each_with_index do |document_home, inx|
      if document_home.owner_user_id.blank?
        if document_home.created_by_user_id.blank?
          if document_home.folder_id.present?
            if document_home.folder.employee_user_id.present?
              usrid = document_home.folder.employee_user_id
              ActiveRecord::Base.connection.execute("update document_homes set
              employee_user_id=#{usrid},
              owner_user_id = #{usrid},
              created_by_user_id= #{usrid}
              where id =#{document_home.id}")
              #document_home.update_attributes(:employee_user_id => usrid, :owner_user_id => usrid, :created_by_user_id => usrid)
            end
          else
            if document_home.employee_user_id.present?
              usrid = document_home.employee_user_id
              ActiveRecord::Base.connection.execute("update document_homes set
              employee_user_id=#{usrid},
              owner_user_id = #{usrid},
              created_by_user_id= #{usrid}
              where id =#{document_home.id}")
              #document_home.update_attributes(:employee_user_id => usrid, :owner_user_id => usrid, :created_by_user_id => usrid)
            end
          end
        elsif document_home.employee_user_id.blank?
          ActiveRecord::Base.connection.execute("update document_homes set
              employee_user_id=#{document_home.created_by_user_id},
              owner_user_id = #{document_home.created_by_user_id}
              where id =#{document_home.id}")
           #document_home.update_attributes(:employee_user_id => document_home.created_by_user_id, :owner_user_id => document_home.created_by_user_id)
        else
          ActiveRecord::Base.connection.execute("update document_homes set
              owner_user_id = #{document_home.employee_user_id}
              where id =#{document_home.id}")
          #document_home.update_attribute(:owner_user_id, document_home.employee_user_id)
        end
        puts "#{inx}"
      end
    end
    end_time = Time.now
    puts "Time Take #{end_time - start_time}"
  end

  task :document_home_for_matter_people_ids => :environment do
    matters = Matter.all
    matters.each do |matter|
      document_homes = matter.document_homes
      document_homes.each do |document_home|
          matterpeoples = document_home.matter_peoples.collect{|person| person.id}
          if(matterpeoples.length==0)
            matter.matter_peoples.each do |person|
                if(person.employee_user_id==document_home.owner_user_id)
                  document_home.matter_peoples << person
                  document_home.save                  
                end
            end
          end
          matter.matter_peoples.each do |person|
            if matter.employee_user_id==person.employee_user_id              
              unless matterpeoples.include?(person.id) && document_home.access_rights==4
                document_home.matter_peoples << person
                document_home.save
              end
            end            
          end          
      end
    end
  end
end