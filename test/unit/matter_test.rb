require 'test_helper'

class MatterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matters
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  brief                :text
#  is_internal          :boolean
#  contact_id           :integer
#  matter_no            :string(255)
#  ref_no               :string(255)
#  description          :text
#  matter_category      :string(255)
#  matter_type_id       :integer
#  employee_user_id     :integer
#  conflict_checked     :boolean
#  created_at           :datetime
#  updated_at           :datetime
#  estimated_hours      :integer
#  opportunity_id       :integer
#  delta                :boolean         default(TRUE), not null
#  phase_id             :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  closed_on            :datetime
#  retainer_fee         :integer
#  min_retainer_fee     :integer
#  matter_date          :date
#  client_access        :boolean         default(FALSE)
#  status_id            :integer
#  sequence_no_used     :integer
#

