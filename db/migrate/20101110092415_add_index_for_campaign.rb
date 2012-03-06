class AddIndexForCampaign < ActiveRecord::Migration
  def self.up
    add_index :campaigns, :campaign_status_type_id
    add_index :campaign_members, :campaign_id
    add_index :opportunities, :campaign_id
  end

  def self.down
    remove_index :campaigns
    remove_index :campaign_members
    remove_index :opportunities
  end
end
