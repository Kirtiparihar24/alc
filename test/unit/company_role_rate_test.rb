require 'test_helper'

class CompanyRoleRateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: company_role_rates
#
#  id                   :integer         not null, primary key
#  role_id              :integer
#  billing_rate         :decimal(10, 2)
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

