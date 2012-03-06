class AddAltEmailToCampaignMembers < ActiveRecord::Migration
  def self.up
    add_column :campaign_members, :alt_email, :string
  end

  def self.down
    remove_column :campaign_members, :alt_email
  end
end
