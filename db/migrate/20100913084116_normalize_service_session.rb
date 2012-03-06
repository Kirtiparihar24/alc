class NormalizeServiceSession < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:service_sessions, :description)
    remove_column(:service_sessions, :type_of_service)
    remove_column(:service_sessions, :communication_status)
  end

  def self.down
    # add removed column
    add_column(:service_sessions, :description, :text)
    add_column(:service_sessions, :type_of_service, :integer)
    add_column(:service_sessions, :communication_status, :integer)
  end
end
