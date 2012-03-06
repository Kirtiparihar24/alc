class Physical::Timeandexpenses::ExpenseEntry < ActiveRecord::Base
  include ExpenseEntryGeneralized
  include ImportData
  acts_as_paranoid
  default_scope :order => 'created_at DESC'

  belongs_to :performer , :class_name => 'User', :foreign_key => 'employee_user_id'
  belongs_to :created_by , :class_name => 'User', :foreign_key => 'created_by_user_id'
  belongs_to :time_entry,:class_name =>'Physical::Timeandexpenses::TimeEntry' ,:foreign_key =>"time_entry_id"
  belongs_to :matter
  belongs_to :matter_people #, :class_name => 'Physical::Timeandexpenses::ExpenseEntry', :foreign_key => 'matter_people_id'
  belongs_to :contact
  belongs_to :company
  belongs_to :tne_invoice
  has_many :document_homes, :as => :mapable, :dependent => :destroy
  #its belongs to expense_type model, the foreign key name and association name bot same that why I use alias name for the association.
  belongs_to :expense, :class_name => 'Physical::Timeandexpenses::ExpenseType',:foreign_key => 'expense_type'
  validates_presence_of :expense_amount
  validates_presence_of :description
  validates_presence_of :expense_type
  validates_numericality_of :expense_amount, :greater_than => 0,:less_than =>999999999999, :allow_blank => :true
  validates_numericality_of :billing_percent, :greater_than => 0, :if => :billing_percent_check
  validates_numericality_of :markup, :greater_than => 0,:less_than_or_equal_to=>1000, :if => :markup_check
  validate :check_matter_inception_date , :if => "self.matter_id" #Avoid check for matter_inception_date if time entry is non matter related : Pratik AJ
  before_save :check_billing_type,:calculate_final_expense_amount
  after_update :save_approved_entry_to_invoice
  attr_accessor  :file
  attr_accessor :current_lawyer
  named_scope :unapproved_entries,:conditions => ["status = 'Open' and is_internal=false"]
  named_scope :approved_entries,:conditions => ["status = 'Approved' and is_internal=false and billing_method_type is not null"]
  named_scope :without_matter, :conditions =>["matter_id is null"]
  ##This scope will fetch expense_entry_dates whose matter_id and employe_id is matter_id and employee_id
  named_scope :max_dates,  lambda {|matter_id, employee_id|
    {:conditions =>["matter_id =? and employee_user_id =?", matter_id, employee_id], :select=> "expense_entry_date"}
  }
  acts_as_commentable

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search,conditions_hash,include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash],:order => 'expense_entry_date asc')
    find(:all , include_hash)
  end
  #IMPORTANT NOTE: METHODS MOVED TO Module ExpenseEntryGeneralized

  # retrive expense entry which is approved and associated to time entry for matter
  def self.approved_expense_matter_entries(matter_ids)
    with_exclusive_scope{find(:all,:select => "matter_id, sum(final_expense_amount) as final_expense_amount", :conditions => ["matter_id in (?) and status = 'Approved' and is_internal=false and billing_method_type is not null and time_entry_id is null",matter_ids], :include => [:matter], :group => :matter_id)}.compact
  end

  # retrive expense entry which is approved and associated to time entry for contact
  def self.approved_expense_contact_entries (company_id)
    with_exclusive_scope{find(:all,:select => "contact_id, sum(final_expense_amount) as final_expense_amount", :conditions => ["company_id = ? and contact_id is not null and status = 'Approved' and is_internal=false and billing_method_type is not null and matter_id is null and time_entry_id is null",company_id], :include => [:contact], :group => :contact_id)}.compact
  end
end

# == Schema Information
#
# Table name: expense_entries
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  employee_user_id     :integer
#  created_by_user_id   :integer
#  expense_type         :integer
#  time_entry_id        :integer
#  description          :text            not null
#  expense_entry_date   :date            not null
#  billing_method_type  :integer
#  billing_percent      :decimal(14, 2)
#  expense_amount       :decimal(14, 2)  not null
#  final_expense_amount :decimal(16, 2)
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
#  markup               :integer
#  matter_people_id     :integer
#

