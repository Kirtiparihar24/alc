require 'test_helper'

class LicenceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: licences
#
#  id            :integer         not null, primary key
#  company_id    :integer         not null
#  product_id    :integer         not null
#  licence_count :integer         not null
#  cost          :integer         not null
#  start_date    :datetime        not null
#  expired_date  :datetime
#  created_at    :datetime
#  updated_at    :datetime
#

