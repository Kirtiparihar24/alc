require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: departments
#
#  id         :integer         not null, primary key
#  parent_id  :integer
#  name       :string(255)     not null
#  location   :string(255)
#  company_id :integer         not null
#  deleted_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

