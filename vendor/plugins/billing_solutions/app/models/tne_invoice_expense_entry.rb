class TneInvoiceExpenseEntry < ActiveRecord::Base
  unloadable
  include ExpenseEntryGeneralized
  belongs_to :matter
  belongs_to :contact
  belongs_to :company
  belongs_to :tne_invoice
  belongs_to :tne_invoice_detail
  belongs_to :performer , :class_name => 'User', :foreign_key => 'employee_user_id'
  belongs_to :created_by , :class_name => 'User', :foreign_key => 'created_by_user_id'
  belongs_to :expense, :class_name => 'Physical::Timeandexpenses::ExpenseType',:foreign_key => 'expense_type'
  belongs_to :tne_invoice_time_entry
  validates_presence_of :expense_amount, :message => :blank
  validates_presence_of :description
  validates_presence_of :is_billable
  before_save :check_billing_type,:calculate_final_expense_amount
  acts_as_paranoid #for soft delete
  #validates_presence_of :description, :message=>:description_msg
  ##This scope will fetch expense_entry_dates whose matter_id and employe_id is matter_id and employee_id
  named_scope :max_dates,  lambda {|matter_id, employee_id|
    {:conditions =>["matter_id =? and employee_user_id =?", matter_id, employee_id], :select=> "expense_entry_date"}
  }
end
