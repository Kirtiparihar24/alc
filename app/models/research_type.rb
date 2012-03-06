class ResearchType < CompanyLookup
  validates_presence_of :alvalue ,:message => "Research Type can't be blank"
  belongs_to :company
  has_many :matter_researches, :foreign_key => :research_type
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

