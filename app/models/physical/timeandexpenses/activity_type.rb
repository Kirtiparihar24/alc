class Physical::Timeandexpenses::ActivityType < CompanyLookup
  belongs_to :company
  has_many :time_entries,:class_name => 'Physical::Timeandexpenses::TimeEntry',:foreign_key => 'activity_type'
  validates_presence_of :alvalue ,:message=> "Activity entry type can't be blank"  
end

# == Schema Information
#
# Table name: company_lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  company_id           :integer         default(1)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  alvalue              :string(255)
#  category_id          :integer
#  sequence             :integer         default(0)
#

