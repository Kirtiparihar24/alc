require 'test_helper'

class CompanyActivityRateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: company_activity_rates
#
#  id                   :integer         not null, primary key
#  activity_type_id     :integer
#  billing_rate         :decimal(10, 2)
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

