
class User < ActiveRecord::Base
  #TODO :Feature 6326 User to get blocked after 5 attempts  While implementing uncomment the below line. Surekha 06/05/2011
  devise  :database_authenticatable, :recoverable, :trackable, :validatable,:timeoutable ,:lockable#, :maximum_attempts => 4 #, :unlock_in => 1 #,:rememberable <== commented rememberable to remove remember me functionality by anil on 19/11/10
  #devise  :database_authenticatable, :recoverable, :trackable, :validatable,:timeoutable #,:lockable, :maximum_attempts => 4 #, :unlock_in => 1 #,:rememberable <== commented rememberable to remove remember me functionality by anil on 19/11/10
  # devise lockable uncommented locking the users after 5 attempts. Supriya Surve :: 8:26 am :: 02/05/2011
  extend ActiveSupport::Memoizable
  include LiviaMailConfig
  include ZimbraTimeZone

  belongs_to :company
  belongs_to :department
  has_one  :employee, :dependent => :destroy
  has_one  :contact, :dependent => :destroy

  has_one  :service_provider, :dependent => :destroy

  has_many :document_bookmarks

  has_many :cluster_users
  has_many :clusters, :through=> :cluster_users

  has_many :avatars # as owner who uploaded it, ex. Contact avatar
  has_many :accounts
  has_many :document_access_controls
  has_many :campaigns
  has_many :contacts
  has_many :opportunities
  has_many :permissions
  has_many :service_provider_employee_mappings,:include => :service_provider,:class_name=>'Physical::Liviaservices::ServiceProviderEmployeeMappings', :foreign_key=>'employee_user_id', :dependent=> :destroy
  has_many :service_sessions,:class_name=>'Physical::Liviaservices::ServiceSession', :foreign_key=>'employee_user_id'
  has_many :preferences
  has_many :shared_accounts, :through => :permissions, :source => :asset, :source_type => "Account", :class_name => "Account"
  has_many :matters,:foreign_key => :employee_user_id
  has_many :matter_peoples,:foreign_key => :employee_user_id
  
  has_many :matter_access_periods,:foreign_key => :employee_user_id
  
  has_many :matter_tasks,:through=>:matter_peoples
  has_many :my_all_matters,:class_name=>"Matter",:through=>:matter_peoples,:source=>:matter
  
  
 
  has_one :user_role
  has_one :role, :through => :user_role
  has_many :private_document_homes, :through => :document_access_controls, :foreign_key =>'employee_user_id'
  has_many :subproduct_assignments
  has_many :subproducts, :through => :subproduct_assignments
  has_many :user_invoices
  has_many :document_homes, :as => :mapable, :dependent => :destroy
  has_many :folders, :as =>:mapable
  has_many :assigned_user_tasks, :class_name => "UserTask",:foreign_key=>'employee_user_id'
  has_many :receiver_tasks,:class_name => "UserTask",:foreign_key => 'assigned_by_employee_user_id'
  has_many :logged_by_tasks,:class_name => "UserTask",:foreign_key => 'created_by_user_id'
  has_many :receiver_communications, :class_name => "Communication", :foreign_key => 'assigned_by_employee_user_id'
  has_many :logged_by_communications, :class_name => "Communication", :foreign_key => 'created_by_user_id'
  has_many :assigned_to_communications, :class_name => "Communication", :foreign_key => 'assigned_to_user_id'
  has_many :employee_favorites
  has_many :sticky_notes ,:foreign_key=>"assigned_to_user_id"
  has_many :user_settings
  has_many :product_licence_details
  has_many :user_work_subtypes
  has_many :work_subtypes, :through => :user_work_subtypes
  has_many :work_subtype_complexities, :through => :user_work_subtypes
  belongs_to :zimbra_activity
  has_many :photos, :dependent => :destroy, :class_name => 'Photo'
  has_many :additional_documents, :dependent => :destroy, :class_name => 'AdditionalDocument'
  has_many :questions, :conditions => ["setting_type='Question'"]
  has_many :default_questions
  has_one :upcoming, :conditions => ["setting_type='Upcoming'"]
  has_one :ftp_folder, :conditions => ["setting_type='FtpFolder'"]
  has_one :upcoming_opportunity, :conditions => ["setting_type='UpcomingOpportunity'"]
  has_many :answers, :conditions => ["setting_type='Answer'"]
  has_many :logged_notes, :class_name => "Communication", :foreign_key => 'created_by_user_id', :order => 'created_at DESC'
  has_many :notifications, :class_name => "Notification" ,:foreign_key =>'receiver_user_id', :order => 'created_at DESC', :dependent => :destroy
  has_many :one_time_notifications, :class_name => "Notification", :select => 'DISTINCT notifications.*', :foreign_key => 'receiver_user_id', :order => 'created_at DESC', :limit => 3
  has_one :open_notifications_count, :class_name => "Notification", :select => 'count(*) as open_notifications', :foreign_key => 'receiver_user_id', :conditions =>['is_read IS NULL OR is_read = false']

  named_scope:get,lambda{{:conditions=>['company_id=? and id NOT IN (?)',current_user.company_id,current_user.id]}}
  #validates_presence_of :first_name, :last_name
  named_scope :except, lambda { | user | { :conditions => "id != #{user.id}" } }

  default_scope :order => 'username ASC'
  acts_as_paranoid
  acts_as_tree :order=>"username"
  # commented for devise
  #  acts_as_authentic do |c|
  #    c.session_class = UserSession
  #    c.validates_uniqueness_of_login_field_options = { :message => "This username has been already taken." }
  #    c.validates_uniqueness_of_email_field_options = { :message => "There is another user with the same email.", :on => :create }
  #    c.validates_length_of_password_field_options  = { :minimum => 8, :if => :require_password? }
  #    c.ignore_blank_passwords = true
  #  end

  # Store current user in the class so we could access it from the activity
  # observer without extra authentication query.
  cattr_accessor :current_user, :current_company, :current_lawyer
  attr_accessor :verified_lawyer_id_by_secretary
  attr_accessor :service_provider_id_by_telephony
  attr_accessible :username, :password, :password_confirmation,:email,:first_name,:last_name,:alt_email,:company_id,:phone,:mobile,:department_id,:security_question,:security_answer,:time_zone,:zimbra_time_zone,:questions_attributes,:nick_name,:timer_state,:timer_start_time,:base_seconds

  validates_presence_of :username, :message => "Please specify the username."
  validates_presence_of :email,    :message => "Please specify your email address."
  validates_uniqueness_of :username, :case_sensitive => false
  validates_format_of :alt_email,
    :with => /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/,
    :message => :email_format, :allow_nil => true, :allow_blank => true
  #validates_presence_of :last_name,    :message => "Please specify your last name."
  after_create :create_user_settings
  after_save :save_into_zimbra

  #this method was added to validate user password in create new company. earlier user and company used to get saved despite of a wrong password as validation was not in user model. Now its working fine :sania wagle, 28 feb 2011
  #TODO: this needs to be deleted
  #validates_format_of :password, :with=> /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/

  accepts_nested_attributes_for :questions
  accepts_nested_attributes_for :answers
  
  def self.not_client(company_id)
    @not_client = all(:include => [:company, :employee, :role, {:product_licence_details =>{:product_licence => :product}}], :conditions => ['company_id = ?', company_id]).find_all{|user| user if !user.role.nil? && !user.role?('client')}.compact
  end

  def name
    self.first_name.blank? ? self.username : self.first_name
  end

  #----------------------------------------------------------------------------
  def self.get_user_name(user)
    first(:select => :username, :conditions => ["id = ?", user])
  end
  #----------------------------------------------------------------------------
  # Generate a random password of <i>len</i> charachters
  def self.random_password(len)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + %w[! @ # $ % ^ & * _]
    random_password = ''
    1.upto(len) { |i| random_password << chars[rand(chars.size-1)] }
    random_password
  end




  def self.generate_and_mail_new_password(name, email)
    # This is the hash that will be returned
    result = Hash.new

    # Check if the name and/or email are valid
    if  name.present? &&  email.present? # The user entered both name and email
      user = self.find_by_username_and_email(name, email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this combination of username and e-mail address'
        return result
         else
      if user.failed_attempts >= 5
        result['flash'] = 'forgotten_notice'
        result['message'] = "Your user account has been blocked. Please use the link sent to your registered email id #{user.email} to reset your password. Kindly contact the administrator if you need any help."
        return result
      end
      end
    elsif  name.present? # The user only entered the name
      user = self.find_by_username(name)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Invalid Email Id. Please enter valid Email Id.'
        return result
      else
      if user.failed_attempts >= 5
        result['flash'] = 'forgotten_notice'
        result['message'] = "Your user account has been blocked. Please use the link sent to your registered email id #{user.email} to reset your password. Kindly contact the administrator if you need any help."
        return result
      end
      end
    elsif  email.present? # The user only entered an e-mail address
      user = User.find_by_email(email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this e-mail address'
        return result
      else
      if user.failed_attempts >= 5
        result['flash'] = 'forgotten_notice'
        result['message'] = "Your user account has been blocked. Please use the link sent to your registered email id #{user.email} to reset your password. Kindly contact the administrator if you need any help."
        return result
      end
      end
    else # The user didn't enter anything
      result['flash'] = 'forgotten_notice'
      result['message'] = 'Please enter an e-mail address'
      return result
    end
    user.reset_password_token = Devise.friendly_token
    user.send_reset_token(result)
  end

  def send_mail_for_forget_password_or_tpin(result,subject,url,other)

  end
  def send_reset_token(result)
    begin
      user=self
      to_email =  self.alt_email ? self.email + ',' + self.alt_email : self.email
      # user.change_password=true
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new do
        from ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        to to_email
        subject 'Password Update'
        html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Hello #{user.full_name},</p><p>Company: #{user.company.name}</p><p>Someone has requested a link to change your password, and you can do this through the link below.</p>
               <p><a href='#{ENV["HOST_NAME"]}/users/password/edit?reset_password_token=#{user.reset_password_token}'>Change my password</a></p>
                <p>If you didn't request this, please ignore this email.</p>
                <p>Your password won't change until you access the link above and create a new one.</p>"
        end


      end
      if mail.deliver! and self.save
        result['flash'] = 'login_confirmation'
        result['message'] = 'You will receive an email to with instructions about how to reset your password in a few minutes. '
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not create a new password'
      end
    rescue Exception => e
      if e.message.match('getaddrinfo: No address associated with nodename')
        result['flash'] = 'forgotten_notice'
        result['message'] = "The mail server settings in the environment file are incorrect. Check the installation instructions to solve this problem. Your password hasn't changed yet."
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = e.message + ".<br /><br />This means either your e-mail address or email configuration for e-mailing is invalid. Please contact the administrator or check the installation instructions. Your password hasn't changed yet."
      end
    end

    # finally return the result
    result
  end


  def generate_and_mail_new_tpin(email)
    # This is the hash that will be returned
    result = Hash.new
    regxp = /([a-z0-9_.-]+)@([a-z0-9-]+)\.([a-z.]+)/i
    if email.match(regxp).nil?
      result['flash'] = 'forgotten_notice'
      result['message'] = 'Please enter valid email address.'
      return result
    end
    self.reset_tpin_token = Devise.friendly_token
    self.send_reset_tpin(result,email)
  end


  def send_reset_tpin(result,email)
    begin
      user=self
      to_email = email
      #to_email = to_email + ',' + self.alt_email unless self.alt_email.nil?
      # user.change_password=true
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new do
        from ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        to to_email
        subject 'TPIN Update'
        html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Hello #{user.full_name},</p><p>Company: #{user.company.name}</p><p>You have requested a link to change your TPIN, and you can do this through the link below.</p>
               <p><a href='#{ENV["HOST_NAME"]}/access_codes/edit/1000?reset_tpin_token=#{user.reset_tpin_token}'>Change my TPIN</a></p>
                <p>If you didn't request this, please ignore this email.</p>
                <p>Your TPIN won't change until you access the link above and create a new one.</p>"
        end


      end
      if mail.deliver! and self.save
        result['flash'] = 'login_confirmation'
        result['message'] = 'You will receive an email  with instructions about how to reset your TPIN in few minutes. '
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not create a new TPIN'
      end
    rescue Exception => e
      if e.message.match('getaddrinfo: No address associated with nodename')
        result['flash'] = 'forgotten_notice'
        result['message'] = "The mail server settings in the environment file are incorrect. Check the installation instructions to solve this problem. Your password hasn't changed yet."
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = e.message + ".<br /><br />This means either your e-mail address or email configuration for e-mailing is invalid. Please contact the administrator or check the installation instructions. Your password hasn't changed yet."
      end
    end

    # finally return the result
    result
  end



  # Generates a new password for the user with the given username
  # and/or password and mails the password to the user.
  # Returns an appriopriate error message if the given user does not exists.
  def self.generate_and_mail_new_password_old(name, email)
    # This is the hash that will be returned
    result = Hash.new

    # Check if the name and/or email are valid
    if not name.blank? and not email.blank? # The user entered both name and email
      user = self.find_by_username_and_email(name, email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this combination of username and e-mail address'
        return result
      end
    elsif not name.blank? # The user only entered the name
      user = self.find_by_username(name)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Invalid Email Id. Please enter valid Email Id.'
        return result
      end
    elsif not email.blank? # The user only entered an e-mail address
      user = User.find_by_email(email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this e-mail address'
        return result
      end
    else # The user didn't enter anything
      result['flash'] = 'forgotten_notice'
      result['message'] = 'Please enter a username and/or an e-mail address'
      return result
    end

    # So far, so good...
    # Generate a new password
    new_password = User.random_password(10)
    user.password = new_password
    user.password_confirmation= new_password

    # Store the new password and try to mail it to the user
    begin

      to_email=user.email
      to_email=to_email + ', ' + user.alt_email  if user.alt_email
      user.change_password=true
      mail = Mail.new do
        from ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        to to_email
        subject 'Password Update'
        body "A new LIVIA password has been generated for you.
                Use the following to log in to LIVIA  :
                URL: http://www.liviaservices.com
                Username: #{user.username}
                Password: #{new_password}"
      end
      if mail.deliver! and user.save
        result['flash'] = 'login_confirmation'
        result['message'] = 'A new password has been e-mailed to ' + user.email
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not create a new password'
      end
    rescue Exception => e
      if e.message.match('getaddrinfo: No address associated with nodename')
        result['flash'] = 'forgotten_notice'
        result['message'] = "The mail server settings in the environment file are incorrect. Check the installation instructions to solve this problem. Your password hasn't changed yet."
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = e.message + ".<br /><br />This means either your e-mail address or email configuration for e-mailing is invalid. Please contact the administrator or check the installation instructions. Your password hasn't changed yet."
      end
    end

    # finally return the result
    result
  end

  #----------------------------------------------------------------------------
  def full_name
    @fullname ||=self.first_name.blank? || self.last_name.blank? ? self.username : "#{self.first_name} #{self.last_name}".titleize
  end

  def company_full_name
    "#{self.company.name}"
  end
  #----------------------------------------------------------------------------
  def preference
    Preference.new(:user => self)
  end
  alias :pref :preference

  #----------------------------------------------------------------------------
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

  # ---------- Methods added by Livia
  #---------------------------------------
  #Replaced with below defined method. It fires a query when ever user.service_provider is called
  #def service_provider
  # ServiceProvider.find_by_user_id(self.id)
  #end

  # deleted the memoized method 'service_provider' as now we can access the user's service provider via association. Also it was causing crash on updating user.service_provider : Sania Wagle , 15 jul 2011

  def leads
    self.contacts.all(:conditions=> ["status = 'lead'"])
  end

  def prospects
    self.contacts.all(:conditions => ["status = 'prospect'"])
  end

  def clients
    self.contacts.all(:conditions => ["status = 'client'"])
  end

  def end_user
    Employee.find_by_user_id(self.id)
  end
  memoize :end_user

  #This method retrieves records from DB based on user selection of parameters in Reports
  #include or select options for below find method is passed as hash 'include_hash'
  def self.find_for_rpt(search, conditions_hash)
    all(:conditions => [search, conditions_hash], :include => :role)
  end

  #Methods which is required for cancan
  def verified_lawyer #(userid)
    #$employee_id = userid
    $employee_id = self.id
  end


  def deleted_employee
    Employee.find_only_deleted(:first, :conditions => ["user_id = ?", self.id])
  end

  # find all the company users except lawfirm_admin
  def self.find_user_not_admin(company_id)
    User.find_all_by_company_id(company_id, :include => :role).collect{|user| user if !user.role?('lawfirm_admin') }.compact
  end

  def self.find_user_not_admin_not_client(company_id)
    @user = User.find_all_by_company_id(company_id, :include => [:company,:role]).find_all{|user| !user.role.nil? && !(user.role?('lawfirm_admin')||user.role?('client')) }
  end

  def self.find_user_role_lawyer(company_id)
    User.find_all_by_company_id(company_id, :include => :role).collect{|user| user if user.role?('lawyer') }.compact
  end


  #  def roles
  #    @assignment = self.assignment
  #    myrole = []
  #    myrole << @assignment.role.name.to_s
  #    myrole
  #  end
  #
  #  def role?(role)
  #    roles.include? role.to_s
  #  end

  # It checks the user role from the user_role table.
  def role?(role)
    self.role ? self.role.name.eql?(role.to_s) : false
  end

  # It return the array of assigned subproducts(modules) to current login user.
  def subproducts
    if self.role?(:secretary) || self.role?(:team_manager)
      user_id = self.service_provider_id_by_telephony.present? ? ServiceProvider.find(self.service_provider_id_by_telephony).user_id : self.id
      employee_id = self.verified_lawyer_id_by_secretary
      @subproduct_assignment ||= SubproductAssignment.all(:include => [:product_licence, :subproduct], :conditions => ['user_id = ? AND employee_user_id = ?', user_id, employee_id])
    else
      @subproduct_assignment ||= SubproductAssignment.all(:include => :subproduct, :conditions => ['user_id = ?', self.id])
    end
    mysubproducts = []
    for myObj in @subproduct_assignment
      mysubproducts << myObj.subproduct.name.to_s
    end
    mysubproducts
  end

  # If user has access of the selected product then it return true otherwise false
  # For a user assigned products are captured once into @subproducts array.
  # @subproducts array is used multiple times in reducing db calls.
  def has_access?(subproduct)
    unless subproduct == :Communication
#      return true if subproduct == :FinancialAccount
      @subproducts ? @subproducts.include?(subproduct.to_s) : (@subproducts = subproducts).include?(subproduct.to_s)
    else
      self.verified_lawyer_id_by_secretary.present?
    end
  end

  def create_user_settings
    if self.role.eql?("employee") || self.role.eql?("client")
      Upcoming.create(:user_id => self.id, :setting_type => 'Upcoming',:setting_value => 7, :company_id => self.company_id)
    end
  end

  def self.users_of_cluster(cluster_id)
    all(:include => [:employee, :service_provider, :company], :conditions => ["users.cluster_id = ?", cluster_id])
  end


  # creating helpdek user for livia employee user
  def create_helpdesk_user(company,password,role_id)
    if APP_URLS[:use_helpdesk]
      begin
        if role_id !=''
          url = URI.parse(APP_URLS[:helpdesk_url] + "/users/clepsotda")
          if url.scheme == 'https'
            uri = URI.parse(APP_URLS[:helpdesk_url] + "/login")
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl =true
            res = https.get(uri.path)
            c=res.response['set-cookie'].split('; ')[0]
            user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
            headers = {
              'Cookie' => c,
              'Referer' => APP_URLS[:helpdesk_url] + "/login",
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => user_agent
            }

            data ="email=#{self.email}&password=#{password}&password_confirmation=#{password}&role_id=#{role_id}&login=#{self.username}&first_name=#{self.first_name}&last_name=#{self.last_name}"
            resp, data = https.post2(url.path, data, headers)
          else
            args={:email=>self.email,:password_confirmation=>password,:password=>password,:role_id=>role_id,:login=>self.username,:first_name=>self.first_name,:last_name=>self.last_name,:created_at=>self.created_at.to_s,:updated_at=>self.updated_at.to_s}
            Net::HTTP.post_form(url,args)
          end
          new_user = User.find_by_sql("SELECT * FROM helpdesk.users WHERE login = '#{self.username}'")[0]
          connection.execute("INSERT INTO helpdesk.employees (company_id, user_id, created_at, updated_at)
                                   VALUES (#{new_user.company_id}, #{new_user.id}, '#{self.created_at}', '#{self.updated_at}');")

          connection.execute("INSERT INTO single_signon.user_apps(product_id, product_user_id, helpdesk_user_id) VALUES ((select id FROM helpdesk.products WHERE key='#{APP_URLS[:livia_portal_key]}' LIMIT 1), #{self.id}, #{new_user.id});")

        elsif self.role.name == 'lawyer'
          company_app = Company.find_by_sql("SELECT * FROM single_signon.company_apps where product_company_id = #{company.id} AND product_id=(select id FROM helpdesk.products WHERE key='#{APP_URLS[:livia_portal_key]}' LIMIT 1)")
          if company_app.blank?
            company_id = Company.find_by_sql("SELECT * FROM helpdesk.companies WHERE name = 'LIVIA India Pvt. Ltd'" )[0].id
            company_client_type_id = Company.find_by_sql("SELECT * FROM helpdesk.company_client_types WHERE company_id = #{company_id}")[0].id
            connection.execute("INSERT INTO helpdesk.company_clients (name,company_id,company_client_type_id,description,created_at,updated_at)
                                   VALUES ('#{company.name}', #{company_id}, #{company_client_type_id} , 'created from livia portal','#{company.created_at}','#{company.updated_at}');")
            helpdesk_company_id = Company.find_by_sql("SELECT * FROM helpdesk.company_clients WHERE name = '#{company.name}'")[0].id
            connection.execute("INSERT INTO single_signon.company_apps(product_id, product_company_id,helpdesk_company_id) VALUES ((select id from helpdesk.products WHERE key='#{APP_URLS[:livia_portal_key]}' LIMIT 1), #{company.id}, #{helpdesk_company_id});")
          else
            helpdesk_company_id = company_app[0].helpdesk_company_id
          end
          helpdesk_role_id = Role.find_by_sql("SELECT id FROM helpdesk.roles WHERE name = 'Client User'")[0].id
          url = URI.parse(APP_URLS[:helpdesk_url] + "/users/clepsotda")
          if url.scheme == 'https'
            uri = URI.parse(APP_URLS[:helpdesk_url] + "/login")
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl =true
            res = https.get(uri.path)
            c=res.response['set-cookie'].split('; ')[0]
            user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
            headers = {
              'Cookie' => c,
              'Referer' => APP_URLS[:helpdesk_url] + "/login",
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => user_agent
            }

            data ="email=#{self.email}&password=#{password}&password_confirmation=#{password}&role_id=#{helpdesk_role_id}&login=#{self.username}&first_name=#{self.first_name}&last_name=#{self.last_name}"
            resp, data = https.post2(url.path, data, headers)
          else
            args={:email=>self.email,:password_confirmation=>password,:password=>password,:role_id=>helpdesk_role_id,:login=>self.username,:first_name=>self.first_name,:last_name=>self.last_name,:created_at=>self.created_at.to_s,:updated_at=>self.updated_at.to_s}
            Net::HTTP.post_form(url,args)
          end
          new_user_id = User.find_by_sql("SELECT * FROM helpdesk.users WHERE login = '#{self.username}'")[0].id
          connection.execute("INSERT INTO helpdesk.company_client_users (company_client_id, user_id, created_at, updated_at)
                                   VALUES (#{helpdesk_company_id},#{new_user_id}, '#{self.created_at}', '#{self.updated_at}');")

          connection.execute("INSERT INTO single_signon.user_apps(product_id,product_user_id,helpdesk_user_id) VALUES ((select id FROM helpdesk.products WHERE key='#{APP_URLS[:livia_portal_key]}' LIMIT 1), #{self.id}, #{new_user_id});")
          #     rescue
        elsif self.role.name=='secretary' || self.role.name=='cluster_manager'
          helpdesk_role_id = Role.find_by_sql("SELECT id FROM helpdesk.roles WHERE name='Livian'")[0].id
          url = URI.parse(APP_URLS[:helpdesk_url] + "/users/clepsotda")
          if url.scheme == 'https'
            uri = URI.parse(APP_URLS[:helpdesk_url] + "/login")
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl =true
            res = https.get(uri.path)
            c=res.response['set-cookie'].split('; ')[0]
            user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'
            headers = {
              'Cookie' => c,
              'Referer' => APP_URLS[:helpdesk_url] + "/login",
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => user_agent
            }

            data ="email=#{self.email}&password=#{password}&password_confirmation=#{password}&role_id=#{helpdesk_role_id}&login=#{self.username}&first_name=#{self.first_name}&last_name=#{self.last_name}"
            resp, data = https.post2(url.path, data, headers)
          else
            args={:email=>self.email,:password_confirmation=>password,:password=>password,:role_id=>helpdesk_role_id,:login=>self.username,:first_name=>self.first_name,:last_name=>self.last_name,:created_at=>self.created_at.to_s,:updated_at=>self.updated_at.to_s}
            Net::HTTP.post_form(url,args)
          end
          new_user = User.find_by_sql("SELECT * FROM helpdesk.users WHERE login = '#{self.username}'")[0]
          connection.execute("INSERT INTO helpdesk.employees (company_id, user_id, created_at, updated_at)
                                   VALUES (#{new_user.company_id}, #{new_user.id}, '#{self.created_at}', '#{self.updated_at}');")

          connection.execute("INSERT INTO single_signon.user_apps(product_id, product_user_id, helpdesk_user_id) VALUES ((SELECT id FROM helpdesk.products WHERE key='#{APP_URLS[:livia_portal_key]}' LIMIT 1), #{self.id},#{new_user.id});")




          #find company
          #create_service_provider
          #create_user
        end
      end
    end
  end

  def save_into_zimbra
    if self.changed.include?("zimbra_time_zone")
      domain = ZimbraUtils.get_domain(self.email)
      host = ZimbraUtils.get_url(domain)
      key = ZimbraUtils.get_key(domain)
      begin
        Resque.enqueue(UserZimbraTimezone, key, host, self.email, self.zimbra_time_zone)
      rescue => ex
      end
    end
  end

  def self.service_provider_users_without_cluster
    find_by_sql("SELECT users.* FROM users INNER JOIN service_providers ON service_providers.user_id = users.id
                 WHERE users.id NOT IN(select user_id from cluster_users) AND users.deleted_at IS NULL")
  end

  def self.common_pool_agents
    find_by_sql("SELECT users.* FROM users INNER JOIN service_providers ON service_providers.user_id = users.id
                 WHERE service_providers.is_cpa = true AND users.deleted_at IS NULL")
  end

  def self.generate_and_mail_new_password_from_matter(name, email,lawyer,updated=nil)
    # This is the hash that will be returned
    result = Hash.new

    # Check if the name and/or email are valid
    if name.present? &&  email.present? # The user entered both name and email
      user = self.find_by_username_and_email(name, email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this combination of username and e-mail address'
        return result
      end
    elsif name.present? # The user only entered the name
      user = self.find_by_username(name)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this username'
        return result
      end
    elsif  email.present? # The user only entered an e-mail address
      user = User.find_by_email(email)
      if user.blank?
        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not find a user with this e-mail address'
        return result
      end
    else # The user didn't enter anything
      result['flash'] = 'forgotten_notice'
      result['message'] = 'Please enter an e-mail address'
      return result
    end
    user.reset_password_token = Devise.friendly_token
    user.send_reset_token_from_matter(result,lawyer,updated)
  end

  def send_reset_token_from_matter(result,lawyer,updated=nil)
    begin
      user=self
      user_name="#{self.try(:first_name)} #{self.try(:last_name)}"
      to_email =  self.alt_email ? self.email + ',' + self.alt_email : self.email
      # user.change_password=true
      LiviaMailConfig::email_settings(user.company)
      if updated
        mail = Mail.new do
        #from ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        from lawyer.nil? ? get_from_email_for_notification_alerts : lawyer.email
        to to_email
        subject "#{user.company.name} : Client Access Updated"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body   "<p>Dear #{user_name},</p><p>Your email id has been changed to #{user.email} in #{user.company.name} company's record. Due to this your login id  for Portal login provided by the #{user.company.name} has changed.</p>
       <p>Your new Login id is #{user.email}.</p>
       <p>Please <a href='#{ENV["HOST_NAME"]}/users/password/edit?reset_password_token=#{user.reset_password_token}'>click here </a>to generate your password</p>"        
        end
        end
      else
      
      mail = Mail.new do
        #from ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
        from lawyer.nil? ? get_from_email_for_notification_alerts : lawyer.email
        to to_email
        subject "#{user.company.name} : Client Access Created"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Dear #{user_name},</p><p>A client access is created for you with Username: #{user.email}  </p><p>By: #{user.company.name}</p>
                <p>Please <a href='#{ENV["HOST_NAME"]}/users/password/edit?reset_password_token=#{user.reset_password_token}'>click here </a>to generate your password</p>


               <br/><p>This is a system generated email</p>"
        end
      end
      end
  
      if mail.deliver! and self.save
        result['flash'] = 'login_confirmation'
        result['message'] = 'You will receive an email to with instructions about how to reset your password in a few minutes. '
      else
        user.errors.full_messages.each {|e| p e}

        result['flash'] = 'forgotten_notice'
        result['message'] = 'Could not create a new password'
      end

    rescue Exception => e
      if e.message.match('getaddrinfo: No address associated with nodename')
        result['flash'] = 'forgotten_notice'
        result['message'] = "The mail server settings in the environment file are incorrect. Check the installation instructions to solve this problem. Your password hasn't changed yet."
      else
        result['flash'] = 'forgotten_notice'
        result['message'] = e.message + ".<br /><br />This means either your e-mail address or email configuration for e-mailing is invalid. Please contact the administrator or check the installation instructions. Your password hasn't changed yet."
      end
    end

    # finally return the result
    result
  end

  def self.find_user(id)
    find id
  end

  def belongs_to_common_pool
    self.service_provider.has_common_pool_access?
  end

  def save_default_questions
    if self.role.name.eql?('lawyer')
      q = CompanyLookup.all(:conditions => ['type = ?', 'DefaultQuestion'])
      q1 = q[0].lvalue
      q2 = q[1].lvalue
      first_question = self.questions.create(:setting_value=>q1,:setting_type=>'Question',:company_id=>self.company_id)
      second_question = self.questions.create(:setting_value=>q2,:setting_type=>'Question',:company_id=>self.company_id)
      a1 = q[0].alvalue
      a2 = q[1].alvalue
      first_question.create_answer(:setting_value=>a1,:setting_type=>'Answer',:company_id=>self.company_id,:user_id=>self.id)
      second_question.create_answer(:setting_value=>a2,:setting_type=>'Answer',:company_id=>self.company_id,:user_id=>self.id)
    end
  end

  def validate_sequrity_questions(questions)
    unless questions.blank?
      questions.each do |index, question|
        self.errors.add_to_base("Question can not be blank") if question["setting_value"].blank?
        self.errors.add_to_base("Answer can not be blank") if question["answer_attributes"]["setting_value"].blank?
      end
    end
  end

  def belongs_to_back_office
    self.service_provider.has_back_office_access? if self.service_provider
  end

  def belongs_to_front_office
    self.service_provider.has_front_office_access? if self.service_provider
  end

  def self.get_users_cluster_livians(user)
    cluster_ids = user.clusters.map(&:id).join(',')
    unless cluster_ids.blank?
      find_by_sql("SELECT distinct u.id, u.first_name,u.last_name FROM users AS u JOIN cluster_users AS cu ON u.id = cu.user_id JOIN service_providers AS sp ON u.id = sp.user_id WHERE cu.cluster_id IN (#{cluster_ids}) AND u.deleted_at IS NULL AND sp.deleted_at IS NULL")
    else
      []
    end
  end

  # Returns user's Back Office Skills
  def get_users_bo_skills
    self.work_subtypes.find(:all ,:include =>[:work_type=>[:category]], :conditions =>{:work_types =>{:categories =>{:has_complexity=>'true'}}})
  end

  def is_team_manager?
    self.role && self.role.name.eql?('team_manager')
  end

  def self.all_cluster_livian(clusters)
   clusters.blank? ? [] : User.all(:conditions => ["cluster_users.cluster_id IN (?) AND users.id = service_providers.user_id", clusters.map(&:id)], :include => [:cluster_users, :service_provider, :user_role], :order => "users.first_name ASC, users.last_name ASC")
  end

  def self.all_cluster_lawyer(clusters)
   clusters.blank? ? [] : User.all(:conditions => ["cluster_users.cluster_id IN (?) AND users.id = employees.user_id", clusters.map(&:id)], :include => [:cluster_users, :employee, :company], :order => "users.first_name ASC, users.last_name ASC")
  end

  def self.all_cluster_manager(clusters)
   clusters.blank? ? [] : User.all(:include => [:cluster_users, :service_provider, :role], :order => "users.first_name ASC, users.last_name ASC", :conditions => ["cluster_users.cluster_id IN (?) AND users.id = service_providers.user_id AND roles.name = 'team_manager'", clusters.map(&:id)])
  end

end
