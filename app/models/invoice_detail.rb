class InvoiceDetail < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :company
  belongs_to :product_licence
  belongs_to :product
  acts_as_paranoid
  named_scope :grouped_records, lambda{|id|{ :group => "product_id, date(product_purchase_date),cost,invoice_id", :conditions => ["invoice_id = ?", id], :select => "product_id, date(product_purchase_date) AS product_purchase_date,invoice_id,cost,sum(count) AS count, sum(total_amount) AS total_amount"}}
  #default_scope :order=>'username DESC, product DESC'
end

# == Schema Information
#
# Table name: invoice_details
#
#  id                    :integer         not null, primary key
#  company_id            :integer         not null
#  invoice_id            :integer         not null
#  licence_id            :integer         not null
#  product_id            :integer         not null
#  billing_from_date     :datetime        not null
#  billing_to_date       :datetime        not null
#  total_amount          :decimal(12, 2)  not null
#  cost                  :decimal(12, 2)  not null
#  count                 :decimal(12, 2)  not null
#  created_at            :datetime
#  updated_at            :datetime
#  delta                 :boolean         default(TRUE), not null
#  permanent_deleted_at  :datetime
#  deleted_at            :datetime
#  created_by_user_id    :integer
#  updated_by_user_id    :integer
#  status                :integer
#  product_purchase_date :datetime
#

