class UserWorkSubtype < ActiveRecord::Base
  belongs_to :work_subtype
  belongs_to :user
  belongs_to :work_subtype_complexity
  
end

# == Schema Information
#
# Table name: user_work_subtypes
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  work_subtype_id :integer
#  created_at      :datetime
#  updated_at      :datetime
#

