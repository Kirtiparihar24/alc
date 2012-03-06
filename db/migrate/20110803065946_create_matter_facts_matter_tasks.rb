class CreateMatterFactsMatterTasks < ActiveRecord::Migration
  def self.up
    create_table :matter_facts_matter_tasks, :id => false do |t|
      t.integer :matter_fact_id
      t.integer :matter_task_id
    end
  end

  def self.down
    drop_table :matter_facts_matter_tasks
  end
end
