require 'test_helper'

class SubproductAssignmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: subproduct_assignments
#
#  id                 :integer         not null, primary key
#  user_id            :integer         not null
#  subproduct_id      :integer         not null
#  employee_user_id   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  product_licence_id :integer         not null
#  company_id         :integer         not null
#  deleted_at         :datetime
#

