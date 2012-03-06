# === Table Information
#
# Only *important* fields listed here:
#
# * Lead lawyer comes from employees table, user_id is stored in _employee_user_id_.
# * Client comes from/goes into contacts table, and _contact_id_ is stored.
# * _matter_type_ is different for each _litigation_type_.
# * _opportunity_id_ is used if this matter is created as a result of a closed/won opportunity.

# A matter can be of two types:
# * Litigation Matter
# * Non-Litigation Matter

# A litigation (Matter) is the case when there is dispute between two parties
# and they seek for a resolution of their issue from the court of law.
# Eg:
# Scam, Illegal Seizure of Land, Breach of Contract. etc.
#
# A non-litigation (Matter) is the case wherein the legal activities done, require some
# formal procedures to be followed as stated by the court of law. In simpler words it
# is about following some legal procedures or preparing some legal documents.
# Eg:
# Company Memorandum of Association, Patent Registration, Licencing/Agreement Drafting. etc.


class Matter < ActiveRecord::Base
  include GeneralFunction
  acts_as_paranoid
  acts_as_commentable
  acts_as_tree
  attr_reader :TYPES_NON_LITI
  attr_reader :TYPES_LITI
  attr_reader :SOURCES
  attr_reader :STATUS
  attr_accessor :matter_type_liti
  attr_accessor :matter_type_nonliti
  attr_accessor :skip_notification
  before_save :set_matter_type,:get_lead_lawyer
  after_save  :open_parent_matter#, :send_mail_to_lead_lawyer

  attr_accessor :format
  attr_accessor :sequence_seperator
  attr_accessor :matter_id_flag
  belongs_to :opportunity
  belongs_to :company
  belongs_to :contact

  belongs_to :user, :foreign_key => :employee_user_id
  belongs_to :phase

  belongs_to :liti_type ,  :foreign_key=>:matter_type_id, :class_name=>"TypesLiti"
  belongs_to :nonliti_type ,  :foreign_key=>:matter_type_id, :class_name=>"TypesNonLiti"
  belongs_to :matter_status, :foreign_key => :status_id, :class_name=>"MatterStatus"
  belongs_to :account

  has_many :time_entries , :class_name=>"Physical::Timeandexpenses::TimeEntry"
  has_many :expense_entries, :class_name=>"Physical::Timeandexpenses::ExpenseEntry"

  has_many :tne_invoice_time_entries
  has_many :tne_invoice_expense_entries

  has_many :matter_billings
  has_many :matter_retainers

  has_many :tne_invoices
  has_many :children, :foreign_key => :parent_id, :class_name => "Matter"

  has_many :folders,  :as => :mapable


  has_many :matter_tasks
  has_many :matter_issues
  has_many :matter_facts
  has_many :matter_peoples
  has_one :matter_termcondition
  has_many :matter_researches
  has_many :matter_risks

  has_many :document_homes, :as => :mapable
  has_many :client_document_homes,:class_name => "DocumentHome", :as => :mapable,  :conditions => "upload_stage = 2 and sub_type is null"
  has_many :employee_document_homes,:class_name => "DocumentHome", :as => :mapable,  :conditions => "upload_stage != 2 and sub_type is null", :order=>'document_homes.created_at desc'

  delegate :account_name, :to => :contact
  delegate :account, :to => :contact
  #strip_attributes!
  has_many :matter_litigations
  has_many :matter_access_periods
  #before_validation "self.name.strip!",:set_null_if_blank
  validates_presence_of :name,:message=>:title_msg
  validates_presence_of :employee_user_id
  validates_presence_of :matter_category
  validates_presence_of :contact_id,:message=>:title_contact_msg

  validates_presence_of :matter_no,:message=>:matter_id_presence_msg
  validates_uniqueness_of :matter_no, :scope => :company_id,:message=> :matter_id_msg


