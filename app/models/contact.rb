class Contact < ActiveRecord::Base
  include GeneralFunction
  include ActionView::Helpers::TextHelper
  include ImportData

  # Belongs to
  belongs_to :assignee, :class_name => "User", :foreign_key => :assigned_to_employee_user_id  
  belongs_to :user
  belongs_to :company
  belongs_to :contact_stage
  belongs_to :lead_status_type,:foreign_key => :status_type
  belongs_to :prospect_status_type,:foreign_key => :status_type
  belongs_to :company_source,:foreign_key => :source
  belongs_to :salutation_type , :foreign_key => :salutation_id

  # has one
  has_one  :address, :dependent => :destroy
  has_one  :contact_additional_field, :dependent => :destroy
  
  # has_many
  # accounts
  has_many :account_contacts, :uniq => true
  has_many :accounts, :through => :account_contacts ,:validate=>true, :uniq => true
  # documents
  has_many :document_homes, :as => :mapable
  has_many :document_access_controls, :dependent => :destroy
  # opportunities
  has_many :opportunities, :dependent => :destroy
  # matters
  has_many :matters,:dependent => :destroy
  has_many :matter_tne_invoices, :through => :matters, :source => :tne_invoices
  has_many :other_matters, :through => :matter_peoples, :source => :matter
  has_many :matter_peoples
  # billing
  has_many :tne_invoices   
  # other
  has_many :activities, :as => :subject, :order => 'created_at DESC'  
  # campaigns
  has_many :members, :class_name => "CampaignMember", :dependent => :destroy
  
  liquid_methods :salutation, :first_name, :middle_name, :last_name, :nickname, :title, :informal_name ,:formal_name
  # Time & Expense
  has_many :time_entries , :class_name=>"Physical::Timeandexpenses::TimeEntry"
  has_many :expense_entries, :class_name=>"Physical::Timeandexpenses::ExpenseEntry"

  before_save :responsible_person_changed
  after_save :update_open_bills

  delegate :name, :to => "accounts[0]", :prefix => "account", :allow_nil => true
  # nested
  accepts_nested_attributes_for :address,:contact_additional_field, :allow_destroy => true
  #named scopes
  named_scope :company_id, lambda { |company_id| { :conditions=>["company_id = ?",company_id] } }
  named_scope :by_first_name ,lambda{|first_name|{:conditions => ["first_name ILIKE ? ", "%#{first_name.strip}%"] } if first_name.present? }
  named_scope :by_last_name ,lambda{|last_name|{:conditions => ["last_name ILIKE ?","%#{last_name.strip}%"] } if last_name.present? }
  named_scope :get_contact_records, lambda{|(current_company,get_comp_id)|{:conditions => ["(company_id = ? AND (status_type!=#{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id} OR status_type IS NULL))", get_comp_id], :include => [:company], :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') ASC"}}

  cattr_reader :per_page
  # validations
  validates_presence_of :first_name, :message => :first_name
  #  To validate maximum length of each field  while uploading contacts from file :Added by Pratik Jadhav/home/livia/WORKSPACE/livia_portal_bug/livia_portal/public/contacts_import_file.xls
  validates_length_of :first_name, :maximum=>64,:allow_nil => true
  validates_length_of :last_name, :maximum=>64,:allow_nil => true
  validates_length_of :email, :maximum=>64,:allow_nil => true
  validates_length_of :phone, :maximum=>15,:allow_nil => true
  validates_length_of :mobile, :maximum=>15,:allow_nil => true, :message => 'number is wrong'
  validates_length_of :fax, :maximum=>15,:allow_nil => true
  validates_length_of :nickname, :maximum=>64,:allow_nil => true
  validates_associated :accounts,:message =>:account_contact_msg
  validate :contact_details
  validates_format_of :email,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*(([A-Za-z0-9])|(\_))+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :email_format,:if => :email_present
  validate_on_update :reason_added#, :update_zimbra_contact_status
  validates_uniqueness_of :first_name, :scope=> [:last_name,:company_id],
    :case_sensitive => false, :allow_nil=>true,
    :message =>:already_system,:if=>:same_email_or_phone
  #validates_format_of :mobile, :with => /\d+/,  :message => :mobile_error,:allow_nil => true
  validate :update_delta_for_search

  before_validation :set_null_if_blank,:format_name
  after_save :update_into_zimbra
  before_destroy :destroy_zimbra_contact#,:add_deactivate_comment#,:change_stage
  after_update :save_matter_people_contact
  before_update :check_if_email_changed
  after_update :create_new_user

  acts_as_commentable
  acts_as_paranoid

  attr_accessor :lead_status, :prospect_status, :reason,:current_user_name,:user_comment,:via,:contact_id,:comment_added ,:change_bill_address

  define_index do
    set_property :delta => true
    indexes :first_name, :prefixes => true
    indexes :last_name, :prefixes => true, :sortable => true
    indexes :middle_name, :prefixes => true, :sortable => true
    indexes :email, :prefixes => true
    indexes accounts.name, :as => :contact_account_name, :prefixes => true
    has :id, :company_id, :status_type, :assigned_to_employee_user_id
    has accounts(:id), :as => :contact_account_id
    where "contacts.deleted_at is null"
  end

  # Methods for Liquid to be used in Campaign mailers ---
  def formal_name    
    salutation = self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
    format_full_name(salutation || "" , self.first_name, self.middle_name, self.last_name, self.nickname ,"formal")
  end
  
  @@per_page=25  

  def informal_name
    salutation = self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
    format_full_name(salutation, self.first_name, self.middle_name, self.last_name, self.nickname ,"informal")
  end

  def salutation
    self.company.salutation_types.find_by_id(self.salutation_id).try(:alvalue)
  end
  #---------- Liquid Ends here

  def update_open_bills
    if self.change_bill_address == "true"
      company = Company.find(self.company_id)
      contact = self
      contact_full_address = get_address
      open_non_matter_invoices , open_matter_invoices , total = Contact.get_open_invoices(company,contact)
      total_open_invoices = open_non_matter_invoices | open_matter_invoices
      total_open_invoices.each do |invoice|
        if contact.try(:accounts).blank? || contact.try(:accounts).first.try(:get_address).blank?
          invoice.client_address = contact_full_address
          invoice.send(:update_without_callbacks)
          #          invoice.update_attribute(:client_address,contact_full_address)
        end
      end
    end
  end

  def self.get_open_invoices(company,contact)
    open_status = company.tne_invoice_statuses.find_by_lvalue("Open").id
    non_matter_open_invoices = contact.tne_invoices.with_status(open_status).address_modified_status('f').find(:all,:conditions=>["tne_invoices.matter_id is null"])
    matter_open_invoices = contact.matter_tne_invoices.with_status(open_status).address_modified_status('f').find(:all,:conditions=>["tne_invoices.contact_id is null"])
    total_open_invoice = non_matter_open_invoices.count + matter_open_invoices.count
    [non_matter_open_invoices,matter_open_invoices,total_open_invoice]
  end

  def email_present
    self[:email].present?
  end
  
  def get_account_old
    self.accounts[0] || Account.new
  end

  def get_account    
    account = accounts.first 
    account || Account.new
  end

  #ToDo: please change the deactivation scenario don't delete please set status field
  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

  def open_opportunities
    closed = CompanyLookup.find_all_by_lvalue_and_company_id(["Closed/Won", "Closed/Lost"],self.company_id).collect {|e| e.id}
    self.opportunities.all(:conditions => ["stage NOT IN (?)", closed])
  end

  def name_and_account_name
    acct_name = ''
    if self.get_account
      acct_name = ", Acc: #{self.get_account.name}"
    end
    self.full_name + acct_name
  end

  def update_delta_for_search
    if !accounts.nil?
      accounts.each {|account|
        account.delta = true
        account.save(false)}
    end

    if !opportunities.nil?
      opportunities.each{ |opp|
        opp.delta = true
        opp.save(false)
      }
    end

    members.each{ |camp_mem|
      cam = camp_mem.campaign
      if cam
        cam.delta = true
        cam.save(false)
      end
    }

    matters.each{ |mat|
    	mat.delta = true
    	mat.save(false)
    }
  end

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  #sorting order changed first_name to last_name wise added by ganesh 18052011
  def self.find_for_rpt(search, conditions_hash, include_hash = {})
    include_hash.merge!(:conditions => [search,conditions_hash], :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') ASC")
    find(:all ,include_hash )
  end

  #when creating a new contact from Business Contacts,
  #column assinged is not getting updated in contacts, for updating assigned to,
  #Param assigned_to_employee_user_id added by Ganesh Dt.02052011
  def self.params_to_create_contact(params,employee_user_id,current_user_id,current_company_id)
    #params[:contact][:assigned_to_employee_user_id].blank? ?  assigned_user_id=employee_user_id :
    assigned_user_id = params[:contact][:assigned_to_employee_user_id]
    params[:contact].merge!(:employee_user_id => employee_user_id, :created_by_user_id => current_user_id, :company_id => current_company_id, :assigned_to_employee_user_id => assigned_user_id  )
    params[:account].merge!(:employee_user_id => employee_user_id, :created_by_user_id => current_user_id, :company_id => current_company_id, :assigned_to_employee_user_id => assigned_user_id) if params[:account]
    #params[:selected_list_box] == 'Lead' ? params[:contact][:status_type]= params[:contact][:lead_status] : params[:contact][:status_type]=params[:contact][:prospect_status]
    #TODO: quick fix by milind for stop creating account as 'Create New'
    if params[:account]
      params[:account].delete(:name) if params[:account][:name] == 'Create New'
    end
    params[:contact][:address_attributes].merge!(:company_id=>current_company_id)
    params[:contact][:contact_additional_field_attributes].merge!(:company_id=>current_company_id)
    if params.has_key?(:account) && params[:account][:name].present?
      if !params[:account][:name] == 'Create New'
        params[:account][:phone]= params[:contact][:phone]
        params[:account][:company_id]=current_company_id
        params[:account][:email]= params[:contact][:email]
        #removed by ganesh because this param is already added above params statement.
        #params[:account][:assigned_to_employee_user_id]=params[:contact][:assigned_to_employee_user_id]
        params[:account][:created_from]="Contacts"
      end
    end

    params
  end

  def self.params_to_update_contact(params, employee_user_id, current_user_id, current_company_id)
    params[:contact].merge!(:user_comment=>params[:comment],:updated_by_user_id=>current_user_id,:company_id=>current_company_id ,:zimbra_contact_status => true )
    params[:account].merge!(:employee_user_id=>employee_user_id,:updated_by_user_id=>current_user_id,:company_id=>current_company_id, :created_by_user_id=>current_user_id ) if params[:account]

    params
  end

  def get_zimbra_contact_location
    if (company_exists = Company.find(self.company_id))
      if company_exists.zimbra_admin_account_email
        "7"
      end
    else
      nil
    end
  end

  def update_into_zimbra
    begin
      if self.get_zimbra_contact_location and (!self.zimbra_contact_id or self.zimbra_contact_status)
        mapping_hash = {
          :first_name => 'firstName',
          :last_name => 'lastName',
          :middle_name=> 'middleName',
          :phone => 'workPhone',
          :email => 'email',
          :alt_email => 'workEmail',
          :website => 'workURL',
          :nickname => 'nickname',
          :mobile => 'mobilePhone',
          :title => 'jobTitle',
          :company => 'company',
          :department => 'department',
          :street => 'workStreet',
          :city => 'workCity',
          :country => 'workCountry',
          :zipcode => 'workPostalCode',
          :state => 'workState',

          # only for proccessing purpose
          :zimbra_contact_id => 'zimbra_contact_id'
        }

        zimbra_contact = {}
        mapping_hash.each { |key, value|
          if self[key]
            zimbra_contact[value] = self[key]
          else
            zimbra_contact[value] = self.address[key] if self.address
          end
        }
        company= Company.find(self.company_id)
        lawyer_email = company.zimbra_admin_account_email #User.find(self.employee_user_id).email
        if lawyer_email
          domain = ZimbraUtils.get_domain(lawyer_email)
          host = ZimbraUtils.get_url(domain)
          key = ZimbraUtils.get_key(domain)
          if !self.zimbra_contact_id
            location = self.get_zimbra_contact_location
            resp_hash = ZimbraContact.create(key, host, lawyer_email, zimbra_contact, location)
            self.zimbra_contact_id = (resp_hash['id'])
            self.zimbra_contact_status = false
            self.send(:update_without_callbacks)
          else
            zimbra_contact['zimbra_contact_id'] = "#{zimbra_contact['zimbra_contact_id']}"
            resp_hash = ZimbraContact.update(key, host, lawyer_email, zimbra_contact)
            self.zimbra_contact_status = false
            self.send(:update_without_callbacks)
          end

        end
      end
    rescue Exception => e
      p e
    end
  end
  
  def save_zimbra_contact(params)
    user = User.find_by_email(params[:email_add])
    if user
      self.company_id=user.company_id
      self.contact_stage_id=user.company.contact_stages.find_by_lvalue_and_alvalue("Lead","Lead").id
      self.assigned_to_employee_user_id=self.employee_user_id=self.created_by_user_id=user.id
    end    
    self.save
  end


  def same_email_or_phone
    phone_check = self[:phone].present? && (self.new_record? ? Contact.exists?(:phone=>self[:phone]) : Contact.find_by_phone(self[:phone],:conditions=>['id!= ?',self.id]).present? )
    email_check =  self[:email].present? && (self.new_record? ? Contact.exists?(:email=>self[:email]) : Contact.find_by_email(self[:email],:conditions=>['id!= ?',self.id]).present? )
    phone_check or email_check
  end

  # Its a custom Validation Which Checks whether a reason is specified when the status is changed
  def reason_added
    self.errors.add(:reason,:add_reason)if self.contact_stage_id_changed? and self.reason.blank?
  end

  def destroy_zimbra_contact
    begin
      company = Company.find(self.company_id)
      lawyer_email = company.zimbra_admin_account_email
      if lawyer_email
        domain = ZimbraUtils.get_domain(lawyer_email)
        host = ZimbraUtils.get_url(domain)
        key = ZimbraUtils.get_key(domain)        
        ZimbraContact.delete(key, host, lawyer_email, "#{self.zimbra_contact_id}")
      end
    rescue Exception => e
      p e
    end
  end

  # Its a custom Validation Which Checks whether either of email id or phone no is specified
  def contact_details
    self[:last_name] = '' if self[:last_name].nil?
    self[:middle_name] = '' if self[:middle_name].nil?
    same_email_or_phone if Contact.find_by_last_name_and_first_name_and_middle_name_and_company_id(self[:last_name], self[:first_name], self[:middle_name], self[:company_id])
    format_name
    self[:email].strip! if self[:email]
    self[:phone].strip! if self[:phone]
    self.errors.add(:email, :email_msg)if self[:email].blank? and  self[:phone].blank?
  end

  def full_info
    self.full_name + (self.email ? " #{self.email} " : ' ') + (self.phone ? "#{self.phone} " : '')
  end

  

  #--- this methods returns contacts based on the parameters passed
  #you can extend its filters by just appending conditions
  #Parameters:-
  # Params-All merged parameters,
  # Company_id-Current Company's ID,
  # User_id-Lawyers Id
  # added gsub to remove the spcial charecters from search
  # E is Added  To escaping Special Characters --sheetal 
  #changes done for DLO
  #strName=  company.last_name_first? ? "contacts.last_name" : "contacts.first_name" unless company.id.nil?
  #Changes done for last name sorting by Ganesh Dt02052011
  def self.get_contacts(params=nil, company=nil, user_id=nil)
    strName= "contacts.last_name"
    cur_user = User.find(user_id) rescue nil
    conditions = "contacts.company_id = #{company.id}"
    conditions += " AND (UPPER(#{strName}) like '#{params[:letter]}%' OR (UPPER(contacts.first_name) like '#{params[:letter]}%' AND (contacts.last_name IS NULL OR contacts.last_name = '')))"  if params[:letter].present?
    conditions = conditions+" AND contact_stage_id = #{params[:contact_type]}" if params[:contact_type].present?
    conditions = conditions+" AND contacts.assigned_to_employee_user_id = #{user_id}"  if params[:mode_type].eql?("MY") || cur_user.employee.my_contacts == true

    if params[:search_items] and search = params[:search]
      hash = {}
      search.keys.each do |key|
        next if search[key].blank?
        search[key]=search[key].gsub(/[']/,"''") if search[key]
        if key == strName
          if search[key]
            search[key].split.each_with_index do |value,index|
              conditions += "AND (contacts.first_name ILIKE E'%#{value.strip}%' OR contacts.last_name ILIKE E'%#{value.strip}%' OR contacts.middle_name ILIKE E'%#{value.strip}%')"
            end
          else
            conditions += "AND (concat(contacts.first_name, concat(' ',contacts.last_name)) ILIKE E'%#{search[key].strip}%')"
          end
        elsif key == "contacts.assigned_to_employee_user_id"
          if search[key]
            search[key].split.each_with_index do |value,index|
              conditions += "AND (users.first_name ILIKE E'%#{value.strip}%' or users.last_name ILIKE E'%#{value.strip}%') "
            end
          else
            conditions += "AND (concat(users.first_name ,concat(' ', users.last_name)) ILIKE E'%#{search[key].strip}%')"
          end
        elsif key =="contacts.contact_stage_id"
          conditions += " AND #{key} = #{search[key].strip}"
        else
          conditions += "AND #{key} ILIKE E'%#{search[key].strip}%' "
        end
        hash[key.sub(".","--")] = search[key].strip
      end
      params[:search] = hash
    end
    if params[:contact_status].present?
      self.paginate(:conditions=>conditions,
        :only_deleted=>true,
        #:include =>[:assignee,:accounts,:contact_stage,:matters,:opportunities, :company],
        :joins => "LEFT OUTER JOIN users ON users.id = contacts.assigned_to_employee_user_id
                     LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                     LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                     LEFT OUTER JOIN company_lookups ON company_lookups.id = contacts.contact_stage_id AND (company_lookups.type = 'ContactStage' )
                     LEFT OUTER JOIN matters ON matters.contact_id = contacts.id
                     LEFT OUTER JOIN opportunities ON opportunities.contact_id = contacts.id",
        :order=>params[:order],
        :page=>params[:page],
        :per_page=>params[:per_page])
    else      
      if params[:search_items]
        self.paginate(:conditions=>conditions,
          #:include =>[:assignee,:accounts, :contact_stage,:matters,:opportunities],
          :joins => "LEFT OUTER JOIN users ON users.id = contacts.assigned_to_employee_user_id
                     LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                     LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                     LEFT OUTER JOIN company_lookups ON company_lookups.id = contacts.contact_stage_id AND (company_lookups.type = 'ContactStage' )
                     LEFT OUTER JOIN matters ON matters.contact_id = contacts.id
                     LEFT OUTER JOIN opportunities ON opportunities.contact_id = contacts.id",
          :page=>params[:page],
          :per_page=>params[:per_page])
      else
        self.paginate(:conditions=>conditions,
          :select => "DISTINCT(contacts.id),contacts.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
          #:joins =>[:assignee, :accounts, :contact_stage,:matters,:opportunities],
          :joins => "LEFT OUTER JOIN users ON users.id = contacts.assigned_to_employee_user_id
                     LEFT OUTER JOIN account_contacts ON (contacts.id = account_contacts.contact_id)
                     LEFT OUTER JOIN accounts ON (accounts.id = account_contacts.account_id)
                     LEFT OUTER JOIN company_lookups ON company_lookups.id = contacts.contact_stage_id AND (company_lookups.type = 'ContactStage' )
                     LEFT OUTER JOIN matters ON matters.contact_id = contacts.id
                     LEFT OUTER JOIN opportunities ON opportunities.contact_id = contacts.id",
          :order=>params[:order],
          :page=>params[:page],
          :per_page=>params[:per_page])
      end
    end
  end

  #This method is used to activating the deactive contacts
  #parameters-current_user- current user who is logged in,tmpstatus-contacts previous sataus
  def activate_contact(current_user, params)
    begin
      self.transaction do
        status_type= self.contact_stage_id == self.company.contact_stages.array_hash_value('lvalue','Lead','id') ?  self.company.lead_status_types.find_by_lvalue("New").id : self.company.prospect_status_types.find_by_lvalue("Active").id
        self.update_attributes(:updated_by_user_id=>current_user.id,:deleted_at=>nil,:status_type=>status_type, :zimbra_contact_status => false, :zimbra_contact_id => nil)
        contact_additional_field = ContactAdditionalField.find_with_deleted(:first, :conditions => {:contact_id => self.id})
        contact_additional_field.update_attribute(:deleted_at,nil) if contact_additional_field.present?
        address = Address.find_with_deleted(:first, :conditions => {:contact_id => self.id})
        address.update_attribute(:deleted_at, nil) if address.present?
        if params.has_key?(:account_id)
          unless params[:account_id] == '0'
            acc = Account.find_with_deleted(params[:account_id])
            acc.update_attribute(:deleted_at,nil)
            self.account_contacts.find_with_deleted(:all).each{|acnt_cnt| acnt_cnt.update_attribute(:deleted_at,nil)}
          else
            acc = Account.find_with_deleted(:first,:conditions => ["primary_contact_id = ?", self.id])
            acc.update_attribute(:primary_contact_id,nil) if acc
            self.account_contacts.find_with_deleted(:all).each{|acnt_cnt| acnt_cnt.destroy!} if self.account_contacts
          end
        else
          self.account_contacts.find_with_deleted(:all).each{|acnt_cnt| acnt_cnt.update_attribute(:deleted_at,nil)}
        end

        self
      end
    rescue
      self
    end
  end

  def add_comment(user_name, created_by_user_id, action, comment)
    comment_text = " User #{user_name.try(:titleize)} has #{action} #{self.contact_stage.lvalue.try(:titleize)} #{self.full_name.try(:titleize)}.#{user_comment}"
    self.comments << Comment.new(:title => "Contact #{action}",
      :created_by_user_id => created_by_user_id,
      :commentable_id => self.id,
      :commentable_type=> 'Contact',
      :comment => comment_text )
    self.save
  end

  #it returns Contact's Account name
  def get_account_name
    if self.deleted?
      acc_cont = self.account_contacts.find_with_deleted(:first)
      if acc_cont
        account = Account.find_with_deleted(acc_cont.account_id)
      end
      account ? account.name : nil
    else
      self.accounts[0] ? self.accounts[0].name : nil
    end
  end

  #it returns Assigned to
  def get_assigned_to
    if self.assigned_to_employee_user_id
      if self.assignee
        self.assignee.full_name.try(:titleize)
      end
    end
  end

  def full_name(format = nil)
    self.last_name.blank? ? "#{self.first_name} #{(self.middle_name)}" : "#{(self.last_name)} #{self.first_name} #{(self.middle_name)}"#
  end
  alias :name :full_name

  #FIX ME
  #this is a quick fix. because i dont want to touch the above method because of the reasons below.
  #this code has been added cos the above code is shared by many modules 
  #and there is a business requirement to show name wiht "," after lastname.
  def name_for_view(format = nil)
    self.last_name.blank? ? "#{self.first_name} #{(self.middle_name)}" : "#{(self.last_name)}, #{self.first_name} #{(self.middle_name)}"#
  end

  #it Returns Formatted contact details for displaying in some drop downs
  def contact_full_details
    contact_data = "#{self.first_name}"
    contact_data += " #{self.last_name}" if self.last_name
    unless self.email.nil?
      contact_data = contact_data + ",  #{self.email}"
    else
      contact_data = contact_data + ",  #{self.phone}"
    end
    contact_data
  end

  def save_with_account(params, employee_user_id)
    ac_name = false
    begin
      Contact.transaction do
        unless params.has_key?(:activate) && params[:activate].eql?("1")
          if params[:account][:id].present?
            ac_name = true
            @account = Account.find(params[:account][:id])            
          elsif params[:account][:name].present?            
            ac_name = true
            if params[:account][:employee_user_id]==nil
              params[:account][:employee_user_id] = employee_user_id
              params[:account][:assigned_to_employee_user_id] = employee_user_id
            end
            @account=Account.new(params[:account])
            @account.valid?            
          end
          account = @account.nil? ?  true:(@account.errors.on(:name).nil?)
          if account && self.save
            #TODO: Temporary Fix by Milind -
            if ac_name == true || params[:action].eql?("link_existing_or_created_account")            
              @account[:primary_contact_id] = self.id if @account.primary_contact_id.nil?
              if @account.save(false)
                AccountContact.find_or_create_by_contact_id_and_account_id(self.id, @account.id)
              end
            end

            true
          else
            #FIXME sad code :(
            self.errors.add(" ", :account_name_already_taken_msg)  if !@account.errors.on(:name).nil?

            false
          end
        else
          contact=Contact.find_only_deleted(params[:deleted_contact_id])
          contact.update_attributes(:deleted_at=>nil)
          self.id=contact.id

          true
        end
      end
    rescue

      false
    end
  end


  #update contact with Account
  def update_with_account(params, employee_user_id)
    Contact.transaction do      
      if params.has_key?(:account)
        if params[:account][:id].present?
          self.account_contacts.each{|acnt_cnt| acnt_cnt.delete} if self.account_contacts
          account = Account.find(params[:account][:id])
          self.accounts << account
        elsif params[:account][:name].present?
          if params[:assigned_to_employee_user_id] == nil
            params[:account][:employee_user_id] = employee_user_id
            params[:account][:assigned_to_employee_user_id] = nil #employee_user_id
          end
          account = Account.new(params[:account])
          self.account_contacts.each{|acnt_cnt| acnt_cnt.delete} if self.account_contacts
          account.primary_contact_id = self.id
          if account.save
            self.accounts << account
          else
            errors = true
          end
        end
      end
      if self.update_attributes(params[:contact]) and !errors
        if self.email_changed?
          self.members.each do |campaign_member|
            campaign_member.email = self.email
            campaign_member.save!
          end
        end

        true
      else
        self.errors.add(" ","#{account.errors.full_messages}") if account and account.errors

        false
      end
    end
  end

  def last_name_blank
    self.last_name.blank?
  end

  def set_null_if_blank
    self.title=nil if self.title.blank?
    self.department=nil if self.department.blank?
    self.fax=nil if self.fax.blank?
    self.email= nil if self.email.blank?
    self.alt_email=nil if self.alt_email.blank?
    self.phone=nil if self.phone.blank?
    self.mobile=nil if self.mobile.blank?
    self.website =nil if self.website.blank?
    self.first_name=nil if self.first_name.blank?   
    self.last_name=nil if self.last_name.blank? || self.last_name.eql?('')
  end

#  def checkinactive
#    if self.deleted_at!=nil
#      true
#    else
#      false
#    end
#  end

  def has_matters?
    (matters.count + other_matters.count) > 0
  end

  # Checks the association of a contact and generates msgs for contact deactivate link
  def checkassociation(label=nil)
    confirm=''
    opp=nil
    mtr=nil
    count_opp = 0
    
    self.opportunities.each do |opp|
      count_opp += 1 if opp.stage!="closed" || opp.stage!="won"
      opp=opp if opp.stage!="closed" || opp.stage!="won"
    end
    matters.each do |mtr|
      mtr=mtr if mtr
    end
    # Ketki 19/10/2010
    if !(self.accounts.blank?) and (self.accounts.reject{|a| a if (!a.blank? and !a.primary_contact_id.blank? and !(a.primary_contact_id == self.id))}.size > 0)
      msg="Cannot Delete #{self.full_name} since its the Primary Contact of #{label} #{self.get_account_name}!"
    elsif mtr.present?
      msg="Cannot Delete this Contact since it has Matter(s) associated with it!"
      confirm=''
    elsif opp.present?
      confirm="This Contact has #{pluralize(count_opp, 'opportunity')}  associated with it! Are you sure you want to continue?"
    end
    [msg,confirm]
  end

  ## permanently delete contacts
  def checkassociationd(label=nil)
    confirmd=''
    can_delete = true
    opp=nil
    mtr=nil

    Opportunity.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |opp|
      opp=opp if opp.stage!="closed" || opp.stage!="won"
    end
    Matter.find_with_deleted(:all,:conditions=>["contact_id=#{self.id}"]).each do |mtr|
      mtr = mtr if mtr
    end

    # Ketki 19/10/2010
    if !(self.accounts.blank?) and (self.accounts.reject{|a| a if (!a.blank? and !a.primary_contact_id.blank? and !(a.primary_contact_id == self.id))}.size > 0)
      msgd="Cannot Delete \"#{self.full_name}\" since its the Primary Contact of #{label} #{self.get_account_name}!"
      can_delete = false
    elsif mtr.present?
      msgd="Cannot Delete this Contact since it has Matter(s) associated with it."
      confirm=''
      can_delete = false
    elsif opp.present?
      confirmd="Contact has a Opportunity \"#{opp.name}\" associated with it"
      can_delete = false
    end
    [msgd,confirmd,can_delete]
  end

  def lead_status; @lead_status||=self.status_type; end
  def prospect_status; @prospect_status||=self.status_type; end


  # Returns only those contacts which have at least one matter to their name.
  def self.clients(cid)
    matter_contacts = MatterPeople.all(:conditions => ["people_type = 'client_contact' OR people_type = 'matter_client' AND contact_id is NOT NULL"])
    matter_contact_ids = matter_contacts.collect(&:contact_id)
    Contact.all(:conditions => [
        "company_id = ? AND id IN (?)",
        cid, matter_contact_ids
      ])
  end

  # Added by Milind, because it was on deactivating it should check for related matter, opp etc.
  #account_contacts deactivation added by ganesh 16052011
  def deactivate_contact(current_user)
    self.updated_by_user_id=current_user.id
    msg, confirm=self.checkassociation
    self.save(false)   
    if self.account_contacts.present?
      self.account_contacts.each do |acc_cont|
        acc_cont.update_attribute(:updated_by_user_id,current_user.id)
        acc_cont.destroy
      end
    end

    if confirm.present?
      self.opportunities.each do |opp|
        opp.update_attributes(:stage => CompanyLookup.find_by_company_id_and_lvalue(self.company_id, "Closed/Lost").id, :reason => 'Contact Deactivated')
        Opportunity.destroy(opp.id)
      end
    end
    if self.members.present?
      self.members.each do |mem|
        mem.destroy!
      end
    end

    if self.matter_peoples.present?
      self.matter_peoples.each do |mp|
        mp.destroy
      end
    end
    
    Contact.destroy(self.id)
  end
  

  # This code is for permanently delete contacts
  ## Need to re factor
  def delete_contact(current_user)
    msgd, confirmd,can_delete=self.checkassociationd
    if can_delete
      AccountContact.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |acc_cont|
        acc_cont.destroy!
      end
      Address.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |address|
        address.destroy!
      end
      ContactAdditionalField.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |contact_additional_field|
        contact_additional_field.destroy!
      end
      Matter.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |mem|
        mem.destroy!
      end
      MatterPeople.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |matterpeople|
        matterpeople.destroy!
      end
      DocumentHome.find_with_deleted(:all, :conditions => ["mapable_id=#{self.id}"]).each do |doc_home|
        Document.all(:conditions => ["document_home_id=#{doc_home.id}"]).each do |doc|
          doc.destroy_without_callbacks!
        end
        doc_home.destroy_without_callbacks!
      end
      Opportunity.find_with_deleted(:all, :conditions => ["contact_id=#{self.id}"]).each do |opp|
        opp.destroy!
      end

      self.destroy_without_callbacks!
    end
  end


  def is_primary_contact
    self.accounts.each do |a|
      return true if a.primary_contact_id == self.id    
    end
    false
  end

  #Send Mail to Contact Assigned to
  def send_mail_to_associates
    user = self.assignee
    if(@is_changed && user && User.current_user!=user)
      send_notification_to_responsible(user,self,User.current_user) if user
      @is_changed = false
      true
    end
  end

  def get_address
    unless self.contact_additional_field.nil?
      (self.contact_additional_field.business_street.present?  ? " #{self.contact_additional_field.business_street} ," : ' ')  + (self.contact_additional_field.business_city.present? ? " #{self.contact_additional_field.business_city}, " : '') +
        (self.contact_additional_field.business_state.present? ? " #{self.contact_additional_field.business_state}, " : ' ')  + (self.contact_additional_field.business_country.present? ? " #{self.contact_additional_field.business_country}, " : ' ') +
        (self.contact_additional_field.business_postal_code.present? ? " #{self.contact_additional_field.business_postal_code} " : ' ')
    end
  end

  #### for searching contact on autocomplete search in communication
  def self.search_communication_contact(q,current_company,get_comp_id)
    self.find:all,
      :include=>:company,:conditions=>"(first_name ILIKE '#{q.strip}%' or last_name ILIKE '#{q.strip}%') and company_id='#{get_comp_id}'and (status_type!=#{CompanyLookup.find_by_lvalue_and_company_id("Rejected",current_company.id).id} OR status_type is null)",
      :order => "coalesce(last_name,'')||''||first_name||''||coalesce(middle_name,'') asc"
  end
  
  private

  def responsible_person_changed
    @is_changed = self.changed.include?("assigned_to_employee_user_id")
    true
  end

  # Make sure at least one user has been selected if the contact is being shared.
  #----------------------------------------------------------------------------

  def format_name
    self.first_name.gsub!(/\b[a-z]/) { |w| w.capitalize } if self.first_name
    self.last_name.gsub!(/\b[a-z]/) { |w| w.capitalize } if self.last_name
    self.middle_name.gsub!(/\b[a-z]/) { |w| w.capitalize } if self.middle_name    
    self.first_name.strip! if self.first_name
    self.last_name.strip! if self.last_name
    self.middle_name.strip! if self.middle_name

    true
  end


  def save_matter_people_contact
    matter_peoples = self.matter_peoples
    matter_peoples.each do |matter_people|
      matter_people.salutation_id = self.salutation_id
      matter_people.name = self.first_name
      matter_people.last_name = self.last_name
      matter_people.phone = self.phone
      matter_people.email = self.email
      matter_people.alternate_email = self.alt_email
      matter_people.fax = self.fax
      matter_people.mobile = self.mobile
      matter_people.company_id = self.company_id
      matter_people.created_by_user_id = self.created_by_user_id
      if self.address
        matter_people.address = self.address.street
        matter_people.city = self.address.city
        matter_people.state = self.address.state
        matter_people.country = self.address.country
        matter_people.zip = self.address.zipcode
      end

      matter_people.save
    end
  end

  #If email-id of contact is changed and  it has associated matters, client's new user would get created
  # !self.email.blank? added to prevent crash when email field updated nil. Bug 6338 - Supriya Surve
  def create_new_user
    if @email_changed && !self.email.blank?
      @email_changed = false
      can_access = false
      self.matter_peoples.collect do |mp|
        can_access = true 
      end
      if can_access
        can_access = false
        new_user = {:username => self.email, :email => self.email, :first_name => self.first_name, :last_name => self.last_name, :company_id => self.company_id, :sign_in_count=> 0}
        old_user = User.find(self.user_id) if self.user_id
        if old_user
          old_user.update_attributes(new_user)
          User.generate_and_mail_new_password_from_matter(old_user.username,old_user.email,User.current_lawyer,true)
          return 
        else
          user = User.new(new_user)
        end
        if user.send(:create_without_callbacks)
          role = Role.find_by_name('client')
          UserRole.find_or_create_by_user_id_and_role_id(user.id,role.id)
          User.generate_and_mail_new_password_from_matter(user.username,user.email,User.current_lawyer)
          self.user_id = user.id
          self.send(:update_without_callbacks)
        end
      end        
    end
  end

  #If email-id of contact is changed and  it has associated matters, client's new user would get created
  def check_if_email_changed
    @email_changed = self.changed.include?('email')
    true
  end

  def self.import_file_type(import_type,file_name,file_format = nil,company=nil,file_to_read =nil,current_user=nil,employee_user=nil)
    # Below define variable are used to mantain invalid contacts in array,invalid contacts count in invalid_length,
    # valid contacts count in valid_length
    @invalid_contacts=[]
    @invalid_length=0
    @valid_length=0
    @company = company   
    if file_format=='CSV'
      ImportData::contact_process_file(file_name,file_to_read,company,current_user,employee_user)
    else
      ImportData::contact_process_excel_file(file_name,file_to_read,company,current_user,employee_user)
    end
  end
  
end

# == Schema Information
#
# Table name: contacts
#
#  id                           :integer         not null, primary key
#  campaign_id                  :integer
#  assigned_to_employee_user_id :integer
#  first_name                   :string(64)      default("")
#  last_name                    :string(64)      default("")
#  title                        :string(64)
#  organization                 :string(64)
#  source                       :integer
#  status                       :integer
#  email                        :string(64)
#  alt_email                    :string(64)
#  phone                        :string(32)
#  mobile                       :string(32)
#  website                      :string(128)
#  rating                       :integer         default(0), not null
#  do_not_call                  :boolean         default(FALSE), not null
#  deleted_at                   :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  status_type                  :integer
#  department                   :text
#  fax                          :text
#  preference                   :string(255)
#  nickname                     :string(255)
#  delta                        :boolean         default(TRUE), not null
#  company_id                   :integer         not null
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  employee_user_id             :integer
#  reports_to                   :string(255)
#  zimbra_contact_id            :integer
#  zimbra_contact_status        :boolean
#  user_id                      :integer
#  contact_stage_id             :integer
#  salutation_id                :integer
#  source_details               :string(255)
#  middle_name                  :string(64)      default("")
#

