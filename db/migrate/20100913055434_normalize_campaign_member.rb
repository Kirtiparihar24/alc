class NormalizeCampaignMember < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:campaign_members, :deleted)
    remove_column(:campaign_members, :owning_org_id)
    remove_column(:campaign_members, :pledged_amount)
  end

  def self.down
    # add removed columns
    add_column(:campaign_members, :deleted,:boolean, :default => false)    
    add_column(:campaign_members, :owning_org_id,:integer)
    add_column(:campaign_members, :pledged_amount,:decimal,:precision => 12,:scale => 2)

  end
end
