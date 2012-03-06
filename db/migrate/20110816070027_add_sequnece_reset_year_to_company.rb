class AddSequneceResetYearToCompany < ActiveRecord::Migration
  def self.up
    add_column :companies, :sequence_reset_year, :integer
  end

  def self.down
    remove_column :companies, :sequence_reset_year
  end
end
