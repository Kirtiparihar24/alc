# Author Rohit
# Task to update first_email_sent for campaigns

desc "Task to update first_email_sent for campaigns"
task :update_first_email_sent_for_campaigns => :environment do
  Campaign.all.each do |campaign|
    campaign.members.each do |member|
      if member.first_mailed_date.present?
        campaign.update_attributes!(:first_email_sent => true)
        break
      end
    end
    campaign.update_attributes!(:first_email_sent => false) if campaign.first_email_sent == nil   
  end
end


