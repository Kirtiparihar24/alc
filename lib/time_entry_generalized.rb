# To change this template, choose Tools | Templates
# and open the template in the editor.

module TimeEntryGeneralized
   #after update callback to create or permanently delete entry in billing invoice entries.// Surekha
  def save_approved_entry_to_invoice
    if self.status_changed?
      t=TneInvoiceTimeEntry.find_by_tne_time_entry_id(self.id)
      if self.status=='Approved'
       if self.is_billable && t.nil?
       tne = TneInvoiceTimeEntry.create(self.attributes)
       tne.tne_time_entry_id = self.id
       tne.save
       end
      else
        if self.status=='Open' && !t.nil?
          t.destroy!
        end
      end
      end
  end


  def time_entry_date_cant_be_lesser_than_matter_inception
    self.errors.add(:time_entry_date,:time_entry_date) if self.time_entry_date && self.matter[:matter_date] &&  self.time_entry_date.to_date < self.matter[:matter_date].to_date
  end


  def check_for_billing_percent
    if(self.billing_method_type == 2 && self.billing_percent.blank?)
      self.billing_method_type=1
    elsif(self.billing_method_type == 3 && self.final_billed_amount.blank?)
      self.billing_method_type=1
    end
    if self.billing_percent && !self.billing_percent.between?(0,100)
      self.errors.add(:base,"Billing percent must be between 0 to 100")
    end
  end



  # Validation check for time difference between start time and end time.
  def check_for_time_difference
    if self.actual_duration.present?
      if self.start_time.present? && self.end_time.present?
        duration =(self.end_time - self.start_time)/3600
        val1 = duration.to_f.roundf2(2).to_s
        val2 = self.actual_duration.to_f.roundf2(2).to_s
        if duration > 0 && !val1.eql?(val2)
          errors.add_to_base(:tne_valid_time)
        end
      end
    end
  end

#  # Rounds up duration to two digits.
#  def round_up_actual_duration
#     actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(self.actual_duration) : one_tenth_timediffernce(self.actual_duration)
#    self.actual_duration = (actual_duration*100).round / 100.0 unless self.actual_duration.blank?
#  end

  # Returns time difference between start time and end time.
  def get_time_difference
    set_start_end_time
    if self.start_time && !self.start_time.nil? && self.end_time && !self.end_time.nil?
      duration = (self.end_time.to_time - self.start_time.to_time) / 60.0
      if duration > 0
        @dur_setng_is_one100th = self.company.duration_setting.setting_value == "1/100th" unless @dur_setng_is_one100th
        actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(duration) : one_tenth_timediffernce(duration)
      else
        return 0
      end
    elsif self.start_time && !self.start_time.nil? && self.end_time.nil?
      return 0
    else
      return "Please enter valid time details in the format HH:MM"
    end
  end

  # Returns final bill amount for time entry.
  def calculate_final_billed_amt
    if self.errors.on(:actual_duration)
#      logger.debug self.errors.each_full { |msg| puts msg }
      return
    end
    @dur_setng_is_one100th = self.company.duration_setting.setting_value == "1/100th" unless @dur_setng_is_one100th
    actual_duration = @dur_setng_is_one100th ? one_hundredth_timediffernce(self.actual_duration) : one_tenth_timediffernce(self.actual_duration)
    #if self.billable_type == 2
#    if (!self.is_billable && self.billing_method_type != 3)
    if (!self.is_billable)
      self.final_billed_amount  = 0
    elsif self.billing_method_type == 1
      self.final_billed_amount  = self.actual_activity_rate ? (self.actual_activity_rate * actual_duration.to_f) : (self.activity_rate * actual_duration.to_f unless self.activity_rate.blank?)
    elsif self.billing_method_type == 3
      self.final_billed_amount  = self.final_billed_amount
    elsif self.actual_activity_rate
      if self.billing_percent
        self.final_billed_amount  =(self.actual_activity_rate * actual_duration.to_f) - ((self.billing_percent/100) * (self.actual_activity_rate * actual_duration.to_f))
      else
        self.final_billed_amount = self.actual_activity_rate * actual_duration.to_f
      end
    elsif self.activity_rate
      if self.billing_percent
        self.final_billed_amount  = (self.activity_rate * actual_duration.to_f) - ((self.billing_percent/100) * (self.activity_rate * actual_duration.fo_f) )
      else
        self.final_billed_amount = self.activity_rate * actual_duration.to_f
      end
    end
    self.final_billed_amount = self.final_billed_amount.to_f.roundf2(2)
  end

  # updated billing percent (discount) and resets other values.
  def calcuate_billing_percent
    self.actual_activity_rate ||= 0
    self.actual_duration ||=0
    self.billing_percent ||=0
    ((self.actual_activity_rate * self.actual_duration) - ((self.billing_percent/100) * (self.actual_activity_rate * self.actual_duration))).to_f.roundf2(2)
  end

  # calculates billed amount.
  def calculate_billed_amount
    billing_rate =  self.actual_activity_rate ?  self.actual_activity_rate  : 0
    actual_duration = @dur_setng_is_one100th ?  one_hundredth_timediffernce(self.actual_duration) : one_tenth_timediffernce(self.actual_duration)
    billed_amount = billing_rate *  actual_duration.to_f
    billed_amount = billed_amount.to_f.fixed_precision(2)
  end

  # formats start time to H:M
  def formatted_start_time
    self.start_time ? self.start_time.strftime('%I:%M %p') : ''
  end

  # formats end time to H:M
  def formatted_end_time
    self.end_time ? self.end_time.strftime('%I:%M %p') : ''
  end

