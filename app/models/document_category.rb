class DocumentCategory< CompanyLookup
  validates_presence_of :lvalue ,:message=>"Category can't be blank"
  belongs_to :company  
  has_many   :documents, :foreign_key => :doc_type_id
  has_many :links ,:foreign_key => :category_id
  has_many  :sub_categories, :class_name=> 'DocumentSubCategory', :foreign_key=> :category_id
  
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

