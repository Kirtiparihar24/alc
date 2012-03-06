class Question < UserSetting
  belongs_to :user
  has_one :answer, :foreign_key => 'ref_id'

  accepts_nested_attributes_for :answer
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

