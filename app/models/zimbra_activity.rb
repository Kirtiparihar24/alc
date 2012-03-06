class ZimbraActivity < ActiveRecord::Base
  require 'cgi'
  include GeneralFunction
  acts_as_paranoid

  belongs_to :user, :foreign_key => :assigned_to_user_id

  attr_accessor :start_date_appointment
  attr_accessor :end_date_appointment
  attr_accessor :start_date_todo
  attr_accessor :end_date_todo
  attr_accessor :end_time
  attr_accessor :start_time, :from_zimbra
  attr_accessor :index_height
  attr_reader :PRIORITIES
  attr_reader :PROGRESSES
  attr_reader :PROGRESS_PERCENTAGES
  attr_reader :SHOW_AS_OPTIONS
  attr_reader :MARK_AS_OPTIONS
  attr_reader :REPEAT_OPTIONS
  attr_reader :REMINDER_OPTIONS

  before_validation :set_start_end_dates

  after_save :update_into_zimbra
  #after_create :send_mail_to_attendees_for_personal_on_create
  before_destroy :destroy_zimbra_matter_task
  before_save :set_status
  after_destroy :destroy_instances  
  after_save :save_lawyer_name

  validates_presence_of :name,  :message => :name_blank
  validates_presence_of :start_date, :message => :start_date_blank
  validates_presence_of :end_date, :message => :due_date_blank
  validates_presence_of :assigned_to_user_id, :message => :responsiblety_blank
  validates_length_of :name, :maximum => 255, :message => :is_too_long
  #validates_length_of :description, :maximum => 512, :message => 'is too long'

  validate :check_end_date
  validate :start_end_date_should_not_equal
