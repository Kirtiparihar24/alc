# Feature 6407 - Supriya Surve - 9th May 2011
#  integer :created_by_user_id, :company_id
#  string :setting_type, :setting_value
#  datetime :deleted_at, :permanent_deleted_at, :created_at, :updated_at
class CompanySetting < ActiveRecord::Base
  belongs_to :company
  belongs_to :user, :foreign_key =>'created_by_user_id'

end

class CampaignMailerEmail < CompanySetting
  belongs_to :company
  validates_presence_of :setting_value ,:message => :setting_value_blank
  validates_uniqueness_of:setting_value,:scope => :company_id, :message => :setting_value_uniquee
  validates_format_of :setting_value,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :setting_value_format, :if => :email_present

  def email_present
    self[:setting_value].present?
  end
  
end

# == Schema Information
#
# Table name: company_settings
#
#  id                   :integer         not null, primary key
#  created_by_user_id   :integer
#  company_id           :integer
#  type                 :string(255)
#  setting_value        :string(255)
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

