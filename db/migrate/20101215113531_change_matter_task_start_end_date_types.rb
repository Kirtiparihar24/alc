class ChangeMatterTaskStartEndDateTypes < ActiveRecord::Migration
  def self.up    
    execute "ALTER TABLE matter_tasks ALTER COLUMN start_date TYPE timestamp without time zone"
    execute "ALTER TABLE matter_tasks ALTER COLUMN end_date TYPE timestamp without time zone"
  end

  def self.down    
    execute "ALTER TABLE matter_tasks ALTER COLUMN start_date TYPE date"
    execute "ALTER TABLE matter_tasks ALTER COLUMN end_date TYPE date"
  end
end
