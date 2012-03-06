class MatterLitigation < ActiveRecord::Base
  belongs_to :matter
  acts_as_paranoid
end

# == Schema Information
#
# Table name: matter_litigations
#
#  id                   :integer         not null, primary key
#  plaintiff            :boolean
#  case_number          :string(255)
#  hearing_before       :string(255)
#  forum                :string(255)
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

