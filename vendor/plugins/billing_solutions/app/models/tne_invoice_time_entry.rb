class TneInvoiceTimeEntry < ActiveRecord::Base
  include TimeEntryGeneralized
  unloadable
  belongs_to :company
  belongs_to :tne_invoice
  belongs_to :tne_invoice_detail
  belongs_to :performer , :class_name => 'User', :foreign_key => 'employee_user_id'
  has_many :tne_invoice_expense_entries,:foreign_key => 'time_entry_id'
  belongs_to :acty_type, :class_name => 'CompanyActivityType',:foreign_key => 'activity_type'
  belongs_to :created_by , :class_name => 'User', :foreign_key => 'created_by_user_id'
  belongs_to :contact
  belongs_to :matter
  validates_presence_of :description, :message=>:description_msg
  validates_numericality_of :actual_duration,:message=>:actual_duration_less_then_msg, :less_than_or_equal_to => 1440, :greater_than_or_equal_to => 0.01
  validates_numericality_of :actual_activity_rate ,:message => :rate_range_message,:less_than_or_equal_to=>9999.99,:greater_than_or_equal_to => 0.01
  validates_presence_of :is_billable, :message=>:billable_should_be_checked
  validates_presence_of :activity_type
  validates_presence_of :billing_percent,:message=>:billing_percent_blank_msg, :if => Proc.new { |tne_invoice_time_entry| tne_invoice_time_entry.billing_method_type == 2 }
  validates_presence_of :final_billed_amount,:message=>:final_billed_amount_blank_msg, :if => Proc.new { |tne_invoice_time_entry| tne_invoice_time_entry.billing_method_type == 3 }
  validates_numericality_of :billing_percent,:message=>:billing_percent_msg, :greater_than => 0, :if => :not_blank?
  validate :check_for_billing_percent ,:validate_start_n_end_time#, :check_for_time_difference
  validate :calculate_final_billed_amt , :if=>Proc.new{|entry|entry.errors.empty?}
  ##This scope will fetch time_entry_dates whose matter_id and employe_id is matter_id and employee_id
  named_scope :max_dates,  lambda {|matter_id, employee_id|
    {:conditions =>["matter_id =? and employee_user_id =?", matter_id, employee_id], :select=> "time_entry_date"}
  }

  acts_as_paranoid #for soft delete
  #validates_presence_of :description, :message=>:description_msg
  def is_override_amout?
   #self.billing_amount.to_f > 0
   self.billing_method_type == 3
 end
#  def self.skip_time_zone_conversion_for_attributes
#    [:start_time, :end_time]
#  end

end
