require 'test_helper'

class MatterFactTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_facts
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  details              :text
#  source               :string(255)
#  material             :integer
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  status_id            :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  doc_source_id        :integer
#

