class Account < ActiveRecord::Base
 
  include GeneralFunction
  
  #added by surekha
  belongs_to :company
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to_employee_user_id
  has_many    :account_contacts
  has_many    :contacts, :through => :account_contacts, :validate=>true, :uniq=>true  
  has_many    :activities, :as => :subject, :order => 'created_at DESC'
  #TODO Updated by amar and viren condition is required to set association
  #May be we can use Single table inheritance
  has_many    :billingaddresses,:class_name=>'Address',:conditions => "address_type='billing'"
  has_many    :shippingaddresses,:class_name=>'Address',:conditions => "address_type='shipping'"
  has_many :document_homes, :as => :mapable
  before_validation :format_name
  validates_presence_of :name, :message=> :account_name_msg  
  validates_uniqueness_of :name,:scope => :company_id, :case_sensitive => false
  validate :update_delta_for_search  
  validate_on_create :add_primary_contact
  validates_presence_of :primary_contact_id, :on => :update, :message => :primary_contact
  validate :same_phone_check , :allow_nil => true
  accepts_nested_attributes_for :shippingaddresses
  accepts_nested_attributes_for :billingaddresses  
  attr_accessor :current_user_name,:via ,:created_from ,:change_bill_address
  acts_as_commentable
  acts_as_paranoid #for soft delete
  acts_as_tree  
  liquid_methods :name #for campaign mailer
  cattr_reader :per_page
  belongs_to :primary_contact, :class_name =>'Contact',:foreign_key=>'primary_contact_id'
  has_many :matters
  @@per_page=25
  before_save :responsible_person_changed,:set_null_if_blank
  after_save :send_mail_to_associates ,:update_open_bills_with_account

  #Used in sphinx search for updating the delta
  # Opportunities also updated as account name should be get updated for opportunities
  # As we can't add this into contact module as we have account over their which will go back into dead lock
  def update_delta_for_search
    if !contacts.nil?
      contacts.each { |cont|
        cont.delta = true
        cont.save(false)	
        if !cont.opportunities.nil?
      	  cont.opportunities.each{ |opp|
            opp.delta = true
            opp.save(false)
          }
        end        
        cont.matters.each{ |mat|
          mat.delta = true
          mat.save(false)
        }
      }
    end
  end
  
  def update_open_bills_with_account
    if self.change_bill_address == "true"
      account_id = self.id? ? self.id : 0
      company = Company.find(self.company_id)
      open_status = company.tne_invoice_statuses.find_by_lvalue("Open").id
      account_address = get_address
      new_client_address = account_address.blank? ? self.primary_contact.try(:get_address) : account_address
      sql = <<-SQL
              update tne_invoices
              set client_address = ltrim('#{new_client_address}')
              where (tne_invoice_status_id = #{open_status} and company_id = #{company.id}
              and address_modified IS NULL or address_modified = 'f') and (contact_id in
              (select contact_id from account_contacts where account_id = #{account_id}) OR
              matter_id in (select id from matters where contact_id in
              (select contact_id from account_contacts where account_id = #{account_id})));
      SQL
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def self.get_open_account_tne_invoices(company,account)
    account_id = account.id? ? account.id : 0
    open_status = company.tne_invoice_statuses.find_by_lvalue("Open").id
    sql = <<-SQL
              select count(*) from tne_invoices where (address_modified is NULL or address_modified = 'f'
              and tne_invoice_status_id = #{open_status}
              and company_id = #{company.id}) and (contact_id in
              (select contact_id from account_contacts where account_id = #{account_id}) OR
              matter_id in (select id from matters where contact_id in
              (select contact_id from account_contacts where account_id = #{account_id})));
    SQL
    result = ActiveRecord::Base.connection.execute(sql)
    total_open_invoices = result.first["count"].to_i

    total_open_invoices
  end

  def set_null_if_blank
    self.phone=nil if self.phone.blank?
    self.website =nil if self.website.blank?
  end

  # Used for sphinx search
  define_index do
    set_property :delta => true
    indexes account.name, :as => :account_name, :prefixes => true
    indexes account.website, :as => :account_website, :prefixes => true
    indexes contacts.first_name, :as => :contact_first_name, :prefixes => true
    indexes contacts.middle_name, :as => :contact_middle_name, :prefixes => true
    indexes contacts.last_name, :as => :contact_last_name, :prefixes => true
    indexes contacts.email, :as => :contact_email, :prefixes => true
    has :id, :company_id
    where "accounts.deleted_at is null "
  end

  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

  named_scope :letter_search, lambda { |letter|
    { :conditions => ["UPPER(name) like ?",letter+'%']}
  }

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search, conditions_hash, include_hash = {})
    include_hash.merge!(:conditions =>[search,conditions_hash],:order => "name asc")
    find(:all , include_hash)
  end

  def matters(status_id)
    if status_id.to_i > 0
      Matter.find(:all ,:conditions => ["status_id = ? and contact_id in (?)", status_id.to_i,self.contact_ids])
    else
      Matter.find_all_by_contact_id(self.contact_ids)
    end
  end
  
  # Validation for presence of a primary contact in a account
  def add_primary_contact
    self.errors.add('this',:primary_contact) if self.contacts.size==0 && self.primary_contact_id.blank?
  end

  #Returns accounts of a company that are assigned to a lawyer
  def self.find_my_accounts(user_id, params)
    @accounts=params[:letter].present? ? Account.scoped_by_assigned_to_employee_user_id(user_id).letter_search(params[:letter]) : Account.scoped_by_assigned_to_employee_user_id(user_id)
    params[:account_status].eql?('deactivated') ? @accounts.find_only_deleted(:all, :include => [{:contacts => [:matters, :opportunities]}, :assignee], :order => params[:order]) : @accounts.all(:include => [{:contacts => [:matters, :opportunities]}, :assignee],
      :order => params[:order])
  end

  #Returns all accounts of a company
  def self.find_all_accounts(company_id, params)
    @accounts = params[:letter].present? ? Account.scoped_by_company_id(company_id).letter_search(params[:letter]) : Account.scoped_by_company_id(company_id)
    params[:account_status].eql?('deactivated') ? @accounts.find_only_deleted(:all, :include => [{:contacts => [:matters,:opportunities]}, :assignee]) : @accounts.all(:include => [{:contacts => [:matters, :opportunities]}, :assignee], :order => params[:order])
  end

  def self.params_to_create_account(params, employee_user_id, current_user_id, current_company_id)
    params[:account][:employee_user_id], params[:contact][:via]=params[:contact][:employee_user_id]=employee_user_id,"Account"
    params[:contact][:company_id]=params[:account][:company_id]=current_company_id
    params[:account][:created_from]="Accounts"
    params[:contact][:created_by_user_id]= params[:account][:created_by_user_id]=current_user_id
    params
  end

  def self.params_to_update_account(params, employee_user_id, current_user_id, current_company_id)
    if params.has_key?(:contact)
      params[:contact][:employee_user_id]= params[:account][:employee_user_id]=params[:contact][:assigned_to_employee_user_id]= employee_user_id
      params[:contact][:company_id]=current_company_id
      params[:contact][:created_by_user_id]= current_user_id
    end
    params[:account][:updated_by_user_id]= current_user_id if params[:account]
    params
  end

  def self.params_to_add_contact(params, employee_user_id, current_user_id, current_company_id)
    params[:contact].merge!(:employee_user_id=>employee_user_id,:assigned_to_employee_user_id=>employee_user_id,:company_id=>current_company_id,:created_by_user_id=>current_user_id)
    if params[:contact].has_key?(:lead_status)
      params[:contact][:status_type] = params[:contact][:lead_status]
      params[:contact].delete_if{|key, value| key=="prospect_status"}
    else
      params[:contact].delete_if{|key, value| key=="lead_status"}
      params[:contact][:status_type] = params[:contact][:prospect_status]
    end
    params
  end

  def self.create_account_with_contact(account_name, contact_id, matter, user)
    account = Account.new
    account.name = account_name
    account.employee_user_id = user
    account.assigned_to_employee_user_id = user
    account.company_id = matter.company_id
    account.primary_contact_id = contact_id
    contact = Contact.find(contact_id)
    account.contacts << contact
    account.save
    matter.update_attribute("account_id", account.id)
  end

  #TODO amar and viren
  #we can use namescope with assocaition set in user model 
  # lambda {|last_name|  {:conditions => ["lastname =?", delete]} if last_name.present?}} 
  def self.get_accounts(params, current_company, emp_user_id, ord)
    conditions="accounts.company_id=#{current_company.id}"
    conditions << " and UPPER(accounts.name) like E'#{params[:letter]}%'"  if params[:letter].present?
    conditions << "and accounts.assigned_to_employee_user_id=#{emp_user_id}" if params[:mode_type]=='MY'
    if params[:search_items] and search = params[:search]
      hash = {}
      search.keys.each do |key|
        next if search[key].blank?
        search[key]=search[key].gsub(/[']/,"''") if search[key]
        if key == "contacts.last_name"
          if search[key]
            search[key].split.each_with_index do |value, index|
              conditions += " AND (contacts.first_name ILIKE E'%#{value.strip}%' OR contacts.middle_name ILIKE E'%#{value.strip}%' OR contacts.last_name ILIKE E'%#{value.strip}%') AND (contacts.id = accounts.primary_contact_id)"
            end
          else
            conditions += " AND (concat(contacts.first_name, concat(' ', contacts.middle_name), concat(' ', contacts.last_name)) ILIKE E'%#{search[key].strip}%')"
          end
        elsif key == "accounts.assigned_to_employee_user_id"
          if search[key]
            search[key].split.each_with_index do |value, index|
              conditions += " AND (users.first_name ILIKE E'%#{value.strip}%' OR users.last_name ILIKE E'%#{value.strip}%')"
            end
          else
            conditions += " AND (concat(users.first_name, concat(' ', contacts.middle_name), concat(' ', users.last_name)) ILIKE E'%#{search[key].strip}%')"
          end
        elsif key == "accounts.phone"
          conditions += " AND accounts.phone ILIKE E'%#{search[key].strip}%' OR accounts.toll_free_phone ILIKE E'%#{search[key].strip}%'"
        else
          conditions += " AND #{key} ILIKE E'%#{search[key].strip}%' "
        end
        hash[key.sub(".","--")] = search[key]
      end
      params[:search] = hash
    end
    self.paginate(:all, :conditions => conditions,
      :select => "DISTINCT accounts.*,coalesce(contacts.last_name,'')||''||contacts.first_name||''||coalesce(middle_name,'') #{append_value(params[:col],params[:secondary_sort])}",
      :joins => [:primary_contact],
      :include => [:assignee],
      :order => ord, :page => params[:page],
      :per_page => params[:per_page])
  end

  #Transaction block applied contacts, accounts , account_contacts -- surekha
  def save_with_contact(params, company_id)
    #Because of the logic return by the developer am doing a temporary Because before creating parent

    self.transaction do
      if params[:contact].has_key?(:id)
        contact = Contact.find(params[:contact][:id]) if params[:contact][:id].present?
        self.contacts << contact if contact
      else
        contact=Contact.new(params[:contact])
        self.contacts << contact
      end
      self.primary_contact_id = contact.id if contact
      if self.valid? && self.errors.empty?
        self.save
      else

        false
      end
    end
  end

  def self_and_all_children
    [self] + children.collect(&:self_and_all_children)
  end


  #This method update a contact with an account
  #Transaction block applied  accounts , account_contacts -- surekha
  def update_with_contact(params, company_id)
    begin
      self.transaction do
        if params[:contact] && params[:contact].has_key?(:id) && params[:contact][:id].present?          
          contact = Contact.find(params[:contact][:id])
          unless contact.accounts.length > 0
            self.contacts << Contact.find(params[:contact][:id])
          end
          params[:account].merge!(:primary_contact_id => params[:contact][:id]) unless self.primary_contact_id         
        end
        
        #:TODO Temp fix for shipping and billing addres, cod not working with address module
        # err = validate_zip_code_format(params)
        if self.update_attributes(params[:account]) #&& err.empty?
          true
        else          
          false
        end
      end
    rescue
      false
    end
  end

  def validate_zip_code_format(params)
    reg = /^\d{5}(-?\d{4})?$/   
    flg = 0
    err = {}
    badd =  params[:account][:shippingaddresses_attributes]['0']['zipcode']
    unless badd.blank?      
      err = {:shipping_zipcode => 'should be 12345-1234'} if !reg.match(badd)
      flg = 1
    end
    cadd =  params[:account][:billingaddresses_attributes]['0']['zipcode']
    unless cadd.blank?
      err.merge!({:billing_zipcode => 'should be 12345-1234'}) if !reg.match(cadd) && flg==1
      err = {:billing_zipcode => 'should be 12345-1234'} if !reg.match(cadd) && flg == 0
    end

    err
  end

  #This method returns the primary contact of an account
  def get_primary_contact
    #Modified by Ketki 19/10/2010
    first = self.primary_contact_id
    unless first.nil?
      Contact.find_with_deleted(first)
    end
  end

  #This method returns the primary contact of an account
  def get_contact_size
    acc_cnt = AccountContact.find_with_deleted(:all, :conditions => {:account_id => self.id})
    cnt=0
    unless acc_cnt.nil?
      acc_cnt.each do|ac|
        contact = Contact.find_with_deleted(ac.contact_id)
        cnt+=1 if contact.present?
      end
    end
    cnt
  end

  def get_contacts
    acc_cnt = AccountContact.find_with_deleted(:all,:conditions => {:account_id => self.id})
    contacts=[]
    acc_cnt.each do |ac|
      contacts << Contact.find_with_deleted(ac.contact_id)
    end
  end

  #Returns account  holders name
  def get_assigned_to
    if self.assigned_to_employee_user_id
      if self.assignee
        self.assignee.full_name.try(:titleize)
      end
    end
  end

  #destroys account with there dependencies
  #Transaction block applied contacts, accounts , account_contacts,opportunities -- surekha
  def destroy_with_dependent(current_user_id)    
    account.destroy
    begin
      self.transaction do
        self.update_attributes(:updated_by_user_id=>current_user_id)
        if self.account_contacts.present?
          self.account_contacts.each do |acnt_cnt|
            acnt_cnt.update_attributes(:updated_by_user_id=>current_user_id)
            acnt_cnt.destroy
          end
        end
        if self.contacts.present?
          self.contacts.each do |contact|
            contact.update_attributes(:updated_by_user_id=>current_user_id)
            contact.opportunities.each do |opportunity|
              opportunity.update_attributes(:stage => self.company.opportunity_stage_types.find_by_lvalue("Closed/Won").id, :updated_by_user_id => current_user_id)
            end
          end
        end
      end
    rescue
      false
    end
  end

  def add_deactivate_comment(object, commentable_type, current_user_id)
    object.comments << Comment.new(:title=> commentable_type + ' Deactivated',
      :created_by_user_id => current_user_id,
      :commentable_id => object.id,:commentable_type => commentable_type,
      :comment => commentable_type + " Deactivated",
      :company_id => object.company_id )
  end

  #this method checks the existence of a association for an account
  def checkassociation(label, lbl_acc= nil)
    confirm=''
    mtr=''
    opp=''
    msg=''
    AccountContact.find_with_deleted(:all, :conditions => ["account_id = ?", "#{self.id}"]).each do |acc_cont|      
      cnt = acc_cont.contact_id
      if cnt.present?
        Opportunity.find_with_deleted(:all, :conditions => ["contact_id = ?", "#{cnt}"]).each do |opp|
          opp=opp if opp.stage != "closed" || opp.stage != "won"
          break unless opp.blank?
        end
        Matter.find_with_deleted(:all, :conditions => ["contact_id = ?", "#{cnt}"]).each do |mtr|
          mtr = mtr
          break unless mtr.blank?
        end
      end      
    end
    if mtr.present?
      msg = "Cannot delete this #{lbl_acc} since a Matter  \"#{mtr.name}\" associated with it!"
      confirm=''
    elsif opp.present?
      confirm= "This #{lbl_acc} has an opportunity \"#{opp.name}\" associated with its contact! Are you sure you want to #{label}?"
    end
    [msg,confirm]
  end

  #Returns the number of opportunities for a account
  def get_opportunity_length
    length =0
    account = Account.find(self.id)
    account.contacts.each do |contact|
      if contact.present?
        if contact.opportunities.size >0
          length +=contact.open_opportunities.size
        end
      end
    end

    length
  end

  def format_name
    account_name = ""
    self.name.squeeze(" ").strip.split(" ").collect{|a| account_name += " "+a.try(:capitalize)}
    self.name = account_name.strip
  end

  #Returns the number of opportunities for a account
  def get_matter_length
    length =0
    self.contacts.each do |contact|
      next unless contact
      if contact.matters.length >0
        length +=1
      end
    end
    length
  end

  #Add a comment to a account
  def add_comment(user_name, user_id, comment)
    if comment.nil? or comment.blank?
      user_comment = ""
    else
      user_comment = " Comment: #{comment}"
    end
    comment_text = " User #{user_name.try(:titleize)} has created.#{user_comment}"
    self.comments << Comment.new(:title=> 'Account Created', :created_by_user_id => user_id, :commentable_id => self.id, :commentable_type=> 'Account', :comment => comment_text )
    self.save
  end

  #Transaction block applied contacts, accounts , account_contacts -- surekha
  def activate_account(current_user_id, params)
    account = Account.find_with_deleted(params[:id])
    if params[:contact] and !params[:contact][:id].blank?
      contact = Contact.find_with_deleted(params[:contact][:id])
      contact.update_attributes(:deleted_at => nil,:updated_by_user_id => current_user_id) if contact.deleted_at
    else
      params[:contact].merge!({:created_by_user_id => current_user_id, :company_id => account.company_id,:updated_by_user_id => current_user_id})
      contact=Contact.new(params[:contact])
      contact.save if contact.valid?
    end
    if contact.errors.empty?
      account.update_attributes(:deleted_at => nil, :updated_by_user_id => current_user_id, :primary_contact_id => contact.id)
      account.account_contacts.each{|acnt_cnt| acnt_cnt.delete} if account.account_contacts
      account.contacts << contact
      [true,""]
    else
      [false,contact.errors.full_messages]
    end   
  end

  def same_phone_check
    if (!self.toll_free_phone.blank? and !self.phone.blank?)
      errors.add(:phone, :same_phone) if self.toll_free_phone.eql?(self.phone)
    end
  end
  #Send Mail to Matter_task Associates
  def send_mail_to_associates
    user = self.assignee
    if(@is_changed && user && User.current_user!=user)
      send_notification_to_responsible(user,self,User.current_user)
      @is_changed = false

      true
    end
  end

  def get_address
    address = self.billingaddresses.find_by_address_type('billing')
    unless address.nil?
      (address.street.present?  ? " #{address.street} ," : ' ')  + (address.city.present? ? " #{address.city}, " : '') +
      (address.state.present? ? " #{address.state}, " : ' ')  + (address.country.present? ? " #{address.country}, " : ' ') +
      (address.zipcode.present? ? " #{address.zipcode} " : ' ')
    end
  end

  
  private

  def responsible_person_changed
    @is_changed = self.changed.include?("assigned_to_employee_user_id")
    true
  end

end

# == Schema Information
#
# Table name: accounts
#  id                           :integer         not null, primary key
#  employee_user_id             :integer
#  assigned_to_employee_user_id :integer
#  name                         :string(64)      default(""), not null
#  access                       :string(8)       default("Private")
#  website                      :string(64)
#  toll_free_phone              :string(32)
#  phone                        :string(32)
#  created_at                   :datetime
#  updated_at                   :datetime
#  email                        :text
#  delta                        :boolean         default(TRUE), not null
#  company_id                   :integer         not null
#  permanent_deleted_at         :datetime
#  deleted_at                   :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  parent_id                    :integer
#  primary_contact_id           :integer
#
