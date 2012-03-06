class AddMiddleNameToCampaignMember < ActiveRecord::Migration
  def self.up
    add_column :campaign_members, :middle_name, :string,:limit=>255
  end

  def self.down
    remove_column :campaign_members, :middle_name
  end
end
