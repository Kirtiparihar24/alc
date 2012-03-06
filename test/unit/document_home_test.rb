require 'test_helper'

class DocumentHomeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: document_homes
#
#  id                             :integer         not null, primary key
#  mapable_type                   :string(255)
#  mapable_id                     :integer
#  access_rights                  :integer
#  latest                         :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  sub_type                       :string(255)
#  sub_type_id                    :integer
#  upload_stage                   :integer
#  converted_by_user_id           :integer
#  delta                          :boolean         default(TRUE), not null
#  company_id                     :integer         not null
#  deleted_at                     :datetime
#  permanent_deleted_at           :datetime
#  created_by_user_id             :integer
#  updated_by_user_id             :integer
#  folder_id                      :integer
#  parent_id                      :integer
#  checked_in_by_employee_user_id :integer
#  checked_in_at                  :datetime
#  repo_update                    :boolean
#  enforce_version_change         :boolean
#  wip_doc                        :integer
#  employee_user_id               :integer
#  owner_user_id                  :integer
#

