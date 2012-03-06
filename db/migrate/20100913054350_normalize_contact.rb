class NormalizeContact < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:contacts, :access)
    rename_column(:contacts, :company_name, :organization)
  end

  def self.down
    # add removed columns
    add_column(:contacts, :access, :string,:default => 'Private')
    rename_column(:contacts, :organization, :company_name)
  end
end
