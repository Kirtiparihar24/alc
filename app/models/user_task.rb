class UserTask < ActiveRecord::Base
  include Wfm::TaskActivities
  include ImportTask

  set_table_name "tasks"
  attr_accessor :task_type
  attr_accessor :start_time, :due_time
  
  belongs_to  :user,:foreign_key => :assigned_to_user_id
  #  belongs_to :provider, :class_name => "ServiceProvider", :foreign_key => 'created_by_user_id'
  belongs_to :logged_by, :class_name => "User", :foreign_key => 'created_by_user_id'
  belongs_to :receiver, :class_name => "User", :foreign_key => 'assigned_by_employee_user_id'
  belongs_to :assigned_user, :class_name => "User", :foreign_key => 'assigned_to_user_id'
  belongs_to :assigned_by_user, :class_name => "User", :foreign_key => 'assigned_by_user_id'
  belongs_to :completed_by, :class_name => "User", :foreign_key => 'completed_by_user_id'
  belongs_to :parent_task, :class_name => "UserTask", :foreign_key => 'parent_id'
  has_many :activities, :as => :subject, :order => 'created_at DESC'
  belongs_to :work_subtype
  belongs_to :category
  belongs_to :work_subtype_complexity
  belongs_to :communication, :foreign_key => :note_id
  has_many :comments
  has_many :document_homes, :as => :mapable
  has_many :audits, :as => :auditable
  has_many :sub_tasks, :class_name => "UserTask", :foreign_key => 'parent_id'
  has_many :notifications, :as => :notification, :order => 'created_at DESC', :dependent => :destroy
  acts_as_commentable
  acts_as_paranoid
  acts_as_audited :only => [:assigned_to_user_id, :work_subtype_id,:created_by_user_id,:due_at,:start_at,:completed_at,:priority]

  validates_presence_of :created_by_user_id
  validates_presence_of :name, :message => "Task can not be blank"
  validates_presence_of :work_subtype_id, :message => "Work Sub-Type can not be blank"
  validates_presence_of :start_at, :if => :is_repeat_task?, :message => "Start at can not be blank"
  validates_numericality_of :tat, :greater_than => 0, :only_integer => true, :message => "TAT must be greater than zero", :if => Proc.new { |task| task.tat.present? }
  validates_numericality_of :stt, :greater_than => 0, :only_integer => true, :message => "STT must be greater than zero", :if => Proc.new { |task| task.stt.present? }

  #validates_length_of :name, :maximum => 1000, :message => "Task name cannot be more than 1000."

  named_scope :latest_repeat_instance, lambda{|task_id,task_name| {:conditions=>["name = ? AND parent_id = ? AND original_start_at IS NOT NULL ",task_name,task_id], :order=>"original_start_at DESC", :limit=>1}}
  named_scope :repeat_tasks, lambda{|task_id,task_name| {:conditions=>["name = ? AND parent_id = ? AND original_start_at IS NOT NULL",task_name,task_id]}}
  named_scope :open_tasks, :conditions=>"status is null"
  named_scope :open_future_repeat_tasks, lambda{|task|{:conditions => ["name = ? AND parent_id = ? AND status IS NULL AND start_at > ? AND original_start_at IS NOT NULL", task.name, task.id, Time.now]}}
  
  named_scope :get_assigned_user_tasks,lambda{|user_id|{:conditions=>["assigned_to_user_id=? and status IS NULL and (repeat IS NULL or repeat = '')", user_id]}}
  named_scope :count_assigned_user_tasks,lambda{|user_id,due_till|{:select=>'count(*) as new_tasks', :conditions=>["assigned_to_user_id = ? and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?", user_id,due_till]}}
  named_scope :overdue_task_count,lambda{|user_ids, due_less_than|{:select=>'count(*) as overdue_tasks', :conditions=>["assigned_to_user_id in (?) and status IS NULL and due_at < ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than]}}
  named_scope :upcomming_task_count,lambda{|user_ids,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["assigned_to_user_id in (?) and status IS NULL and due_at < ? and due_at >= ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than,due_greater_than]}}
  named_scope :todays_task_count,lambda{|user_ids, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["assigned_to_user_id in (?) and status IS NULL and due_at < ? and due_at >= ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than,due_greater_than]}}
  named_scope :count_assigned_by_lawyers,lambda{|user_ids,due_till|{:select=>'count(*) as new_tasks', :conditions=>["assigned_by_employee_user_id in (?) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?", user_ids,due_till]}}
  
  # task count for manager with front office, back office and common pool access
  named_scope :count_for_fo_cp_bo_manager,lambda{|lawyer_ids,cp_livian_ids,skills_id,due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?) or assigned_to_user_id is null) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",lawyer_ids,cp_livian_ids,skills_id,due_till]}}
  # task count for manager with front office and common pool access
  named_scope :count_for_fo_cp_manager,lambda{|lawyer_ids,cp_livian_ids,bo_skills_id, due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",lawyer_ids,cp_livian_ids,bo_skills_id,due_till]}}
  # task count for manager with front office and back office access
  named_scope :count_for_fo_bo_manager,lambda{|lawyer_ids,livian_ids,skills_id, due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?)) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",lawyer_ids, livian_ids, skills_id, due_till]}}
  # task count for manager with common pool and back office access
  named_scope :count_for_cp_bo_manager,lambda{|cp_livian_ids,bo_skills_id,skills_id, due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?)) or work_subtype_id in (?)) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",cp_livian_ids,bo_skills_id,skills_id, due_till]}}
  # task count for manager with common pool access
  named_scope :count_for_cp_manager,lambda{|cp_livian_ids,bo_skills_id, due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",cp_livian_ids,bo_skills_id, due_till]}}
  # task count for manager with back office access
  named_scope :count_for_bo_manager,lambda{|livian_ids, skills_id, due_till|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_to_user_id in (?) or work_subtype_id in (?)) and status IS NULL and (repeat IS NULL or repeat = '') and due_at < ?",livian_ids, skills_id, due_till]}}

  named_scope :overdue_count_for_fo_cp_bo_manager,lambda{|lawyer_ids,cp_livian_ids,skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["((assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?) or assigned_to_user_id is null) and due_at < ?) and status IS NULL and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,skills_id,due_less_than]}}
  named_scope :overdue_count_for_fo_cp_manager,lambda{|lawyer_ids,cp_livian_ids,bo_skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["((assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and due_at < ?) and status IS NULL and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,bo_skills_id,due_less_than]}}
  named_scope :overdue_count_for_fo_bo_manager,lambda{|lawyer_ids,livian_ids,skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["((assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?)) and due_at < ?) and status IS NULL and (repeat IS NULL or repeat = '')",lawyer_ids,livian_ids,skills_id,due_less_than]}}
  named_scope :overdue_count_for_cp_bo_manager,lambda{|cp_livian_ids,bo_skills_id,skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["((assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?)) or work_subtype_id in (?))and due_at < ?) and status IS NULL and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,skills_id,due_less_than]}}
  named_scope :overdue_count_for_fo_manager,lambda{|user_ids,due_less_than|{:select=>'count(*) as overdue_tasks', :conditions=>["assigned_by_employee_user_id in (?) and status IS NULL and due_at < ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than]}}
  named_scope :overdue_count_for_cp_manager,lambda{|cp_livian_ids,bo_skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["((assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and due_at < ?) and status IS NULL and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,due_less_than]}}
  named_scope :overdue_count_for_bo_manager,lambda{|livian_ids, skills_id,due_less_than|{:select=>'count(*) as new_tasks', :conditions=>["(assigned_to_user_id in (?) or work_subtype_id in (?)) and due_at < ? and status IS NULL and (repeat IS NULL or repeat = '')",livian_ids, skills_id,due_less_than]}}

  named_scope :upcomming_count_for_fo_cp_bo_manager,lambda{|lawyer_ids,cp_livian_ids,skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?) or assigned_to_user_id is null) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,skills_id,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_fo_cp_manager,lambda{|lawyer_ids,cp_livian_ids,bo_skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,bo_skills_id,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_fo_bo_manager,lambda{|lawyer_ids,livian_ids,skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?)) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids,livian_ids,skills_id,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_cp_bo_manager,lambda{|cp_livian_ids,bo_skills_id,skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?)) or work_subtype_id in (?)) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,skills_id,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_fo_manager,lambda{|user_ids,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["assigned_by_employee_user_id in (?) and status IS NULL and due_at < ? and due_at >= ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_cp_manager,lambda{|cp_livian_ids,bo_skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,due_less_than,due_greater_than]}}
  named_scope :upcomming_count_for_bo_manager,lambda{|livian_ids, skills_id,due_less_than,due_greater_than|{:select=>'count(*) as upcomming_tasks', :conditions=>["(assigned_to_user_id in (?) or work_subtype_id in (?)) and due_at < ? and due_at >= ? and status IS NULL and (repeat IS NULL or repeat = '')",livian_ids, skills_id,due_less_than, due_greater_than]}}

  named_scope :todays_count_for_fo_cp_bo_manager,lambda{|lawyer_ids,cp_livian_ids,skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?) or assigned_to_user_id is null) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,skills_id,due_less_than,due_greater_than]}}
  named_scope :todays_count_for_fo_cp_manager,lambda{|lawyer_ids,cp_livian_ids,bo_skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids,cp_livian_ids,bo_skills_id,due_less_than,due_greater_than]}}
  named_scope :todays_count_for_fo_bo_manager,lambda{|lawyer_ids,livian_ids,skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_by_employee_user_id in (?) or assigned_to_user_id in (?) or work_subtype_id in (?)) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",lawyer_ids, livian_ids, skills_id, due_less_than, due_greater_than]}}
  named_scope :todays_count_for_cp_bo_manager,lambda{|cp_livian_ids,bo_skills_id,skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?)) or work_subtype_id in (?)) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,skills_id,due_less_than,due_greater_than]}}
  named_scope :todays_count_for_fo_manager,lambda{|user_ids, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["assigned_by_employee_user_id in (?) and status IS NULL and due_at < ? and due_at >= ? and (repeat IS NULL or repeat = '')", user_ids,due_less_than,due_greater_than]}}
  named_scope :todays_count_for_cp_manager,lambda{|cp_livian_ids,bo_skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_to_user_id in (?) or (assigned_to_user_id is null and work_subtype_id not in (?))) and (due_at < ? and due_at >= ? and status IS NULL) and (repeat IS NULL or repeat = '')",cp_livian_ids,bo_skills_id,due_less_than,due_greater_than]}}
  named_scope :todays_count_for_bo_manager,lambda{|livian_ids, skills_id, due_less_than, due_greater_than|{:select=>'count(*) as todays_tasks', :conditions=>["(assigned_to_user_id in (?) or work_subtype_id in (?)) and due_at < ? and due_at >= ? and status IS NULL and (repeat IS NULL or repeat = '')",livian_ids, skills_id, due_less_than, due_greater_than]}}

  before_save :set_due_at
  
  PRIORITIES = [["Normal","1"],["Urgent","2"]]
  REPEAT_OPTIONS = [["Never", nil], ["Daily", "DAI"], ["Weekly", "WEE"], ["Monthly", "MON"], ["Annualy", "ANU"]]

  # Below code is used to show Lawyer's full name.
  def get_lawyer
    #if self.asset_type == "Communication"
    note = Communication.find(self.asset_id, :include => :receiver)
    return note.receiver.try(:full_name)
    #end
  end

  # Below code is used to show all the task related to selected secretary id.
  def self.get_all_secratary_details_task_list(secratary)
    secratary.blank? ? all(:conditions => ["assigned_to_user_id IS NULL AND (status != 'complete' OR status IS NULL)"], :include => [:communication => [:receiver => [:service_provider_employee_mappings => :service_provider]]]) : all(:conditions => ["assigned_to_user_id = ? AND (status != 'complete' OR status IS NULL)", secratary], :include => [:communication => [:receiver => [:service_provider_employee_mappings => :service_provider]]])
  end

  # Below code is used to show all the  assigned task details by secretary on passing the service_providers id.
  def self.get_task_assigned_to_secretary(service_providers)
    @get_task_assigned_to_secretary = all(:include => :user, :conditions => ["share_with_client AND assigned_by_employee_user_id IN (?) AND (status IS NULL  OR status != 'complete')", service_providers], :order => "created_at DESC")
  end

  # Below code is used to show all the completed task details by secretary on passing the service_providers id.
  # If current user is livian,then will show all tasks for lawyer. Else shows tasks that have 'share_with_client' as true
  def self.get_task_completed_to_secretary(lawyer,is_secretary_or_team_manager,from_date=nil,to_date=nil)
    conditions = " AND (repeat IS NULL or repeat = '')"
    conditions += " AND share_with_client = true" unless is_secretary_or_team_manager
    if from_date && to_date
      from_date = Time.zone.parse(from_date).utc
      to_date   = Time.zone.parse(to_date).utc + 1.day
      all(:select => 'id, share_with_client,created_at, name, completed_at, completed_by_user_id', :conditions => ["assigned_by_employee_user_id IN (?) AND status LIKE 'complete' AND completed_at >= ? AND completed_at < ? #{conditions}", lawyer, from_date, to_date], :order => "created_at DESC")
    else
      default_time = Time.zone.parse(Time.zone.now.utc.to_date.strftime) - 1.week
      all(:select => 'id, share_with_client, created_at, name, completed_at, completed_by_user_id', :conditions => ["assigned_by_employee_user_id IN (?) AND status LIKE 'complete' AND completed_at >= ? #{conditions}", lawyer,default_time], :order => "created_at DESC")
    end
  end 

  # returns open tasks for the lawyer
  # If current user is livian,then will show all tasks for lawyer. Else shows tasks that have 'share_with_client' as true
  def self.get_outstanding_tasks(lawyer_id,is_secretary_or_team_manager,to_date)
    generate_repeat_task_instances_for_outstanding_tasks(lawyer_id,is_secretary_or_team_manager,to_date)
    to_date = Time.zone.parse(to_date).utc + 1.day
    conditions = " AND (repeat IS NULL or repeat = '')"
    conditions += " AND share_with_client = true" unless is_secretary_or_team_manager
    conditions = ["assigned_by_employee_user_id = ? AND status is null AND  due_at < ? #{conditions}", lawyer_id, to_date]
    all(:select => 'id,share_with_client,start_at,due_at,name,priority', :conditions => conditions, :order => "due_at DESC")
  end

  def get_stt
    unless stt.nil?
      stt
    else
      work_subtype_complexity ? work_subtype_complexity.stt : ""
    end
  end


  def get_tat
    unless tat.nil?
      tat
    else
      work_subtype_complexity ? work_subtype_complexity.tat : ""
    end
  end

  def set_due_at
    tat = self.get_tat
    due = self.start_at.present? ? self.start_at : self.communication.created_at
    if self.due_at.blank?
      self.due_at = due + (60 * 60 * tat.to_i) unless tat.blank?
    end
  end

  def self.filter_index_by(option,id,page)
    case option
    when 'lawyer'
      all(:conditions => ['status IS NULL AND assigned_by_employee_user_id = ?', id]).paginate :page => page, :per_page => 10
    when 'priority'
      all(:conditions => ['status IS NULL AND priority = ?', id]).paginate :page => page, :per_page => 10
    when 'work_subtype'
      all(:conditions => ['status IS NULL AND work_subtype_id = ?', id]).paginate :page => page, :per_page => 10
    when 'assigned_to'
      all(:conditions => ['status IS NULL AND assigned_to_user_id=?', id]).paginate :page => page, :per_page => 10
    when 'cluster'
      cluster = Cluster.find id
      lawfirm_users = []
      cluster.all_lawfirm_users.collect{|lawfirm_user| lawfirm_users << lawfirm_user.id}
      all(:conditions => ['status IS NULL AND assigned_by_employee_user_id IN (?)', lawfirm_users]).paginate :page => page, :per_page => 10
    end
  end

  def self.all_tasks(user_ids)
    all :conditions => ['assigned_to_user_id IN (?) AND status IS NULL', user_ids]
  end

  # returning tasks based on filter parameters
  def self.get_tasks(params,user_ids,secretary,current_user,cluster_livian_user_ids,lawyer_ids,order)
    if secretary
      conditions = get_secretary_conditions(params,current_user,cluster_livian_user_ids,lawyer_ids)
    else
      conditions = get_manager_conditions(params,user_ids,current_user,cluster_livian_user_ids)
    end
    date_today = Time.zone.now.utc.to_date.strftime
    due_geater_than = Time.zone.parse(date_today).utc
    due_less_than = due_geater_than + 1.day
    if params[:search].present?
      employee_user_ids = params[:search][:employee_user_ids].reject(&:blank?) if params[:search][:employee_user_ids].present?
      conditions = "(" + conditions + ")" + " and assigned_by_employee_user_id in (#{employee_user_ids.join(',')})" unless employee_user_ids.blank?
      
      case params[:search][:status]
      when "Overdue"
        conditions = "(" + conditions + ")" + " and due_at < '#{due_geater_than}'"
      when "Today"
        conditions = "(" + conditions + ")" + " and due_at < '#{due_less_than}' and due_at >= '#{due_geater_than}'"
      when "Upcoming"
        conditions = "(" + conditions + ")" + " and due_at < '#{due_less_than+7.day}' and due_at >= '#{due_less_than}'"
      end

      if params[:search][:status] == "Completed"
        from_date = Time.zone.parse(params[:search][:from_date]).utc
        to_date = Time.zone.parse(params[:search][:to_date]).utc + 1.day
        conditions = "(" + conditions + ")" + " and status='complete' and completed_at < '#{to_date}' AND completed_at >='#{from_date}'"
      else
        conditions = "(" + conditions + ")" + " and status IS NULL"
        generate_repeat_instances = true
      end
      
      unless params[:search][:company_id].blank?
        conditions = "(" + conditions + ")" + " and company_id = '#{params[:search][:company_id]}'"
      end

      unless params[:search][:priority].blank?
        conditions = "(" + conditions + ")" + " and priority = '#{params[:search][:priority]}'"
      end
    else
      conditions = "(" + conditions + ")" + " and status IS NULL"
      generate_repeat_instances = true
    end
    if params[:search].present? && !params[:search][:due_at].blank?
      due_date = Time.zone.parse(params[:search][:due_at]).utc + 1.day
    else
      due_date = due_geater_than + 8.day
    end
    generate_recurring_task_instances(conditions,due_date) if generate_repeat_instances
    conditions = "(" + conditions + ")" + " and due_at < '#{due_date}' and (repeat IS NULL or repeat = '')" unless params[:search].present? && params[:search][:status] == "Completed"
    if params[:order_to].blank?
      join_to = ""
    elsif params[:order_to] == 'Assigned To'
      join_to = "LEFT OUTER JOIN users ON users.id = tasks.assigned_to_user_id"
    elsif params[:order_to] == 'Assigned By'
      join_to = "LEFT OUTER JOIN users ON users.id = tasks.assigned_by_user_id"
    else
      join_to = "LEFT OUTER JOIN users ON users.id = tasks.assigned_by_employee_user_id"
    end
    
    if join_to.blank?
      paginate :include=>[:work_subtype], :conditions => conditions, :order => order, :page => params[:page], :per_page => params[:per_page] || 10
    else
      paginate :joins => join_to, :include=>[:work_subtype], :conditions => conditions, :order => order, :page => params[:page], :per_page => params[:per_page] || 10
    end
  end

  def self.get_secretary_conditions(params,current_user,cluster_livian_user_ids,lawyer_ids)
    if params[:search].present? && params[:search][:all_clusters] == "1"
      conditions = "assigned_by_employee_user_id in (#{lawyer_ids.join(',')})"
    elsif params[:search].present? && params[:search][:my_clusters] == "1"
      conditions= "assigned_by_employee_user_id in (#{lawyer_ids.join(',')}) and assigned_to_user_id in (#{cluster_livian_user_ids.join(',')})"
    else
      conditions= "assigned_to_user_id = #{current_user.id}"
    end
    conditions
  end

  def self.get_manager_conditions(params,user_ids,current_user,cluster_livian_user_ids)
    if params[:search].present?
      if !params[:search][:user_id].blank?
        ids = params[:search][:user_id]
        conditions= "assigned_to_user_id in (#{ids})"
      elsif !params[:search][:cluster_id].blank?
        cluster = Cluster.find(params[:search][:cluster_id])
        ids = cluster.livians.map(&:id).join(',')
        ids = [0] if ids.blank?
        conditions= "assigned_to_user_id in (#{ids})"
      else
        ids = user_ids.join(',')
      end
    else
      ids = user_ids.join(',')
    end
    ids = [0] if ids.blank?
    conditions= "assigned_by_employee_user_id in (#{ids})" if conditions.blank?
    if current_user.belongs_to_common_pool
      cp_livian = Cluster.get_common_pool_livian_users
      cp_livian_ids = cp_livian.map(&:id)
      cp_livian_ids = [0] if cp_livian_ids.blank?
      bo_work_subtypes = WorkSubtype.back_office_work_subtypes
      bo_work_subtype_ids = bo_work_subtypes.map(&:id)
      bo_work_subtype_ids = [0] if bo_work_subtype_ids.blank?
      conditions = "(" + conditions + " or assigned_to_user_id in (#{cp_livian_ids.join(',')}) or (assigned_to_user_id is null and work_subtype_id not in (#{bo_work_subtype_ids.join(',')})))"
    end
    if current_user.belongs_to_back_office
      skills_id = current_user.get_users_bo_skills.map(&:id)
      skills_id = [0] if skills_id.blank?
      if !params[:search].blank? && (!params[:search][:user_id].blank? || !params[:search][:cluster_id].blank?)
        conditions = "(" + conditions + ")"  + " and " + "( work_subtype_id in (#{skills_id.join(',')})) or assigned_to_user_id in (#{cluster_livian_user_ids.join(',')})" 
      else
        conditions = "(" + conditions + ")"  + " or " + "( work_subtype_id in (#{skills_id.join(',')})) or assigned_to_user_id in (#{cluster_livian_user_ids.join(',')})" 
      end
    end
    conditions
  end

  def self.create_tasks(params,note,user_id,from_edit=false)
    cnt = 0
    livian_user = User.find(user_id)
    parent_ids,task_errors,valid_tasks = [],[],[]
    created_by_lawyer = note.logged_by.employee.present? ? true : false if note && note.logged_by
    tasks = set_repeat_schedule(params,note,user_id)
    tasks.each do |task|
      unless task.work_subtype_id.nil?
        work_subtype = WorkSubtype.find(task.work_subtype_id)
        task.category_id = work_subtype.work_type.category_id
        if task.work_subtype_complexity_id.nil?
          complexities = work_subtype.work_subtype_complexities
          task.work_subtype_complexity_id = complexities.first.id unless complexities.blank?
        end
      end
      if task.status == "complete"
        task.completed_by_user_id = user_id
        task.completed_at = Time.now
      else
        task.status = nil
      end
      if !task.start_at.blank?
        task.set_task_start_date(livian_user)
      end
      if !task.due_at.blank?
        task.set_tast_due_date(livian_user)
      end
      if task.valid?
        valid_tasks << task
      else
        task.errors.each { |error| task_errors.push(error[1])}
      end
    end
    if task_errors.blank?
      tasks.each do |task|
        task.save
        if from_edit
          parent_ids << params[:id]
        else
          parent_ids << task.id
        end
        task.update_attribute(:parent_id,parent_ids.first) if task.parent_id.present? && parent_ids.first.to_i != task.id.to_i
        Document.assign_documents(task,note,user_id,created_by_lawyer) unless from_edit
        task.create_default_repeat_instances if task.is_repeat_task?
        cnt = cnt+1
      end
    end
    return cnt,task_errors.uniq
  end

  def self.get_user_data_for_task_count(user)
    fo_access = user.service_provider.has_front_office_access?
    bo_access = user.service_provider.has_back_office_access?
    cp_access = user.service_provider.has_common_pool_access?
    cp_livian_ids,skills_id,bo_skills_id=[],[],[]
    if cp_access
      cp_livian = Cluster.get_common_pool_livian_users
      cp_livian_ids = cp_livian.map(&:id)
      cp_livian_ids = [0] if cp_livian_ids.blank?
      bo_skills = WorkSubtype.back_office_work_subtypes
      bo_skills_id = bo_skills.map(&:id)
    end
    skills_id = user.get_users_bo_skills.map(&:id) if bo_access
    return fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id
  end


  def self.get_task_count(lawyer_user_ids,livian_user_ids,secretary,user,params=nil)
    date = Time.zone.now.utc.to_date.strftime
    due_geater_than = Time.zone.parse(date).utc
    due_less_than = due_geater_than + 1.day
    if params && params[:search].present? && !params[:search][:due_at].blank?
      due_till = Time.zone.parse(params[:search][:due_at]).utc + 1.day
    else
      due_till = due_geater_than + 8.day
    end
    if secretary
      task_count = count_assigned_user_tasks(livian_user_ids,due_till)[0].new_tasks
      overdue_task_count  = overdue_task_count(livian_user_ids,due_geater_than)[0].overdue_tasks.to_i
      upcoming_task_count = upcomming_task_count(livian_user_ids,due_less_than+7.day,due_less_than)[0].upcomming_tasks.to_i
      todays_task_count   = todays_task_count(livian_user_ids,due_less_than,due_geater_than)[0].todays_tasks.to_i
    else
      fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id = get_user_data_for_task_count(user)
      cp_and_cluster_user_ids = (livian_user_ids + cp_livian_ids).uniq
      if fo_access && cp_access && bo_access
        task_count = count_for_fo_cp_bo_manager(lawyer_user_ids, cp_and_cluster_user_ids, skills_id, due_till)[0].new_tasks
      elsif fo_access && cp_access
        task_count = count_for_fo_cp_manager(lawyer_user_ids,cp_livian_ids,bo_skills_id, due_till)[0].new_tasks
      elsif fo_access && bo_access
        task_count = count_for_fo_bo_manager(lawyer_user_ids,livian_user_ids,skills_id, due_till)[0].new_tasks
      elsif bo_access && cp_access
        task_count = count_for_cp_bo_manager(cp_and_cluster_user_ids, bo_skills_id,skills_id, due_till)[0].new_tasks
      elsif fo_access
        task_count = count_assigned_by_lawyers(lawyer_user_ids,due_till)[0].new_tasks
      elsif cp_access
        task_count = count_for_cp_manager(cp_livian_ids,bo_skills_id, due_till)[0].new_tasks
      elsif bo_access
        task_count = count_for_bo_manager(livian_user_ids, skills_id, due_till)[0].new_tasks
      end
      overdue_task_count,upcoming_task_count,todays_task_count = compute_alert_task_counts(lawyer_user_ids,fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id,due_less_than,due_geater_than,livian_user_ids)
    end
    return task_count,overdue_task_count,upcoming_task_count,todays_task_count
  end

  def self.get_alert_task_counts(lawyer_user_ids,livian_user_ids,secretary,user)
    date_today = Time.zone.now.utc.to_date.strftime
    due_geater_than = Time.zone.parse(date_today).utc
    due_less_than = due_geater_than + 1.day
    if secretary
      overdue_task_count  = overdue_task_count(livian_user_ids,due_less_than)[0].overdue_tasks.to_i
      upcoming_task_count = upcomming_task_count(livian_user_ids,due_less_than+7.day,due_less_than)[0].upcomming_tasks.to_i
      todays_task_count   = todays_task_count(livian_user_ids,due_less_than,due_geater_than)[0].todays_tasks.to_i
    else
      fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id = get_user_data_for_task_count(user)
      overdue_task_count,upcoming_task_count,todays_task_count = compute_alert_task_counts(lawyer_user_ids,fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id,due_less_than,due_geater_than,livian_user_ids)
    end
    return overdue_task_count,upcoming_task_count,todays_task_count
  end

  def self.compute_alert_task_counts(lawyer_user_ids,fo_access,bo_access,cp_access,cp_livian_ids,skills_id,bo_skills_id,due_less_than,due_geater_than,livian_user_ids)
    cp_and_cluster_user_ids = (livian_user_ids + cp_livian_ids).uniq
    if fo_access && cp_access && bo_access
      overdue_task_count = overdue_count_for_fo_cp_bo_manager(lawyer_user_ids,cp_and_cluster_user_ids,skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_fo_cp_bo_manager(lawyer_user_ids,cp_and_cluster_user_ids,skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_fo_cp_bo_manager(lawyer_user_ids,cp_and_cluster_user_ids,skills_id,due_less_than,due_geater_than)[0].todays_tasks
    elsif fo_access && cp_access
      overdue_task_count = overdue_count_for_fo_cp_manager(lawyer_user_ids,cp_livian_ids,bo_skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_fo_cp_manager(lawyer_user_ids,cp_livian_ids,bo_skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_fo_cp_manager(lawyer_user_ids,cp_livian_ids,bo_skills_id,due_less_than,due_geater_than)[0].todays_tasks
    elsif fo_access && bo_access
      overdue_task_count = overdue_count_for_fo_bo_manager(lawyer_user_ids,livian_user_ids,skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_fo_bo_manager(lawyer_user_ids,livian_user_ids,skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_fo_bo_manager(lawyer_user_ids,livian_user_ids,skills_id,due_less_than,due_geater_than)[0].todays_tasks
    elsif bo_access && cp_access
      overdue_task_count = overdue_count_for_cp_bo_manager(cp_and_cluster_user_ids,bo_skills_id,skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_cp_bo_manager(cp_and_cluster_user_ids,bo_skills_id,skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_cp_bo_manager(cp_and_cluster_user_ids,bo_skills_id,skills_id,due_less_than,due_geater_than)[0].todays_tasks
    elsif fo_access
      overdue_task_count = overdue_count_for_fo_manager(lawyer_user_ids,due_geater_than)[0].overdue_tasks
      upcomming_task_count = upcomming_count_for_fo_manager(lawyer_user_ids,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_fo_manager(lawyer_user_ids,due_less_than,due_geater_than)[0].todays_tasks
    elsif cp_access
      overdue_task_count = overdue_count_for_cp_manager(cp_livian_ids,bo_skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_cp_manager(cp_livian_ids,bo_skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_cp_manager(cp_livian_ids,bo_skills_id,due_less_than,due_geater_than)[0].todays_tasks
    elsif bo_access
      overdue_task_count = overdue_count_for_bo_manager(livian_user_ids, skills_id,due_geater_than)[0].new_tasks
      upcomming_task_count = upcomming_count_for_bo_manager(livian_user_ids, skills_id,due_less_than+7.day,due_less_than)[0].upcomming_tasks
      todays_task_count = todays_count_for_bo_manager(livian_user_ids, skills_id,due_less_than,due_geater_than)[0].todays_tasks
    end
    return overdue_task_count.to_i,upcomming_task_count.to_i,todays_task_count.to_i
  end

  def logged_by_with_destroyed
    User.find_with_deleted(self.created_by_user_id)
  end

  def is_back_office_task?
    self.category.has_complexity if self.category.present?
  end

  def update_due_at(params,old_due_at)
    unless params[:task][:due_at].blank?
      due_at = Time.parse(params[:task][:due_at])
      if old_due_at.strftime("%d-%m-%Y %H:%M") == due_at.strftime("%d-%m-%Y %H:%M")
        tat = self.get_tat
        stars_at = self.start_at.present? ? self.start_at : self.communication.created_at
        new_due_at = stars_at + (60 * 60 * tat.to_i) unless tat.blank?
        self.due_at = new_due_at
        self.save
      end
    end
  end

  def task_object_for_histroy(type, value)
    case type
    when "work_subtype_id"
      return ["Work Sub-Type",WorkSubtype.find(value).name] rescue ["Work Sub-Type","<div style='color:red'>NOT FOUND </div>"]
    when "assigned_to_user_id"
      return ["Assigned User",value.blank? ? "Common Queue" : User.find_with_deleted(value).full_name ]
    when "priority"
      return ["Priority",value=="1" ? "Normal" : "Urgent"]
    when "start_at"
      return ["Start Date",value.blank? ? '' : value.in_time_zone.strftime("%m/%d/%Y %l:%M:%S %p")]
    when "due_at"
      return ["Due Date",value.blank? ? '' : value.in_time_zone.strftime("%m/%d/%Y %l:%M:%S %p")]
    when "completed_at"
      return ["Complete",value.blank? ? '' : value.in_time_zone.strftime("%m/%d/%Y %l:%M:%S %p")]
    end
  end

  # retrieves all the 'open' subtasks for a particular task excluding the parent task
  def self.all_children(parent_id)
    #find(parent_id).sub_tasks.open_tasks
    UserTask.find_by_sql("WITH RECURSIVE q AS(SELECT h, 1 AS level FROM tasks h WHERE parent_id = #{parent_id} AND status IS NULL and deleted_at is NULL UNION ALL SELECT hi, q.level + 1 AS level FROM q JOIN tasks hi ON hi.parent_id = (q.h).id and status is null and deleted_at is NULL) SELECT (q.h).* FROM q;")
  end
  
  def self.set_repeat_schedule(params,note,user_id)
    tasks = []
    params[:tasks].values.each { |task|
      if task[:repeat] == "WEE" && task[:repeat_wday].blank?
        task[:repeat_wday] = 2
      elsif task[:repeat] == "WEE" && !task[:repeat_wday].blank?
        wdays = task.delete(:repeat_wday)
        task[:repeat_wday] = 0
        wdays.each do|e|
          task[:repeat_wday] |= e.to_i
        end
      end
      tasks << UserTask.new(task.merge!(:assigned_by_user_id=>user_id,:created_by_user_id =>user_id,:assigned_by_employee_user_id =>note.assigned_by_employee_user_id,:company_id=>note.company_id,:note_id=>note.id,:time_zone => task[:time_zone]))
    }
    tasks
  end

  def self.check_validations(params,user)
    task_errors = []
    tasks = params[:tasks].values.collect { |task| UserTask.new(task.merge!(:created_by_user_id =>user.id))}
    tasks.each do |task|
      unless task.valid?
        task.errors.each { |error|
          task_errors.push(error[1])
        }
      end
    end
    task_errors.uniq
  end

  def set_task_start_date(livian_user)
    start_time = self.start_time.present? ? self.start_time.to_s : "00:00:00"
    start_date = Date.parse(self.start_at.to_s).strftime("%d-%m-%Y")
    lawyer_tz = self.time_zone
    livian_tz = livian_user.time_zone
    diff = (self.start_at.in_time_zone(lawyer_tz).utc_offset) - (self.start_at.in_time_zone(livian_tz).utc_offset)
    parsed_start_time = start_time
    new_start_date = DateTime.parse(start_date+" "+parsed_start_time)
    self.start_at = new_start_date.advance(:seconds=> -diff).strftime("%d-%m-%Y %H:%M:%S")
  end

  def set_tast_due_date(livian_user)
    due_time = self.due_time.present? ? self.due_time.to_s : "23:59:59"
    due_date = Date.parse(self.due_at.to_s).strftime("%d-%m-%Y")
    lawyer_tz = self.time_zone
    livian_tz = livian_user.time_zone
    diff = (self.due_at.in_time_zone(lawyer_tz).utc_offset) - (self.due_at.in_time_zone(livian_tz).utc_offset)
    parsed_due_time = due_time
    new_due_date = DateTime.parse(due_date+" "+parsed_due_time)
    self.due_at = new_due_date.advance(:seconds=> -diff).strftime("%d-%m-%Y %H:%M:%S")
  end

  def is_repeat_task?
    !repeat.nil? && repeat != ''
  end

  def repeat_wday?(day_val)
    repeat_wday & day_val == day_val
  end
  
  def update_repeat_instances
    repeat_tasks = UserTask.repeat_tasks(id,name).open_tasks
    if status == 'complete'
      past_repeat_tasks = repeat_tasks.select{|task| task.start_at <= Time.now}
      future_repeat_tasks = repeat_tasks.select{|task| task.start_at > Time.now}
      UserTask.update_all({:completed_at => Time.now, :status =>'complete', :completed_by_user_id => completed_by_user_id},['id in (?)', past_repeat_tasks.map(&:id)])
      UserTask.destroy_all(['id in (?)', future_repeat_tasks.map(&:id)])
    else
      future_repeat_tasks = repeat_tasks.select{|task| task.start_at > Time.now || (task.start_at == start_at && task.comments.blank? && task.document_homes.blank?)}
      UserTask.destroy_all(['id in (?)', future_repeat_tasks.map(&:id)])
      self.create_default_repeat_instances
    end
  end

  #find all documents count on releated to given tasks
  def self.find_all_doc(tasks)
    tasks.blank? ? 0 : DocumentHome.find(:all, :conditions => ["mapable_type = 'UserTask' AND mapable_id in (?)",tasks.map(&:id)]).count
  end

  #find all documents count on releated to given tasks
  def self.find_all_comments(tasks)
    tasks.blank? ? 0 : Comment.find(:all, :conditions => ["commentable_type = 'UserTask' AND commentable_id in (?)",tasks.map(&:id)]).count
  end
  
  #import task by excel file
  def self.import_task_by_excel(params,user_id)
    path_to_file = ImportTask::save_data_file(params[:import_file], user_id)
    ImportTask::task_entry_process_file(path_to_file, user_id)
  end

end

# == Schema Information
#
# Table name: tasks
#
#  id                           :integer         not null, primary key
#  assigned_to_user_id          :integer
#  completed_by_user_id         :integer
#  name                         :text            default(""), not null
#  note_id                      :integer
#  priority                     :string(32)
#  completed_at                 :datetime
#  deleted_at                   :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  status                       :string(255)
#  tasktype                     :integer
#  bucket                       :string(32)
#  due_at                       :datetime
#  company_id                   :integer
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  permanent_deleted_at         :time
#  assigned_by_employee_user_id :integer
#  category_id                  :integer
#  work_subtype_id              :integer
#  work_subtype_complexity_id   :integer
#  stt                          :integer
#  tat                          :integer
#  assigned_by_user_id          :integer
#  share_with_client            :boolean
#
