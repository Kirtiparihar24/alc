class ClientRole < CompanyLookup
  validates_presence_of :lvalue ,:message=>"Client Role can't be blank"
  has_many :matter_peoples
  belongs_to :company
  named_scope :except_lead_lawyer_matter_client_for_matter, :conditions => ["lvalue not in ('Lead Lawyer','Matter Client')"]

  def self.check_and_assign_lvalue(client_role, original_lvalue)
    if original_lvalue == "Lead Lawyer" || original_lvalue == "Matter Client"
      lvalue = original_lvalue
    else
      lvalue = client_role[:lvalue].blank?  ? client_role[:alvalue] : client_role[:lvalue]
    end
    lvalue
  end
  
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

