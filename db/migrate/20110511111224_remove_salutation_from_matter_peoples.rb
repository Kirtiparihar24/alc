class RemoveSalutationFromMatterPeoples < ActiveRecord::Migration
  def self.up
    remove_column :matter_peoples, :salutation
    remove_column :contacts, :salutation
  end

  def self.down
    add_column :matter_peoples, :salutation, :string
    add_column :contact, :salutation, :string
  end
end
