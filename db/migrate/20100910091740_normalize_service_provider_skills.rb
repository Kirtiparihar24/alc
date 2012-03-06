class NormalizeServiceProviderSkills < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:service_provider_skills, :deleted)
  end

  def self.down
    # add removed columns
    add_column(:service_provider_skills, :deleted ,:boolean) 
  end
end
