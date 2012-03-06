class ModifyCommunicationTasksViewAndChangeDatatypeOfNameInTasks < ActiveRecord::Migration
  def self.up
    execute "DROP VIEW communication_tasks;"
    change_table :tasks do |t|
      t.change :name, :text
    end
    execute "CREATE OR REPLACE VIEW communication_tasks AS
             SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.work_subtype_id as tasktype, t.assigned_to_user_id, t.status, t.name, t.created_at
             FROM tasks t, notes c
             WHERE t.note_id = c.id
             ORDER BY c.created_at, t.priority DESC;"
    role = Role.find_by_name('secretary')
    role.update_attributes(:for_wfm=>true) if role
  end

  def self.down
    execute "DROP VIEW communication_tasks;"
    change_table :tasks do |t|
      t.change :name, :string,:default => "", :null => false
    end
    execute "CREATE OR REPLACE VIEW communication_tasks AS
             SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.tasktype, t.assigned_to_user_id, t.status, t.name, t.created_at
             FROM tasks t, notes c
             WHERE t.note_id = c.id
             ORDER BY c.created_at, t.priority DESC;"
    role = Role.find_by_name('secretary')
    role.update_attributes(:for_wfm=>nil) if role
  end
end
