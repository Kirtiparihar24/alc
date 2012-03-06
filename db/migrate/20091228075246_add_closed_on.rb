class AddClosedOn < ActiveRecord::Migration
  def self.up
    add_column :opportunities, :closed_on, :datetime
    add_column :matters, :closed_on, :datetime
    add_column :service_providers, :created_by_user_id, :integer
  end

  def self.down
    remove_column :opportunities, :closed_on
    remove_column :matters, :closed_on
    remove_column :service_providers, :created_by_user_id
  end
end
