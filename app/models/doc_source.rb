class DocSource < CompanyLookup
  validates_presence_of :alvalue ,:message=>"Source can't be blank"
  belongs_to :company
  has_many   :documents, :foreign_key => 'doc_source_id'
  has_many :matter_facts
  
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

