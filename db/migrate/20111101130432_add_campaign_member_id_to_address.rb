class AddCampaignMemberIdToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :campaign_member_id, :integer
  end

  def self.down
    remove_column :addresses, :campaign_member_id
  end
end
