require 'test_helper'

class MatterRiskTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_risks
#
#  id                   :integer         not null, primary key
#  name                 :text
#  details              :text
#  is_material          :boolean
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

