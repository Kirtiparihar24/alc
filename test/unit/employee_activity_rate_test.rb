require 'test_helper'

class EmployeeActivityRateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: employee_activity_rates
#
#  id                   :integer         not null, primary key
#  employee_user_id     :integer
#  activity_type_id     :integer
#  billing_rate         :decimal(, )
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

