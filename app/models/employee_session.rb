class EmployeeSession < ActiveRecord::Base
   belongs_to :employee, :class_name => "Employee"
end

# == Schema Information
#
# Table name: employee_sessions
#
#  id                   :integer         not null, primary key
#  created_at           :datetime        not null
#  updated_at           :datetime
#  deleted              :boolean         default(FALSE)
#  company_id           :integer
#  employee_id          :integer
#  session_start        :datetime
#  session_end          :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

