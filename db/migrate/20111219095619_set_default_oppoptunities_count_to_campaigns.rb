class SetDefaultOppoptunitiesCountToCampaigns < ActiveRecord::Migration
  def self.up
   change_column :campaigns, :opportunities_count, :integer ,:default => 0
  end

  def self.down
  # You can't currently remove default values in Rails
     
  end
end
