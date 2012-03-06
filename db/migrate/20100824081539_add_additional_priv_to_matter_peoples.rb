class AddAdditionalPrivToMatterPeoples < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :additional_priv, :integer
  end

  def self.down
    remove_column :matter_peoples, :additional_priv
  end
end
