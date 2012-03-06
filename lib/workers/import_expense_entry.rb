class ImportExpenseEntry
  @queue = :import_expense_entry

  def self.perform(path_to_file, current_user, company, employee_user)
    ImportData::expense_entry_process_file(path_to_file, current_user, company, employee_user)
  end
end
