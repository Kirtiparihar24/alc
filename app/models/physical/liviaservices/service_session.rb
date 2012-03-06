class Physical::Liviaservices::ServiceSession < ActiveRecord::Base
  belongs_to :assignment , :class_name => "Physical::Liviaservices::ServiceProviderEmployeeMappings", :foreign_key => "service_assignment_id"
  belongs_to :sp_session , :class_name => "Physical::Liviaservices::ServiceProviderSession", :foreign_key => "provider_session_id" 
  belongs_to :user, :foreign_key =>'employee_user_id'
end

# == Schema Information
#
# Table name: service_sessions
#
#  id                    :integer         not null, primary key
#  provider_session_id   :integer         not null
#  service_assignment_id :integer
#  session_start         :datetime
#  session_end           :datetime
#  company_id            :integer         not null
#  deleted_at            :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  permanent_deleted_at  :datetime
#  employee_user_id      :integer
#

