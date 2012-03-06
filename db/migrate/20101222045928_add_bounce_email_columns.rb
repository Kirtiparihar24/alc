class AddBounceEmailColumns < ActiveRecord::Migration
  def self.up
    add_column(:campaign_members, :bounce_code, :string)
    add_column(:campaign_members, :bounce_reason, :text,:size=>800)
  end

  def self.down
    remove_column(:campaign_members, :bounce_code)
    remove_column(:campaign_members, :bounce_reason)
  end
end
