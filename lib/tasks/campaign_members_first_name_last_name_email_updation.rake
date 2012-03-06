# For Campaign members first_name,last_name and email updation
namespace :campaign_members_first_name_last_name_email_updation do
  task :update_campaign_mumbers => :environment do
    camp_mem = CampaignMember.find(:all,:conditions => 'contact_id is not null',:order => "contact_id")
    p"------------------------Task Execution Begin-------------------------------------"
      camp_mem.each do |upd_camp_mem|
	      upd_camp_mem.first_name = Contact.find(upd_camp_mem.contact_id).first_name
	      upd_camp_mem.last_name = Contact.find(upd_camp_mem.contact_id).last_name
	      upd_camp_mem.email = Contact.find(upd_camp_mem.contact_id).email
	      upd_camp_mem.save     

       end
  p"------------------------Task Execution end-------------------------------------"
  end

end
