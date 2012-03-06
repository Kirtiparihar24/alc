class Phase < CompanyLookup
  validates_presence_of :alvalue ,:message=>"Phase can't be blank"
  belongs_to :company
  has_many   :matters
  has_many   :matter_tasks
  has_many :documents ,:foreign_key => :phase_id
  #default_scope :order => 'lvalue ASC'
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

