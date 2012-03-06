# This is new class added in order to add SalutationType into type of company_lookups table Rahul P 3/5/2011
class SalutationType < CompanyLookup
  belongs_to :company
  has_many :contacts, :foreign_key => :salutation_id
  has_many :matter_peoples
  validates_presence_of :alvalue, :message=>"SalutationType can't be blank"

  def self.add_salute(company,params)
    salutation = SalutationType.new(params[:salutation_type].merge(:lvalue=>params[:salutation_type][:alvalue]))
    if salutation.valid? && salutation.errors.empty?
      company.salutation_types << salutation
    end
    salutation
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

