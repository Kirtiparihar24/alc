class CompanyTempLicence < ActiveRecord::Base
  belongs_to :company
  
end

# == Schema Information
#
# Table name: company_temp_licences
#
#  id                 :integer         not null, primary key
#  company_id         :integer
#  licence_limit      :integer
#  created_by_user_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

