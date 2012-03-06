require 'test_helper'

class MatterResearchTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_researches
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  research_type        :integer
#  citation             :string(255)
#  description          :text
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  is_internal          :boolean
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

