class NormalizeCampaign < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:campaigns, :objectives)
    remove_column(:campaigns, :identifier)
  end

  def self.down
    # add removed columns
    add_column(:campaigns, :objectives, :text)
    add_column(:campaigns, :identifier, :string) 
  end
end
