class ServiceProvider < ActiveRecord::Base
  #belongs_to :cluster
  #Type => { 1=>"Livian(Front Office)", 2=>"Back Office", 4=>"Common Pool"}
  
  belongs_to :user, :class_name => "User"
  has_many :service_provider_employee_mappings, :class_name => "Physical::Liviaservices::ServiceProviderEmployeeMappings", :foreign_key => 'service_provider_id'
  has_many :assign_lawfirm_users , :class_name => "User", :through => :service_provider_employee_mappings, :source => :user
  has_many :skills , :class_name => "Physical::Liviaservices::ServiceProviderSkill", :foreign_key => "service_provider_id", :dependent=> :destroy
  belongs_to :company
  attr_accessor :first_name, :last_name
  delegate :full_name, :to => :user, :allow_nil => true
  
  validate 'name'

  acts_as_paranoid

  after_commit   :update_MsSQL_server_data if RAILS_ENV == 'development'

  named_scope :find_by_name,  lambda { | name | {:joins => [:user], :order => "users.first_name ASC, users.last_name ASC", :conditions => ["users.first_name || users.last_name ILIKE ?", "%#{name.delete(' ')}%"] } }

  def name
    if self.first_name.blank? || self.last_name.blank?
      self.errors.add('Enter',' first and last name')
    end
  end

  def sp_full_name
    if self.user
      @sp_full_name= "#{self.user.first_name} #{self.user.last_name}"
    end
  end

  def deleted_sp_full_name
    begin
      @user = User.find_with_deleted(self.user_id)
      if @user
        "#{@user.first_name} #{@user.last_name}"
      end
    rescue => e
      false
    end
  end

  # returns all the service providers belonging to a cluster
  def self.get_cluster_service_providers(cluster_id)
    all(:include => :user, :conditions => ["users.cluster_id = ?", cluster_id.to_i])
  end

  # based on the skills assigned, assigns the task from common pool to user
  def get_next_task(is_cpa, belongs_to_back_office, belongs_to_front_office)
    skills_array = []
    comm_task = []
    cond = ''
    users_skills = self.user.work_subtypes
    skills_array = users_skills.map(&:id)
    skills = skills_array.blank? ? 0 : skills_array.join(',')
    if is_cpa || belongs_to_back_office
      cond = "work_subtype_id in (#{skills}) and assigned_to_user_id IS NULL and ( status is null or status != 'complete') and (repeat IS NULL or repeat = '')"
    end
    if belongs_to_front_office
      lawyer_array =  self.assign_lawfirm_users.map(&:id)
      l_array = lawyer_array.blank? ? 0 : lawyer_array.join(',')
      cond = "work_subtype_id in (#{skills}) and assigned_by_employee_user_id in (#{l_array}) and assigned_to_user_id is null and ( status is null or status != 'complete') and (repeat IS NULL or repeat = '')"
    end
    comm_task = UserTask.find(:all, :order => 'due_at', :include => [:work_subtype_complexity], :conditions=>cond).compact
    comm_task.each do |task|
      if task.is_back_office_task?
        user_complexity_level = self.user.work_subtype_complexities.find(:first, :conditions=> ['work_subtype_complexities.work_subtype_id = ?', task.work_subtype_id]).complexity_level rescue 0
        task_complexity_level = task.work_subtype_complexity.complexity_level rescue 0
        comm_task.delete(task) if task_complexity_level > user_complexity_level
      end
    end
    comm_task.first
  end

  def is_online
    active_session = Physical::Liviaservices::ServiceProviderSession.find(:all,
      :conditions => ["service_provider_id = ? and session_start < now() and session_end is null", self.id]).last
    if active_session
      "Online"
    else
      "Offline"
    end
  end

  def save_with_user(params)
    params[:user][:first_name]=params[:service_provider][:first_name]
    params[:user][:last_name]=params[:service_provider][:last_name]
    params[:user][:company_id]=params[:service_provider][:company_id]
    reg = /^(?=.*\d)(?=.*([a-z]))(?=.*([A-Z]))(?=.*([\x21-\x2F]|[\x3A-\x40]|[\x5B-\x60]|[\x7B-\x7E]))([\x20-\x7E]){8,40}$/
    unless reg.match(params[:user][:password])
      self.errors.add("Password Field:","Password should be of minimum 8 characters with atleast 1 small letter, 1 caps, 1 numeric and 1 special characer")
    end
    @user = User.new(params[:user])
    unless @user.valid?
      self.valid?
      @user.errors.each{|attr,msg| self.errors.add(attr,msg)}
    end
    if self.errors.count==0
      @user.save
      self.user_id= @user.id
      self.save
      if params[:role][:id].present? &&  params[:role][:id] != ""
        role = Role.find(params[:role][:id].to_i, :include => [{:categories => {:work_types => :work_subtypes}}])
      else
        role = Role.find_by_name('secretary', :include => [{:categories => {:work_types => :work_subtypes}}])
      end
      UserRole.find_or_create_by_user_id_and_role_id(@user.id,role.id)
      if params[:cluster_ids].present?
        clusters = Cluster.find(params[:cluster_ids])
        for cluster in clusters
          @clusteruser = ClusterUser.find_or_create_by_user_id_and_cluster_id(@user.id, cluster.id)
        end
      end
      update_provider_type(params)
      create_user_work_subtypes(@user,params[:work_skills]) unless params[:work_skills].blank?

      true
    else
      false
    end
  end

  def create_user_work_subtypes(user,work_skill_ids)
    for work_skill_id in work_skill_ids
      work_skill = work_skill_id.split('-')
      if  work_skill.size > 1
        user.user_work_subtypes.create(:work_subtype_id => work_skill[1], :work_subtype_complexity_id => work_skill[0])
      else
        user.user_work_subtypes.create(:work_subtype_id => work_skill[0])
      end
    end
  end



  # deletes work subtypes for a livian user (service provider)
  def delete_user_work_subtypes(user,role)
    for category in role.categories
      for work_type in category.work_types
        for work_subtype in work_type.work_subtypes
          UserWorkSubtype.delete_all(:user_id=>user.id,:work_subtype_id=>work_subtype.id)
        end
      end
    end
  end

  # Updates MsSQL server database used for telephonic integration
  def update_MsSQL_server_data
    begin
      ActiveRecord::Base.establish_connection(:sqlserver)
      database = ActiveRecord::Base.connection
      res =  database.execute("SELECT * FROM ServiceProviders where ID=#{self.id}")

      if res != 0
        column_value_pairs = ''
        column_value_pairs += (database.quote_column_name('CreatedAt') + ' = ' + database.quote(self.created_at) + ",")
        column_value_pairs += (database.quote_column_name('UpdatedAt') + ' = ' + database.quote(self.updated_at) + ",")
        column_value_pairs += (database.quote_column_name('Deleted') + ' = ' + database.quote(self.deleted) + ",")
        column_value_pairs += (database.quote_column_name('Birthdate') + ' = ' + database.quote(self.birthdate) + ",")
        column_value_pairs += (database.quote_column_name('Description') + ' = ' + database.quote(self.description) + ",")
        column_value_pairs += (database.quote_column_name('UserID') + ' = ' + database.quote(self.user_id) + ",")
        column_value_pairs += (database.quote_column_name('CompanyID') + ' = ' + database.quote(self.company_id) + ",")
        column_value_pairs += (database.quote_column_name('DeletedAt') + ' = ' + database.quote(self.deleted_at) + ",")
        column_value_pairs += (database.quote_column_name('CreatedByUserID') + ' = ' + database.quote(self.created_by_user_id))
        
        database.execute("UPDATE ServiceProviders SET #{column_value_pairs} WHERE ID = #{self.id}")
      else

        column_names=['ID','CreatedAt','UpdatedAt', 'Deleted','Birthdate','Description','UserID',
          'CompanyID','DeletedAt','CreatedByUserID'].map { |name| database.quote_column_name(name) }.join(",")
        dd = self.deleted_at.to_datetime unless self.deleted_at.nil?
        cd = self.created_at.to_datetime unless self.created_at.nil?
        ud = self.updated_at.to_datetime unless self.updated_at.nil?
        deleted = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(self.deleted) unless self.deleted.nil?
        bd = self.birthdate.to_datetime unless self.birthdate.nil?

        values = [self.id,cd,ud,deleted,bd,self.description,self.user_id,self.company_id,
          dd,self.created_by_user_id].map { |value| database.quote(value) }.join(",")
        database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:ServiceProviders, column_names, values])

      end

    rescue
    end
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.establish_connection(RAILS_ENV)
  end


  def self.find_service_provider(id)
    first :conditions => {'id' => id}, :include => [:service_provider_employee_mappings => [:user]]
  end

  def self.all_wfm
    all :conditions => ['for_wfm']
  end

  #  :all, :include=>[:user],:conditions=>["user_roles.role_id=?",role_id]

  def self.find_secretary(id)
    first :conditions => ['id = ?', id], :include => [{:user => :clusters}]
  end

  # Assigned service provider to all the selected cluster employees
  # and subproduct_assignement
  def cluster_assignment(cluster_id)
    cluster = Cluster.find(cluster_id)
    clusterusers = cluster.all_lawfirm_users
    for lwfusers in clusterusers
      livian_user_mapped = Physical::Liviaservices::ServiceProviderEmployeeMappings.find_by_employee_user_id_and_service_provider_id(lwfusers.user_id,self.id)
      unless livian_user_mapped
        Physical::Liviaservices::ServiceProviderEmployeeMappings.create(:service_provider_id => self.id, :employee_user_id => lwfusers.user_id, :status => 1, :priority => nil)
        lawfirm_user_subproducts = lwfusers.user.subproduct_assignments
        lawfirm_user_subproducts.each do |subproduct|
          SubproductAssignment.create(:user_id => self.user_id, :subproduct_id => subproduct.subproduct_id, :employee_user_id => lwfusers.user_id, :product_licence_id => subproduct.product_licence_id, :company_id => lwfusers.company_id)
        end
      end
    end
  end


  def update_role(role_id)
    user = self.user
    role = user.role :include => [{:categories => {:work_types => :work_subtypes}}]
    sec_role = Role.find_by_name('secretary', :include => [{:categories => {:work_types => :work_subtypes}}])
    if role_id == "" && role.id != sec_role.id
      user.user_role.update_attributes(:role_id => sec_role.id)
      #      delete_user_work_subtypes(user,role)
      #      create_user_work_subtypes(user,sec_role)
    elsif role_id != "" && role.id != role_id.to_i
      user.user_role.update_attributes(:role_id => role_id.to_i)
      new_role = Role.find(role_id.to_i, :include => [{:categories => {:work_types => :work_subtypes}}])
      #      delete_user_work_subtypes(user,role)
      #      create_user_work_subtypes(user,new_role)
    end
  end

  # updating type of the service provider
  def update_provider_type(params)
    unless params[:type].blank?
      self.provider_type = 0
      params[:type].each do|e|
        self.provider_type |= e.to_i
      end
    else
      self.provider_type = 1
    end
    self.save
  end

  def has_common_pool_access?
    self.provider_type & 4 == 4
  end

  def has_back_office_access?
    self.provider_type & 2 == 2
  end

  def has_front_office_access?
    self.provider_type & 1 == 1
  end

  def has_common_pool_or_back_office_access?
    has_common_pool_access? or has_back_office_access?
  end

  def assign_categories
    c_name=[];
    if self.has_front_office_access?
      c_name.push("Livian")
    end
    if self.has_back_office_access?
      c_name.push("Back Office")
    end
    if self.has_common_pool_access?
      c_name.push("Common Pool")
    end
    c_name
  end
end

# == Schema Information
#
# Table name: service_providers
#
#  id                   :integer         not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  deleted              :boolean         default(FALSE)
#  salutation           :integer
#  birthdate            :date
#  description          :text
#  user_id              :integer         not null
#  company_id           :integer         not null
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  created_by_user_id   :integer
#  is_cpa               :boolean
#

