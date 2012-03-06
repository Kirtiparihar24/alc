# Feature 6323 :: sequence column for enabling company-wise ordering of company_lookups data- Supriya Surve : 06/05/2011
class AddSequenceToCompanyLookups < ActiveRecord::Migration
  def self.up
    add_column :company_lookups, :sequence, :integer, :default => 0    
  end

  def self.down
    remove_column :company_lookups, :sequence
  end
end
