class OpportunityStageType < CompanyLookup
  belongs_to :company
  has_many :opportunities, :foreign_key => :stage
  validates_presence_of :alvalue, :message=> :opportunity_stage_name
  validates_numericality_of :percentage,:message=>"should be between 0 To 100", :less_than_or_equal_to => 100, :greater_than_or_equal_to => 0,:if => Proc.new { |stage| stage.percentage !=nil && !stage.percentage.blank? }
  named_scope :get_status_type, lambda { |lvalue|
    {:conditions => ["lvalue = ? ", lvalue]}
  }
  named_scope :get_status_value, lambda { |id|
    {:conditions => ["id = ? ", id]}
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
