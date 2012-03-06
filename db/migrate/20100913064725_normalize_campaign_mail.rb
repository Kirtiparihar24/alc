class NormalizeCampaignMail < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:campaign_mails, :owning_org_id)
  end

  def self.down
    # add removed columns
    add_column(:campaign_mails, :owning_org_id, :integer)
  end
end
