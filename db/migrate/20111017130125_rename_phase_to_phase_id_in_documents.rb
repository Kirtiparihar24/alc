class RenamePhaseToPhaseIdInDocuments < ActiveRecord::Migration
  def self.up
    rename_column :documents, :phase, :phase_id
  end

  def self.down
    rename_column :documents, :phase_id, :phase
  end
end
