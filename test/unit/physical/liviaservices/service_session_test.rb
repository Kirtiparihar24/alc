require 'test_helper'

class Physical::Liviaservices::ServiceSessionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: service_sessions
#
#  id                    :integer         not null, primary key
#  provider_session_id   :integer         not null
#  service_assignment_id :integer
#  session_start         :datetime
#  session_end           :datetime
#  company_id            :integer         not null
#  deleted_at            :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  permanent_deleted_at  :datetime
#  employee_user_id      :integer
#

