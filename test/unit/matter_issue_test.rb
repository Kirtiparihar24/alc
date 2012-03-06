require 'test_helper'

class MatterIssueTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_issues
#
#  id                           :integer         not null, primary key
#  name                         :text
#  parent_id                    :integer
#  is_primary                   :boolean
#  is_key_issue                 :boolean
#  description                  :text
#  target_resolution_date       :date
#  assigned_to_matter_people_id :integer
#  matter_id                    :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  resolved                     :boolean
#  resolution                   :text
#  active                       :boolean
#  client_issue                 :boolean
#  resolved_at                  :date
#  company_id                   :integer         not null
#  deleted_at                   :datetime
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#

