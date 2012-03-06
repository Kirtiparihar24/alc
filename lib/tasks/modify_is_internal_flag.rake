namespace :set_is_internal do

  desc "Change the wrong time entries"
  task :change_time_entries_is_internal => :environment do
    time_entries = Physical::Timeandexpenses::TimeEntry.find(:all,:conditions => ["(is_internal = true and (contact_id is not null or matter_id is not null or matter_people_id is not null))"])
    time_entries.each do |time_entry|
      time_entry.update_attribute(:is_internal,false)
    end
  end

  desc "Change the wrong expense entries"
  task :change_expense_entries_is_internal => :environment do
    expense_entries = Physical::Timeandexpenses::ExpenseEntry.find(:all,:conditions => ["(is_internal = true and (contact_id is not null or matter_id is not null or matter_people_id is not null))"])
    expense_entries.each do |expense_entry|
      expense_entry.update_attribute(:is_internal,false)
    end
  end

end