#  # Returns matter specific total time of time entries.
#  # i/p: matter_id
#  def self.accountable_hours_for_matter(matter_id)
#    #entries = Physical::Timeandexpenses::TimeEntry.find(:all, :conditions => ["matter_id = ? AND billable_type = 1", matter_id])
#    entries = Physical::Timeandexpenses::TimeEntry.find(:all, :conditions => ["matter_id = ? AND is_billable", matter_id])
#    hours = 0
#    entries.each do|e|
#      hours += e.actual_duration
#    end
#    hours
#  end
#
#
#
#  # Returns employee rate from employees or company_role_rates
#  def self.get_employee_rate(company_id, employee_user_id, role_id)
#    employee = Employee.find_by_user_id(employee_user_id)
#    unless employee.nil?
#      rate =  employee.billing_rate
#    end
#    if rate.blank? || rate <= 0
#      role_id = 175 if role_id.blank?
#      company_role_rate = CompanyRoleRate.find_by_company_id_and_role_id(company_id, role_id)
#      rate = company_role_rate.nil? ? '' : company_role_rate.billing_rate
#    end
#    rate
#  end
#
#  # Returns employee activity rate from employee_activity_rates or company_activity_rates
#  def self.get_employee_activity_rate(company_id, employee_user_id, activity_type_id)
#    emp_act_rate = EmployeeActivityRate.find_by_employee_user_id_and_activity_type_id(employee_user_id, activity_type_id)
#    unless emp_act_rate.nil?
#      rate = emp_act_rate.billing_rate
#    else
#      company_act_rate = CompanyActivityRate.find_by_company_id_and_activity_type_id(company_id, activity_type_id)
#      rate = company_act_rate.nil? ? '' : company_act_rate.billing_rate
#    end
#    rate
#  end

#  # Returns billing rate for time entry for current employee.
#  def self.get_billing_rate(company_id, employee_user_id, activity_type_id, role_id)
#    rate = get_employee_activity_rate(company_id, employee_user_id, activity_type_id)
#    if rate.blank?
#      rate = get_employee_rate(company_id, employee_user_id, role_id)
#    end
#    rate
#  end

#def is_duration_valid?
#   self.actual_duration = get_time_difference
#   if  self.actual_duration.kind_of? Float
#     return true
#   else
#     self.actual_duration=''
#   end
# end
 def is_error?
   !self.errors.on(:actual_duration)
 end
 def is_override_amout?
   #self.billing_amount.to_f > 0
   self.billing_method_type == 3
 end
 def not_blank?
   !self.billing_percent.nil?
 end

 def check_actual_duration_explictly_entered
   duration = get_time_difference
   unless (duration.kind_of?(String))
     self.start_time=self.end_time=nil if self.actual_duration && duration < self.actual_duration
   end
 end

 def zero_rate
   if self.actual_activity_rate != nil && self.actual_activity_rate.to_f == 0
      self.errors.add(:base,"Rate can not be zero.")
   end
 end

 def check_matter_inception_date
   if self.matter_id.present? && self.matter_id!=0
  matter_inception_date=Matter.find_by_id(self.matter_id).matter_date
  if self.time_entry_date && self.time_entry_date < matter_inception_date
    self.errors.add(:base,"Time entry date cannot be less than matter inception date")
  end
   end
 end

 def validate_start_n_end_time
   if self.actual_duration == 0.00 && (self.start_time.present? || self.end_time.present?) && self.start_time.strftime('%H:%M') >= self.end_time.strftime('%H:%M')
     self.errors.add_to_base('End time should be greater than Start time')
   end
 end

# private

 # This method is using for to set the start and end time date, because of the data base column field is DateTime instead of time.
 # we need to set date from which user selected.
 public
 def set_start_end_time
   unless self.start_time.nil? && self.start_time.blank?
    self.start_time =DateTime.new(y=self.time_entry_date.year,m=self.time_entry_date.mon,d=self.time_entry_date.day, h=self.start_time.hour,min=self.start_time.min,s=self.start_time.sec,of=0)
   end
   unless self.end_time.nil? && self.end_time.blank?
    self.end_time =DateTime.new(y=self.time_entry_date.year,m=self.time_entry_date.mon,d=self.time_entry_date.day, h=self.end_time.hour,min=self.end_time.min,s=self.end_time.sec,of=0)
   end
 end
end
