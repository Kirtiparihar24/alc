class EmployeeActivityRate < ActiveRecord::Base
 validates_uniqueness_of :activity_type_id, :scope => :employee_user_id
 validates_presence_of :billing_rate, :employee_user_id, :activity_type_id
 validates_numericality_of :billing_rate, :greater_than => 0,:less_than=>10000, :message => "should be greater than 0 and less than 10000"
 belongs_to :company_activity_type ,:foreign_key => :activity_type_id
end

# == Schema Information
#
# Table name: employee_activity_rates
#
#  id                   :integer         not null, primary key
#  employee_user_id     :integer
#  activity_type_id     :integer
#  billing_rate         :decimal(, )
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

