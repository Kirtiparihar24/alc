# To change this template, choose Tools | Templates
# and open the template in the editor.
module Wfm::TaskActivities
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    # find the open repeat tasks of a lawyer, if a repeat task instance is occurring in the
    # given period generate that instance if the instance is not present
    def generate_repeat_task_instances_for_outstanding_tasks(lawyer_id,is_secretary_or_team_manager,to_date)
      conditions = "repeat in ('DAI','WEE','MON','ANU')"
      conditions += " AND share_with_client = true" unless is_secretary_or_team_manager
      conditions = ["assigned_by_employee_user_id = ? AND status is null AND #{conditions}",lawyer_id]
      repeat_tasks = UserTask.find(:all,:conditions=>conditions)
      for task in repeat_tasks
        case task.repeat
        when 'DAI'
          generate_daily_instances(task,to_date)
        when 'WEE'
          generate_weekly_instances(task,to_date)
        when 'MON'
          generate_monthly_instances(task,to_date)
        when 'ANU'
          create_anual_instances(task,to_date)
        end
      end
    end

    def generate_daily_instances(task,to_date)
      to_date = Time.zone.parse(to_date).to_date
      latest_instnace = UserTask.latest_repeat_instance(task.id,task.name)[0]
      starting_time = latest_instnace.original_start_at.in_time_zone(task.time_zone) if latest_instnace
      starting_time += 1.day if starting_time
      starting_time ||= task.start_at.in_time_zone(task.time_zone)
      to_date = task.end_at if task.end_at && task.end_at < to_date
      if to_date >= starting_time.to_date && task.start_at.to_date <= to_date
        while starting_time.to_date <= to_date
            task.create_task_of_date(starting_time)
            starting_time += 1.day
        end
      end
    end

    def generate_weekly_instances(task,to_date)
      to_date = Time.zone.parse(to_date).to_date
      latest_instnace =  UserTask.latest_repeat_instance(task.id,task.name)[0]
      starting_time = latest_instnace.original_start_at.in_time_zone(task.time_zone) if latest_instnace
      starting_time += 1.day if starting_time
      starting_time ||= task.start_at.in_time_zone(task.time_zone)
      to_date = task.end_at if task.end_at && task.end_at < to_date
      if to_date >= starting_time.to_date && task.start_at.to_date <= to_date
        while starting_time.to_date <= to_date
          i = starting_time.wday
          j = 0
          while !task.repeat_wday?(2**i)
            i == 6 ? i=0 : i= i+1
            j = j + 1
          end
          starting_time += j.day
          if starting_time.to_date <=to_date 
            task.create_task_of_date(starting_time)
          end
          starting_time += 1.day
        end
      end
    end

    def generate_monthly_instances(task,to_date)
      to_date = Time.zone.parse(to_date).to_date
      latest_instnace =  UserTask.latest_repeat_instance(task.id,task.name)[0]
      starting_time = latest_instnace.original_start_at.in_time_zone(task.time_zone) if latest_instnace
      starting_time += 1.day if starting_time
      starting_time ||= task.start_at.in_time_zone(task.time_zone)
      to_date = task.end_at if task.end_at && task.end_at < to_date
      if to_date >= starting_time.to_date && task.start_at.to_date <= to_date
        task_day_of_month = task.start_at.in_time_zone(task.time_zone).day
        while starting_time.to_date <= to_date
          unless starting_time.day == task_day_of_month
            starting_date_month_days = month_days(starting_time.year, starting_time.month)
            if task_day_of_month > starting_date_month_days
              starting_time += (starting_date_month_days - starting_time.day)
            else
              c1 = starting_date_month_days - task_day_of_month
              c2 = starting_date_month_days - starting_time.day
              c3 = c2 - c1
              if c3 >=0
                starting_time += c3.day
              else
                starting_time = starting_time + c3.day + 1.month
              end
            end
          end
          if starting_time <= to_date
            task.create_task_of_date(starting_time)
          end
          starting_time += 1.month
        end
      end
    end

    def create_anual_instances(task,to_date)
      to_date = Time.zone.parse(to_date).to_date
      latest_instnace =  UserTask.latest_repeat_instance(task.id,task.name)[0]
      starting_time = latest_instnace.original_start_at.in_time_zone(task.time_zone) if latest_instnace
      starting_time += 1.year if starting_time
      starting_time ||= task.start_at.in_time_zone(task.time_zone)
      to_date = task.end_at if task.end_at && task.end_at < to_date
      if to_date >= starting_time.to_date && task.start_at.to_date <= to_date
        while starting_time.to_date <= to_date
          task.create_task_of_date(starting_time)
          starting_time += 1.year
        end
      end
    end

    def generate_recurring_task_instances(conditions,due_date)
      to_date = due_date.strftime("%m/%d/%Y")
      conditions = "(" + conditions + ")" + " and repeat in ('DAI','WEE','MON','ANU')"
      repeat_tasks = UserTask.find(:all,:conditions=>conditions)
      unless repeat_tasks.blank?
        repeat_tasks.each do |task|
          case task.repeat
          when 'DAI'
            generate_daily_instances(task,to_date)
          when 'WEE'
            generate_weekly_instances(task,to_date)
          when 'MON'
            generate_monthly_instances(task,to_date)
          when 'ANU'
            create_anual_instances(task,to_date)
          end
        end
      end
    end

    def month_days(y, m)
      leap_year_month_days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
      common_year_month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
      if ((y % 4 == 0) && (y % 100 != 0)) || (y % 400 == 0)
        leap_year_month_days[m-1]
      else
        common_year_month_days[m-1]
      end
    end

  end

  # to create first repeat instance of a repeating task
  def create_default_repeat_instances
    case repeat
    when 'DAI'
      self.create_default_daily_instances
    when 'WEE'
      self.create_default_weekly_instances
    when ('MON' || 'ANU')
      self.create_default_monthy_or_anual_instance
    end
  end

  def create_default_daily_instances
    week_end_day = Date.today + 7.day
    starting_time = start_at.in_time_zone(time_zone)
    if starting_time.to_date > week_end_day
      self.create_task_of_date(starting_time)
    else
      if end_at
        while starting_time.to_date <= week_end_day && starting_time.to_date <= end_at
          self.create_task_of_date(starting_time)
          starting_time=starting_time + 1.day
        end
      else
        while starting_time.to_date <= week_end_day
          self.create_task_of_date(starting_time)
          starting_time=starting_time + 1.day
        end
      end
    end
  end

  def create_default_weekly_instances
    week_end_day = Date.today + 7.day
    starting_time = start_at.in_time_zone(time_zone)
    if starting_time.to_date > week_end_day
      create_task_of_date(starting_time)
    else
      if end_at
        while starting_time.to_date <= week_end_day && starting_time.to_date <= end_at
          i = starting_time.wday
          j = 0
          while !repeat_wday?(2**i)
            i == 6 ? i=0 : i= i+1
            j = j + 1
          end
          create_task_of_date(starting_time + j.day) if (starting_time + j.day).to_date <= week_end_day && (starting_time + j.day).to_date <= end_at
          starting_time = starting_time + (j+1).day
        end
      else
        while starting_time.to_date <= week_end_day
          i = starting_time.wday
          j = 0
          while !repeat_wday?(2**i)
            i == 6 ? i=0 : i= i+1
            j = j + 1
          end
          create_task_of_date(starting_time + j.day) if (starting_time + j.day).to_date <= week_end_day
          starting_time = starting_time + (j+1).day
        end
      end
    end
  end

  def create_default_monthy_or_anual_instance
    self.create_task_of_date(start_at.in_time_zone(time_zone))
  end

  def create_task_of_date(starting_time)
    due_at_time = starting_time + (due_at - start_at)
    task = UserTask.new(:assigned_to_user_id=>assigned_to_user_id,:name=>name,
                 :note_id=>note_id,:priority=>priority,:due_at=>due_at_time,
                 :company_id =>company_id,:created_by_user_id=>created_by_user_id,
                 :assigned_by_employee_user_id=>assigned_by_employee_user_id,
                 :category_id=>category_id,:work_subtype_id=>work_subtype_id,
                 :work_subtype_complexity_id=>work_subtype_complexity_id,:stt=>stt,:tat=>tat,
                 :assigned_by_user_id=>assigned_by_user_id,
                 :share_with_client=>share_with_client,:start_at=>starting_time,
                 :parent_id=>id,:time_zone=>time_zone,:original_start_at=>starting_time)
    task.save
  end

end

