class AddColumnEmployeeMyContacts < ActiveRecord::Migration
  def self.up
    add_column(:employees, :my_contacts, :boolean,:default=>false)
    add_column(:employees, :my_campaign, :boolean,:default=>false)
    add_column(:employees, :my_opportunities, :boolean,:default=>false)
  end

  def self.down
    remove_column(:employees, :my_contacts)
    remove_column(:employees, :my_campaign)
    remove_column(:employees, :my_opportunities)
  end
end
