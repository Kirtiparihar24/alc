require 'test_helper'

class UserSettingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: user_settings
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  setting_type  :string(255)
#  setting_value :string(255)
#  company_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  ref_id        :integer
#

