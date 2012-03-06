class Employee < ActiveRecord::Base
  #set_primary_key 'user_id'
  belongs_to :company
  belongs_to :user
  accepts_nested_attributes_for :user
  belongs_to :department
  belongs_to :designation
  #attr_accessor :first_name, :last_name
  attr_accessor :photo_upload, :helpdesk_role_id
  has_many :credentials, :class_name => "Physical::Clientservices::EmployeeMailCredential"
  has_many :service_provider_employee_mappings, :class_name => "Physical::Liviaservices::ServiceProviderEmployeeMappings", :foreign_key => 'employee_user_id', :dependent=>:destroy
  has_many :roles, :class_name =>"Physical::Clientservices::Role"
  has_many :tasks, :foreign_key => 'assigned_to_user_id'

  has_many :matters, :foreign_key=>'employee_user_id'
  has_many :document_access_controls, :foreign_key=>'employee_user_id'
  has_many :document_homes, :through => :document_access_controls
  has_attached_file :photo,
                    :url  => "public/images/employee_images/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/images/employee_images/:id/:style/:basename.:extension"
#  validates_attachment_content_type :photo, :content_type=>['image/jpeg', 'image/png', 'image/gif'], :allow_blank=>true
  validate :photo_content_type_error
  validates_presence_of :first_name, :message=>:first_name
  validates_presence_of :last_name
  validates_presence_of :email
  validates_presence_of :access_code
  validates_presence_of :registered_number1
