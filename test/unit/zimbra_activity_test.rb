require 'test_helper'

class ZimbraActivityTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: zimbra_activities
#
#  id                     :integer         not null, primary key
#  name                   :string(255)
#  description            :text
#  category               :string(255)
#  zimbra_folder_location :integer
#  assigned_to_user_id    :integer
#  zimbra_task_id         :string(255)
#  zimbra_status          :boolean
#  reminder               :integer
#  repeat                 :string(255)
#  location               :text
#  attendees_emails       :text
#  response               :boolean
#  notification           :boolean
#  show_as                :string(255)
#  mark_as                :string(255)
#  start_date             :datetime
#  end_date               :datetime
#  all_day_event          :boolean
#  exception_status       :boolean
#  task_id                :integer
#  exception_start_date   :datetime
#  occurrence_type        :string(255)
#  count                  :integer
#  until                  :date
#  progress_percentage    :string(255)
#  progress               :string(255)
#  priority               :string(255)
#  deleted_at             :datetime
#  company_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  completed_at           :date
#  user_name              :string(255)
#

