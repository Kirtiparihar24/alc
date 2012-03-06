require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: categories
#
#  id             :integer         not null, primary key
#  name           :string(255)
#  description    :text
#  created_at     :datetime
#  updated_at     :datetime
#  has_complexity :boolean         default(FALSE)
#