#  validates_presence_of :registered_number1
#  validates_length_of :access_code, :is => 4
#  validates_numericality_of :access_code, :only_integer => true
  validates_uniqueness_of :access_code,  :scope=> ['phone']
  #validates_presence_of :designation
  validates_presence_of :designation_id
  validates_presence_of :department_id

  acts_as_paranoid
  acts_as_tree :order=>"first_name"

  #It returns list of selected company employees.
  named_scope :getemployees,lambda{|company_id|{:conditions=>['company_id = ?',company_id]}}
  
  #It returns list of selected company employees who are users also.
  named_scope :getcompanyemployeelist,lambda{|company_id|{:conditions=>['company_id = ? and user_id is not null',company_id]}}
  
  #It return list of selected company employees who doesnt have selected service provider
  named_scope :getcompanyemployeelist_not_sp,lambda{|company_id,splist|{:conditions=>['company_id = ? and user_id is not null and id not in (?)',company_id,splist]}}

  #It returns employee list of department.
  named_scope :getdepartmentemployeelist,lambda{|department|{:conditions=>["department_id in (?)",department]}}

  validates_format_of :email,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :email_msg,
    :if => :email?

  validates_uniqueness_of :first_name, :scope=> ['last_name','company_id','email'],
    :case_sensitive => false, :allow_nil=>true,
    :message =>:already_system,:if=>:same_email_or_phone

  validates_uniqueness_of :phone,  :scope=> ['first_name','company_id'],
    :case_sensitive => false, :allow_nil=>true,
    :message =>:already_system,:if=>:last_name_blank

  validates_uniqueness_of :email
  validate :helpdesk_role


  def same_email_or_phone
    Employee.find_by_phone(self[:phone]) || Employee.find_by_email(self[:email])
  end

  def last_name_blank
    self.last_name.blank?
  end
  
  #Public methods for Employee Model
  def company_lawyers
    self.all(:conditions => ['employee_of = ?', self.employee_id])
  end

  # Return deactivated user object for employee
  def deleted_user
    User.find_only_deleted(:first, :conditions => ["id = ?", self.user_id])
  end

  
  def full_employee_name
    "#{self.first_name.titleize} #{self.last_name.titleize}"
  end
  
  def full_name
    "#{self.first_name.titleize} #{self.last_name.titleize}"
  end
  
  def full_name_with_company
    "#{self.user.first_name.titleize} #{self.user.last_name.titleize}, #{self.company.name}"
  end

  def leads
    self.contacts.all(:conditions => ["status='lead'"])
  end

  def prospects
    self.contacts.all(:conditions => ["status='prospect'"])
  end

  def clients
    self.contacts.all(:conditions => ["status='client'"])
  end
  
  def company_full_name
    "#{self.company.name}"
  end

  def company
    @company ||= Company.find self.company_id
  end

  def save_with_user(params)

    if params[:is_user]
      params[:user][:first_name]  = params[:employee][:first_name]
      params[:user][:last_name]   = params[:employee][:last_name]
      params[:user][:email]       = params[:employee][:email]
      params[:user][:phone]       = params[:employee][:phone]
      params[:user][:mobile]      = params[:employee][:mobile]
      params[:user][:company_id]  = params[:company_id]
      params[:user][:department_id]  = params[:employee][:department_id]
      params[:user][:parent_id] = params[:employee][:parent_id] 
      params[:user][:time_zone] = params[:user][:time_zone]
      @user = User.new(params[:user])
      reg = /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/
      unless @user.valid?
        unless reg.match(params[:user][:password])
          self.errors.add("Password Field:","Password should be of minimum 8 characters with atleast 1 small letter, 1 caps, 1 numeric and 1 special characer")
          return false
        end

        self.valid?
        @user.errors.each{|attr,msg| self.errors.add(attr,msg)}
        return false
      else
        unless reg.match(params[:user][:password])
          self.errors.add("Password Field:","Password should be of minimum 8 characters with atleast 1 small letter, 1 caps, 1 numeric and 1 special characer")
          return false
        end
        if (self.valid? && self.errors.count==0)
          Employee.transaction do     # Added By - Hitesh
            @user.save
            self.user_id = @user.id    
            @role = Role.find_by_name('lawyer')
            @userrole = UserRole.find_or_create_by_user_id_and_role_id(@user.id,@role.id)
            self.save
          end
          return true
        else
          return false
        end        
      end
    else      
      if self.save
        return true
      else        
        return false
      end
    end

  end



  def update_with_user(id,params)
      params[:employee][:first_name] = params[:employee][:first_name].strip
      params[:employee][:last_name] = params[:employee][:last_name].strip
      params[:user][:first_name]  = params[:employee][:first_name].strip!
      params[:user][:last_name]   = params[:employee][:last_name].strip!
      params[:user][:email]       = params[:employee][:email]
      params[:user][:phone]       = params[:employee][:phone]
      params[:user][:mobile]      = params[:employee][:mobile]    
      params[:user][:company_id]  = params[:company_id]
      params[:user][:department_id]  = params[:employee][:department_id]
      params[:user][:parent_id] = params[:employee][:parent_id]
      params[:user][:time_zone] = params[:user][:time_zone]
      @employee = Employee.find(id)
      Employee.transaction do     # Added By - Hitesh
        @employee.update_attributes(params[:employee])      
        if params[:is_user]
          @user =  User.create(params[:user])
          if @user.save
            @employee.update_attributes(:user_id => @user.id)
            @role = Role.find_by_name('lawyer')
            @userrole = UserRole.find_or_create_by_user_id_and_role_id(@user.id,@role.id)
          else
            
            @user.errors.each do |obj, val|
              @employee.errors.add_to_base(obj + ' ' + val)
            end
            return @employee, false
          end
        elsif @employee.user_id
          # Removed conditions for security questions on 22/11/10 by anil
          #@employee.user.update_attributes(:first_name=>params[:employee][:first_name],:last_name=>params[:employee][:last_name],:email=> params[:employee][:email],:phone => params[:employee][:phone],:mobile => params[:employee][:mobile],:parent_id=>params[:employee][:parent_id],:department_id=>params[:employee][:department_id],:security_question=>params[:user][:security_question],:security_answer=>params[:user][:security_answer],:alt_email=>params[:user][:alt_email]) if !params[:user][:alt_email].blank?
          @employee.user.update_attributes(:first_name    => params[:employee][:first_name],
                                           :last_name     => params[:employee][:last_name],
                                           :email         => params[:employee][:email],
                                           :phone         => params[:employee][:phone],
                                           :mobile        => params[:employee][:mobile],
                                           :parent_id     => params[:employee][:parent_id],
                                           :department_id => params[:employee][:department_id],
                                           :time_zone => params[:user][:time_zone],
#                                           :security_question => params[:user][:security_question],
#                                           :security_answer => params[:user][:security_answer],
                                           :username => params[:user][:username],
                                           :alt_email => params[:user][:alt_email])
        end

        if @employee.user.present? && @employee.user.errors.length > 0
            @employee.user.errors.each do |obj, val|
              @employee.errors.add_to_base(obj + ' ' + val)
            end
        end
        if @employee.errors.length > 0
          return @employee, false
        else
          return @employee, true
        end
      end
  end




  def first_name_with_designation
    "#{self.first_name}"
  end

  # returns employees belonging to a cluster
  def self.get_cluster_employees(cluster_id)
    all(:include => :user, :conditions => ["users.cluster_id = ?", cluster_id.to_i])
  end

  def self.get_employees(params)
    conditions = ""
    unless params[:search][:name] == ""
      names = params[:search][:name].strip.split
      for name in names
        conditions += " OR " unless conditions == ""
        conditions += "(employees.first_name ILIKE '#{name}%' or employees.last_name ILIKE '#{name}%')"
      end
    end
    conditions='(' + conditions + ')' unless conditions == ""
    unless params[:search][:email] == ""
      conditions += " AND " unless conditions == ""
      conditions += "(employees.email = '#{params[:search][:email]}')"
    end
    unless params[:search][:birthdate] == ""
      conditions += " AND " unless conditions == ""
      conditions += "(employees.birthdate = '#{params[:search][:birthdate]}')"
    end
    unless params[:search][:phone] == ""
      conditions += " AND " unless conditions == ""
      conditions += "(employees.phone = '#{params[:search][:phone]}')"
    end
