namespace :update_campaigns_status do
  task :name_type => :environment do
   CampaignMember.connection.execute("update campaign_members set campaign_member_status_type_id=(select id from lookups where type='CampaignMemberStatusType' and lvalue='New') where campaign_member_status_type_id is null")
  end
end