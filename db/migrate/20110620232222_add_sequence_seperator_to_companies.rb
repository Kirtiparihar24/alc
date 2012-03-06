class AddSequenceSeperatorToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :sequence_seperator, :string,:limit=>5
  end

  def self.down
    remove_column :companies, :sequence_seperator
  end
end
