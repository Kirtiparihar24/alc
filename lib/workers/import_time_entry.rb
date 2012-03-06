class ImportTimeEntry
  @queue = :import_time_entry

  def self.perform(path_to_file, current_user, company, employee_user)
    ImportData::time_entry_process_excel_file(path_to_file, current_user, company, employee_user)
  end
end
