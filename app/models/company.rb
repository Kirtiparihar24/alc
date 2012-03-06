class Company < ActiveRecord::Base
  has_many :users
  
  # Admin
  has_many :company_email_settings
  has_many :company_temp_licences
  has_many :company_settings # added for campaigns mailer to store email ids - 09-05-2011 - Supriya Surve

  has_many :employees, :dependent => :destroy
  has_many :invoice_details
  has_many :product_licences
  has_many :products, :through => :product_licences
  has_many :invoices
  has_many :roles
  has_many :departments
  has_many :company_role_rates
  has_many :company_activity_rates
  has_many :licences
  has_many :compliance_types
  
  # CRM ============
  # Contacts
  has_many :contacts, :dependent => :destroy
  has_many :contact_phone_type, :dependent => :destroy, :class_name => 'ContactPhoneType'
  
  # Opportunities
  has_many :opportunities, :dependent =>:destroy, :order => "opportunities.name asc"

  # Campaigns
  has_many :campaigns, :dependent => :destroy, :class_name => 'Campaign'
  has_many :campaign_members, :dependent => :destroy, :class_name => 'CampaignMember'
  has_many :campaign_status_types, :dependent => :destroy, :class_name => 'CampaignStatusType'
  has_many :campaign_member_status_types, :dependent => :destroy, :class_name => 'CampaignMemberStatusType'
  has_many :campaign_mailer_emails

  # Accounts
  has_many :accounts, :order => "accounts.name asc"
  has_one  :account, :through=>:cgc_company_accounts
  has_many :billing_address, :class_name => "Address"
  has_many :shipping_address, :class_name => "Address"
  has_many :cgc_company_accounts

  # Documents
  has_many :document_access_controls
  has_many :repository_documents, :class_name=> 'DocumentHome', :as => :mapable
  has_many :links, :as => :mapable  
  has_many :document_homes, :through => :document_access_controls
  has_many :folders, :as=>:mapable

  # Time & Expense
  has_many :time_entries, :class_name =>"Physical::Timeandexpenses::TimeEntry"
  has_many :expense_entries, :class_name =>"Physical::Timeandexpenses::ExpenseEntry"
  
  # Company Lookups
  has_many :contact_stages, :dependent => :destroy, :order => :sequence
  has_many :lead_status_types, :dependent => :destroy, :class_name => 'LeadStatusType', :order => :sequence
  has_many :prospect_status_types, :dependent => :destroy, :class_name => 'ProspectStatusType', :order => :sequence
  has_many :matter_privileges, :dependent => :destroy, :class_name => 'MatterPrivilege', :order => :sequence
  has_many :opportunity_stage_types, :dependent => :destroy, :class_name => 'OpportunityStageType', :order => :sequence
  has_many :doc_sources, :dependent=> :destroy, :order => :sequence
  has_many :phases, :dependent => :destroy, :order => :sequence
  has_many :liti_types, :class_name =>"TypesLiti", :dependent=> :destroy, :order => :sequence
  has_many :nonliti_types, :class_name=>"TypesNonLiti", :dependent=> :destroy, :order => :sequence
  has_many :document_categories, :dependent => :destroy, :order => :sequence
  has_many :document_sub_categories, :dependent => :destroy, :order => :sequence
  has_many :activity_types, :class_name => 'Physical::Timeandexpenses::ActivityType', :dependent=> :destroy, :order => :sequence
  has_many :expense_types, :class_name => 'Physical::Timeandexpenses::ExpenseType', :dependent=> :destroy, :order => :sequence
  has_many :research_types, :dependent=> :destroy, :order => :sequence
  has_many :campaign_Member_status_types, :class_name=>"CampaignMemberStatusType", :dependent => :destroy, :order => :sequence
  has_many :campaign_status_types, :class_name=>"CampaignStatusType", :dependent => :destroy, :order => :sequence
  has_many :document_types, :dependent => :destroy, :class_name => 'DocumentType', :order => :sequence # Added By Pratik AJ on 04-05-2011.
  has_many :salutation_types, :class_name=>"SalutationType", :dependent => :destroy, :order => :sequence
  has_many :company_sources, :dependent => :destroy, :order => :sequence
  has_many :team_roles, :dependent => :destroy, :order => :sequence
  has_many :client_roles, :dependent => :destroy, :order => :sequence
  has_many :other_roles, :dependent => :destroy, :order => :sequence
  has_many :client_rep_roles, :dependent => :destroy, :order => :sequence
  has_many :matter_statuses, :dependent => :destroy, :order => :sequence
  has_many :matter_fact_types, :dependent => :destroy, :class_name => 'MatterFactType', :order => :sequence
  has_many :designations, :order => :sequence
  has_many :task_types, :dependent => :destroy, :class_name => 'TaskType', :order => :sequence
  has_many :appointment_types, :dependent => :destroy, :class_name => 'AppointmentType', :order => :sequence
  has_many :company_activity_types, :dependent=> :destroy, :order => :sequence
  has_many :designations, :order => :sequence
  has_many :financial_account_types, :dependent => :destroy
  has_many :financial_accounts, :dependent => :destroy
  has_many :approval_statuses, :dependent => :destroy, :order => :sequence
  has_many :transaction_statuses, :dependent => :destroy, :order => :sequence
  has_many :purposes, :dependent => :destroy, :order => :sequence
  has_many :income_types, :dependent => :destroy, :order => :sequence
  has_one  :rating_type, :class_name =>'RatingType', :dependent => :destroy

  # Biling
  has_one :duration_setting
  has_one :tne_invoice_setting
  has_many :tne_invoices
  has_many :tne_invoice_details  
  has_many :tne_invoice_statuses, :dependent => :destroy, :order => :sequence  

  # Generic
  has_one :dynamic_label
	has_many :import_histories 

	# WFM
	has_many :service_providers
	has_many :subproduct_assignments	
	has_many :communications
	  
  # matters
  has_many :matter_budgets
  has_many :matters, :order => "name asc"
  has_many :matter_peoples
  has_many :matter_access_periods
  has_many :matter_statuses, :class_name =>"MatterStatus", :dependent => :destroy, :order => :sequence
  
  # validation
  validates_presence_of :name
	validates_uniqueness_of :name

  # Named Scopes
	named_scope :company,lambda{|current_user| {:conditions=>['id NOT IN(?)', current_user], :order => "companies.name"}}
  named_scope :search_by_name,lambda{|name| {:conditions=>"name ILIKE '#{name}%'", :order => "companies.name"}}

  # Nested
  accepts_nested_attributes_for :billing_address
	accepts_nested_attributes_for :shipping_address

  # Attr
	attr_accessor :old_sequence_id

  # Gems/ Plugins
	acts_as_paranoid

  # Paperclip
	has_attached_file :logo, :path => ":rails_root/public/company_logos/:id/:style/:basename.:extension",
    :style => { :original => "154x51!" },
    :url  => "/company_logos/:id/:style/:basename.:extension"
		
	IMAGE_TYPE=['image/jpeg', 'image/png', 'image/gif', 'image/x-png']

	def validate
		if (self.logo_updated_at.to_i==Time.zone.now.to_i) && IMAGE_TYPE.include?(self.logo.content_type)
			temp_file = logo.queued_for_write[:original] #get the file that is being uploaded
			dimensions = Paperclip::Geometry.from_file(temp_file)
      #raise dimensions.width.inspect
			if ((dimensions.width != 154) && (dimensions.height != 51))
				errors.add("logo", "image size must be 154px * 51px.")
				self.logo = nil
			end
		end
	end
  validates_attachment_content_type :logo, :content_type=>IMAGE_TYPE, :allow_blank => true



	SORT_BY = {
    "name"         => "name ASC",
    "date created" => "created_at DESC",
    "date updated" => "updated_at DESC"
	}

	PERSON_TYPE = ["Salesman", "Sales Partner"]
  #It return list of companies except livia.
	named_scope :getcompanylist,lambda{|company_id|{:conditions=>['id NOT IN (?)',company_id], :order => "name"}}

	after_create :associate_values, :create_helpdesk_company_client, :create_default_duration_setting
  
	validates_presence_of:billingdate	
	validates_length_of :general_info, :maximum => 500, :allow_blank => true
	validates_length_of :write_up, :maximum => 500, :allow_blank => true

	def self.per_page ;  20                         ; end
	def self.outline  ;  "long"                     ; end
	def self.sort_by  ;  "created_at DESC" ; end

	def user_clients
		self.contacts.all(:include => [:user], :conditions => ["contacts.user_id IS NOT NULL"])
	end

	def users_not_client
		self.users.find_all{|user| user if !user.role.nil? && !user.role?('client') }.compact
	end

	def company_admin
		self.users.find_all{|user| user if !user.role.nil? && user.role?('lawfirm_admin') }
	end

	def self.total_licence(company_id)
		licences = Licence.all(:include => :company, :conditions => ['company_id = ? AND (expired_date >= ? OR expired_date IS NULL)', company_id, Time.zone.now])
		tmp = 0
		licences.each do |obj|
			tmp += obj.licence_count
		end
		tmp
	end

  def create_default_duration_setting
    self.create_duration_setting(:created_by_user_id=>1, :company_id => self.id, :setting_value=>'1/100th')
  end

	def get_zimbra_contact_location
		"#{self.zimbra_admin_account_id}:#{self.zimbra_contact_folder_id}"
	end

	def get_temporary_licence_usage
		total_licence = 0
		self.company_temp_licences.map do |ctl|
			total_licence += ctl.licence_limit
		end
		used_licence = self.product_licences.scoped_by_licence_type(1).count

		total_licence - used_licence
	end

	def get_lvalue(lval="Lead")
		self.contact_stages.find_by_lvalue(lval, :select => :id)
	end

	def name_type
		self.name
	end

	def create_helpdesk_company_client
		if APP_URLS[:use_helpdesk]
			begin
				company_id = Company.find_by_sql("select * from helpdesk.companies where name = 'LIVIA India Pvt. Ltd'" )[0].id
				company_client_type_id = Company.find_by_sql("select * from helpdesk.company_client_types where company_id=#{company_id}")[0].id
				connection.execute("INSERT INTO helpdesk.company_clients (name,company_id,company_client_type_id,description,created_at,updated_at)
                                 VALUES ('#{self.name}',#{company_id},#{company_client_type_id},'created from livia portal','#{self.created_at}','#{self.updated_at}');")

				helpdesk_company_id = Company.find_by_sql("select * from helpdesk.company_clients where name = '#{self.name}'")[0].id
				connection.execute("INSERT INTO single_signon.company_apps(product_id, product_company_id,helpdesk_company_id) VALUES ((select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1), #{self.id},#{helpdesk_company_id});")
			rescue
			end
		end
	end

	def get_all_matter_types
		types = []
		types << self.nonliti_types
		types << self.liti_types
		types = types.flatten

    types
	end

	def self.my_add_time(time1, time2)
		return time1 unless time2.present?
		return time2 unless time1.present?
		tmp1 = time1.split(":")
		tmp2 = time2.split(":")
		return "0" if tmp1.size == 1 && tmp2.size == 1
		if tmp1.size == 1 && tmp2.size > 1
			time2
		elsif tmp2.size == 1 && tmp1.size > 1
			time1
		else
			sec1 = tmp1[2].to_i + tmp1[1].to_i * 60 + tmp1[0].to_i * 3600
			sec2 = tmp2[2].to_i + tmp2[1].to_i * 60 + tmp2[0].to_i * 3600
			sec = sec1 + sec2
			"#{sec / 3600}:#{(sec % 3600) / 60}:#{(sec % 3600) % 60}" 
		end
	end

	def self.portal_usage_query(start_date, end_date, company_id=nil, employee_id=nil)
		if company_id.blank? && employee_id.blank?
			pgresult = ActiveRecord::Base.connection.execute("select c.name as lawfirm, (e.first_name|| ' '|| e.last_name) as lawyer, date(es.created_at) as logged_in_date, sum(es.session_end - es.session_start) as logged_in_time,
      (select count(*) from matters where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as matter_count,
      (select count(*) from contacts where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as contact_count,
      (select count(*) from opportunities where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as opportunity_count,
      (select count(*) from time_entries where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as time_entry_count
    from companies c 
    left outer join employees e on c.id=e.company_id
    left outer join employee_sessions es on e.id=es.employee_id
    left outer join users u on e.user_id=u.id 
    where date(es.created_at) between '#{start_date}' and '#{end_date}'
    group by c.id, u.id, c.name, e.first_name, e.last_name, es.created_at
    order by c.name, lawyer, logged_in_date asc")
		elsif employee_id.blank?
			pgresult =ActiveRecord::Base.connection.execute("select c.name as lawfirm, (e.first_name|| ' '|| e.last_name) as lawyer, date(es.created_at) as logged_in_date, sum(es.session_end - es.session_start) as logged_in_time,
      (select count(*) from matters where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as matter_count,
      (select count(*) from contacts where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as contact_count,
      (select count(*) from opportunities where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as opportunity_count,
      (select count(*) from time_entries where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as time_entry_count
    from companies c 
    left outer join employees e on c.id=e.company_id
    left outer join employee_sessions es on e.id=es.employee_id
    left outer join users u on e.user_id=u.id 
    where date(es.created_at) between '#{start_date}' and '#{end_date}' AND c.id = #{company_id}
    group by c.id, u.id, c.name, e.first_name, e.last_name, es.created_at
    order by c.name, lawyer, logged_in_date asc")
		else
			pgresult =ActiveRecord::Base.connection.execute("select c.name as lawfirm, (e.first_name|| ' '|| e.last_name) as lawyer, date(es.created_at) as logged_in_date, sum(es.session_end - es.session_start) as logged_in_time,
      (select count(*) from matters where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as matter_count,
      (select count(*) from contacts where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as contact_count,
      (select count(*) from opportunities where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as opportunity_count,
      (select count(*) from time_entries where company_id=c.id and employee_user_id=u.id and date(created_at) = date(es.created_at)) as time_entry_count
    from companies c 
    left outer join employees e on c.id=e.company_id
    left outer join employee_sessions es on e.id=es.employee_id
    left outer join users u on e.user_id=u.id 
    where date(es.created_at) between '#{start_date}' and '#{end_date}' AND c.id = #{company_id} AND e.id = #{employee_id}
    group by c.id, u.id, c.name, e.first_name, e.last_name, es.created_at
    order by c.name, lawyer, logged_in_date asc")
		end
	end

	def self.portal_usage_report(start_date, end_date, company_id, employee_id)
		pgresult = portal_usage_query(start_date, end_date, company_id, employee_id)
		result_hash_array = []
		cname,ename,login_date = nil,nil,nil
		tmp_hash = nil
		last_equal = false
		pgresult.each do|hash|
			if cname.nil?
				tmp_hash = hash.clone
				cname = hash["lawfirm"]
				ename = hash["lawyer"]
				login_date = hash["logged_in_date"]
			else
				if cname == hash["lawfirm"] && ename == hash["lawyer"] && login_date == hash["logged_in_date"]
					tmp_hash["logged_in_time"] = my_add_time(tmp_hash["logged_in_time"], hash["logged_in_time"])
					last_equal = true
				else
					result_hash_array << tmp_hash
					tmp_hash = hash.clone
					cname = hash["lawfirm"]
					ename = hash["lawyer"]
					login_date = hash["logged_in_date"]
					last_equal = false
				end
			end
		end
		result_hash_array << tmp_hash if last_equal
		result_hash_array

	end

  # Returns matched result of company's lawyers and lawyers assigned lawyers
  # The argument 'assigned_lawfirm_users' takes an array of lawyers assigned to self
  def get_assigned_employee_users(assigned_lawfirm_users)
    lawfirm_employees = self.employees.uniq.delete_if{|e| e.blank? || e.user.blank?}
    lawfirm_users = lawfirm_employees.map(&:user) if lawfirm_employees
    lawfirm_users.to_a & assigned_lawfirm_users.to_a
  end

  def self.search_company_name(name,law_value)
    all :conditions=>["name ILIKE '#{name.strip}%'AND id IN (?)",law_value], :order => "companies.name"
  end
	private
  #This methods is used to set necessary values for the new company
	def associate_values
		require 'yaml'
		company_values = YAML::load_file("#{RAILS_ROOT}/lib/company/company.yml")
		company_values.each_pair do |key,val|
			temp_arr = val.split(',')
			temp_arr.each do |arr|
				unless Company.reflect_on_association(key.to_sym).macro == :has_one
					#Commented as on creation of a new company alvalues for only contact_stages was set and not for others. - Ketki
					#          key == 'contact_stages' ? self.send(key).create(:lvalue=>arr.strip, :alvalue=>arr.strip) : self.send(key).create(:lvalue=>arr.strip)
					self.send(key).create(:lvalue=>arr.strip, :alvalue=>arr.strip)
				else
					key == 'rating_type' ? eval("self.create_#{key}(:lvalue=>'#{arr.strip.to_s}', :alvalue => '#{arr.strip.to_s}')") : eval("self.create_#{key}(:lvalue=>'#{arr.strip.to_s}')")
				end
			end
		end
	end

end


# == Schema Information
#
# Table name: companies
#
#  id                         :integer         not null, primary key
#  created_at                 :datetime
#  updated_at                 :datetime
#  name                       :string(200)     not null
#  about                      :text
#  deleted_at                 :datetime
#  permanent_deleted_at       :datetime
#  created_by_user_id         :integer
#  updated_by_user_id         :integer
#  zimbra_admin_account_email :string(255)
#  zimbra_admin_account_id    :string(255)
#  zimbra_contact_folder_id   :integer
#  is_cgc                     :boolean
#  billingdate                :datetime
#  sales_rep                  :string(255)
#  sales_rep_type             :string(255)
#  comm_payable               :boolean
#  temp_licence_limit         :integer         default(10)
#  notes                      :string(2000)
#  last_name_first            :boolean         default(FALSE), not null
#  logo_file_name             :string(255)
#  logo_content_type          :string(255)
#  logo_file_size             :integer
#  logo_updated_at            :datetime
#  parent_company             :string(255)
#  subsidiary                 :string(255)
#  general_info               :text
#  write_up                   :text
#  own_file                   :boolean         default(FALSE)
#  sequence_no                :integer
#  format                     :string(50)
#  sequence_seperator         :string(5)
#

