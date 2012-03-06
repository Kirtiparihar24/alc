# To change this template, choose Tools | Templates
# and open the template in the editor.

class ContactStage < CompanyLookup
  belongs_to :company
  has_many :contacts
  validates_presence_of :alvalue, :message=>"Contact Stage Name can't be blank"


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

