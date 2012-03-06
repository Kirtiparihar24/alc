class CompanyRoleRate < ActiveRecord::Base
  belongs_to :company
  validates_uniqueness_of :role_id, :scope => :company_id , :message => "rate already defined!"
  validates_presence_of :billing_rate, :role_id, :message => "should not be blank!"
  validates_numericality_of :billing_rate, :greater_than => 0,:less_than=>10000, :message => "should be greater than 0 and less than 10000"

  def people_role
    CompanyLookup.find_by_id self.role_id
  end
 
end

# == Schema Information
#
# Table name: company_role_rates
#
#  id                   :integer         not null, primary key
#  role_id              :integer
#  billing_rate         :decimal(10, 2)
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

