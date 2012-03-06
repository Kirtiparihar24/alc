class AddSequenceNoToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :sequence_no, :integer
  end

  def self.down
    remove_column :companies, :sequence_no
  end
end
