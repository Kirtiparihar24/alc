class AddSalutationIdToMatterPeoples < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :salutation_id, :integer
  end

  def self.down
    remove_column :matter_peoples, :salutation_id
  end
end
