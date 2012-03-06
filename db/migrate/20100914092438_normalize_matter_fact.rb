class NormalizeMatterFact < ActiveRecord::Migration
  def self.up
    # rename status to status_id
    rename_column(:matter_facts, :status, :status_id)    
  end

  def self.down
    rename_column(:matter_facts, :status_id, :status)    
  end
end
