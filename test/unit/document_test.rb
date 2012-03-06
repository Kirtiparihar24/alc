require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: documents
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  phase                :string(255)
#  bookmark             :boolean
#  description          :text
#  author               :string(255)
#  source               :string(255)
#  privilege            :string(255)
#  data_file_name       :string(255)
#  data_content_type    :string(255)
#  data_file_size       :integer
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer
#  document_home_id     :integer
#  delta                :boolean         default(TRUE), not null
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  category_id          :integer
#  sub_category_id      :integer
#  doc_source_id        :integer
#  doc_type_id          :integer
#

