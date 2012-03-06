class AddSalutationToCampaignMember < ActiveRecord::Migration
  def self.up
    add_column :campaign_members, :salutation_id, :integer
  end

  def self.down
    remove_column :campaign_members, :salutation_id
  end
end
