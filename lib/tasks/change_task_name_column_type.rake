namespace :change_column_type do 
  task :name_type => :environment do
    UserTask.connection.execute("DROP VIEW communication_tasks")
    UserTask.connection.execute("ALTER TABLE tasks ALTER COLUMN name TYPE text")
    UserTask.connection.execute("ALTER TABLE tasks ALTER COLUMN name DROP DEFAULT")
    UserTask.connection.execute("CREATE OR REPLACE VIEW communication_tasks AS
      SELECT t.id, t.priority, t.company_id, c.assigned_by_employee_user_id, c.created_at AS notes_creation, t.task_of_type, t.assigned_to_user_id, t.status, t.name, t.created_at
      FROM tasks t, notes c
      WHERE t.asset_type = 'Communication'::text AND t.asset_id = c.id
      ORDER BY c.created_at, t.priority DESC;
ALTER TABLE communication_tasks OWNER TO livia")

  end
end