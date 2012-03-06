class Subproduct < ActiveRecord::Base
  set_table_name "subproducts"
  has_many    :product_subproducts
  has_many    :products, :through => :product_subproducts
  
  has_many :subproduct_assignments
  has_many :users, :through => :subproduct_assignments
  
  validates_presence_of :name, :message => "Module name can't be blank"
  validates_uniqueness_of :name, :case_sensitive => false
  acts_as_paranoid #for soft delete
  default_scope :order => 'subproducts.created_at DESC'

end
# == Schema Information
#
# Table name: subproducts
#
#  id                   :integer         not null, primary key
#  name                 :string(64)      default(""), not null
#  created_at           :datetime
#  updated_at           :datetime
#  delta                :boolean         default(TRUE), not null
#  permanent_deleted_at :datetime
#  deleted_at           :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#

