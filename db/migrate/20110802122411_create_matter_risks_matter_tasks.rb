class CreateMatterRisksMatterTasks < ActiveRecord::Migration
  def self.up
    create_table :matter_risks_matter_tasks, :id => false do |t|
      t.integer :matter_risk_id
      t.integer :matter_task_id
    end
  end

  def self.down
    drop_table :matter_risks_matter_tasks
  end
end
