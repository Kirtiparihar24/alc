require 'test_helper'

class MatterPeopleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_peoples
#
#  id                   :integer         not null, primary key
#  employee_user_id     :integer
#  people_type          :string(255)
#  name                 :string(255)
#  email                :string(255)
#  address              :text
#  fax                  :string(255)
#  phone                :string(255)
#  is_active            :boolean
#  start_date           :date
#  end_date             :date
#  primary_contact      :boolean
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  matter_team_role_id  :integer
#  contact_id           :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  member_start_date    :date
#  member_end_date      :date
#  last_name            :string(32)
#  notes                :string(255)
#  city                 :string(64)
#  state                :string(64)
#  zip                  :string(16)
#  country              :string(64)
#  alternate_email      :string(64)
#  mobile               :string(16)
#  role_text            :string(64)
#  added_to_contact     :boolean
#  additional_priv      :integer
#  can_access_matter    :boolean
#  salutation_id        :integer
#  middle_name          :string(64)
#  allow_time_entry     :boolean         default(FALSE)
#

