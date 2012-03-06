require 'test_helper'

class AssetTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: assets
#
#  id                   :integer         not null, primary key
#  data_file_name       :string(255)
#  data_content_type    :string(255)
#  data_file_size       :integer
#  created_at           :datetime
#  updated_at           :datetime
#  attachable_id        :integer
#  attachable_type      :string(255)
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

