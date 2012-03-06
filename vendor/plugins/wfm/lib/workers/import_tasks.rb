class ImportTasks
  @queue = :import_tasks

  def self.perform(path_to_file, current_user)
    ImportData::task_entry_process_file(path_to_file, current_user)
  end
end