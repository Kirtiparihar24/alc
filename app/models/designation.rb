class Designation < CompanyLookup
  belongs_to :company
  has_many :employees
  validates_presence_of :designation, :message => "can't be blank"
  validates_uniqueness_of :lvalue, :scope => :company_id, :message => :designation_already_exist, :case_sensitive => false

  named_scope :get_companys_designation, lambda{|company_id|{:select => ['id,lvalue'],:conditions => ["company_id = ?", company_id]}}
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

