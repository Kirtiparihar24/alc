class NormalizeAccount < ActiveRecord::Migration
  def self.up
    # remove unused column
    remove_column(:accounts, :dotted_ids)
  end

  def self.down
    # add removed column
    add_column(:accounts, :dotted_ids, :integer) 
  end
end
