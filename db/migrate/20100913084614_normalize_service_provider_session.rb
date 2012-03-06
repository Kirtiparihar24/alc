class NormalizeServiceProviderSession < ActiveRecord::Migration
  def self.up
    # remove unused column
    remove_column(:service_provider_sessions, :deleted)
  end

  def self.down
    # add removed column
    add_column(:service_provider_sessions, :deleted, :boolean ,:default => false) 
  end
end
