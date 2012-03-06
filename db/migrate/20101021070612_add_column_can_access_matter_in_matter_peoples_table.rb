class AddColumnCanAccessMatterInMatterPeoplesTable < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :can_access_matter, :boolean
  end

  def self.down
    remove_column :matter_peoples, :can_access_matter
  end
end
