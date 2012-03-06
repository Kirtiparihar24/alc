class RenameColumnPhaseToPhaseIdInMatterTasks < ActiveRecord::Migration
  def self.up
    rename_column :matter_tasks, :phase, :phase_id
  end

  def self.down
    rename_column :matter_tasks, :phase_id, :phase
  end
end