#  validate :occurrence_select, :unless => :from_zimbra
  before_save :occurrence_value
  validate :check_until_date
  
  PRIORITIES = {"Normal" => "5", "Low" => "9", "High" => "1"}
  PRIORITIES_REVERSE = {"1" => "High", "5" => "Normal", "9" => "Low"}
  PROGRESSES = {"Not Started" => "NEED", "Completed" => "COMP", "In Progress" => "INPR", "Waiting on someone else" => "WAITING", "Deferred" => "DEFERRED"}
  PROGRESS_PERCENTAGES = [ "0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100" ]
  SHOW_AS_OPTIONS = { "Busy" => "B", "Free" => "F", "Out of office" => "O" }
  MARK_AS_OPTIONS = {"Public" => "PUB", "Private" => "PRI"}
  REPEAT_OPTIONS = [["Never", nil], ["Every Day", "DAI"], ["Every Week", "WEE"], ["Every Month", "MON"], ["Every Year", "YEA"]]
  REMIND_OPTIONS = {"Never" => "0", "1 minute before" => "1"}

  mins_hash = {}
  [5,10,15,30,45,60].collect {|e| mins_hash["#{e} minutes before"]= e.to_s }
  hours_hash = {}
  [2,3,4,5,18].collect {|e| hours_hash["#{e} hours before"]= (e*60).to_s }
  REMIND_OPTIONS.merge!(mins_hash)
  REMIND_OPTIONS.merge!(hours_hash)
  REMINDER_OPTIONS =  REMIND_OPTIONS.sort {|a,b| a[1].to_i <=> b[1].to_i }

  def self.get_user_id(lawyer_email)
    usr =  User.find_by_email(lawyer_email)
    usrid = usr.id
    companyid = usr.company_id

    [usrid, companyid]
  end

  def self.zimbra_appointment_params(data)
    data.delete(:action)
    data.delete(:controller)
    data[:start_date] = ZimbraActivity.set_date_time(data[:start_date],data[:start_time], data[:lawyer_email])
    data[:end_date] = ZimbraActivity.set_date_time(data[:end_date], data[:end_time], data[:lawyer_email])
    data.delete(:end_time)
    data.delete(:start_time)
    data[:notification] = data[:notify]
    data.delete(:notify)
    data[:name] = CGI.unescape(data[:name])
    data[:category] ||= "appointment"

    data
  end

  def self.zimbra_task_params(data)
    data[:start_date] = data[:start_date].to_date
    data[:end_date] = data[:end_date].to_date
    data[:category] ||= "todo"
    data.delete(:lawyer_email)
    data.delete(:lawyer_name)
    data.delete(:action)
    data.delete(:controller)

    data
  end


  def self.set_date_time(set_date,set_time, lawyer_email)
    cuser = User.find_by_email(lawyer_email)
    Time.zone = (!cuser.blank? ? cuser.time_zone : 'UTC')
    date_time = Time.zone.parse("#{set_date} #{Time.parse(set_time).strftime("%H:%M:%S")}").getutc
  rescue Exception => e
    date_time 
  end

  def self.zimbra_appt_date_range(occurence_type, companyid, end_date, userid, sdate, edate, attendee_email, status)
    conditions = " category = '#{occurence_type}' AND company_id = #{companyid} "
    appointment = occurence_type.eql?("appointment")
    if status=="Open" || status=="Overdue"
      conditions += " AND progress != 'COMP' "
      if status=="Overdue"
        if appointment
          conditions += " AND date(start_date) <= '#{end_date}'"
        else
          conditions += " AND date(end_date) <= '#{end_date}'"
        end
      end
    else
      conditions += " AND progress = 'COMP' AND completed_at <= '#{end_date}'"
    end

    unless sdate.blank? && edate.blank?
      if appointment
        conditions += " AND (date(start_date) <= '#{edate}') "
      else
        conditions += " AND (date(end_date) BETWEEN '#{sdate}' AND '#{edate}') "
      end
    end
    if attendee_email.blank?
      conditions += "AND assigned_to_user_id in (#{userid.join(',')}) "
    else
      conditions += "AND (assigned_to_user_id IN (#{userid.join(',')}) OR ((attendees_emails IS NOT NULL AND attendees_emails LIKE '%#{attendee_email}%'))) "
    end
    if(occurence_type=='todo')
       find(:all, :conditions => conditions, :order => "start_date")
    else
       find_with_deleted(:all, :conditions => conditions, :order => "start_date")
    end
  end
  
  def set_start_end_dates
    # discription - same in matter tasks
    if self.category.eql?("appointment")
      self.start_date = self.start_date_appointment unless self.start_date_appointment.blank?
      self.end_date = self.end_date_appointment  unless self.end_date_appointment.blank?
    else      
      self.start_date = self.start_date_todo unless self.start_date_todo.blank?
      self.end_date = self.end_date_todo unless self.end_date_todo.blank?
    end
  end

  def update_into_zimbra
    user = User.find(self.assigned_to_user_id)
    lawyer_email = user.email
    lawyer_name = user.full_name
    begin
      if lawyer_email
        zimbra_admin = Company.find(User.find_by_email(lawyer_email).company_id).zimbra_admin_account_email
        if zimbra_admin
          if self.category.eql?("todo")
            if !self.zimbra_task_id or self.zimbra_status
              comp_hash = {
                :all_day => 'allDay',
                :name => 'name',
                :progress_percentage => 'percentComplete',
                :progress => 'status',
                :priority => 'priority',
                :mark_as => 'class'
              }
              task_hash = {
                :start_date => 's',
                :end_date => 'e',
                :name => 'su',
                :zimbra_task_id => 'zimbra_task_id',
                :description => 'content'
              }
              zimbra_task_hash = {}
              task_hash.each { |key, value|
                if key.eql?(:start_date) or  key.eql?(:end_date)
                  zimbra_task_hash[value] = self[key].strftime("%Y%m%d")
                else
                  zimbra_task_hash[value] = self[key]
                end
              }
              zimbra_comp_hash = {}
              comp_hash.each { |key, value|
                zimbra_comp_hash[value] = self[key]
              }

              unless zimbra_comp_hash['fb']
                zimbra_comp_hash["fb"]="B"
              end

              unless zimbra_comp_hash['allDay']
                zimbra_comp_hash["allDay"]="0"
              end

              unless zimbra_comp_hash['status']
                zimbra_comp_hash["status"]=self.progress
                zimbra_comp_hash["percentComplete"]=self.progress_percentage
              end

              zimbra_comp_hash['name'] = self.name
              zimbra_task_hash['su'] = zimbra_comp_hash['name']

              domain = ZimbraUtils.get_domain(lawyer_email)
              host = ZimbraUtils.get_url(domain)
              key = ZimbraUtils.get_key(domain)
              location = 15
              zimbra_task_hash["or"] = lawyer_email
              zimbra_task_hash["a"] = lawyer_name
              if ZimbraConfig.find(:domain => domain)
                if !self.zimbra_task_id
                  resp_hash = ZimbraTask.create_task(key, host, lawyer_email, zimbra_task_hash, zimbra_comp_hash, location)
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  ZimbraActivity.update_all({:zimbra_task_id => zimbra_id, :zimbra_status => false},{:id => self.id})
                else
                  resp_hash = ZimbraTask.update_task(key, host, lawyer_email, zimbra_task_hash, zimbra_comp_hash,location)
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  ZimbraActivity.update_all({:zimbra_task_id => zimbra_id, :zimbra_status => false},{:id => self.id})
                end
              end
            end
          elsif self.category.eql?("appointment")
            if !self.zimbra_task_id || self.zimbra_status
              apt_hash = {
                :description => "content",
                :attendees_emails => "at",
                :repeat => "freq",
                :reminder => "m",
                :name => "su",
                :zimbra_task_id => 'zimbra_task_id',
                :start_date => 'sd',
                :end_date => 'ed',
                :count => 'count',
                :until => 'until',
                :exception_start_date => 'ex_date',
                :task_id => 'task_id',
                 :mark_as => 'class'

              }
              location=10

              zimbra_apt_comp_hash = {}
              zimbra_apt_comp_hash["status"]="CONF"
              zimbra_apt_comp_hash["fb"]="T"
              zimbra_apt_comp_hash["class"]=self.mark_as
              zimbra_apt_comp_hash["transp"]="O"
              zimbra_apt_comp_hash["name"]=self.name
              unless zimbra_apt_comp_hash['allDay']
                zimbra_apt_comp_hash["allDay"]="0"
              end

              if self.occurrence_type.eql?("until")
                self.count = nil
              end

              zimbra_apt_hash ={}
              apt_hash.each {|key,value|
                unless self[key].blank?
                  if key.eql?(:start_date) or  key.eql?(:end_date) or key.eql?(:until) or key.eql?(:exception_start_date)
                    zimbra_apt_hash[value] = self[key].strftime("%Y%m%d") unless self[key].blank?
                    zimbra_apt_hash['st'] = self[key].strftime("%H%M%S") if key.eql?(:start_date)
                    zimbra_apt_hash['et'] = self[key].strftime("%H%M%S") if key.eql?(:end_date)
                    zimbra_apt_hash['ex_time'] = self[key].strftime("%H%M%S") if key.eql?(:exception_start_date)
                  else
                    zimbra_apt_hash[value] = self[key]
                  end
                end
              }
              zimbra_apt_hash["su"] = zimbra_apt_comp_hash["name"]
              zimbra_apt_hash["content_mail"] = "The following is a new meeting request:

  Subject: #{zimbra_apt_hash["su"]}
  Organizer: #{zimbra_apt_hash["a"]}

  Invitees: #{zimbra_apt_hash["at"]}

  *~*~*~*~*~*~*~*~*~*

  #{zimbra_apt_hash["content"]}"
              zimbra_apt_hash["or"] = lawyer_name
              zimbra_apt_hash["a"] = lawyer_email
              domain = ZimbraUtils.get_domain(lawyer_email)
              host = ZimbraUtils.get_url(domain)
              key = ZimbraUtils.get_key(domain)
              if  ZimbraConfig.find(:domain=>domain)
                #zimbra_apt_hash["tz"] = ZimbraTask.get_prefs_request(key, host, lawyer_email.to_s, lawyer_name.to_s)
                zimbra_apt_hash["tz"] = User.find_by_email(lawyer_email).zimbra_time_zone
                if self.zimbra_task_id.blank?
                  resp_hash = ZimbraTask.create_apt(key, host, lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
                  zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                  ZimbraActivity.update_all({:zimbra_task_id => zimbra_id, :zimbra_status => false},{:id => self.id})
                else
                  if self.exception_status == true
                    resp_hash = ZimbraTask.create_exception_apt(key, host, lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash, location)
                    zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                    ZimbraActivity.update_all({:zimbra_task_id => zimbra_id, :zimbra_status => false, :exception_status => false},{:id => self.id})
                  else
                    resp_hash = ZimbraTask.update_apt(key, host, lawyer_email, zimbra_apt_hash, zimbra_apt_comp_hash,location)
                    zimbra_id = resp_hash['invId'].blank? ? self.zimbra_task_id : resp_hash['invId']
                    ZimbraActivity.update_all({:zimbra_task_id => zimbra_id, :zimbra_status => false},{:id => self.id})
                  end
                end
              end
            end
          end
        end
      end
    rescue Exception=>e
      puts "#" * 70
      puts e
      puts e.backtrace
      puts "#" * 70
    end
  end

  def destroy_zimbra_matter_task
    user = User.find(self.assigned_to_user_id)
    lawyer_email = user.email
    lawyer_name = user.full_name
    if lawyer_email
      u = User.find_by_email(lawyer_email)
      if u.present?
        zimbra_admin = Company.find(u.company_id).zimbra_admin_account_email
      else
        zimbra_admin = nil
      end
      if zimbra_admin
        if self.category.eql?("todo")
          domain = ZimbraUtils.get_domain(lawyer_email)
          host = ZimbraUtils.get_url(domain)
          key = ZimbraUtils.get_key(domain)
          if ZimbraConfig.find(:domain => domain)
            ZimbraTask.delete_task(key, host, lawyer_email, self.zimbra_task_id)
          end
        else
          cancel_hash ={
            "at" => self.attendees_emails,
            "su" => self.name,
            "content" =>"The following is a new meeting request:

  Subject: #{self.name}
  Organizer: #{lawyer_email}
  Invitees: #{self.attendees_emails}

  *~*~*~*~*~*~*~*~*~*

  #{self.description}"
          }


          domain = ZimbraUtils.get_domain(lawyer_email)
          host = ZimbraUtils.get_url(domain)
          key = ZimbraUtils.get_key(domain)
          if ZimbraConfig.find(:domain => domain)
            unless self.exception_start_date.blank?
              cancel_hash["ex_start_date"] = self.exception_start_date.strftime("%Y%m%d")
              cancel_hash["ex_start_time"] = (self.exception_start_date).strftime("%H%M%S")
              cancel_hash["tz"] = ZimbraTask.get_prefs_request(key, host, lawyer_email.to_s, lawyer_name.to_s)
            end
            ZimbraTask.delete_apt(key, host, lawyer_email, cancel_hash,self.zimbra_task_id)
          end
        end
      end
    end
  end

  def destroy_instances
    if self.category.eql?("appointment") and self.task_id.blank?
      zimbra_activity_instance = []
      zimbra_activity_instance = ZimbraActivity.all(:conditions => ["task_id = ?", self.id])
      zimbra_activity_instance.each{|x| x.destroy}
    end
  end

  def occurrence_select
    if self.category.eql?('appointment')
      unless self.repeat.blank?
        if (self.occurrence_type)
          self.errors.add(' ', 'Select end after date') if (self.occurrence_type.eql?("until") and self.until.blank?)
          self.errors.add(' ', 'Select end after count') if (self.occurrence_type.eql?("count") and self.count.blank?)
        else
          self.errors.add(' ', 'Select count or end after date')
        end
      end
    end
  end

  def occurrence_value
    unless self.category.eql?("todo") and self.repeat.blank?
      if self.occurrence_type.eql?("until")
        self.count = nil
      else
        self.until = nil
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

  # Check that end date is after/on start date.
  def check_end_date
    #    if self.category.eql?("appointment")
    unless self.start_date.blank? or self.end_date.blank?
      if (self.end_date < self.start_date)
        self.category.eql?("appointment")? self.errors.add(' ', 'End Date can\'t be before Start Date') : self.errors.add(' ', 'Due Date can\'t be before Start Date')
      end
      if self.end_date == self.start_date
        self.errors.add(' ', 'End Time can not be before start time') if (self.end_date.to_time < self.start_date.to_time)
      end
    end
    #    end
  end

  def check_until_date
    if self.until and !self.task_id
      if self.until < self.start_date.to_date
        self.errors.add(' ', 'End date can not be before start date')
      end
    end
  end

  def set_status
    if self.progress and self.progress_percentage
      self.progress = self.progress
      self.progress_percentage = self.progress_percentage
    else
      self.progress = "INPR"
      self.progress_percentage = "0"
    end
  end
  
  def send_mail_to_attendees_for_personal_on_create
    if self.category.eql?("appointment") and !self.attendees_emails.blank?
      att_arr = self.attendees_emails.split(",")
      user = User.current_user
      for i in att_arr
        send_notificaton_to_attendees(user, self, i)
      end
    end
  end

  def activity_completed?
    self.progress == "COMP"
  end

  def activity_open?
    self.progress != "COMP" || self.completed_at.nil?
  end

  def activity_overdue?
    the_date = self.category.eql?("appointment") ? self.start_date.to_date : self.end_date.to_date
    to_day = Time.zone.now.to_date
    if self.category.eql?("appointment")
      if the_date && (the_date < to_day)
        return true
#      elsif the_date && (the_date == to_day)
#        if self.start_date.to_time < Time.zone.now.to_time
#          return true
#        end
      else
        return false
      end
    else
     activity_open? and (the_date && (the_date < to_day))
    end
  end

  def activity_upcoming?
    is_appointment = self.category.eql?("appointment")
    @@user_setting = User.current_lawyer.upcoming
    if @@user_setting.nil?
      @@user_setting = self.matter.user.upcoming
      if @@user_setting.nil?
        @@user_setting = Upcoming.create(:user_id => self.matter.employee_user_id, :setting_type => 'Upcoming',:setting_value => 7, :company_id => self.company_id)
      else
        if @@user_setting.setting_value.nil?
          @@user_setting.update_attribute(:setting_value,7)
        end
      end
    end
    custom_days = @@user_setting.setting_value.to_i
    today = Time.zone.now.to_date
    the_date = is_appointment ? self.start_date.to_date : self.end_date.to_date
    if is_appointment
      (the_date && the_date > today && the_date <= (today + custom_days.days))
    else
      activity_open? && (the_date && the_date > today && the_date <= (today + custom_days.days))
    end    
  end

  def activity_today?
    is_appointment = self.category.eql?("appointment")
    the_date = is_appointment ? self.start_date.to_date : self.end_date.to_date
    if is_appointment
    (the_date && the_date == Time.zone.now.to_date)
    else
      activity_open? && (the_date && the_date == Time.zone.now.to_date)
    end
  end


  def save_lawyer_name
    ZimbraActivity.update_all({:user_name=> self.user.try(:full_name)},{:id => self.id})
  end
  
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
    i=1
    while(edate>sdate)
      i+=1
      sdate = sdate>>1
    end

    i
  end

  def yearly_count
    edate = self.until
    sdate = self.start_date.to_date
=begin

      i=1
      while(edate > sdate)
        i+=1
        sdate = Date.new(sdate.year+1,sdate.month,sdate.day)
      end
      return i
=end
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

    ate_array
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

  def start_end_date_should_not_equal
    return unless start_date && end_date && start_time && end_time
    if category.present? && category.eql?("appointment")
      if start_date == end_date &&  start_time == end_time
        self.errors.add('Start date','- End date And Start Time - End Time cannot be same')
      end
    end
  end

end

# == Schema Information
#
# Table name: zimbra_activities
#
#  id                     :integer         not null, primary key
#  name                   :string(255)
#  description            :text
#  category               :string(255)
#  zimbra_folder_location :integer
#  assigned_to_user_id    :integer
#  zimbra_task_id         :string(255)
#  zimbra_status          :boolean
#  reminder               :integer
#  repeat                 :string(255)
#  location               :text
#  attendees_emails       :text
#  response               :boolean
#  notification           :boolean
#  show_as                :string(255)
#  mark_as                :string(255)
#  start_date             :datetime
#  end_date               :datetime
#  all_day_event          :boolean
#  exception_status       :boolean
#  task_id                :integer
#  exception_start_date   :datetime
#  occurrence_type        :string(255)
#  count                  :integer
#  until                  :date
#  progress_percentage    :string(255)
#  progress               :string(255)
#  priority               :string(255)
#  deleted_at             :datetime
#  company_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  completed_at           :date
#  user_name              :string(255)
#

