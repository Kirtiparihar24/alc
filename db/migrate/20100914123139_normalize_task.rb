class NormalizeTask < ActiveRecord::Migration
  def self.up
    # rename column
    
    rename_column(:tasks, :asset_id, :note_id) if Task.column_names.to_a.include?('asset_id')
    rename_column(:tasks, :task_of_type, :tasktype) if Task.column_names.to_a.include?('task_of_type')
    if Task.column_names.to_a.include?('asset_type')
      execute "DROP VIEW communication_tasks;"
      remove_column(:tasks, :asset_type) 
    end
    
    # replace existing view with new defination
    execute "CREATE OR REPLACE VIEW communication_tasks AS 
            SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.tasktype, t.assigned_to_user_id, t.status, t.name, t.created_at
            FROM tasks t, notes c
            WHERE t.note_id = c.id
            ORDER BY c.created_at, t.priority DESC;"
    
  end

  def self.down
    # add removed column
    add_column(:tasks, :asset_type, :string)  unless Task.column_names.to_a.include?('asset_type')
    
    rename_column(:tasks, :note_id, :asset_id) if Task.column_names.to_a.include?('note_id')
    rename_column(:tasks, :tasktype, :task_of_type) if Task.column_names.to_a.include?('tasktype')
    
    # recreate old view
    execute "CREATE OR REPLACE VIEW communication_tasks AS 
            SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.task_of_type, t.assigned_to_user_id, t.status, t.name, t.created_at
            FROM tasks t, notes c
            WHERE t.asset_type = 'Communication' AND t.asset_id = c.id
            ORDER BY c.created_at, t.priority DESC;"

  end
end
