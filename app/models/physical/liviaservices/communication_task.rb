class Physical::Liviaservices::CommunicationTask < ActiveRecord::Base
end

# == Schema Information
#
# Table name: communication_tasks
#
#  id                           :integer         primary key
#  priority                     :string(32)
#  company_id                   :integer
#  assigned_by_employee_user_id :integer
#  notes_creation               :datetime
#  tasktype                     :integer
#  assigned_to_user_id          :integer
#  status                       :string(255)
#  name                         :text
#  created_at                   :datetime
#

