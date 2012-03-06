class NormalizeRoles < ActiveRecord::Migration
  def self.up
    # remove unused columns
    remove_column(:roles, :company_id)
    remove_column(:roles, :deleted_at)
  end

  def self.down
    # add removed columns
    add_column(:roles, :company_id, :integer) 
    add_column(:roles, :deleted_at, :timestamp) 
  end
end
