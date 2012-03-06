# Author Anil
# or Setting up final billed amout to 0 for internal time and expense entries
desc "For Setting up final billed amout to 0 for internal time and expense entries"
task :set_final_billed_amount => :environment do
  Physical::Timeandexpenses::TimeEntry.find(:all).each do|te|
    if te.is_internal
      te.is_billable = false
      te.final_billed_amount = 0.00
      te.save(false)
    end
  end
  Physical::Timeandexpenses::ExpenseEntry.find(:all).each do|ee|
    if ee.is_internal
      ee.is_billable = false
      ee.final_expense_amount = 0.00
      ee.save(false)
    end
  end
end