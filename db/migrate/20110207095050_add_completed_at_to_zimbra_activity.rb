class AddCompletedAtToZimbraActivity < ActiveRecord::Migration
  def self.up
    add_column :zimbra_activities, :completed_at, :date
    add_column :zimbra_activities, :user_name, :string
  end

  def self.down
    remove_column :zimbra_activities, :completed_at
    remove_column :zimbra_activities, :user_name
  end
end
