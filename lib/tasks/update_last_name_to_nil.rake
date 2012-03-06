# For update last_name to nil where last_name=''
namespace :update_last_name_to_nil do
  task :update_last_name => :environment do
   last_name_update=Contact.find(:all,:conditions=>'length(last_name)=0')
    p"--------------------Contact Count Total Records to set nil----------------------#{last_name_update.size}"     
    p"------------------------Contact Last Name Updation Task Execution Begin-------------------------------------"
      last_name_update.each do |upd_last_name|	
          upd_last_name.last_name = nil
          upd_last_name.save(false)
       end
    p"------------------------Contact Last Name Updation Task Execution end-------------------------------------"
   
   camp_mem = CampaignMember.find(:all,:conditions => 'length(last_name)=0')

    p"------------------------Campaign Last_name Updation Task Execution Begin-------------------------------------"
      camp_mem.each do |upd_camp_mem|
	      upd_camp_mem.last_name = nil
	      upd_camp_mem.save(false)

       end
  p"------------------------Campaign Last_name Updation Task Execution end-------------------------------------"
  end

end