#    Retainer fee translation missing: us_2, activerecord, errors, models, matter, attributes, retainer_fee, greater_than
#    Min retainer fee translation missing: us_2, activerecord, errors, models, matter, attributes, min_retainer_fee, greater_than

  validates_numericality_of :retainer_fee, :greater_than => 0, :allow_blank => true
  validates_numericality_of :min_retainer_fee, :greater_than => 0, :allow_blank => true

  validate :check_retainer_fee

  validate :check_if_completeable
  accepts_nested_attributes_for :matter_litigations,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } },
    :allow_destroy => true

  named_scope :matter_ids, lambda {|matters|
    {:conditions=>["id IN (?)", matters], :order =>'company_id, status_id DESC', :include => [:user, :contact, :matter_billings, :matter_retainers]}
  }
  # find records with same company,usage:- Matter.same_company(company_id)
  named_scope :same_company_and_employee_user_id, lambda { |company_id,user_id|
    {:joins => [:user, {:contact => :accounts}], :conditions => { :company_id => company_id, :employee_user_id => user_id} }
  }

  named_scope :with_status, lambda { |status|
    { :conditions => { :status_id => status } }
  }

  named_scope :with_order, lambda { |order|
    { :order=>order }
  }
  named_scope :letter_search, lambda { |letter|
    unless letter.nil?
      { :conditions => ["UPPER(matters.name) like ?",letter+'%']}
    end
  }

  named_scope :get_matter_records,lambda{|get_comp_id, get_employee_user_id| {:joins=>:matter_peoples, :conditions => ["matter_peoples.company_id = ? AND matter_peoples.employee_user_id IS NOT NULL AND matter_peoples.employee_user_id = ? AND matter_peoples.deleted_at is NULL", get_comp_id, get_employee_user_id], :order => "name "}}

  def account_name
    if self.contact.accounts[0]
      self.contact.accounts[0].name
    end
  end

  def account
    if self.contact.accounts[0]
      self.contact.accounts[0]
    end
  end

  def set_null_if_blank
    self.matter_no=nil if self.matter_no.blank?
  end

  def matter_name_initials(matter_name)
    matter_name.strip.scan(/(^\w|\s\w)/).flatten.to_s.gsub(/\s/,".")
  end
  def primary_matter_contact
    self.matter_peoples.primary_contact.first
  end

  def accessible_client_document_homes(euid)
    @mp = employee_matter_people(euid)
    docs = []
    if euid == self.employee_user_id || @mp.can_view_client_docs?
      docs = self.client_document_homes
    else
      self.client_document_homes.each do|e|

      end
    end
  end

  # Return contacts associated to the primary contact's account if any.
  def get_account_contacts
    acontacts = self.contact.accounts[0].present? ? (self.contact.accounts[0].contacts - [self.contact]) : []
    clientcontacts = self.matter_peoples.client_contacts
    acontacts - clientcontacts.collect(&:contact)
  end

  def client_contacts
    self.matter_peoples.client_contacts
  end

  def matter_start_date
    self.matter_date || self.created_at
  end

  # Returns true if this matter is shared with the client.
  def shared_with_client?
    self.access_rights && self.access_rights.to_i == 4
  end

  def my_role_expired?(euid)
    @my_role_expired ||=MatterPeople.me(euid, self.id, self.company_id).expired?
  end
  def my_role_begin?(euid)
    @my_role_begin ||=MatterPeople.me(euid, self.id, self.company_id).not_yet_started?
  end

  # Returns true IF atleast one fact/risk is associated with this matter.
  # This is used to allow edit of litigation type for matter, If no risk/fact
  # was associated with this matter.
  def fact_or_risk_associated?
    (self.matter_risks.count + self.matter_facts.count) > 0
  end

  # Set matter data from opportunity.
  def set_opportunity(cid, opp_id)
    unless opp_id.nil?
      opp = Opportunity.scoped_by_company_id(cid).find(opp_id)
      self.opportunity_id = opp.id
      if self.name.nil?
        self.name = opp.name
      end
      self.contact_id = opp.contact_id
      self.estimated_hours = opp.estimated_hours
    end
  end

  def my_matter_people_entry(euid)
    self.matter_peoples.find_all {|e| e.employee_user_id == euid}[0]
  end

  def my_role_expired?(euid)
    self.my_matter_people_entry(euid).expired?
  end

  def check_retainer_fee
    if min_retainer_fee.present? && retainer_fee.present?
      #self.errors.add_to_base(:min_retainer_cannot_be_greater_than_retainer_fee) if min_retainer_fee > retainer_fee
      # FIXME: above did not work!
      self.errors.add_to_base("Minimum Retainer Fee cannot be greater than Retainer Fee") if min_retainer_fee > retainer_fee
    end
  end

  # Validates if the matter can be marked as completed.
  def check_if_completeable
    if !self.new_record? and self.completed?
      chld = Matter.find_all_by_parent_id(self.id)
      chld_not_cmplt = false
      chld.collect{|c| chld_not_cmplt = true if !c.completed? } unless chld.blank?
      if self.any_child_open?
        self.errors.add_to_base("This matter has linked child matter(s) that are still open. Please close the same first.")
      elsif self.open_todos.size > 0
        self.errors.add_to_base("Could not complete the matter: there are some incomplete tasks in the matter.")
      elsif chld_not_cmplt
        self.errors.add_to_base('This matter has linked child matter(s) that are still open. Please close the same first.' )
      end
    end
  end

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search,conditions_hash,include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash],:order => "name asc")
    find(:all, include_hash )
  end

  STATUS = [ "Completed", "Open" ]
  SOURCES = [ "", "Email", "Letter", "Fax", "Client", "Other" ]

  def set_matter_type
    if self.matter_category.eql?("litigation")
      self.matter_type_id = self.matter_type_liti unless self.matter_type_liti.blank?
    elsif self.matter_category.eql?("non-litigation")
      self.matter_type_id = self.matter_type_nonliti unless self.matter_type_nonliti.blank?
    end
  end



  # Returns the total billed amount till date. Skips entries from the table where
  # they are made for additional payments to the otiginal bill.
  # implemented ignore cancel bills in total bill amount as suggested by Varun Sir Done by ganesh 28072011
  def total_bill_amount
    bills = self.matter_billings.all(:conditions => ["id = bill_id"])
    tot = 0
    bills.each do |e|
       if e.matter_billing_status && e.matter_billing_status.lvalue != 'Cancelled'
        tot += nil2zero(e.bill_amount)
       end
    end
    return tot
  end

  # Return true of any of the child matters for this matter is open, false otherwise.
  def any_child_open?
    return (self.children.all :joins => "INNER JOIN company_lookups ON company_lookups.id = status_id", :conditions => "company_lookups.id=#{self.status_id}  AND company_lookups.lvalue='Open'").size > 0
  end


  # Returns the total billed/or paid against that bill (if it was settled)
  # amount till date. Skips entries from the table where they are made for
  # additional payments to the original bill.
  # implemented ignore cancel bills in total_adjusted_bill_amoun as suggested by Varun Sir Done by ganesh 28072011
  def total_adjusted_bill_amount
    bills = self.matter_billings.all(:conditions => ["id = bill_id"])
    tot = 0
    bills.each do |e|
      if e.matter_billing_status.lvalue == 'Settled'
        tot += e.computed_bill_amount_paid
      else
         if e.matter_billing_status.lvalue != 'Cancelled'
          tot += e.bill_amount
         end
      end
    end
    return tot
  end
 
  #returns [sum of settled bills + sum paid for all open bills]
  # implemented ignore cancel bills in amt_paid_and_settled_bills as suggested by Varun Sir Done by ganesh 28072011
  def amt_paid_and_settled_bills
    bills = self.matter_billings.all(:conditions => ["id = bill_id"])
    tot = 0
    bills.each do |e|
       if e.matter_billing_status.lvalue != 'Cancelled'
        tot += e.computed_bill_amount_paid
       end
    end
    return tot
  end

  #return sum of settled bills + sum paid for all open bills
  def amt_available_for_bill_payment_or_settlement
    return self.amount_received_till_date-amt_paid_and_settled_bills    
  end

  # Returns only bills entries (skipping the payment entries against the bills).
  def get_bills
    self.matter_billings.all(:conditions => ["id = bill_id"])
  end

  # Returns only those bill amount total which are open.
  def open_bills_total
    tot = 0
    count = 0
    bills = self.matter_billings.all(:conditions => ["id = bill_id"])
    bills.each do |e|
      if e.matter_billing_status.lvalue == 'Open' || e.matter_billing_status.lvalue=='Finalized' || e.matter_billing_status.lvalue=='Sent to Client'
        tot += nil2zero(e.bill_amount)
        count += 1
      end
    end
    return [count, tot]
  end

  def client_documents_for_assignee_lawyer(euid)
    DocumentHome.find_all_by_mapable_type_and_mapable_id_and_upload_stage("Matter", self.id, 2)
  end

  def document_homes_from_client
    DocumentHome.find_document_homes_for_matter('Matter', self.id)
  end


  # Returns the bill amount total till date for only settled bills.
  def settled_bills_total
    tot = 0
    count = 0
    bills = self.matter_billings.all(:conditions => ["id = bill_id"])
    bills.each do |e|
      if e.matter_billing_status && e.matter_billing_status.lvalue == 'Settled'
        tot += nil2zero(e.computed_bill_amount_paid)
        count += 1
      end
    end
    return [count, tot]
  end

  #-------------END-----------------

  def get_terms_of_engagement
    DocumentHome.find_toe_document_home_for_matter('Matter',self.id)
  end

  # Returns total amount received from the client till date.
  def amount_received_till_date
    tot = 0
    self.matter_retainers.each {|e| tot += nil2zero(e.amount)}

    tot
  end


  # Returns credit amount calculated for this matter. This is the difference
  # between amount received from client and adjusted billed amount total.
  def credit_amount
    self.amount_received_till_date - self.total_adjusted_bill_amount
  end

  # Used for sphinx indexing.
  define_index do
    set_property :delta => true
    indexes :name, :as => :matter_name, :prefixes => true
    indexes [user.first_name, user.last_name ], :as => :user_name, :prefixes => true
    indexes [contact.first_name, contact.middle_name, contact.last_name], :as => :contact_name, :prefixes => true
    indexes contact.accounts.name, :as => :account_name, :prefixes => true
    indexes :matter_no, :as => :matter_id, :prefixes => true
    indexes :ref_no, :as => :referance_id, :prefixes => true
    indexes liti_type.lvalue, :as => :matter_category, :prefixes => true
    indexes nonliti_type.lvalue, :as => :nonlitigation_type, :prefixes => true
    has :id, :company_id
  end

  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

  # Returns the matters which are shared with client.
  def self.client_accessible(page, client_ids, status)
    # NEW LOGIC!
    # Show matters for primary matter contact and all client contacts who can access the matter.
    client_entries = MatterPeople.all(:conditions => ["(people_type = 'client_contact' OR people_type = 'matter_client') AND can_access_matter  AND contact_id in (?)", client_ids])
    client_matter_ids = client_entries.collect(&:matter_id)
    paginate(:page => page,
      :conditions => ["id IN (?) AND status_id = ?",
        client_matter_ids,
        status],
      :per_page => 10,
      :order=> 'created_at DESC')
  end

  #  def document_homes(filter='other')
  #    if filter=='client'
  #      DocumentHome.all(:conditions => ["mapable_type = ? AND mapable_id = ? and upload_stage = 2",'Matter',self.id ], :order=> 'created_at DESC')
  #    else
  #      DocumentHome.all(:conditions => ["mapable_type = ? AND mapable_id = ? and upload_stage != 2",'Matter',self.id  ], :order=> 'created_at DESC')
  #    end
  #
  #  end


  # Returns the comments for this matter's tasks that were entered by client.
  def client_comments
    comments = []
    self.my_matter_tasks(get_employee_user_id).collect {|e| comments << e.comments}
    comments = comments.flatten.uniq.find_all {|e| e.title == "MatterTask Client" || e.title == "Client_Task_Comment"}
    unread = []
    read = []
    comments.each {|e|
      if e.is_read.nil? or e.is_read == false
        unread << e
      else
        read << e if (e.created_at >= (Time.zone.now.to_date-1.day))
      end
    }
    [unread,read]
  end

  # Returns the count of documents uploaded by the client.
  def get_client_doc_count
    self.client_documents.size
  end

  def is_accessible_to_me?(euid, cid)
    return true if self.employee_user_id == euid
    self.matter_peoples.all(:conditions => ["employee_user_id = ?", euid]).size > 0
  end

  # Saves matter and create a new contact entry if needed.
  def self.save_with_contact_and_opportunity(params, euid, opp_id)
    # Name: Mandeep Singh
    # Date: Sep 9, 2010
    # Transaction purpose: Creates the matter record and updates the associated
    #  contact record. Also creats the client (contact's) entry in matter peoples
    #  table. Then creates lead lawyer entry in matter peoples table. If the login
    #  lawyer is not lead lawyer and a role was chosen for him add another entry
    #  for him as the specified role in matter peoples table.
    # Tables affected: matters, conatcts, matter_peoples
   # begin
      #Matter.transaction do
      company = User.current_company
      @matter = company.matters.new(params["matter"])
      @matter.created_by_user_id = User.current_user.id
      if @matter.valid?
        # There is no error in the matter record...
        # Now, also create a matter people entry for the client.
        #          :role => TeamRoles.role_from_name("Matter Client"),
        if params["matter"]["client_access"]
          @access_matter=true
        else
          @access_matter=false
        end
        
        matter_client = @matter.matter_peoples.new({
            :contact_id => @matter.contact_id,
            :name => @matter.contact.try(:full_name),
            :is_active => true,
            :people_type => 'matter_client',
            :matter_team_role_id => @matter.company.client_roles.array_hash_value('lvalue','Matter Client','id'),
            :matter_id => @matter.id,
            #:start_date => Time.zone.now.to_date,
            :created_by_user_id => @matter.created_by_user_id,
            :company_id => @matter.company_id,
            :can_access_matter => @access_matter,
            :email => params["contact"].present? ? params["contact"]["email"] : '',
            :phone => @matter.contact.try(:phone)
          })
        if matter_client.valid?
          @matter.matter_litigations.each {|e| e.company_id = @matter.company_id}
          @matter.save
          @matter.set_opportunity(company.id, opp_id)
          matter_client.matter_id = @matter.id
          matter_client.contact_id = @matter.contact_id
          matter_client.save
          @matter.create_lead_lawyer.save
          @matter.create_lawyer_entry(euid, params)
          @matter.skip_notification = true
          @matter.save
          matter_peoples = MatterPeople.find_all_by_matter_id(@matter.id)
          matter_peoples.each do |matter_people|
            matter_people.matter_access_periods.build(:matter_id => @matter.id,:start_date => matter_people.start_date,:end_date => matter_people.end_date, :company_id => @matter.company_id, :employee_user_id => matter_people.employee_user_id, :is_active => matter_people.is_active).save!
          end
           @matter.contact.assigned_to_employee_user_id = euid
          @matter.contact.save(false) #end(:update_without_callbacks)
        else
          matter_client.errors.each do|e|
            @matter.errors.add(e[0], e[1])
          end
          return @matter, false
        end
        return @matter, true
      else
        [@matter, false]
      end
      #end
    rescue Exception => exc
      logger.info("Matter Creation Error : #{exc.message}")
      @matter.errors.add_to_base("DB Store Error: #{exc.message}")
      [@matter, false]
    end

  # Create lead lawyer's entry in matter peoples.
  def create_lead_lawyer
    
    lead_lawyer = self.matter_peoples.new({
        :employee_user_id => self.employee_user_id,
        :people_type => 'client',
        :created_by_user_id => self.created_by_user_id,
        :matter_id => self.id,
        :is_active => true,
        :matter_team_role_id => self.company.client_roles.array_hash_value('lvalue','Lead Lawyer','id'),
        :start_date => self.matter_start_date,
        :company_id => self.company_id
      })

    lead_lawyer
  end

  # If the current lawyer is not the lead lawyer, add him in law team with
  # specified role.
  def create_lawyer_entry(euid, data)
    lawyer_id = euid
    lead_id = data["matter"]["employee_user_id"].to_i
    # If Current lawyer is not the lead lawyer in this matter...
    # Then we have to add this lawyer in the matter team with the
    # specified role.
   
    if lead_id.to_i != lawyer_id.to_i && !data["lawyer"]["role"].blank?
      lawyer_entry = self.matter_peoples.new({
          :employee_user_id => lawyer_id,
          :people_type => 'client',
          :matter_id => self.id,
          :is_active => true,
          :matter_team_role_id => data["lawyer"]["role"],
          :created_by_user_id => self.created_by_user_id,
          :company_id => self.company_id
        })
      lawyer_entry.start_date = Time.zone.now.to_date
      lawyer_entry.save
    end
  end

  # For array level sorting of matter records.
  def <=>(o)
    self.name <=> o.name
  end

  # Returns the lead lawyer's name.
  def get_lawyer_name
    if self.employee_user_id
      if self.user
        self.user.try(:full_name).try(:titleize)
      end
    else
      ''
    end
  end

  # Returns only those matter records for which the current lawyer is lead lawyer.
  def self.find_my_matters(employee_user_id, company_id,params, perpage)
    search = "1=1" #required
    search += set_filter_conditions(params)
    if params[:matter_status]
      self.same_company_and_employee_user_id(company_id,employee_user_id).with_status(params[:matter_status]).with_order(params[:order]).letter_search(params[:letter]).paginate(:page => params[:page], :per_page => perpage, :conditions => search,
        #:include=>[{:matter_tasks=>:comments},:client_document_homes,:parent]
        :select => "Distinct matters.*, matters.name as matter_name, coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins => "LEFT OUTER JOIN matter_tasks ON matter_tasks.matter_id = matters.id
                   LEFT OUTER JOIN comments ON comments.commentable_id = matter_tasks.id AND comments.commentable_type = 'MatterTask'
                   LEFT OUTER JOIN document_homes ON document_homes.mapable_id = matters.id AND document_homes.mapable_type = 'Matter'AND upload_stage = 2 and sub_type is null
                   LEFT OUTER JOIN matters parents_matters ON parents_matters.id = matters.parent_id"
      )
    else
      self.same_company_and_employee_user_id(company_id,employee_user_id).with_order(params[:order]).letter_search(params[:letter]).paginate(:page => params[:page], :per_page => perpage, :conditions => search,
        #:include=>[{:matter_tasks=>:comments},:client_document_homes,:parent]
        :select => "Distinct matters.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins => "LEFT OUTER JOIN matter_tasks ON matter_tasks.matter_id = matters.id
                   LEFT OUTER JOIN comments ON comments.commentable_id = matter_tasks.id AND comments.commentable_type = 'MatterTask'
                   LEFT OUTER JOIN document_homes ON document_homes.mapable_id = matters.id AND document_homes.mapable_type = 'Matter'AND upload_stage = 2 and sub_type is null
                   LEFT OUTER JOIN matters parents_matters ON parents_matters.id = matters.parent_id"
      )
    end
  end


  def self.set_filter_conditions(params)
    conditions = ""

    if params[:search_items] and search = params[:search]
      hash = {}
      search.each do |key,value|

        next if search[key].blank?
         search[key] =search[key].gsub(/[']/,"''")  if search[key]
        if key == "matters.matter_date"
          begin
            search[key] = Date.parse(search[key])
            conditions += "AND #{key} = '#{search[key]}' "
          rescue Exception => e
            hash[key.sub(".","--")] = ""
            p e
            next
          end
        elsif key == "contacts.last_name"
          if search[key]
             search[key].split.each_with_index do |value,index|
                conditions += " AND  (contacts.first_name ILIKE E'%#{value}%'or contacts.middle_name ILIKE E'%#{value}%' or contacts.last_name ILIKE E'%#{value}%' )"
# or contacts.last_name || 	contacts.middle_name || contacts.first_name ILIKE '%#{value}%') "
             end
          else
            conditions += " AND  (concat(contacts.first_name ,concat(' ', contacts.last_name)) ILIKE E'%#{value.strip}%')"
          end
        elsif key == "users.username"
          if search[key]
             search[key].split.each_with_index do |value,index|
          conditions += " AND  (users.first_name ILIKE E'%#{value}%' or users.last_name ILIKE E'%#{value}%') "
             end
          else
          conditions += " AND  (concat(users.first_name ,concat(' ', users.last_name)) ILIKE E'%#{value.strip}%')"
          end
        else
          conditions += " AND #{key} ILIKE E'%#{search[key].strip}%' "
        end

        hash[key.sub(".","--")] = search[key]
      end
      params[:search] = hash
    end
    conditions
  end


  # Returns only those matter records from matter table where the current
  # lawyer is either a lead lawyer or law team member.
  def self.find_my_all_matters(employee_user_id, company_id, params, perpage)
    search = set_filter_conditions(params)
    matter_peoples = MatterPeople.all(:conditions => ["company_id = ? AND employee_user_id IS NOT NULL AND employee_user_id = ? AND is_active = ?", company_id, employee_user_id, true], :order => 'created_at ASC')
    if params[:matter_status].nil?
      self.letter_search(params[:letter]).paginate(:page=>params[:page], :per_page=>perpage,
        :select => "Distinct matters.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins =>"LEFT OUTER JOIN contacts ON contacts.id = matters.contact_id
                  LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                  LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                  LEFT OUTER JOIN users ON users.id = matters.employee_user_id",
        :conditions=>["matters.id in (?)and matters.company_id =? #{search}", matter_peoples.collect {|e| e.matter_id},company_id],:order=>params[:order],:include=>[:client_document_homes,:parent,:user,{:contact=>:accounts}])
    else
      self.letter_search(params[:letter]).paginate(:page=>params[:page], :per_page=>perpage,
        :select => "Distinct matters.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins =>"LEFT OUTER JOIN contacts ON contacts.id = matters.contact_id
                  LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                  LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                  LEFT OUTER JOIN users ON users.id = matters.employee_user_id",
       # :include=>[:client_document_homes,:parent,:user,{:contact=>:accounts}],
        :conditions=>["matters.id in (?) and matters.status_id in (?) and matters.company_id =? #{search}", matter_peoples.collect {|e| e.matter_id},params[:matter_status],company_id],:order=>params[:order])
    end
    #    self.letter_search(params[:letter]).find(:all,:include =>[:user,{:contact=>:accounts}],:conditions=>["matters.id in (?)and matters.company_id =?", matter_peoples.collect {|e| e.matter_id},company_id],:order=>params[:order])
  end




  def self.find_all_matters(employee_user_id, company_id, params, perpage)
    search = set_filter_conditions(params)
    if params[:matter_status].nil?
      self.letter_search(params[:letter]).paginate(:page=>params[:page], :per_page=>perpage,
        :select => "DISTINCT matters.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins =>"LEFT OUTER JOIN contacts ON contacts.id = matters.contact_id
                  LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                  LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                  LEFT OUTER JOIN users ON users.id = matters.employee_user_id",
        :conditions=>["matters.company_id =? #{search}",company_id],:order=>params[:order])
    else
      self.letter_search(params[:letter]).paginate(:page=>params[:page], :per_page=>perpage,
        :select => "DISTINCT matters.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
        :joins =>"LEFT OUTER JOIN contacts ON contacts.id = matters.contact_id
                  LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                  LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                  LEFT OUTER JOIN users ON users.id = matters.employee_user_id",
        :conditions=>["matters.status_id in (?) and matters.company_id =? #{search}",params[:matter_status],company_id],:order=>params[:order])
    end

  end

  # Returns all the matters in the employee's company where (s)he is a lead
  # lawyer in the matter.
  def self.my_matters(employee_user_id, company_id)
    self.scoped_by_employee_user_id(employee_user_id, company_id)
  end


  # Return records found by sphinx search.
  def self.search_results(cid, eid, q, star = true, matter_status = nil ,mode_type = nil, show_expired = true)
    case mode_type.downcase
    when 'all'
      matter_ids = Matter.all(:select => :id, :conditions => {:company_id => cid}, :order=> "created_at DESC").collect(&:id)
    when 'my_all'
      matter_ids = Matter.team_matters(eid, cid, matter_status, nil, show_expired).collect(&:id)
    when 'my'
      matter_ids = User.find(eid).matters.all(:select => :id, :conditions => ["status_id = ?", matter_status], :order => "name").collect(&:id)
    end
    if matter_ids.present?
      q = "*" + q + "*"
      # here we can use :star => true option but they it work will not produce the expected result so we have added * manually.
      # Since if we :star => reue option then q will be atomatically "*rahul* *P* *chaudhari*"
      Matter.search(q, :with => {:id => matter_ids}, :limit => 10000)
    else
      []
    end
  end

  # Returns all the matters in the employee's company where (s)he is a lead
  # lawyer in the matter or is part of the law team of matter.
  def self.team_matters(employee_user_id, company_id,matter_status=nil,column_name=nil, show_expired=false)
    condition_string = "matter_peoples.company_id = ? AND matter_peoples.employee_user_id IS NOT NULL AND matter_peoples.employee_user_id = ? AND is_active = ? AND matter_peoples.deleted_at is NULL"
    unless show_expired
      condition_string += " AND (matter_peoples.end_date is NULL OR matter_peoples.end_date > '#{Time.zone.now.to_date}')"
    end
    if column_name.nil?
      column_name = 'created_at DESC'
    end

    if matter_status && matter_status != '0'
      condition_string += " AND matters.status_id = #{matter_status}"
    end
    @matters = Matter.all(:joins => :matter_peoples, :conditions => [condition_string, company_id, employee_user_id, true], :order => "#{column_name}")
  end

  def self.active_team_matters(employee_user_id)
	  #Find Matter in which he is part of mater uptill today
	  User.find(employee_user_id).my_all_matters.all(:conditions => ["matter_peoples.end_date IS NULL OR matter_peoples.end_date >= '#{Time.zone.now.to_date}'"])
  end

  def self.firm_manager_matters(company_id,matter_status=nil,column_name=nil, show_expired=false)
    condition_string = "matter_peoples.company_id = ? AND matter_peoples.employee_user_id IS NOT NULL AND is_active = ? AND matter_peoples.deleted_at is NULL"
    unless show_expired
      condition_string += " AND (matter_peoples.end_date is NULL OR matter_peoples.end_date > '#{Time.zone.now.to_date}')"
    end
    if column_name.nil?
      column_name = 'created_at DESC'
    end

    if matter_status && matter_status != '0'
      condition_string += " AND matters.status_id = #{matter_status}"
    end
=begin
    if matter_status
#      @matters = Matter.find(:all,:joins=>:matter_peoples,:include=>[:client_document_homes,{:matter_tasks=>:comments}], :conditions => ["matter_peoples.company_id = ? and matters.status_id =? AND is_active = ? AND matter_peoples.deleted_at is NULL AND (matter_peoples.end_date is NULL OR matter_peoples.end_date > ?)", company_id,matter_status, true, Time.zone.now.to_date], :order=> "#{column_name}")
      @matters = Matter.find(:all,:joins=>:matter_peoples,:include=>[:client_document_homes,{:matter_tasks=>:comments}], :conditions => [condition_string, company_id,matter_status,employee_user_id, true], :order=> "#{column_name}")
    else
#      @matters = Matter.find(:all,:joins=>:matter_peoples,:include=>[:client_document_homes,{:matter_tasks=>:comments}], :conditions => ["matter_peoples.company_id = ? AND is_active = ? AND matter_peoples.deleted_at is NULL AND (matter_peoples.end_date is NULL OR matter_peoples.end_date > ?)", company_id, true, Time.zone.now.to_date], :order=> "#{column_name}")
      @matters = Matter.find(:all,:joins=>:matter_peoples,:include=>[:client_document_homes,{:matter_tasks=>:comments}], :conditions => ["matter_peoples.company_id = ? AND matter_peoples.employee_user_id IS NOT NULL AND matter_peoples.employee_user_id = ? AND is_active = ? AND matter_peoples.deleted_at is NULL AND (matter_peoples.end_date is NULL OR matter_peoples.end_date > ?)", company_id,employee_user_id, true, Time.zone.now.to_date], :order=> "#{column_name}")
    end
=end
    @matters = Matter.all(:select => "distinct(matters.*)", :joins => "INNER JOIN matter_peoples ON matters.id=matter_peoples.matter_id", :include =>[:client_document_homes, {:matter_tasks => :comments}], :conditions => [condition_string, company_id, true], :order => "#{column_name}")
  end

  # Returns all unexpired matters in the employee's company where (s)he is a lead
  # lawyer in the matter or is part of the law team of matter.
  def self.unexpired_team_matters(employee_user_id, company_id, date)
    Matter.find_by_sql("SELECT m.* FROM matters m
              left outer join matter_peoples mp on m.id = mp.matter_id
              WHERE (mp.employee_user_id IS NOT NULL AND mp.employee_user_id = #{employee_user_id} AND mp.is_active = 't' AND m.company_id = #{company_id}
              AND ((mp.end_date >= '#{date}' AND mp.start_date <= '#{date}') or (mp.start_date <= '#{date}' and mp.end_date is null)
              or (mp.start_date is null and mp.end_date is null))) AND mp.deleted_at IS NULL AND m.deleted_at IS NULL
              ORDER BY m.name ASC, mp.created_at ASC, mp.created_at DESC")
  end
  def self.search_team_matters(employee_user_id, company_id, date,text)
     Matter.find_by_sql("SELECT m.* FROM matters m INNER JOIN matter_peoples mp on mp.matter_id=m.id where " +
        "(mp.employee_user_id IS NOT NULL AND mp.deleted_at is null AND m.deleted_at IS NULL AND mp.employee_user_id =#{employee_user_id} AND m.company_id=#{company_id} AND mp.is_active = 't' AND " +
        "((mp.end_date >= '#{date}' AND mp.start_date <= '#{date}') or " +
        "(mp.start_date <= '#{date}' and mp.end_date is null) or " +
        "(mp.start_date is null and mp.end_date is null))) AND (m.name ILIKE '#{text}%') order by m.name")
  end

  # Returns all unexpired matters where a given contact is involved as a client.
  def self.employee_contact_matters(employee_user_id, company_id, contact_id,date)
    matters = date.nil? ? Matter.team_matters(employee_user_id, company_id).find_all {|m| m.contact_id == contact_id} : Matter.unexpired_team_matters(employee_user_id, company_id, date).find_all {|m| m.contact_id == contact_id}
    matters.sort.uniq
  end

  # Finds people in the opposite team, which are marked as primary contact
  # to be listed on matter edit page.
  def opposite_primary_contacts
    self.matter_peoples.all(:conditions => ["people_type = 'opposites' AND primary_contact = ?", true])
  end
  # Finds people in the opposite team.
  def opposite_contacts
    self.matter_peoples.all(:conditions => ["people_type = 'opposites'"])
  end

  # Returns true if this is a litigation matter, false otherwise.
  def is_litigation
    self.matter_category.eql?("litigation")
  end

  # Returns the lead lawyer entry from matter_peoples table.
  def lead_lawyer
    MatterPeople.first(:conditions =>
        ["employee_user_id = ? AND matter_id = ? AND is_active = ?", self.employee_user_id, self.id, true])
  end

  # Returns the tasks assigned to the matter client.
  def client_tasks
    self.matter_tasks.all(:conditions => {:client_task => true})
  end

  # Return tasks accessible for comments to the given lawyer.
  def comment_accessible_matter_tasks(euid)
    @mp = employee_matter_people(euid)
    team_member = self.get_team_member(euid)
    # Lead lawyer or lawyer with additional privilege of client comments can see
    # comments for all the tasks.
    if euid == self.employee_user_id || (team_member && team_member.can_view_client_comments?)
      self.matter_tasks
    else
      self.matter_tasks.all(:include => [:comments, {:matter => :contact}], :conditions => ['assigned_to_matter_people_id=?', @mp.id])
    end
  end

  # Return tasks assigned to the given lawyer.
  def my_matter_tasks(euid,order=nil, letter_search='')
    @mpid = employee_matter_people_id(euid)
    condition ="matter_tasks.assigned_to_matter_people_id = #{@mpid} "
    condition << " and upper(substr(matter_tasks.name, 1, 1)) = '#{letter_search}' " unless letter_search.blank?
    unless order.nil?
      self.matter_tasks.with_order(order).find_with_deleted(:all, :conditions => condition)
    else
      #self.matter_tasks.find_all {|e| e.assigned_to_matter_people_id == mpid}
      self.matter_tasks.find_with_deleted(:all,:include => [:comments, {:matter => :contact}], :conditions => condition)
    end
  end

  def firm_manager_tasks(order=nil, letter_search='')
    condition = "upper(substr(matter_tasks.name, 1, 1)) = '#{letter_search}' " unless letter_search.blank?
    unless order.nil?
      self.matter_tasks.with_order(order).all(:conditions => condition)
    else
      #self.matter_tasks.find_all {|e| e.assigned_to_matter_people_id == mpid}
      self.matter_tasks.all(:include => [:comments, {:matter => :contact}], :conditions => condition)
    end
  end
  # Returns open tasks assigned to the matter client.
  def client_tasks_open
    self.client_tasks.find_all {|e| (e.completed.nil? or !e.completed) if e.category.eql?('todo') }
  end

  # Returns overdue tasks assigned to the matter client.
  def client_tasks_overdue
    self.client_tasks.find_all {|e|  e.category.eql?('todo') and (e.completed.nil? or !e.completed) and e.end_date && e.end_date < Time.zone.now.utc.to_date}
  end

  # Returns upcoming tasks assigned to the matter client.
  def client_tasks_upcoming
    today = Time.zone.now.to_date
    self.client_tasks.find_all {|e| ((e.completed.nil? or !e.completed) or e.category.eql?('appointment')) and (e.end_date && e.end_date > today and e.end_date <= (today + 6.days)) }
  end

  # Returns closed tasks assigned to the matter client.
  def client_tasks_closed
    self.client_tasks.find_all {|e| e.completed and e.category.eql?('todo')}
  end

  def completed?
    self.matter_status && self.matter_status.lvalue.eql?("Completed")
  end

  # Find matter people id in current matter, for the given employee.
  def employee_matter_people_id(employee_user_id)
    @e ||= self.matter_peoples.find_all_by_employee_user_id(employee_user_id).first
    @e ? @e.id : nil
  end

  # Find matter people in current matter, for the given employee.
  def employee_matter_people(employee_user_id)
    @e ||= self.matter_peoples.find_all_by_employee_user_id(employee_user_id).first
  end

  # Returns all the tasks in the matter which are not yet completed.
  # Refactored Amar ensure that Conditions should be inside find instead of array iteration
  def open_tasks
    self.matter_tasks.open_tasks(:all, :with_deleted => true)
  end

  def open_todos
    self.matter_tasks.open_todos
  end

  # Returns all the open tasks that are to be done by today, and assigned to
  # given law team member.
  def todays_tasks(matter_people_id = nil)
    self.matter_tasks.open_tasks.assigned_tasks(matter_people_id).today(Time.zone.now.to_date)
  end

  # Returns all the open tasks that are to be done in next week, and assigned to
  # given law team member.
  def upcoming_tasks(matter_people_id = nil)
    today = Time.zone.now.to_date
    custom_days = User.current_lawyer.upcoming.setting_value.to_i
    self.matter_tasks.open_tasks.assigned_tasks(matter_people_id).upcoming(today,custom_days)
  end

  # Returns all the open tasks that were supposed to be done by today or before
  # and assigned to given law team member.
  def overdue_tasks(matter_people_id = nil)
    today = Time.zone.now.to_date
    self.matter_tasks.open_tasks.assigned_tasks(matter_people_id).overdue(today)
  end

  # Returns all the open tasks
  # and assigned to given law team member.
  def view_all_tasks(matter_people_id = nil)

    if matter_people_id
       self.matter_tasks.open_tasks.assigned_tasks(matter_people_id).find_with_deleted(:all, :conditions => "task_id IS NULL")
    else
      self.open_tasks
    end

  end

  #This method validates matter inception date so that it is not greater than present date : sania wagle
  #  def validates_inception_date
  #     self.errors.add(:matter_date,:matter_inception_date)if !self.id && self[:matter_date].present? && self[:matter_date].to_date > Time.zone.now.to_date
  #  end

  def self.get_based_on_category(tasks, category)
    task = []
      tasks.each do |t|
        task << t  if !t.category.blank? && t.category == category.to_s
      end
  end

  def self.matters_index(data, cid, euid, perpage,order=nil)
    #Because of dynamic list we need matter status id
    data[:matter_status] ||= [self.get_id_of_matter_status("Open",cid)]
    data[:order] = order.nil?? 'matters.name ASC':order
    @mode_type     =(data[:mode_type].eql?("ALL")|| data[:mode_type].nil?)? 'ALL':'MY'
    @matter_status = data[:matter_status]
    @matters       = data[:mode_type].eql?("MY") ? Matter.find_my_matters(euid, cid, data,perpage) : ( data[:mode_type].eql?("MY_ALL") ? Matter.find_my_all_matters(euid, cid, data,perpage) : Matter.find_all_matters(euid, cid,data,perpage))
  end

  def self.update_with_lead_lawyer(params, euid)
    company = User.current_company
    @matter = company.matters.find(params[:id])
    #    @matter.access_rights = 1 if params[:matter][:access_rights].nil?

    # Name: Mandeep Singh
    # Date: Sep 9, 2010
    # Transaction purpose: Updates the matter, and lead lawyer if changed. Also
    #  updates the client contact to be as client and active.
    # Tables affected: matters, matter_peoples, contacts.
    #  Matter.transaction do
    unless params[:matter][:employee_user_id].nil?
      # Change of lead lawyer.
      new_emp_usr_id = params[:matter][:employee_user_id].to_i
      old_emp_usr_id = @matter.employee_user_id
      # Is there a lead lawyer change?
      if old_emp_usr_id != new_emp_usr_id
        # Find and delete any old lead lawyer entry.
        old_lead = @matter.matter_peoples.first(:conditions =>
            ["employee_user_id = ? AND is_active = ?",
            old_emp_usr_id, true])

        old_lead.destroy unless old_lead.nil?
        # Find and delete any old membership entry.
        old_role = @matter.matter_peoples.first(:conditions =>
            ["employee_user_id = ? AND is_active = ?",
            new_emp_usr_id, true])
        old_role.destroy unless old_role.nil?

        # Now create new lead lawyer entry.
        lead_lawyer = @matter.create_lead_lawyer
      end
    end

    if params[:matter][:status].eql?("Completed")
      params[:matter][:closed_on] = Time.zone.now
    end

    params[:matter][:updated_by_user_id] = User.current_user.id


    if @matter.update_attributes(params[:matter])
      lead_lawyer.save if lead_lawyer

      @matter.contact.save(false) #end(:update_without_callbacks)
      return @matter,true
    end
    [@matter,false]
  end

  def self.get_id_of_matter_status(str,cid)
    MatterStatus.find_by_lvalue_and_company_id(str,cid).id
  end

  def current_status
    self.matter_status.lvalue if self.matter_status
  end

  # If a matter date is moved ahead, then change the matter peoples start date
  # for those entries where they fall short new date of the matter.
  def update_matter_peoples_start_date
    date = self.matter_date || self.created_at.to_date
    self.matter_peoples.lawteam_members.each do|e|
      e.update_start_date(date) if e.start_date < date
    end
    lead_lawyer = self.matter_peoples.find_by_employee_user_id(self.employee_user_id)
    if lead_lawyer.present? && lead_lawyer.start_date < date
      lead_lawyer.start_date = date
      lead_lawyer.end_date = nil
      lead_lawyer.send(:update_without_callbacks)
    end
  end
  def send_mail_to_lead_lawyer
    user = self.user
    if(@is_changed && user && user!=User.current_user)
      send_notification_to_responsible(user,self,User.current_user)
    end
  end

  def get_team_member(emp_user_id)
    self.matter_peoples.lawteam_members.first(:conditions => ["is_active = true AND employee_user_id = ?", emp_user_id])
  end

  def get_client_docs(user_id,is_firm_manager_can_access)
    conditions = "mapable_type='Matter' AND upload_stage=2 AND sub_type IS NULL"
    if(!is_firm_manager_can_access)
      conditions += " AND matter_peoples.is_active=TRUE"
    end
    conditions += " AND matter_peoples.employee_user_id = ?  AND mapable_id = ?"
    DocumentHome.all(:joins => "INNER JOIN matter_peoples ON mapable_id=matter_peoples.matter_id", :conditions => [conditions,user_id, self.id])
  end
  def can_add_people?(euid)
    team_member = self.get_team_member(euid)
    self.employee_user_id == euid || (team_member && team_member.can_control_matter_access?)
  end

  def self.find_all_matters_for_instructions(employee_user_id, company_id)
    matter_peoples = MatterPeople.all(:conditions => ["company_id = ? AND employee_user_id IS NOT NULL AND employee_user_id = ? AND is_active = ?", company_id, employee_user_id, true])
    self.all(:conditions => ["matters.id IN (?) AND matters.company_id = ?", matter_peoples.collect {|e| e.matter_id},company_id], :include => [:user, {:contact => :accounts}], :order => "name")
  end

  def self.find_matter_peoples_matters(matter_peoples)
    all :conditions=>["id IN (?)",matter_peoples.collect {|e| e.matter_id}], :order => 'name ASC'
  end

  #When parent and child both are complete and child-task is opened, parent-matter also opens -Ketki 30/05/2011
  def open_parent_matter
    if !self.completed? and self.parent_id and self.parent.completed?
      open_status_id = MatterStatus.find_by_lvalue_and_company_id('Open', self.company_id).id
      Matter.update_all({:status_id => open_status_id}, {:id => self.parent_id})
    end
  end

  def delete_matter
    Matter.transaction do
      #msg, confirm=self.check_association
      self.matter_termcondition.destroy! if self.matter_termcondition

    if self.matter_peoples.present?
      self.matter_peoples.each do |mtr_ppl|
        mtr_ppl.destroy!
      end
    end

    if self.matter_tasks.present?
      self.matter_tasks.each do |mtr_tsk|

        mtr_tsk.destroy!
      end
    end


    if self.matter_issues.present?
      self.matter_issues.each do |mtr_isu|
        check = matter_issues.find_by_sql("SELECT matter_issue_id FROM matter_issues_matter_risks WHERE matter_issue_id = #{mtr_isu.id}")
        check1 = matter_issues.find_by_sql("SELECT matter_issue_id FROM matter_issues_matter_researches WHERE matter_issue_id = #{mtr_isu.id}")
        check2 = matter_issues.find_by_sql("SELECT matter_issue_id FROM matter_issues_matter_tasks WHERE matter_issue_id = #{mtr_isu.id}")
        matter_issues.find_by_sql("DELETE FROM matter_issues_matter_risks WHERE matter_issue_id = #{mtr_isu.id}" ) if check.present?
        matter_issues.find_by_sql("DELETE FROM matter_issues_matter_researches WHERE matter_issue_id = #{mtr_isu.id}" ) if check1.present?
        matter_issues.find_by_sql("DELETE FROM matter_issues_matter_tasks WHERE matter_issue_id = #{mtr_isu.id}" ) if check2.present?
        mtr_isu.destroy_without_callbacks!
      end
    end

     if self.matter_risks.present?
      self.matter_risks.each do |mtr_rsk|
        mtr_rsk.destroy_without_callbacks!
      end
    end

     if self.matter_facts.present?
      self.matter_facts.each do |mtr_fcts|
        check = matter_issues.find_by_sql("SELECT matter_fact_id FROM matter_facts_matter_issues WHERE matter_fact_id = #{mtr_fcts.id}")
        check1 = matter_issues.find_by_sql("SELECT matter_fact_id FROM matter_facts_matter_researches WHERE matter_fact_id = #{mtr_fcts.id}")
        matter_issues.find_by_sql("DELETE FROM matter_facts_matter_issues WHERE matter_fact_id = #{mtr_fcts.id}" ) if check.present?
        matter_issues.find_by_sql("DELETE FROM matter_facts_matter_researches WHERE matter_fact_id = #{mtr_fcts.id}" ) if check1.present?
        mtr_fcts.destroy_without_callbacks!
      end
    end


    if self.matter_researches.present?

      self.matter_researches.each do |mtr_rsearch|
        check = matter_issues.find_by_sql("SELECT matter_research_id FROM matter_researches_matter_risks WHERE matter_research_id = #{mtr_rsearch.id}")
        check1 = matter_issues.find_by_sql("SELECT matter_research_id FROM matter_researches_matter_tasks WHERE matter_research_id = #{mtr_rsearch.id}")
        matter_issues.find_by_sql("DELETE FROM matter_researches_matter_risks WHERE matter_research_id = #{mtr_rsearch.id}" ) if check.present?
        matter_issues.find_by_sql("DELETE FROM matter_researches_matter_tasks WHERE matter_research_id = #{mtr_rsearch.id}" ) if check1.present?
        mtr_rsearch.destroy_without_callbacks!
      end
    end

    if self.matter_billings.present?
      self.matter_billings.each do |mtr_bill|
        mtr_bill.destroy_without_callbacks
      end
    end

    if self.matter_retainers.present?
      self.matter_retainers.each do |mtr_rtn|
        mtr_rtn.destroy_without_callbacks
      end
    end

    fin_trans = FinancialTransaction.find_all_by_matter_id_and_company_id(self.id,self.company_id)
    if fin_trans.present?
      fin_trans.each do |mtr_fin|
        mtr_fin.destroy_without_callbacks
      end
    end

    fin_acct = FinancialAccount.find_all_by_matter_id_and_company_id(self.id,self.company_id)
    if fin_acct.present?
      fin_acct.each do |mtr_acct|
        mtr_acct.destroy_without_callbacks
      end
    end

    if self.time_entries.present?
      self.time_entries.each do |time_entry|
        time_entry.destroy_without_callbacks! if time_entry.status.eql?('Open')
      end
    end


    if self.expense_entries.present?
      self.expense_entries.each do |expense_entry|
        expense_entry.destroy_without_callbacks! if expense_entry.status.eql?('Open')
      end
    end
    self.destroy_without_callbacks!
    end
  end

  def fetch_time_and_expense_max_date(employee_id)
    dates = []
    dates << time_entries.max_dates(id, employee_id).maximum(:time_entry_date)
    dates << expense_entries.max_dates(id, employee_id).maximum(:expense_entry_date)
    dates << tne_invoice_time_entries.max_dates(id, employee_id).maximum(:time_entry_date)
    dates << tne_invoice_expense_entries.max_dates(id, employee_id).maximum(:expense_entry_date)

    dates.compact.sort.last
  end


  private

  def get_lead_lawyer
    @is_changed = self.changed.include?("employee_user_id")
    true
  end

  def nil2zero(amt)
    amt.nil? ? 0 : amt
  end

  def self.import_file_type(import_type,file_name,file_format = nil,company=nil,file_to_read =nil,current_user=nil,employee_user=nil)
    # Below define variable are used to mantain invalid matters in array,invalid matters count in invalid_length,
    # valid matters count in valid_length
    @company = company
    @invalid_matters =[]
    @invalid_length=0
    @valid_length=0
    #@topic = params[:optional]? params[:optional] : nil
    if file_format=='CSV'
      ImportData::matter_process_file(file_name,file_to_read,company,current_user,employee_user)
    else
      ImportData::matter_process_excel_file(file_name,file_to_read,company,current_user,employee_user)
    end
  end
end

# == Schema Information
#
# Table name: matters
#
#  id                   :integer         not null, primary key
#  name                 :text
#  parent_id            :integer
#  brief                :text
#  is_internal          :boolean
#  contact_id           :integer
#  matter_no            :string(255)
#  ref_no               :string(255)
#  description          :text
#  matter_category      :string(255)
#  matter_type_id       :integer
#  employee_user_id     :integer
#  conflict_checked     :boolean
#  created_at           :datetime
#  updated_at           :datetime
#  estimated_hours      :integer
#  opportunity_id       :integer
#  delta                :boolean         default(TRUE), not null
#  phase_id             :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  updated_by_user_id   :integer
#  closed_on            :datetime
#  retainer_fee         :integer
#  min_retainer_fee     :integer
#  matter_date          :date
#  client_access        :boolean         default(FALSE)
#  status_id            :integer
#  sequence_no_used     :integer
#

