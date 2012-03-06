class Payment < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :lookup
  acts_as_paranoid
  validates_presence_of :payment_mode, :message => "Please fill all mandatory details"
  validates_presence_of :amount, :message => "Please fill all mandatory details"
  validates_presence_of :payment_date, :message => "Please fill all mandatory details"
  def self.payment_mode_check(payment_mode_id)
    Lookup.find_by_id(payment_mode_id).lvalue;
  end
  
end

# == Schema Information
#
# Table name: payments
#
#  id                   :integer         not null, primary key
#  invoice_id           :integer         not null
#  payment_mode         :string(255)     not null
#  amount               :integer         not null
#  cheque_no            :string(255)
#  cheque_date          :datetime
#  bank_name            :string(255)
#  branch_name          :string(255)
#  paypal_account_id    :string(255)
#  status               :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  delta                :boolean         default(TRUE), not null
#  permanent_deleted_at :datetime
#  deleted_at           :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  payment_date         :datetime        not null
#

