class AddColumnToCampaignMember < ActiveRecord::Migration
  def self.up
    add_column :campaign_members, :response_token, :string
  end

  def self.down
    remove_column :campaign_members, :response_token
  end
end
