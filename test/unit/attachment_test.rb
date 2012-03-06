require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: attachments
#
#  id                :integer         not null, primary key
#  attachable_id     :integer
#  attachable_type   :string(255)
#  type              :string(255)
#  data_file_name    :string(255)
#  data_content_type :string(255)
#  data_file_size    :string(255)
#  data_name         :string(255)
#  data_description  :string(255)
#  deleted_at        :datetime
#  created_at        :datetime
#  updated_at        :datetime
#  active            :boolean         default(TRUE)
#

