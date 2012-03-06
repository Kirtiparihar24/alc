class DocumentAccessControl < ActiveRecord::Base
  belongs_to :document_home
  belongs_to :matter_people #, :dependent=>:destroy
  belongs_to :contact
  belongs_to :user, :class_name => 'User', :foreign_key=>'employee_user_id', :dependent=>:destroy
  belongs_to :company, :class_name => 'Company'

  acts_as_paranoid
  
  before_save :set_company_id
  
  def set_company_id
    self.company_id = self.document_home.company_id
  end

end

# == Schema Information
#
# Table name: document_access_controls
#
#  id                   :integer         not null, primary key
#  document_home_id     :integer
#  matter_people_id     :integer
#  created_at           :datetime
#  updated_at           :datetime
#  contact_id           :integer
#  employee_user_id     :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#

