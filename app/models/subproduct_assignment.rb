class SubproductAssignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :subproduct  
  belongs_to :product_licence  
  acts_as_paranoid
  belongs_to:company
  
  #It return subproduct list for serviceprovider, all the subproduct which is assigned by lawyer to serviceprovider. 
  named_scope :getsubproductlist,lambda{|emp_user_id|{:select => ["distinct subproduct_id"], :conditions => ['employee_user_id = ?', emp_user_id]}}

  ##It will return all the sub product ids on the basis of user_id and product_licence_id
  named_scope :get_all_subproduct_ids, lambda{|user_id, product_licence_id| {:select => "subproduct_id", :conditions => ["user_id = ? AND product_licence_id = ?", user_id,product_licence_id]}} do
    def subproduct_ids
      collect(&:subproduct_id)
    end
  end
 end

# == Schema Information
#
# Table name: subproduct_assignments
#
#  id                 :integer         not null, primary key
#  user_id            :integer         not null
#  subproduct_id      :integer         not null
#  employee_user_id   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  product_licence_id :integer         not null
#  company_id         :integer         not null
#  deleted_at         :datetime
#

