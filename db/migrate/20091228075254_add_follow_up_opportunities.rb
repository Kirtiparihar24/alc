class AddFollowUpOpportunities < ActiveRecord::Migration
  def self.up
     add_column :opportunities, :follow_up, :datetime
  end

  def self.down
    remove_column :opportunities, :follow_up
  end
end