#    unless params[:search][:designation_id] == ""
#      conditions += " AND " unless conditions == ""
#      conditions += "(employees.designation_id = '#{params[:search][:designation_id]}')"
#    end
    conditions = "id = 0" if conditions.blank?
    self.paginate(:conditions=>conditions,
        :order=>'employees.created_at DESC',
        :page=>params[:page],
        :per_page=>10)
  end


  # Assign lawfirm_user to all the serviceprovider of the selected cluster
  # also add subproductassignment.
  def cluster_assignment(cluster_id)
    mailmodule = Subproduct.find_by_name('Mail')
    mysubproducts = self.user.subproduct_assignments
    serviceprovidersproducts = SubproductAssignment.getsubproductlist(self.user_id)
    cluster = Cluster.find(cluster_id)
    clusterlivian = cluster.all_employees
    unless mysubproducts.blank?
      for livian in clusterlivian
        livian_user_mapped = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id_and_service_provider_id(self.user_id,livian.id)
        unless livian_user_mapped
          Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:service_provider_id => livian.id, :employee_user_id => self.user_id, :status => 1, :priority => nil)
          if serviceprovidersproducts.blank?
            mysubproducts.each do |subproduct|
              if subproduct.subproduct_id != mailmodule.id
                SubproductAssignment.create(:user_id => livian.user.id, :subproduct_id => subproduct.subproduct_id, :employee_user_id => self.user_id, :product_licence_id => self.user.subproduct_assignments.first.product_licence_id, :company_id => self.company_id)
              end
            end
          else
            serviceprovidersproducts.each do |subproduct|
              if subproduct.id != mailmodule.id
                SubproductAssignment.create(:user_id => livian.user.id, :subproduct_id => subproduct.subproduct_id, :employee_user_id => self.user_id, :product_licence_id => self.user.subproduct_assignments.first.product_licence_id, :company_id => self.company_id)
              end
            end
          end
        end
      end
      return true
    else
      return false
    end

  end

  # To customize validation message on photo-content-type - Ketki 12/5/2011
  def photo_content_type_error
     if self.photo_upload and self.photo_content_type and !['image/jpeg', 'image/gif','image/png'].include?(self.photo_content_type)
       self.errors.add(" ", "Upload format not supported. Please check your photo's format and try again. We support these photo formats: JPG, GIF and PNG")
     end
  end

  # get the users of all the lawyers
  def self.get_all_employee_users
    lawyers = []
    all_employees = self.all(:order => "first_name, last_name")
    all_employees.collect{|employee| lawyers << employee.user if employee.user}
    return lawyers
  end

  #it is used to check the helpdesk role while creating new employee 
  def helpdesk_role
    if self.helpdesk_role_id && self.helpdesk_role_id.blank?
     self.errors.add("Helpdesk Role", "can't be blank")
    end
  end
   
end
# == Schema Information
#
# Table name: employees
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  salutation           :integer
#  birthdate            :date
#  description          :text
#  user_id              :integer
#  billing_rate         :integer
#  role_id              :integer
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  first_name           :string(32)
#  last_name            :string(32)
#  email                :string(255)
#  phone                :string(32)
#  mobile               :string(32)
#  parent_id            :integer
#  department_id        :integer
#  designation_id       :integer
#  registered_number1   :string(255)
#  registered_number2   :string(255)
#  registered_number3   :string(255)
#  access_code          :string(255)
#  my_contacts          :boolean         default(FALSE)
#  my_campaign          :boolean         default(FALSE)
#  my_opportunities     :boolean         default(FALSE)
#  photo_file_name      :string(255)
#  photo_content_type   :string(255)
#  photo_file_size      :integer
#  photo_updated_at     :datetime
#  reference1           :string(255)
#  reference2           :string(255)
#

