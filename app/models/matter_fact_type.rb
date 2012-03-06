# To change this template, choose Tools | Templates
# and open the template in the editor.

class MatterFactType < CompanyLookup
  validates_presence_of :alvalue ,:message=>"Matter Fact Type can't be blank"
  belongs_to :company
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

