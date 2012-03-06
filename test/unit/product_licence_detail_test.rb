require 'test_helper'

class ProductLicenceDetailTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: product_licence_details
#
#  id                 :integer         not null, primary key
#  product_licence_id :integer         not null
#  start_date         :datetime        not null
#  expired_date       :datetime
#  status             :integer
#  created_at         :datetime
#  updated_at         :datetime
#  user_id            :integer         not null
#  deleted_at         :datetime
#

