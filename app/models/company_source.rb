class CompanySource < CompanyLookup
  validates_presence_of :alvalue ,:message=>"Source can't be empty"
  belongs_to :company
  has_many   :contacts,:foreign_key => :source
  has_many   :opportunities,:foreign_key => :source
  
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

