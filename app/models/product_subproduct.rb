class ProductSubproduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :subproduct
  validates_presence_of :product_id, :subproduct_id
  acts_as_paranoid
end
# == Schema Information
#
# Table name: product_subproducts
#
#  id                   :integer         not null, primary key
#  product_id           :integer         not null
#  subproduct_id        :integer         not null
#  deleted_at           :datetime
#  created_at           :datetime
#  updated_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

