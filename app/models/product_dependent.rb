class ProductDependent < ActiveRecord::Base
  belongs_to :product
  acts_as_paranoid

  def product_parent_name(product_id)
    Product.find(product_id).name
  end

  def product_name
    Product.find(parent_id).name
  end

end


# == Schema Information
#
# Table name: product_dependents
#
#  id         :integer         not null, primary key
#  product_id :integer         not null
#  parent_id  :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#

