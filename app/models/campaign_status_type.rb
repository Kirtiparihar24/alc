class CampaignStatusType < CompanyLookup
  belongs_to :company
  has_many :campaigns
  named_scope :planned, lambda { |company_id|
    { :conditions => ["lvalue = ? and company_id = ? ",'Planned', company_id] }
  }
  named_scope :inprogress, lambda { |company_id|
    { :conditions => ["lvalue = ? and company_id = ? ",'Inprogress', company_id] }
  }
  named_scope :completed, lambda { |company_id|
    { :conditions => ["lvalue = ? and company_id = ? ",'Completed', company_id] }
  }
  named_scope :aborted, lambda { |company_id|
    { :conditions => ["lvalue = ? and company_id = ? ",'Aborted', company_id] }
  }

  named_scope :completed_or_aborted, lambda { |company_id|
    { :conditions => ["lvalue In (?) and company_id = ?",['Completed','Aborted'], company_id] }
  }

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

