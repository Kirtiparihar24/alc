require 'test_helper'

class Physical::Timeandexpenses::TimeEntryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: time_entries
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer         not null
#  created_by_user_id   :integer
#  activity_type        :integer         not null
#  description          :text            not null
#  time_entry_date      :date            not null
#  start_time           :datetime
#  end_time             :datetime
#  actual_duration      :decimal(14, 2)  not null
#  billing_method_type  :integer
#  billing_percent      :decimal(14, 2)
#  activity_rate        :decimal(12, 2)
#  actual_activity_rate :decimal(14, 2)
#  final_billed_amount  :decimal(16, 2)
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
#  matter_people_id     :integer
#

