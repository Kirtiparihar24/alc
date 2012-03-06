class AddIsCpaColumnToServiceProvidersTable < ActiveRecord::Migration
  def self.up
    add_column :service_providers, :is_cpa, :boolean
  end

  def self.down
    remove_column :service_providers, :is_cpa, :boolean
  end
end
