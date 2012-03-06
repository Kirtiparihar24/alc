require 'test_helper'

class Physical::Timeandexpenses::ExpenseEntryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: expense_entries
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer
#  created_by_user_id   :integer
#  expense_type         :integer
#  time_entry_id        :integer
#  description          :text            not null
#  expense_entry_date   :date            not null
#  billing_method_type  :integer
#  billing_percent      :decimal(14, 2)
#  expense_amount       :decimal(14, 2)  not null
#  final_expense_amount :decimal(16, 2)
#  contact_id           :integer
#  matter_id            :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  updated_by_user_id   :integer
#  status               :string(255)     default("Open")
#  matter_task_id       :integer
#  is_billable          :boolean         default(FALSE)
#  is_internal          :boolean         default(TRUE)
#  tne_invoice_id       :integer
#  markup               :integer
#  matter_people_id     :integer
#

