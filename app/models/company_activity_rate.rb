class CompanyActivityRate < ActiveRecord::Base
  validates_uniqueness_of :company_id, :scope => :activity_type_id
  validates_presence_of :billing_rate,:company_id,:activity_type_id
  validates_numericality_of :billing_rate, :greater_than => 0,:less_than=>10000, :message => "should be greater than 0 and less than 10000"
  belongs_to :company
  
end

# == Schema Information
#
# Table name: company_activity_rates
#
#  id                   :integer         not null, primary key
#  activity_type_id     :integer
#  billing_rate         :decimal(10, 2)
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

