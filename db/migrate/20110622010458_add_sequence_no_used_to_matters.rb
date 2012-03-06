class AddSequenceNoUsedToMatters < ActiveRecord::Migration
  def self.up
    add_column :matters, :sequence_no_used, :integer
  end

  def self.down
    remove_column :matters, :sequence_no_used
  end
end
