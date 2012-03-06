class NormalizeBdrbJobQueue < ActiveRecord::Migration
  def self.up
    # remove table bdrb_job_queues becouse now it is not used
    drop_table :bdrb_job_queues
  end

  def self.down
    # recreate deleted table
    create_table :bdrb_job_queues do |t|
      t.text :args
      t.string :worker_name
      t.string :worker_method
      t.string :job_key
      t.integer :taken
      t.integer :finished
      t.integer :timeout
      t.integer :priority
      t.timestamp :submitted_at
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamp :archived_at
      t.string :tag
      t.string :submitter_info
      t.string :runner_info
      t.string :worker_key
      t.timestamp :scheduled_at
    end        
  end
end
