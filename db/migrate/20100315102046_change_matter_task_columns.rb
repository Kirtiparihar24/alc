class ChangeMatterTaskColumns < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :client_task_type, :string
    add_column :matter_tasks, :client_task_doc_name, :string
    add_column :matter_tasks, :client_task_doc_desc, :string
  end

  def self.down
    remove_column :matter_tasks, :client_task_type
    remove_column :matter_tasks, :client_task_doc_name
    remove_column :matter_tasks, :client_task_doc_desc
  end
end
