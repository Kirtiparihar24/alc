class AddColumnProviderTypeToServiceProvider < ActiveRecord::Migration
  def self.up
    add_column :service_providers, :provider_type, :integer
  end

  def self.down
    remove_column :service_providers, :provider_type
  end
end
