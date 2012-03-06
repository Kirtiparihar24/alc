class ProductLicenceDetail < ActiveRecord::Base
  belongs_to :product_licence
  belongs_to :user
  acts_as_paranoid
  #It returns list of assigned licences to selected user.
  named_scope :getuserlicence, lambda{|user_id| {:conditions => ['user_id = ?', user_id]}}  
end

# == Schema Information
#
# Table name: product_licence_details
#
#  id                 :integer         not null, primary key
#  product_licence_id :integer         not null
#  start_date         :datetime        not null
#  expired_date       :datetime
#  status             :integer
#  created_at         :datetime
#  updated_at         :datetime
#  user_id            :integer         not null
#  deleted_at         :datetime
#

