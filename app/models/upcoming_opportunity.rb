class UpcomingOpportunity < UserSetting
  belongs_to :user
  validates_presence_of :setting_value, :message => "upcomming_setting_value_blank"
  validates_numericality_of :setting_value, :message => "setting_value_numerical", :greater_than => 0
end
# == Schema Information
#
# Table name: user_settings
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  setting_type  :string(255)
#  setting_value :string(255)
#  company_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  ref_id        :integer
#

