require 'test_helper'

class ProductLicenceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: product_licences
#
#  id                 :integer         not null, primary key
#  product_id         :integer         not null
#  company_id         :integer
#  licence_key        :string(255)     not null
#  licence_cost       :float           not null
#  start_at           :datetime        not null
#  end_at             :datetime
#  deleted_at         :datetime
#  created_by_user_id :integer
#  updated_by_user_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#  status             :integer         default(0)
#  licence_id         :integer         not null
#  licence_type       :integer         default(0), not null
#

