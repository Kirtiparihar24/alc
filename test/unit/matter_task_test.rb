require 'test_helper'

class MatterTaskTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: matter_tasks
#
#  id                           :integer         not null, primary key
#  name                         :text
#  parent_id                    :integer
#  phase_id                     :integer
#  description                  :text
#  assigned_to_matter_people_id :integer
#  completed                    :boolean
#  completed_at                 :date
#  assoc_as                     :string(255)
#  matter_id                    :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  critical                     :boolean
#  client_task                  :boolean
#  company_id                   :integer         not null
#  deleted_at                   :datetime
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  category                     :string(255)
#  location                     :string(255)
#  priority                     :string(255)
#  progress                     :string(255)
#  progress_percentage          :string(255)
#  show_as                      :string(255)
#  mark_as                      :string(255)
#  all_day_event                :boolean
#  start_time                   :time
#  end_time                     :time
#  repeat                       :string(255)
#  reminder                     :string(255)
#  attendees_emails             :text
#  zimbra_task_id               :string(255)
#  zimbra_task_status           :boolean
#  lawyer_name                  :string(255)
#  lawyer_email                 :string(255)
#  client_task_type             :string(255)
#  client_task_doc_name         :string(255)
#  client_task_doc_desc         :string(255)
#  occurrence_type              :string(255)     default("count")
#  count                        :integer
#  until                        :date
#  exception_status             :boolean
#  exception_start_date         :date
#  exception_start_time         :time
#  task_id                      :integer
#  start_date                   :datetime
#  end_date                     :datetime
#  assigned_to_user_id          :integer
#  category_type_id             :integer
#

