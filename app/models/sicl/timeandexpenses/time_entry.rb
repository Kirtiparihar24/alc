class Physical::Timeandexpenses::TimeEntry < ActiveRecord::Base
  #Relationships for TimeEntry Entry Model
  include TimeEntryGeneralized
  include ImportData
  acts_as_paranoid
  default_scope :order => 'created_at DESC'
 
  belongs_to :performer , :class_name => 'User', :foreign_key => 'employee_user_id'
  belongs_to :created_by , :class_name => 'User', :foreign_key => 'created_by_user_id'
  has_many :expense_entries, :class_name => 'Physical::Timeandexpenses::ExpenseEntry',:foreign_key => 'time_entry_id', :dependent => :destroy
  has_many :document_homes, :as => :mapable, :dependent => :destroy
  belongs_to :contact
  belongs_to :matter
  belongs_to :matter_people 
  belongs_to :company
  belongs_to :tne_invoice
  #its belongs to acitivit_type model, the foreign key name and association name bot same that why I use alias name for the association.
  belongs_to :acty_type, :class_name => 'CompanyActivityType',:foreign_key => 'activity_type'
  
  #Validations for Time Entry Model
  validates_presence_of :time_entry_date
  validates_presence_of :is_internal, :message => :select_matter_contact_or_check_internal, :if => Proc.new { |time_entry| time_entry.contact_id == nil && time_entry.matter_id == nil }
  validates_presence_of :description, :message=>:description_msg
  validates_numericality_of :actual_duration,:message=>:actual_duration_less_then_msg, :less_than_or_equal_to => 1440, :greater_than_or_equal_to => 0.01
  validates_numericality_of :actual_activity_rate ,:message =>:rate_range_message,:less_than_or_equal_to=>9999.99,:greater_than_or_equal_to => 0.01
  validate :zero_rate,:validate_check,:validate_start_n_end_time
  validates_presence_of :activity_type
  validates_presence_of :billing_percent,:message=>:billing_percent_blank_msg, :if => Proc.new { |time_entry| time_entry.billing_method_type == 2 }
  validates_presence_of :final_billed_amount,:message=>:final_billed_amount_blank_msg,:less_than_or_equal_to => 0, :if => Proc.new { |time_entry| time_entry.billing_method_type == 3 }
  attr_accessor  :nonuser
  validates_numericality_of :billing_percent,:message=>:billing_percent_msg, :greater_than => 0, :if => :not_blank?
  validate :check_for_billing_percent #, :check_for_time_difference
   
  #Callbacks for Time Model
  validate :calculate_final_billed_amt ,:if=>Proc.new{|entry|entry.errors.empty?}
  validate :check_matter_inception_date#, :if => self.matter_id #Avoid check for matter_inception_date if time entry is non matter related : Pratik AJ
  attr_accessor :bill_amount,:file_size
  attr_accessor  :file
  before_validation :set_start_end_time
  before_save :check_and_set_internal
  # Validation for billing percent value.
  after_update :save_approved_entry_to_invoice  
  acts_as_commentable
  #IMPORTANT NOTE: METHODS MOVED TO Module TimeEntryGeneralized
  attr_accessor :current_lawyer
  
  named_scope :unapproved_entries,:conditions => ["status = 'Open' and is_internal=false"]
  named_scope :approved_entries,:conditions => ["status = 'Approved' and is_internal=false and billing_method_type is not null"]
  named_scope :without_matter, :conditions =>["matter_id is null"]
  ##This scope will fetch time_entry_dates whose matter_id and employe_id is matter_id and employee_id
  named_scope :max_dates,  lambda {|matter_id, employee_id|
    {:conditions =>["matter_id =? and employee_user_id =?", matter_id, employee_id], :select=> "time_entry_date"}
  }

  def self.unapproved_matter_entries(matter_ids)
    with_exclusive_scope{find(:all,:select => "matter_id, sum(final_billed_amount) as final_billed_amount, sum(actual_duration) as actual_duration", :conditions => ["matter_id in (?) and status = 'Open' and is_internal=false ",matter_ids], :include => [:matter], :group => :matter_id)}.compact
  end

  def self.approved_matter_entries(matter_ids)
    with_exclusive_scope{find(:all,:select => "matter_id, sum(final_billed_amount) as final_billed_amount, sum(actual_duration) as actual_duration", :conditions => ["matter_id in (?) and status = 'Approved' and is_internal=false and billing_method_type is not null ",matter_ids], :include => [:matter], :group => :matter_id)}.compact
  end
  
  def self.unapproved_contact_entries (company_id)
    with_exclusive_scope{find(:all,:select => "contact_id, sum(final_billed_amount) as final_billed_amount, sum(actual_duration) as actual_duration", :conditions => ["company_id = ? and contact_id is not null and status = 'Open' and is_internal=false and matter_id is null",company_id], :include => [:contact], :group => :contact_id)}.compact
  end

  def self.approved_contact_entries (company_id)
    with_exclusive_scope{find(:all,:select => "contact_id, sum(final_billed_amount) as final_billed_amount, sum(actual_duration) as actual_duration", :conditions => ["company_id = ? and contact_id is not null and status = 'Approved' and is_internal=false and billing_method_type is not null and matter_id is null",company_id], :include => [:contact], :group => :contact_id)}.compact
  end

  # Returns billing rate for time entry for current employee.
  def self.get_billing_rate(company_id, employee_user_id, activity_type_id, role_id, emp_id)
    rate = get_employee_activity_rate(company_id, employee_user_id, activity_type_id, emp_id)
    rate = get_employee_rate(company_id, employee_user_id, role_id,emp_id) if rate.blank?
    rate
  end
  
  # Returns matter specific total time of time entries.
  # i/p: matter_id
  def self.accountable_hours_for_matter(matter_id)    
    entries = Physical::Timeandexpenses::TimeEntry.find(:all, :conditions => ["matter_id = ? AND is_billable", matter_id])
    hours = 0
    entries.each do|e|
      hours += e.actual_duration
    end
    hours
  end

  # Returns employee rate from employees or company_role_rates
  def self.get_employee_rate(company_id, employee_user_id, role_id, emp_id)
    employee = Employee.find_by_user_id(employee_user_id.eql?(emp_id) ? employee_user_id : emp_id)
    unless employee.nil?
      rate =  employee.billing_rate
    end
    if rate.blank? || rate <= 0
      return 0.00 if role_id.blank?
      company_role_rate = CompanyRoleRate.find_by_company_id_and_role_id(company_id, role_id)
      rate = company_role_rate.nil? ? '' : company_role_rate.billing_rate
    end
    rate
  end

  # Returns employee activity rate from employee_activity_rates or company_activity_rates
  def self.get_employee_activity_rate(company_id, employee_user_id, activity_type_id, emp_id)
    emp_act_rate = EmployeeActivityRate.find_by_employee_user_id_and_activity_type_id(employee_user_id.eql?(emp_id) ? employee_user_id : emp_id , activity_type_id)
    unless emp_act_rate.nil?
      rate = emp_act_rate.billing_rate
    else
      company_act_rate = CompanyActivityRate.find_by_company_id_and_activity_type_id(company_id, activity_type_id)
      rate = company_act_rate.nil? ? '' : company_act_rate.billing_rate
    end
    rate
  end

  #This method will save start_time, :end_time save date in UTC formate.
  def self.skip_time_zone_conversion_for_attributes
    [:start_time, :end_time]
  end


  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search, conditions_hash, include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash],:order => 'time_entry_date asc')
    find(:all , include_hash)
  end

  def validate_check
    if self.nonuser.eql?('1') && self.matter_id.nil?
      self.errors.add_to_base('Please Select Matter')
    elsif self.nonuser.eql?('1') && self.matter_people_id.nil?
      self.errors.add_to_base('Please Select Matter People')
    end
  end

  def check_and_set_internal
    if self.matter_id == nil && self.contact_id == nil
      self.is_internal = true
    end
  end

end

# == Schema Information
#
# Table name: time_entries
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer         not null
#  created_by_user_id   :integer
#  activity_type        :integer         not null
#  description          :text            not null
#  time_entry_date      :date            not null
#  start_time           :datetime
#  end_time             :datetime
#  actual_duration      :decimal(14, 2)  not null
#  billing_method_type  :integer
#  billing_percent      :decimal(14, 2)
#  activity_rate        :decimal(12, 2)
#  actual_activity_rate :decimal(14, 2)
#  final_billed_amount  :decimal(16, 2)
#  contact_id           :integer
#  matter_id            :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  updated_by_user_id   :integer
#  status               :string(255)     default("Open")
#  matter_task_id       :integer
#  is_billable          :boolean         default(FALSE)
#  is_internal          :boolean         default(TRUE)
#  tne_invoice_id       :integer
#  matter_people_id     :integer
#

