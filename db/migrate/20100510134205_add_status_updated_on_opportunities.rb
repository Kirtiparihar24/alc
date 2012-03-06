class AddStatusUpdatedOnOpportunities < ActiveRecord::Migration
  def self.up
    add_column :opportunities,:status_updated_on, :timestamp
  end

  def self.down
  end
end
