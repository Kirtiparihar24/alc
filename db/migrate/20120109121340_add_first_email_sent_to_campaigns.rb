class AddFirstEmailSentToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :first_email_sent, :boolean, :default => false
  end

  def self.down
    remove_column :campaigns, :first_email_sent
  end
end
