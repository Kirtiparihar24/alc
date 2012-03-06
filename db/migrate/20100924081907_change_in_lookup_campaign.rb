class ChangeInLookupCampaign < ActiveRecord::Migration
  def self.up
    execute "UPDATE lookups SET type = 'CampaignStatusType' where type in ('Physical::Crm::Campaign::CampaignStatusType')"
    execute "UPDATE lookups SET type = 'CampaignMemberStatusType' where type in ('Physical::Crm::Campaign::CampaignMemberStatusType')"
  end

  def self.down
    execute "UPDATE lookups SET type = 'Physical::Crm::Campaign::CampaignStatusType' where type in ('CampaignStatusType')"
    execute "UPDATE lookups SET type = 'Physical::Crm::Campaign::CampaignMemberStatusType' where type in ('CampaignMemberStatusType')"
  end
end
