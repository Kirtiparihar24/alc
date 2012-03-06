namespace :associated_expense_entry_status_update do
  task :status_update => :environment do
    expense_entries=Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions=>['time_entry_id is not null'])
    expense_entries.each do |exp|
      puts exp.time_entry.status
      exp.update_attribute("status",exp.time_entry.status)
    end
  end
end