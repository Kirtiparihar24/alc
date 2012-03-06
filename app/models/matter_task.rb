# MatterTask category field was storing values todo and appointment.
# The fields have been renamed on the user view level, and todo is now reffered
# as activity and appointment is called schedule.

class MatterTask < ActiveRecord::Base
  #  serialize :selected_options, Hash
  
  include MatterPeoplesHelper
  include GeneralFunction
  acts_as_paranoid
  belongs_to :matter
  belongs_to :company
  belongs_to :matter_people ,:foreign_key => :assigned_to_matter_people_id,:with_deleted => true
  belongs_to :assigned_to_user, :foreign_key => :assigned_to_user_id, :class_name => "User"
  belongs_to :assigned_to_matter_people, :foreign_key => :assigned_to_matter_people_id, :class_name => "MatterPeople"
  belongs_to :company_activity_type ,:foreign_key=>:category_type_id
  #Not needed.
  #has_many  :documents, :as => :documentable, :dependent => :destroy
  has_and_belongs_to_many :document_homes
  has_and_belongs_to_many :matter_issues
  has_and_belongs_to_many :matter_risks ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad
  has_and_belongs_to_many :matter_facts ###Added for the Feature #7512 - Link task risk issue fact - all to all, added by shripad

 
  has_many :children, :foreign_key => :parent_id, :class_name => "MatterTask"
  acts_as_tree
  acts_as_commentable
  #before_save :set_start_date
  before_save :mark_complete,:reset_complete_date,:responsible_person_changed,:get_lawyer
  after_save :update_into_zimbra
  after_save :send_mail_to_associates
  before_save :set_attendees_emails  
  before_destroy :destroy_zimbra_matter_task
  after_destroy :destroy_instances
  before_validation :set_start_end_dates
  after_create :send_mail_to_attendees_on_create
  after_update :send_mail_to_attendees_on_update
  after_save :save_assigned_to_user
  after_update :complete_children
  after_save :open_parent_on_open_child
  before_save :occurrence_value
  # validate :check_if_parent_complete
  validate :start_end_date_should_not_equal
  validate :check_child_task_end_date
  validate :check_parent_tasks_end_date
  attr_accessor :start_date_appointment
  attr_accessor :end_date_appointment
  attr_accessor :start_date_todo
  attr_accessor :end_date_todo

  attr_accessor :start_time
  attr_accessor :end_time
  cattr_reader :per_page
  @@per_page=25
  has_and_belongs_to_many :matter_researches
  belongs_to :phase
  belongs_to :task_type, :class_name => "TaskType", :foreign_key => :category_type_id
  belongs_to :appointment_type, :class_name => "AppointmentType", :foreign_key => :category_type_id
  validates_presence_of :name,  :message => :name_blank
  validates_presence_of :start_date, :message => :start_date_blank
  # Done for different validation message for todo and appointment
  validates_presence_of :end_date, :message => :due_date_blank, :if => Proc.new { |matter_task| matter_task.category == "todo" }
  validates_presence_of :end_date, :message => :end_date_blank, :if => Proc.new { |matter_task| matter_task.category == "appointment" }

  validates_presence_of :assigned_to_matter_people_id, :message => :responsiblety_blank
  #  validates_uniqueness_of :name, :scope => [:matter_id,  :company_id ],:unless => :check_if_instance

  #  validate :completed_date_cannot_be_less_than_start
  validate :validate_start_due_date
  validate :completed_date_cannot_be_future
  validate :check_completed_at
  validate :check_parent
  validate :check_end_date
  # As per the new reqiurement instead of validating if the parent-task can be completed we have to enforce completion of all child tasks -Ketki
  #  validate :check_if_completable
  #  validate :occurrence_select, :unless => :from_zimbra
  #  validate :occurrence_value
  validate :check_until_date
  validates_length_of :name, :maximum => 255, :message => :too_long
  validates_length_of :description, :maximum => 512, :message => :too_long
  #skip_time_zone_conversion_for_attributes = :start_date,:end_date,:start_time,:end_time, :start_date_appointment, :end_date_appointment, :start_date_todo, :end_date_todo
  attr_reader :PRIORITIES
  attr_reader :PROGRESSES
  attr_reader :PROGRESS_PERCENTAGES
  attr_reader :SHOW_AS_OPTIONS
  attr_reader :MARK_AS_OPTIONS
  attr_reader :REPEAT_OPTIONS
  attr_reader :REMINDER_OPTIONS
  attr_reader :DAYS
  attr_accessor :time_zone
  attr_accessor :skip_on_create_instance, :from_zimbra
  #  attr_accessor :repeat_days, :poslist,
  attr_accessor :index_height

  PRIORITIES = {"Normal" => "5", "Low" => "9", "High" => "1"}
  PRIORITIES_REVERSE = {"1" => "High", "5" => "Normal", "9" => "Low"}  
  PROGRESSES = {"Not Started" => "NEED", "Completed" => "COMP", "In Progress" => "INPR", "Waiting on someone else" => "WAITING", "Deferred" => "DEFERRED"}
  PROGRESS_PERCENTAGES = [ "0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100" ]
  SHOW_AS_OPTIONS = { "Busy" => "B", "Free" => "F", "Out of office" => "O" }
  MARK_AS_OPTIONS = {"Public" => "PRI", "Private" => "PUB"}
  #REPEAT_OPTIONS = {"Never" => nil, "Every Day" => "DAI", "Every Week" => "WEE", "Every Month" => "MON", "Every Year" => "YEA"}
  REPEAT_OPTIONS = [["Never", nil], ["Every Day", "DAI"], ["Every Week", "WEE"], ["Every Month", "MON"], ["Every Year", "YEA"]]
  REMIND_OPTIONS = {"Never" => "0", "1 minute before" => "1"}
  #  DAYS = [["Sunday", "SU"], ["Monday", "MO" ], ["Tuesday", "TU"], ["Wednesday", "WE"], ["Thursday", "TH"], ["Friday", "FR" ], ["Saturday", "SA"]]
  #  DAYOFREPEAT = [["first", 1], ["second",  2], ["third", 3], ["fourth", 4], ["last", -1]]
  
  mins_hash = {}
  [5,10,15,30,45,60].collect {|e| mins_hash["#{e} minutes before"]= e.to_s }
  hours_hash = {}
  [2,3,4,5,18].collect {|e| hours_hash["#{e} hours before"]= (e*60).to_s }
  REMIND_OPTIONS.merge!(mins_hash)
  REMIND_OPTIONS.merge!(hours_hash)
  REMINDER_OPTIONS =  REMIND_OPTIONS.sort {|a,b| a[1].to_i <=> b[1].to_i }
  #   REPEAT_OPTIONS = REPEAT_OPTIONS.sort
  # find out open matter task where is not completed or it is an appoinment 
  named_scope :open_tasks,{:conditions=>"completed is null or completed = false or category ='appointment'"} 
  named_scope :open_todos,{:conditions=>"completed is null or completed = false and category ='todo'"} 
  named_scope :appointments,{ :conditions=>"category ='appointment'"} 
  named_scope :todos,{:conditions=>"category ='todo'"} 
  named_scope :today,lambda{|today_date|{:conditions=>"(category = 'todo' AND end_date = #{today_date}) OR (category = 'appointment' AND start_date = #{today_date}) "}}  
  named_scope :upcoming,lambda{|today_date,custom_days|{
            :conditions=>["category = ? AND end_date = ? 
                          OR category = ? AND start_date > ? and start_date <= ?",
                          'todo',today_date,'appoinment',today_date,today_date+custom_days.days]}}  
 named_scope :overdue,lambda{|today_date|{:conditions=>"(category = 'todo' AND end_date < #{today_date}) OR (category = 'appointment' AND start_date < #{today_date}) "}}   
 named_scope :assigned_tasks ,lambda {|matter_people_id| {:conditions=>"assigned_to_matter_people_id = #{matter_people_id}"} if matter_people_id}
  
 
  named_scope :with_order, lambda { |order|
    { :include=> :assigned_to_user,:order => order }
  }
  HUMANIZED_ATTRIBUTES = {
    :name => "Activity Name"
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def reset_complete_date
     self.completed_at = nil unless self.completed
    
   
  end

  def is_appointment?
    self.category.present? && self.category.eql?("appointment")
  end
  
  def check_if_completable
    if self.completed && self.any_child_open?
        self.errors.add('Could not complete the matter task:', "there are some open child tasks for this matter task.")

    end
  end

  # IF the task is completed in portal, mark its completion in zimbra also -- Mandeep (21/04/10)
  def mark_complete
    if self.completed
      self.progress = "COMP"
      self.progress_percentage = "100"
    elsif self.progress and !self.progress.eql?('COMP') and self.progress_percentage
      self.progress = self.progress
      self.progress_percentage = self.progress_percentage
    else
      self.progress = "INPR"
      self.progress_percentage = "0"
    end
  end

  # Called before save, this method is used as a helper for schedule/todo type
  # of task and their different date params to be merged into common fields in
  # the task table.
  def set_start_end_dates
    # If the task is a schedule/appointment type then we need to set the start
    #+ and end time for it. We save them in the same fields start_date,
    #+ end_date. The start_time and end_time fields are deprecated and they 
    #+ are used as place holders in form. They will be removed from table
    #+ definition.
    # Database migration and rake task is there to change field type for
    #+ start/end date. Now storing time and date in same fields.
    if self.category.eql?("appointment")
      self.start_date = self.start_date_appointment unless self.start_date_appointment.blank?
      self.end_date = self.end_date_appointment  unless self.end_date_appointment.blank?      
=begin
      if false && start_date && end_date
        sd = start_date.utc
        ed = end_date.utc
        st = start_time #.in_time_zone
        et = end_time        
        p sd, ed, st, et
        self.start_date = DateTime.new(sd.year, sd.month, sd.day, st.hour, st.min, st.sec).utc
        self.end_date = DateTime.new(ed.year, ed.month, ed.day, et.hour, et.min, et.sec)         
        p start_date
        p end_date
      end
=end
    else
      #self.start_date = self.end_date_todo unless self.end_date_todo.blank? #self.start_date_todo unless self.start_date_todo.blank?
      self.start_date = self.start_date_todo unless self.start_date_todo.blank?
      self.end_date = self.end_date_todo unless self.end_date_todo.blank?
    end
  end

  def open?
    if category.eql?('todo')
      completed == false || completed.nil?
    else
      !overdue?
    end
  end

  
  # Refactored code.
  # TODO: needs testing.
  def overdue?
    if is_appointment?
      start_date.to_date < Time.zone.now.to_date
    else
      open? && end_date.to_date < Time.zone.now.to_date
    end
  end

  def upcoming?
    # Check for user setting for login lawyer -- mandeep
    custom_days = User.current_lawyer.upcoming.try(:setting_value).try(:to_i) || Upcoming.create!(:setting_type=>'Upcoming',:setting_value=>30,:user_id=>User.current_lawyer.id,:company_id=>User.current_lawyer.company.id).setting_value.to_i
    today = Time.zone.now.to_date
    the_date = self.category.eql?("appointment") ? self.start_date.to_date : self.end_date.to_date
    if self.category.eql?("appointment")
      (the_date && the_date > today && the_date <= (today + custom_days.days))
    else
      open? && (the_date && the_date > today && the_date <= (today + custom_days.days))
    end    
  end

  def duedate
    self.category.eql?("appointment") ? self.start_date : self.end_date
  end

  def today?
    the_date = self.category.eql?("appointment") ? self.start_date.to_date : self.end_date.to_date
    open? && (the_date && the_date == Time.zone.now.to_date)
  end

  def assigned_to_current_lawyer?(euid)
    mp = MatterPeople.first(:conditions => ["matter_id = ? AND employee_user_id = ?", self.matter_id, euid])
    self.assigned_to_matter_people_id == mp.id
  end



  def get_lawyer
    lawyer = employee_from_matter_people_id(self.assigned_to_matter_people_id)
    self.lawyer_email =lawyer.email.to_s
    self.lawyer_name = lawyer.full_name.to_s
  end

  def set_start_date
    if self.category.eql?("todo")
      self.start_date = self.end_date
    end
  end

  # Return true of any of the child tasks for this matter task is open, false otherwise.
  def any_child_open?
    self.children.each do |e|
      return true unless e.completed
    end
    false
  end

  def get_date(date)
    if date
      date.strftime("%Y%m%d")
    end
  end

  def get_zimbra_lawyer
    self.lawyer_email.eql?("mkd@ddiplaw.com") ? "mdickinson@mdick.liviaservices.com" : self.lawyer_email    
  end

  def update_into_zimbra
    begin
      if self.lawyer_email
        get_zimbra_lawyer
        zimbra_admin = Company.find(User.find_by_email(self.lawyer_email).company_id).zimbra_admin_account_email
        if zimbra_admin
          if self.category.eql?("todo")
            if !self.zimbra_task_id || self.zimbra_task_status || @is_changed
              comp_hash = {
                :all_day => 'allDay',
                :name => 'name',
                :progress_percentage => 'percentComplete',
                :progress => 'status',
                :priority => 'priority'
              }
              task_hash = {
                :lawyer_name => "or",
                :lawyer_email => "a",
                :start_date => 's',
                :end_date => 'e',
                :name => 'su',
                :zimbra_task_id => 'zimbra_task_id',
                :description => 'content',
                :zimbra_task_uid => 'zimbra_task_uid'
              }
              zimbra_task_hash = {}
              task_hash.each { |key, value|
                if key.eql?(:start_date) or  key.eql?(:end_date)
                  zimbra_task_hash[value] = get_date(self[key])
                else
                  zimbra_task_hash[value] = self[key]
                end
              }
              zimbra_comp_hash = {}
              comp_hash.each { |key, value|
                zimbra_comp_hash[value] = self[key]
              }
              unless zimbra_comp_hash['class']
                zimbra_comp_hash["class"]="PUB"
              end

              unless zimbra_comp_hash['fb']
                zimbra_comp_hash["fb"]="B"
              end

              unless zimbra_comp_hash['allDay']
                zimbra_comp_hash["allDay"]="0"
              end

              if self.completed
                zimbra_comp_hash["status"]="COMP"
                zimbra_comp_hash["percentComplete"]="100"
              else
                zimbra_comp_hash["status"]=self.progress
                zimbra_comp_hash["percentComplete"]=self.progress_percentage
              end

              zimbra_comp_hash['name'] = self.name + " <" + Matter.find(self.matter_id).name + ">"
              zimbra_task_hash['su'] = zimbra_comp_hash['name']

              domain = ZimbraUtils.get_domain(self.lawyer_email)
              host = ZimbraUtils.get_url(domain)
              key = ZimbraUtils.get_key(domain)
              location = 15
              if ZimbraConfig.find(:domain => domain)
                if !self.zimbra_task_id
                  resp_hash = ZimbraTask.create_task(key, host, self.lawyer_email, zimbra_task_hash, zimbra_comp_hash, location)
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  MatterTask.update_all({:zimbra_task_id => resp_hash['invId'], :zimbra_task_status => false},{:id => self.id})
                else
                  if @is_changed # this condition is added when lead lawyer is changed.The tasks of old lawyer must be created for new lead lawyer and then deleted for old lawyer
                     old_lawyer = self.lawyer_email_was
                     ZimbraTask.delete_task(key, host, old_lawyer, self.zimbra_task_id)
                    resp_hash = ZimbraTask.create_task(key, host, self.lawyer_email, zimbra_task_hash, zimbra_comp_hash, location)
                  else
                  resp_hash = ZimbraTask.update_task(key, host, self.lawyer_email, zimbra_task_hash, zimbra_comp_hash,location)
                  end
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  MatterTask.update_all({:zimbra_task_id => resp_hash['invId'], :zimbra_task_status => false},{:id => self.id})
                end
              end
            end
          elsif self.category.eql?("appointment")

            if !self.zimbra_task_id || self.zimbra_task_status || @is_changed

              apt_hash = {
                :description => "content",
                :attendees_emails => "at",
                :repeat => "freq",
                :reminder => "m",
                :name => "su",
                :lawyer_name => "or",
                :lawyer_email => "a",
                :zimbra_task_id => 'zimbra_task_id',
                :start_date => 'sd',
                :end_date => 'ed',
                :count => 'count',
                :until => 'until',
                :exception_start_date => 'ex_date',
                :exception_start_time => 'ex_time',
                :task_id => 'task_id'
              }
              location=10

              zimbra_apt_comp_hash = {}
              zimbra_apt_comp_hash["status"] = "CONF"
              zimbra_apt_comp_hash["fb"] = "T"
              zimbra_apt_comp_hash["class"] = "PRI"
              zimbra_apt_comp_hash["transp"] = "O"
              zimbra_apt_comp_hash["name"] = self.name + " <" + Matter.find(self.matter_id).name + ">"
              unless zimbra_apt_comp_hash['allDay']
                zimbra_apt_comp_hash["allDay"]="0"
              end

              if self.occurrence_type.eql?("until")
                self.count = nil
              end

             # added to take care of timezone when changing apponitments from one lawyer to another
             user_time = self.lawyer_email_was.present? ? self.lawyer_email_was: self.lawyer_email
             user_time_zone = User.find_by_email(user_time).time_zone

              zimbra_apt_hash ={}
              apt_hash.each {|key,value|
                if key.eql?(:start_date) or  key.eql?(:end_date) or key.eql?(:until) or key.eql?(:exception_start_date)
                  zimbra_apt_hash[value] = get_date(self[key])
                  zimbra_apt_hash['st'] = self[key].in_time_zone(user_time_zone).strftime("%H%M%S") if key.eql?(:start_date)
                  zimbra_apt_hash['et'] = self[key].in_time_zone(user_time_zone).strftime("%H%M%S") if key.eql?(:end_date)
                elsif key.eql?(:start_time) or key.eql?(:end_time) or (key.eql?(:exception_start_time) and !self.exception_start_time.nil?)
                  zimbra_apt_hash[value] = self[key].strftime("%H%M%S")
                else
                  zimbra_apt_hash[value] = self[key]
                end
              }
              zimbra_apt_hash["su"] = zimbra_apt_comp_hash["name"]
              zimbra_apt_hash["content_mail"] = "The following is a new meeting request:

    Subject: #{zimbra_apt_hash["su"]}
  Organizer: #{zimbra_apt_hash["a"]}

  Invitees: #{zimbra_apt_hash["at"]}

  *~*~*~*~*~*~*~*~*~*

  #{zimbra_apt_hash["content"]}"

              domain = ZimbraUtils.get_domain(self.lawyer_email)
              host = ZimbraUtils.get_url(domain)
              key = ZimbraUtils.get_key(domain)
              if ZimbraConfig.find(:domain => domain)
                #zimbra_apt_hash["tz"] = ZimbraTask.get_prefs_request(key, host,self.lawyer_email.to_s,self.lawyer_name.to_s)
                zimbra_apt_hash["tz"] = User.find_by_email(self.lawyer_email).zimbra_time_zone

                if self.zimbra_task_id.blank? # this condition when first time a new appointment is created. Then zimbra task id does not exist . So just create
                  resp_hash = ZimbraTask.create_apt(key, host, self.lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  MatterTask.update_all({:zimbra_task_id => zimbra_id, :zimbra_task_status => false},{:id => self.id})
                else
                  if self.task_id.present? and zimbra_task_id.blank?
                    #|| self.exception_status == true # if exception then task id will be present so create exception.
                    # when lead lawyer is changed(condition to check @is_changed) then all the exceptions as well as deleted instances are passed.
                    # in such cases the zimbra_task_id of such instances must refer to the parent zimbra_task_id.
                    zimbra_apt_hash["zimbra_task_id"] = MatterTask.find_by_id(self.task_id).zimbra_task_id if @is_changed
                    resp_hash = ZimbraTask.create_exception_apt(key, host, self.lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
                    zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                    MatterTask.update_all({:zimbra_task_id => zimbra_id, :zimbra_task_status => false, :exception_status => false},{:id => self.id})
                  else
                    if @is_changed #if lead lawyer is changed
                      old_lawyer = self.lawyer_email_was
                         cancel_hash ={
                          "at" => self.attendees_emails,
                          "su" => self.name,
                          "content" =>"The following is a new meeting request:

                Subject: #{self.name}
                Organizer: #{self.lawyer_email}
                Invitees: #{self.attendees_emails}

                *~*~*~*~*~*~*~*~*~*

                #{self.description}"
                        }

                       unless self.exception_start_date.blank?
                        cancel_hash["ex_start_date"] = get_date(self.exception_start_date)
                        #cancel_hash["ex_start_time"] = (self.exception_start_time).strftime("%H%M%S")
                        cancel_hash["tz"] = ZimbraTask.get_prefs_request(key, host,old_lawyer.to_s,old_lawyer.to_s)
                      end
                      # delete appointments for old and create for new
                      ZimbraTask.delete_apt(key, host, old_lawyer, cancel_hash,self.zimbra_task_id)
                     resp_hash = ZimbraTask.create_apt(key, host, self.lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash, location)      
                    else
                      # if none of above and appointment is just edited then update the appointment
                       resp_hash = ZimbraTask.update_apt(key, host, self.lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash,location)
                    end
                    zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                    MatterTask.update_all({:zimbra_task_id => zimbra_id, :zimbra_task_status => false},{:id => self.id})
                  end
                end
              end

            end
          end
        end
      end
    rescue Exception => e
      #TODO  send the exception via mail
      puts e.to_s
      puts e.backtrace.join("\n")
    end
  end

  def destroy_zimbra_matter_task
    if self.lawyer_email
      get_zimbra_lawyer
      u = User.find_by_email(self.lawyer_email)
      if u.present?
        zimbra_admin = Company.find(u.company_id).zimbra_admin_account_email
      else
        zimbra_admin = nil
      end
      if zimbra_admin
        if self.category.eql?("todo")
          domain = ZimbraUtils.get_domain(self.lawyer_email)
          host = ZimbraUtils.get_url(domain)
          key = ZimbraUtils.get_key(domain)
          if ZimbraConfig.find(:domain => domain)
            ZimbraTask.delete_task(key, host, self.lawyer_email, self.zimbra_task_id)
          end
        else
          cancel_hash ={
            "at" => self.attendees_emails,
            "su" => self.name,
            "content" =>"The following is a new meeting request:

  Subject: #{self.name}
  Organizer: #{self.lawyer_email}
  Invitees: #{self.attendees_emails}

  *~*~*~*~*~*~*~*~*~*

  #{self.description}"
          }


          domain = ZimbraUtils.get_domain(self.lawyer_email)
          host = ZimbraUtils.get_url(domain)
          key = ZimbraUtils.get_key(domain)
          if ZimbraConfig.find(:domain => domain)
            unless self.exception_start_date.blank?
              cancel_hash["ex_start_date"] = get_date(self.exception_start_date)
              cancel_hash["ex_start_time"] = (self.exception_start_time).strftime("%H%M%S")
              cancel_hash["tz"] = ZimbraTask.get_prefs_request(key, host,self.lawyer_email.to_s,self.lawyer_name.to_s)
            end
            ZimbraTask.delete_apt(key, host, self.lawyer_email, cancel_hash,self.zimbra_task_id)
          end
        end
      end
    end
  rescue Exception => e
    puts "#" * 70
    puts e
    puts e.backtrace
    puts "#" * 70

  end

  def has_multiple_entries
    if self.category.eql?("appointment") && !self.repeat.blank?
      if self.count || self.until
        if self.occurrence_type.eql?("until") || (self.occurrence_type.eql?("count") && (self.count > 1))
          true
        else
          false
        end
      end
    end
  end

  #def find_exception_count
  #self
  #end

  def task_count_instances
    #ex_count = find_exception_count
    if self.occurrence_type.eql?("count")
      count = self.count.to_i
      return count
    elsif self.occurrence_type.eql?("until")
      if self.start_date and self.until
        case(self.repeat)
        when "DAI" then daily_count
        when "WEE" then weekly_count
        when "MON" then monthly_count
        when "YEA" then yearly_count
        end
      end
    else
      1      
    end
  end
  
  def task_count_for_no_end_repeat(date_end)
    appointment = self.clone
    unless date_end.blank?
      appointment.until = Date.parse(date_end.to_s)
      if appointment.start_date
        case(appointment.repeat)
        when "DAI" then appointment.daily_count
        when "WEE" then appointment.weekly_count
        when "MON" then appointment.monthly_count
        when "YEA" then appointment.yearly_count
        end
      end
    end
  end

  def daily_count
    edate = self.until 
    sdate = self.start_date.to_date
=begin    i=1
      while(sdate>edate)
        i+=1
        edate=edate+1
      end
=end
    count = ((edate-sdate).to_i) +1

    count
  end

  def weekly_count
    edate = self.until
    sdate = self.start_date.to_date 
=begin
      i=1
      while(edate>sdate)
        i+=1
        sdate+=7
      end
      return i
=end
    count = (((edate-sdate)/7).to_i) +1

    count
  end

  def monthly_count
    edate = self.until
    sdate = self.start_date.to_date   
    i=0
    while(edate>sdate)
      i+=1
      sdate = sdate>>1
    end

    i
  end

  def yearly_count
    edate = self.until
    sdate = self.start_date.to_date
    count = (((edate-sdate)/365).to_i)+1

    count
  end

  def instance_start_date(count)
    case(self.repeat)
    when("DAI") then start_daily_date(count)
    when("WEE") then start_weekly_date(count)
    when("MON") then start_monthly_date(count)
    when("YEA") then start_yearly_date(count)
    end
  end

  def start_daily_date(count)
    sdate = self.start_date.clone
    sdate = sdate.to_date
    date_array=[]
    i=0
    while(i < count )
      date_array << sdate
      sdate += 1
      i+=1
    end

    date_array
  end

  def start_weekly_date(count)
    sdate = self.start_date.clone
    sdate = sdate.to_date
    date_array=[]
    i=0
    while(i<count)
      date_array << sdate
      sdate = sdate.to_date + 7
      i+=1
    end

    date_array
  end

  def start_monthly_date(count)
    sdate = self.start_date.clone
    sdate = sdate.to_date
    date_array=[]
    i=0
    while( i < count)
      date_array << sdate
      sdate = sdate.to_date >> 1
      i+=1
    end

    date_array
  end

  def start_yearly_date(count)
    sdate = self.start_date.clone
    sdate = sdate.to_date
    date_array=[]
    i=0
    while( i < count)
      date_array << sdate
      sdate = Date.new(sdate.year+1,sdate.month,sdate.day)
      i+=1
    end

    date_array
  end


  def instance_end_date(count)
    case(self.repeat)
    when("DAI") then end_daily_date(count)
    when("WEE") then end_weekly_date(count)
    when("MON") then end_monthly_date(count)
    when("YEA") then end_yearly_date(count)
    end
  end

  def end_daily_date(count)
    edate = self.end_date.clone
    #time = Time.mktime(m.start_date.year,m.start_date.mon,m.start_date.day+1)
    edate = edate.to_date
    date_array=[]
    i=0
    while(i < count )
      date_array << edate
      edate += 1
      i+=1
    end

    date_array
  end

  def end_weekly_date(count)
    edate = self.end_date.clone
    edate = edate.to_date
    date_array=[]
    i=0
    while(i<count)
      date_array << edate
      edate = edate + 7
      i+=1
    end

    date_array
  end

  def end_monthly_date(count)
    edate = self.end_date.clone
    edate = edate.to_date
    date_array=[]
    i=0
    while( i < count)
      date_array << edate
      edate = edate >> 1
      i+=1
    end

    date_array
  end

  def end_yearly_date(count)
    edate = self.end_date.clone
    edate = edate.to_date
    date_array=[]
    i=0
    while( i < count)
      date_array << edate
      edate = Date.new(edate.year+1,edate.month,edate.day)
      i+=1
    end

    date_array
  end

  # Check that end date is after/on start date.
  def check_end_date
    #    if self.category.eql?("appointment")
    unless self.start_date.nil? or self.end_date.nil?
      if (self.end_date < self.start_date)
        self.category.eql?("appointment")? self.errors.add(' ', 'End Date can\'t be before Start Date') : self.errors.add(' ', 'Due Date can\'t be before Start Date')
      end
      if self.end_date == self.start_date
        self.errors.add(' ', 'End Time can not be before start time') if (self.end_date.to_time < self.start_date.to_time)
      end
    end
    #    end
  end

  # The completed at field is mandatory if completed is true.
  def check_completed_at
    self.errors.add('Completion Date', 'can\'t be blank') if (self.completed && self.completed_at.blank?)
  end

  def completed_date_cannot_be_future
    if completed == true      
      errors.add('Completed Date', "can\'t be greater than todays date") if completed_at > Time.zone.now.to_date
    end
  end

  #  Following method validates the completed_at date so that is not lesser than matter start_date :sania wagle

  def completed_date_cannot_be_less_than_start
    self.errors.add(:completed_at,"can\'t be lesser than start date") if self.start_date && self.completed_at && self.completed &&  self.completed_at.to_date < self.start_date.to_date
  end


  def validate_start_due_date
    self.errors.add(:start_date_todo,:start_date_todo) if self.start_date && self.matter[:matter_date] &&  self.start_date.to_date < self.matter[:matter_date].to_date
    #   self.errors.add(:end_date_todo,:end_date_todo) if self.end_date && self.start_date &&  self.end_date.to_date < self.start_date.to_date
  end


  # Parent it is required for task having assoc_as == 'sub'.
  def check_parent
    self.errors.add('Parent Task', 'can\'t be blank') if (self.assoc_as.eql?('1') && self.parent_id.blank?)
  end

  def self.accessible_matter_tasks(allowed_ids)
    self.scoped_by_user_id(allowed_ids).all
  end

  # Return true if task status matches the give status.
  def check_task_status(status)
    return true if (status.eql?("overdue") && self.overdue?)
    return true if (status.eql?("open") && self.open?)
    return true if (status.eql?("complete") && self.completed)
    return true if (status.eql?("all"))

    false
  end

  def instance_overdue(task_instance)
    task_instance.completed == false && (task_instance.end_date && task_instance.end_date < Time.zone.now.to_date)
  end

  def instance_open(task_instance)
    task_instance.completed == false && (task_instance.end_date && task_instance.end_date >= Time.zone.now.to_date)
  end
  #  # Returns parent name.
  #  def parent_name
  #    unless self.parent_id.nil?
  #      MatterTask.find(self.parent_id).name
  #    end
  #  end
  #
  #  # Returns parent.
  #  def parent
  #    unless self.parent_id.nil?
  #      MatterTask.find(self.parent_id)
  #    end
  #  end

  # Returns sub tasks.
  def sub_tasks
    MatterTask.all(:conditions => ["parent_id = ?", self.id])
  end

  # Returns information on completion date, if completed.
  def get_completion(date)
    y = self.completed ? "Yes" : "No"
    (date && self.completed) ? "#{y} (#{date})" : "#{y}"
  end

  # Returns the name of matter people whom this task was assigned.
  def assigned_to_name
    if self.assigned_to_user_id
      assigned_to_user.full_name
    elsif self.assigned_to_matter_people_id
      assigned_to_matter_people.get_name
    end
  end

  # Returns the tasks assigned to the matter client.
  def client_tasks
    self.all(:conditions => {:client_task => true})
  end

  # Returns open tasks assigned to the matter client.
  def client_tasks_open
    self.find_all {|e| e.completed.nil? or !e.completed }
  end

  # Returns overdue tasks assigned to the matter client.
  def client_tasks_overdue
    self.find_all {|e| (e.completed.nil? or !e.completed) and e.complete_by < Time.zone.now }
  end

  # Returns upcoming tasks assigned to the matter client.
  def client_tasks_upcoming
    today = Time.zone.now
    self.find_all {|e| (e.completed.nil? or !e.completed) and (e.complete_by >= today and e.complete_by <= (today + 6.days)) }
  end

  # Returns closed tasks assigned to the matter client.
  def client_tasks_closed
    self.find_all {|e| e.completed }
  end
  # Checks end time if repeat is not never.
  def occurrence_select
    if self.category.eql?('appointment')
      unless self.repeat.blank?
        if (self.occurrence_type)
          self.errors.add(' ', 'Select End by date') if (self.occurrence_type.eql?("until") and self.until.blank?)
          self.errors.add(' ', 'Select End after count') if (self.occurrence_type.eql?("count") and self.count.blank?)
        end
      end
    end
  end

  def check_until_date
    if self.until and !self.task_id
      if self.until < self.start_date.to_date
        self.errors.add(' ', 'End date can not be before start date')
      end
    end
  end

  #instance_task = MatterTask.find_with_deleted(:first, :conditions => ["task_id = ? AND exception_start_date = ?",self.id, check_date])
  #return instance_task

  def occurrence_value
    unless self.category.eql?("todo") and self.repeat.blank?
      if self.occurrence_type.eql?("until")
        self.count = nil
      else
        self.until = nil
      end
    end
  end

  def destroy_instances
    if self.category.eql?("appointment") and self.task_id.blank?
      matter_task_instance = []
      matter_task_instance = MatterTask.all(:conditions => ["task_id = ?", self.id])
      matter_task_instance.each{|x| x.destroy}
    end
  end

   def self.matter_tasks_date_range(occurence_type, companyid, start_date, end_date, params, attendees_email)
    conditions = " category = '#{occurence_type}' AND matter_tasks.company_id = #{companyid} "
    appointment = occurence_type.eql?("appointment")
    status = params[:status]
    
    if status=="Open" || status=="Overdue"
      conditions += " AND completed = false "
      if status=="Overdue"
        if appointment
          conditions += " AND date(matter_tasks.start_date) <= '#{end_date}'"
        else
          conditions += " AND date(matter_tasks.end_date) <= '#{end_date}'"
        end
      end
    elsif status=="Completed"
      conditions += " AND completed = true AND completed_at <= '#{end_date}'"
    end
    
    unless params[:start_date].blank? && params[:end_date].blank?
      if appointment
        #conditions += " AND (date(matter_tasks.start_date) BETWEEN '#{params[:start_date]}' AND '#{params[:end_date]}') "
        conditions += " AND (date(matter_tasks.start_date) <= '#{params[:end_date]}') "
      else
        conditions += " AND (date(matter_tasks.end_date) BETWEEN '#{params[:start_date]}' AND '#{params[:end_date]}') "
      end
    end
    
    unless params[:matters].blank?      
      conditions += "AND matter_id in(#{params[:matters].join(",")}) "
    end
    unless params[:people].blank?
      if appointment
        conditions += "AND ((attendees_emails is not null AND attendees_emails like '%#{attendees_email}%') OR assigned_to_matter_people_id in (#{params[:matter_people].join(',')})) "
      else
        conditions += "AND assigned_to_matter_people_id in (#{params[:matter_people].join(',')})"
      end
    end
    if(occurence_type=='todo')
      find(:all, :conditions => conditions, :order => "matter_tasks.start_date",:include=>:matter, :select => "matter_tasks.id, matter_tasks.name, matter_tasks.parent_id, matter_tasks.description, matter_tasks.assigned_to_matter_people_id, matter_tasks.completed, matter_tasks.completed_at, matter_tasks.matter_id, matter_tasks.company_id, matter_tasks.deleted_at, matter_tasks.category, matter_tasks.lawyer_name, matter_tasks.occurrence_type, matter_tasks.count, matter_tasks.until, matter_tasks.exception_start_date, matter_tasks.task_id, matter_tasks.start_date, matter_tasks.end_date, matter_tasks.assigned_to_user_id, matters.id, matters.name")
    else
       find_with_deleted(:all, :conditions => conditions, :order => "matter_tasks.start_date",:include=>:matter, :select => "matter_tasks.id, matter_tasks.name, matter_tasks.parent_id, matter_tasks.description, matter_tasks.assigned_to_matter_people_id, matter_tasks.completed, matter_tasks.completed_at, matter_tasks.matter_id, matter_tasks.company_id, matter_tasks.deleted_at, matter_tasks.category, matter_tasks.lawyer_name, matter_tasks.occurrence_type, matter_tasks.count, matter_tasks.until, matter_tasks.exception_start_date, matter_tasks.task_id, matter_tasks.start_date, matter_tasks.end_date, matter_tasks.assigned_to_user_id, matters.id, matters.name")
    end
  end

  def check_if_instance
    self.skip_on_create_instance
  end

  def set_attendees_emails
    unless self.attendees_emails.blank?
      self.attendees_emails = self.attendees_emails.split(/[\r\n\s,',']/)
      self.attendees_emails.reject!{|att| att.nil? or att.blank?}
      self.attendees_emails = self.attendees_emails.uniq
      self.attendees_emails = self.attendees_emails.join(', ')
    end
  end

  def add_people_attendees(people_attendees, attendees_emails)
    unless attendees_emails.blank?
      if !people_attendees.blank? and people_attendees.length > 0
        people_attendees.each do |attendee|
          attendees_emails << ", #{attendee}" unless attendee.blank?
        end
      else
        attendees_emails << ", #{people_attendees}" unless people_attendees.blank?
      end
      self.attendees_emails = attendees_emails
    else
      self.attendees_emails = people_attendees
    end
  end

  #Send Mail to Matter_task Associates
  def send_mail_to_associates
    user = self.matter_people.assignee
    if(@is_changed && user && User.current_user!=user)
      send_notification_to_responsible(user,self,User.current_user)
      @is_changed = false

      true
    end
  end

  def check_if_instance
    self.skip_on_create_instance
  end

  # Sends notification to attendees when an appointment is created.
  def send_mail_to_attendees_on_create
    if self.category.eql?("appointment") and !self.attendees_emails.blank?
      user = self.matter_people.assignee
      att_arr = self.attendees_emails.split(",")
      for i in att_arr
        send_notificaton_to_attendees(user, self, i)
      end

      true
    end
  end

  # Sends notification to attendees when an appointment is updated.
  def send_mail_to_attendees_on_update
    if self.category.eql?("appointment")
      if self.changed.include?("start_date") or self.changed.include?("attendees_emails") or self.changed.include?("repeat") or self.changed.include?("count") or self.changed.include?("until")
        user = self.matter_people.assignee
        if self.attendees_emails
          att_arr = self.attendees_emails.split(",")
          for i in att_arr
            send_update_notificaton_to_attendees(user, self, i)
          end
        end

        true
      end
    end
  end
  
  def save_assigned_to_user
    MatterTask.update_all({:assigned_to_user_id => self.matter_people.assignee.id},{:id => self.id})
  end

  #Find employee or contact name from email.
  def get_attendee_name_from_email(attemail, companyid, matterid)
    attemail = attemail.chomp
    cnt = Contact.first(:conditions => {:company_id => companyid, :email => attemail})
    usr = User.first(:conditions => {:company_id => companyid, :email => attemail})
    if cnt or usr
      if cnt
        cnt.full_name
      else
        usr.full_name
      end
    end
  end

  def get_all_children()
    children = self.children
    child_tasks = []
    if children
      children.each do |child|
        child_tasks << child
        child_tasks.flatten
        child.get_grand_children(child_tasks)
      end

      child_tasks.flatten
    end
  end

  def get_grand_children(child_tasks)
    task_children = self.children
    if task_children
      task_children.each do |child|
        child_tasks << child
        child.get_grand_children(child_tasks)
      end
      child_tasks.flatten
    end
  end

  #Child tasks of parent are marked completed when 
  def complete_children
    if self.category.eql?('todo') and self.completed
      if self.children
        children = self.get_all_children
        children.each do |child|
          if child.completed.blank? or !child.completed
            child.update_attributes(:completed => true, :completed_at => self.completed_at, :zimbra_task_status => true)
            #            MatterTask.update_all({:completed => true, :completed_at => self.completed_at}, {:id => child.id})
          end
        end
      end
    end
  end

  #  def check_if_parent_complete
  #    parent = self.parent
  #    unless parent.blank?
  #      if parent.completed
  #        self.errors.add(" ","Cannot add open task to completed parent task") unless self.completed
  #      end
  #    end
  #  end

  def check_child_task_end_date
    parent = self.parent if self.category.eql?('todo') && assoc_as == "1"
    if !parent.blank? and parent.category.eql?('todo')
      unless self.end_date.blank?
        self.errors.add(' ', 'Child task cannot have end date after parent-tasks end date' ) if self.end_date > parent.end_date
      else 
        self.errors.add(' ', 'Child task end date cannot be blank' )
      end
    end
  end

  def check_parent_tasks_end_date
    if self.category.eql?('todo')
      children = self.get_all_children
      error = false
      children.collect{|child| error = true if child.category.eql?('todo') and child.end_date > self.end_date} if children
      if error
        self.errors.add(' ', 'Parent task cannot have end date before child task.')
      end
    end
    
  end
  
  def open_parent_on_open_child
    if self.category.eql?('todo') and !self.completed and self.parent
      self.ancestors.each do |parent|
        parent.update_attributes(:completed => false, :completed_at => nil, :zimbra_task_status => true) if parent.completed
      end
    end
  end

  def get_category_types(company)
    if self.new_record?
      task_category_types = []
      task_category_types << company.company_activity_types
      task_category_types = task_category_types.flatten

     [ task_category_types, task_category_types ]
    else
      category_types = company.company_activity_types
      category_types = category_types.flatten

      category_types
    end    
  end

  def start_end_date_should_not_equal
    return unless start_date && end_date && start_time && end_time
    if is_appointment?
      if start_date == end_date &&  start_time == end_time
        self.errors.add('Start date','- End date And Start Time - End Time cannot be same')
      end
    end
  end

  def responsible_person_changed
    @is_changed = false
    @is_changed = self.changed.include?("assigned_to_matter_people_id") if !new_record?

    true
  end
end

# == Schema Information
#
# Table name: matter_tasks
#
#  id                           :integer         not null, primary key
#  name                         :text
#  parent_id                    :integer
#  phase_id                     :integer
#  description                  :text
#  assigned_to_matter_people_id :integer
#  completed                    :boolean
#  completed_at                 :date
#  assoc_as                     :string(255)
#  matter_id                    :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  critical                     :boolean
#  client_task                  :boolean
#  company_id                   :integer         not null
#  deleted_at                   :datetime
#  permanent_deleted_at         :datetime
#  created_by_user_id           :integer
#  updated_by_user_id           :integer
#  category                     :string(255)
#  location                     :string(255)
#  priority                     :string(255)
#  progress                     :string(255)
#  progress_percentage          :string(255)
#  show_as                      :string(255)
#  mark_as                      :string(255)
#  all_day_event                :boolean
#  start_time                   :time
#  end_time                     :time
#  repeat                       :string(255)
#  reminder                     :string(255)
#  attendees_emails             :text
#  zimbra_task_id               :string(255)
#  zimbra_task_status           :boolean
#  lawyer_name                  :string(255)
#  lawyer_email                 :string(255)
#  client_task_type             :string(255)
#  client_task_doc_name         :string(255)
#  client_task_doc_desc         :string(255)
#  occurrence_type              :string(255)     default("count")
#  count                        :integer
#  until                        :date
#  exception_status             :boolean
#  exception_start_date         :date
#  exception_start_time         :time
#  task_id                      :integer
#  start_date                   :datetime
#  end_date                     :datetime
#  assigned_to_user_id          :integer
#  category_type_id             :integer
#

