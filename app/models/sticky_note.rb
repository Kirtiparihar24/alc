class StickyNote < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :description
end

# == Schema Information
#
# Table name: sticky_notes
#
#  id                  :integer         not null, primary key
#  created_at          :datetime        not null
#  updated_at          :datetime
#  created_by_user_id  :integer         not null
#  description         :text            not null
#  company_id          :integer
#  assigned_to_user_id :integer
#

