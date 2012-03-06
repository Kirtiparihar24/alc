class AddedColumnReportsToInContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :reports_to, :string
  end

  def self.down
#    remove_column :contacts, :reports_to
  end
end
