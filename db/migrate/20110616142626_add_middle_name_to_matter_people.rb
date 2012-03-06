class AddMiddleNameToMatterPeople < ActiveRecord::Migration
  def self.up
    add_column :matter_peoples, :middle_name, :string,:limit=>64
  end

  def self.down
    remove_column :matter_peoples, :middle_name
  end
end
