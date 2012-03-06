require 'test_helper'

class WorkSubtypeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: work_subtypes
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  description  :text
#  work_type_id :integer
#  created_at   :datetime
#  updated_at   :datetime
#

