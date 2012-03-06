# === Table Information
#
# Only *important* fields listed here:
#
# * _employee_user_id_ stores the employee entry for law team members.
# * _contact_id_ stores the contact id from contacts table, for client entry.

class MatterPeople < ActiveRecord::Base
  include GeneralFunction
  acts_as_paranoid
  belongs_to :matter
  belongs_to :company
  belongs_to :contact
  belongs_to :matter_team_role, :class_name => "CompanyLookup", :foreign_key => :matter_team_role_id
  belongs_to  :assignee, :class_name => "User", :foreign_key => :employee_user_id
  belongs_to  :salutation_type , :foreign_key => :salutation_id
  default_scope :order => 'matter_peoples.created_at DESC'
 
  has_many :matter_tasks, :foreign_key => :assigned_to_matter_people_id
  has_many :matter_issues, :foreign_key => :assigned_to_matter_people_id
  has_many :document_access_controls, :dependent =>:destroy
  has_many :document_homes, :through => :document_access_controls, :dependent =>:destroy
  has_many :time_entries , :class_name => 'Physical::Timeandexpenses::TimeEntry', :foreign_key => 'matter_people_id'
  has_many :expense_entries , :class_name => 'Physical::Timeandexpenses::ExpenseEntry', :foreign_key => 'matter_people_id'
  has_many :matter_access_periods
  validate :people_details
  attr_accessor :effective_from,:contact_stage_id
  attr_accessor :create_contact_entry
  attr_reader :TEAM_ROLES
  attr_reader :OTHER_ROLES
  attr_reader :CLIENT_REP_ROLES
  attr_reader :BILLING_TYPES
  attr_reader :BILLING_BY

  named_scope :client_contacts, :conditions => {:people_type => 'client_contact'}
  named_scope :lawteam_members, :conditions => {:people_type => 'client'}
  named_scope :client_contacts_and_matter_client, :conditions => ["people_type=? OR people_type=?",'matter_client','client_contact']
  named_scope :other_related, :conditions => ["people_type='others' AND is_active = true"]
  named_scope :for_allow_time_entry, :conditions => {:allow_time_entry => true}
  named_scope :primary_contact, :conditions => ["people_type = 'matter_client'"]

  validate :validates_inception_date
  #validates_length_of :name, :maximum=>64,:allow_nil => true ,:message=>"is too long it should not exceed 64 char."
  validates_format_of :email,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*(([A-Za-z0-9])|(\_))+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :email_format,:if => :email_present
  before_save :set_name
    
  #validates_format_of :phone, :with => /^[+\/\-() 0-9]+$/,  :message => :phone_error, :allow_blank=> true, :allow_nil => true

  BILLING_TYPES = [
    "Fixed Rate",
    "Hourly Rate",
    "Flexi Rate"
  ]
  BILLING_BY = [
    "By Lawyer",
    "By Level",
    "By Activity",
    "By Rate Card"
  ]

  TEAM_ROLES = [
    "Managing Partner",
    "Senior Partner",
    "Junior Partner",
    "Associate Partner",
    "Senior Counsel",
    "Junior Counsel",
    "Associate",
    "Senior Associate",
    "Para Legal",
    "Executive Assistant"
  ].sort
  OTHER_ROLES = [
    "External Counsel",
    "Consultant & Advisor",
    "Beneficiary",
    "Deponent",
    "Cross-defendant",
    "Debtor",
    "Creditor",
    "Liquidator",
    "Trustee",
    "Administrator",
    "Legal Clerk",
    "Judges' Assistant",
    "Witness",
    "Expert Witness",
    "Eye-Witness",
    "Character Witness"
  ].sort
  CLIENT_REP_ROLES = [
    "Corporate Counsel",
    "General Counsel",
    "In-house Counsel",
    "General Manager - Legal",
    "Legal Executive",
    "Business Head /Manager",
    "Technical Executive",
    "Technical Assistant",
    "Paralegal"
  ].sort

  validate :check_start_date
  validate :check_end_date

  def email_present
    self[:email].present?
  end

  def validates_inception_date
    self.errors.add(:matter_date,:matter_inception_date)if !self.id && self[:matter_date].present? && self[:matter_date].to_date > Time.zone.now.to_date
  end

  # method defined to validate presence of phone : sania wagle
  def phone_present
    self[:phone].present?
  end

  #Added for the Feature #8234 - export to excel in all view pages in T & E
  #This will fetch lawyer designation
  def self.get_lawyer_designation(employee_user_id, matter_id)
     mp = MatterPeople.first(:conditions => ["employee_user_id = ? AND matter_id = ?", employee_user_id, matter_id])
    if mp
      mp.matter_team_role.alvalue
    end
  end

  def check_start_date
    if self.people_type == "client"
      unless self.start_date.blank?
        matter = Matter.find(self.matter_id)
        date = matter.created_at.to_date
        date = matter.matter_date.to_date unless matter.matter_date.blank?
        self.errors.add('This',:start_date_before_matter_date) if self.start_date < date
      end
    end
  end

  def check_end_date
    if self.start_date.present? &&  self.end_date.present?
      self.errors.add('This',:end_date_before_start_date) if self.end_date < self.start_date
    end
  end

  def create_from_contact(params, page)
    if params[:matter_people][:contact_id].blank?
      page << "alert('Please select a contact.')";
      return false
    end
    contact = Contact.find(params[:matter_people][:contact_id])
    self.name = contact.first_name
    self.last_name = contact.last_name
    self.email = contact.email
    self.salutation_id = contact.salutation_id
    self.phone = contact.phone
    self.alternate_email = contact.alt_email
    self.fax = contact.fax
    self.mobile = contact.mobile
    self.contact_id = contact.id
    unless contact.address.nil?
      self.address = contact.address.street
      self.city = contact.address.city
      self.state = contact.address.state
      self.country = contact.address.country
      self.zip = contact.address.zipcode
    end
    self.people_type = "client_contact"
    if self.save && set_primary_contact(contact, params)
      page << "tb_remove()"
      page << "window.location.reload()"
      return true
    end

    false
  end

  # Its a custom Validation Which Checks whether either of email id or phone no is specified
  def people_details
    self[:email].strip! if self[:email]
    self[:phone].strip! if self[:phone]

    case self.people_type
    when "client"
      self.errors.add_to_base("Please select an employee name") if self.employee_user_id.blank?
      self.errors.add_to_base("Please select a member from date") if self.start_date.blank?
    when "matter_client"
      self.errors.add_to_base("Please select or create a contact") if self.contact_id.blank?
    when "client_contact"
      self.errors.add_to_base("Please enter First Name") if self.name.blank?
      self.errors.add_to_base("Please enter phone or email") if (self.phone.blank? && self.email.blank? && !self.can_access_matter?)
      self.errors.add_to_base("Please enter email") if(self.email.blank? && self.can_access_matter?)
    else
      self.errors.add_to_base("Please enter First Name") if self.name.blank?
      self.errors.add_to_base("Please enter phone or email") if (self.phone.blank? && self.email.blank?)
    end
  end

  def since_inception?
    return true if self.new_record?
    self.start_date == self.matter.matter_start_date
  end

  def law_team_member?
    self.people_type == 'client'
  end

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search, conditions_hash, include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash])
    find(:all, include_hash )
  end

  def self.is_part_of_matter_and_matter_people?(matter_id, emp_id)
    MatterPeople.count(:conditions => ['matter_id = ? AND employee_user_id = ?', matter_id, emp_id] ) > 0
  end

  def update_with_contact(params)
    return false unless self.update_attributes(params[:matter_people])
    if params[:hidden_added_to_contact]
      if self.contact_id
        contact = Contact.find(self.contact_id)
      else
        contact = Contact.new
      end
      set_contact(contact, params)
    else
      true
    end
  end

  def save_with_contact(params)
    if !self.contact_id && params[:hidden_added_to_contact]=="true"
      contact = Contact.new
      set_contact(contact, params)
    else
      self.save
    end
  end

  # Set name in case of a law team/client entry.
  def set_name
  end

  # Returns titleized name.
  def name_titleize
    if self.name?
      self.name=self.name.try(:titleize)
    end
  end

  # Return list of other related matter peoples.
  def self.others
    self.all(:conditions => ["people_type = 'others' AND is_active = true"])
  end

  # Return list of opposite team peoples.
  def self.opposite
    self.all(:conditions => ["people_type = 'opposites' AND is_active = true"])
  end

  # Return list of law team members.
  def self.client
    self.all(:conditions => ["people_type = 'client' AND is_active = true"])
  end

  # Return list of client representative matter peoples.
  def self.client_representative
    self.all(:conditions => ["people_type = 'client_representative' AND is_active = true"])
  end

  def self.only_client_representative
    self.all(:conditions => ["people_type = 'client_representative' AND is_active = true AND contact_id IS NULL"])
  end

  # Returns lawyer name.
  def get_lawyer_name
    if self.employee_user_id
      if self.assignee
        self.assignee.try(:full_name).try(:titleize)
      end
    else
      return ''
    end
  end

  # Returns lawyer info.
  def get_lawyer_info
    if self.employee_user_id
      usr = User.find(self.employee_user_id)
      "#{usr.full_name}<br />#{usr.phone} #{usr.email}"
    end
  end

  # Returns role.
  def get_role
    if matter_team_role_id.present?
      matter_team_role.try(:alvalue)
    else
      role_text
    end
  end

  # Returns name.
  def get_name
    if self.employee_user_id
      User.find_with_deleted(self.employee_user_id).full_name
    elsif self.contact_id
      Contact.find_with_deleted(self.contact_id).full_name
    else
      self.try(:name) + " " + (self.try(:last_name) || '')
    end
  end

  # Returns email.
  def get_email
    if self.employee_user_id
      User.find_with_deleted(self.employee_user_id).email
    elsif self.email.present?
      self.email
    elsif self.contact_id
      Contact.find_with_deleted(self.contact_id).email
    end
  end

  # Returns phone.
  def get_phone
    if self.employee_user_id
      User.find_with_deleted(self.employee_user_id).phone
    elsif self.phone.present?
      self.phone
    elsif self.contact_id
      Contact.find_with_deleted(self.contact_id).phone
    end
  end

  # Returns name,phone and email info.
  def get_info
    "#{self.name}<br />#{self.phone} #{self.email}"
  end

  # Check name given in case no employee selected.
  def check_name
    self.errors.add('This', :name_blank) if (self.employee_user_id.blank? && self.name.blank?)
  end

  def full_name
    self.name
  end

  def rep_full_name
    "#{self.name} #{self.last_name}"
  end
  # Find the entry for current lawyer from matter people.
  def self.me(uid,mid,cid)
    i ||= MatterPeople.first(:conditions => [
        "employee_user_id IS NOT NULL AND employee_user_id = ? AND matter_id = ? AND company_id = ?",
        uid, mid, cid]
    )
  end

  # Returns true if the membership is expired, false otherwise.
  def expired?
    return false if (self.start_date.nil? or self.end_date.nil?)
    self.end_date < Time.zone.now.to_date
  end

  # Returns true if the membership is not yet started, false otherwise.
  def not_yet_started?
    return false if (self.start_date.nil?)
    self.start_date > Time.zone.now.to_date
  end

  # dates
  # Start - End
  # 19/09 - 21/09
  # 19/09 - 22/09
  # 21/09 - 26/09
  # Output- 19/09 - 26/09
  # Return the start_date and end_date if end_date is nil, it means he has full access to the matter
  # else 
  # it will check if end_date>=current_time (eg if end_date is 21/09 >= 19/09)
  # Then It will check (start_date == prev_end_date || start_date < prev_end_date)  && end_date >= prev_end_date
  #then prev_end_date is change
  #at last array of start_date and end_date return
  def get_matter_access_period_dates
    #previous_period = self.matter_access_periods.find(:first,:order => "start_date")
    access_periods = self.matter_access_periods.all
    previous_period = access_periods.first
    prev_start_date, prev_end_date = previous_period.start_date, previous_period.end_date    
    current_time = Time.zone.now.to_date
    access_periods.each do|ap|
      if ap.start_date.blank? || ap.end_date.blank?
        return [ap.start_date,ap.end_date]
      end
      if ap.start_date <= current_time && ap.end_date.blank?
        return [ap.start_date,ap.end_date]
      elsif ap.end_date >= current_time
        if(ap.start_date == prev_end_date || ap.start_date < prev_end_date)  && ap.end_date >= prev_end_date
          prev_end_date = ap.end_date          
        end      
      end      
    end

    [prev_start_date, prev_end_date]
  end

  # Returns list of those matter peoples whose membership is not expired.
  def self.current_lawteam_members(mid)
    Matter.find(mid).matter_peoples.find_all {|m|
      m.people_type == 'client' && (m.end_date.nil? || (m.start_date <= Time.zone.now.to_date && m.end_date > Time.zone.now.to_date))
    }
  end

  def self.get_name_and_email(matter)   
    matterppl = matter.matter_peoples
    userppl = []
    cntctppl = []
    mattrall = matterppl.all(:conditions => ["employee_user_id IS NOT NULL OR contact_id IS NOT NULL"])
    clientall = matterppl.only_client_representative
    others = matterppl.others
    mattrall.collect{|mp| mp.contact_id.nil? ? userppl << mp.employee_user_id : cntctppl << mp.contact_id }
    userall = User.find_with_deleted(userppl).uniq
    cntctall = Contact.find_with_deleted(:all, :conditions => ["id IN (?)",cntctppl]).uniq
    alldetails = []
    userall.each{|u| (alldetails << [u.full_name,u.email]) unless u.email.blank? }
    cntctall.each{|c| (alldetails << [c.full_name,c.email]) unless c.email.blank?}
    clientall.each{|clnt| (alldetails << [clnt.rep_full_name, clnt.email]) unless clnt.email.blank?}
    others.each{|othr| (alldetails << [othr.rep_full_name, othr.email]) unless othr.email.blank?}

    alldetails
  end

  def set_contact(contact, params, dont_save=false)
    contact.salutation_id = self.salutation_id
    contact.first_name = self.name
    contact.last_name = self.last_name
    contact.middle_name = self.middle_name
    contact.phone = self.phone
    contact.email = self.email
    contact.alt_email = self.alternate_email
    contact.fax = self.fax
    contact.mobile = self.mobile
    contact.company_id = self.company_id
    contact.created_by_user_id = self.created_by_user_id
    contact.address ||= contact.build_address
    contact.address.street = self.address
    contact.address.city = self.city
    contact.address.state = self.state
    contact.address.country = self.country
    contact.address.zipcode = self.zip    
    contact.contact_stage_id= params[:matter_people][:contact_stage_id] unless params[:matter_people].blank?
    #in client contact if the contacts are not in client state and if try to update it was througing exception to add reason
    #so we added the reason
    contact.reason = "Stage changed to Client"
    if dont_save
      return contact
    end   
    if contact.valid?
      new_contact = contact.new_record?
      contact.save
      self.contact_id = contact.id
      account = self.matter.contact.accounts[0] if params[:account].blank?
      # Add the newly created contact to the account if the primary matter contact
      # is associated with an account.
      if new_contact and account
        contact.accounts << account
      end

      self.save && set_primary_contact(contact, params)
        
    else
      error = "<ul>" + contact.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
      self.errors.add(" ", "#{error}")

      false
    end    
  end

  def handle_additional_priv(params)
    unless params[:additional_privs].blank?
      self.additional_priv = 0
      params[:additional_privs].each do|e|
        self.additional_priv |= e.to_i
      end
      self.save
    end
  end

  # Handling of additional privileges to matter people law team members.
  # Accessible actions are stored in bit fields.
  def get_additional_priv
    self.additional_priv.blank? ? 0 : self.additional_priv
  end

  def can_view_client_docs?
    self.get_additional_priv & 1 == 1
  end

  def can_view_client_comments?
    self.get_additional_priv & 2 == 2
  end

  def can_control_matter_access?
    self.get_additional_priv & 4 == 4
  end

  def can_enforce_version_control?
    self.get_additional_priv & 8 == 8
  end

  def can_assign_tasks?
    self.get_additional_priv & 16 == 16
  end

  def can_checkin_docs?
    self.get_additional_priv & 32 == 32
  end

  def can_change_status_time_and_expense?
    self.get_additional_priv & 64 == 64
  end

  # Updates the start date with given date and keep the membership period intact.
  def update_start_date(date)
    date1 = self.start_date
    date2 = self.end_date
    self.start_date = date
    if date2.present?
      diff = date2 - date1
      self.end_date = date + diff
    end
    self.send(:update_without_callbacks)
  end

  def get_prev_email
    @prev_email=self.email_was
    puts @prev_email
  end
  
  def self.find_matter_people(user_id)
    all :conditions => ["employee_user_id = ? AND is_active = ?", user_id, true], :order=>'created_at ASC'
  end

  def create_matter_client(email, can_access_matter, contact)
    user=User.find_by_email(email)
    if(user.nil? && can_access_matter)
      user = User.new
      user.email=email
      user.first_name=contact.try(:first_name)
      user.last_name=contact.try(:last_name)
      user.username=email
      user.sign_in_count=0
      user.company_id=contact.company_id
      user.save(false)
      role=Role.find_by_name('client')
      userrole = UserRole.find_or_create_by_user_id_and_role_id(user.id,role.id)
      User.generate_and_mail_new_password_from_matter(user.username,user.email,User.current_lawyer)      
      matter_user=self.matter.user      
      send_notification_to_lead_lawyer(matter_user,self.matter,User.current_lawyer)      
      contact=self.contact
      contact.user_id=user.id
      contact.send(:update_without_callbacks)      
    end
  end

  private
  
  def set_primary_contact(contact, params)
    matter = self.matter
    if params[:primary_matter_contact].present?
      oldclient = matter.matter_peoples.find_by_contact_id(matter.contact_id)
      if oldclient.matter_team_role_id.blank?
        team_role_id = self.company.client_roles.find_by_lvalue("Matter Client").id
        self.matter_team_role_id = team_role_id
      else
        oldclient.people_type = 'client_contact'
        self.matter_team_role_id = oldclient.matter_team_role_id
        oldclient.matter_team_role_id = nil #people_type = 'client_contact'
        oldclient.role_text = self.role_text
      end
      matter.contact_id = contact.id
      self.people_type = 'matter_client'
      matter.send(:update_without_callbacks) && self.send(:update_without_callbacks) && oldclient.send(:update_without_callbacks)
    else
      true
    end
  end  
end

# == Schema Information
#
# Table name: matter_peoples
#
#  id                   :integer         not null, primary key
#  employee_user_id     :integer
#  people_type          :string(255)
#  name                 :string(255)
#  email                :string(255)
#  address              :text
#  fax                  :string(255)
#  phone                :string(255)
#  is_active            :boolean
#  start_date           :date
#  end_date             :date
#  primary_contact      :boolean
#  matter_id            :integer
#  created_at           :datetime
#  updated_at           :datetime
#  matter_team_role_id  :integer
#  contact_id           :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  member_start_date    :date
#  member_end_date      :date
#  last_name            :string(32)
#  notes                :string(255)
#  city                 :string(64)
#  state                :string(64)
#  zip                  :string(16)
#  country              :string(64)
#  alternate_email      :string(64)
#  mobile               :string(16)
#  role_text            :string(64)
#  added_to_contact     :boolean
#  additional_priv      :integer
#  can_access_matter    :boolean
#  salutation_id        :integer
#  middle_name          :string(64)
#  allow_time_entry     :boolean         default(FALSE)
#

