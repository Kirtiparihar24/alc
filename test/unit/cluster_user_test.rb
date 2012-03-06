require 'test_helper'

class ClusterUserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: cluster_users
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  cluster_id :integer
#  created_at :datetime
#  updated_at :datetime
#  from_date  :datetime
#  to_date    :datetime
#

