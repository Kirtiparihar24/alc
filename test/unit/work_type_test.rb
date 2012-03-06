require 'test_helper'

class WorkTypeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: work_types
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  category_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#

