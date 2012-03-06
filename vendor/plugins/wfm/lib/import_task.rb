module ImportTask
  require 'flexible_csv'
  require 'csv'
  require 'spreadsheet'
  include GeneralFunction

  ImportPath="#{RAILS_ROOT}/assets/imports"

  def self.import_file_name_format(current_user_id, name)
    # format is current_user_id and timestamp and then name for uniqness of file import
    return "#{current_user_id}_#{Time.now.to_i}_#{name}"
  end

  def self.save_data_file(import_file, current_user_id)
    path = File.join(ImportPath, import_file_name_format(current_user_id, import_file.original_filename))
    File.open(path, "wb") { |f| f.write(import_file.read) }
    return path
  end

  def self.utf8_value(val)
    !val.blank? ? Iconv.conv("UTF-8//IGNORE", "US-ASCII", val.to_s.strip.gsub("'","`")) : nil
  end
  
  def self.tasks_excel_parsing(oo,line,current_user_id)
    date_exp = /^(((0?[1-9]|1[012])\/(0?[1-9]|1\d|2[0-8])|(0?[13456789]|1[012])\/(29|30)|(0?[13578]|1[02])\/31)\/(19|[2-9]\d)\d{2}|0?2\/29\/((19|[2-9]\d)(0[48]|[2468][048]|[13579][26])|(([2468][048]|[3579][26])00)))$/
    if self.utf8_value(oo.cell(line,'A')).blank?
      @errors << "Task on line #{line} Task Name can not be blank!"
    else
      task_name = self.utf8_value(oo.cell(line,'A')).try(:capitalize)
    end
    if (self.utf8_value(oo.cell(line,'B'))!=nil && ["Normal","Urgent"].include?(self.utf8_value(oo.cell(line,'B')).capitalize))
      task_priority = self.utf8_value(oo.cell(line,'B')).capitalize.eql?('Normal') ? '1' : '2'
    else
      @errors << "Task on line #{line} fill Priority!"
    end
    unless self.utf8_value(oo.cell(line,'C')).blank?
      start_date = self.utf8_value(oo.cell(line,'C'))
      if start_date.match(date_exp)
        task_start_date = DateTime.parse(start_date).strftime("%d-%m-%Y %H:%M:%S")
      else
        @errors << "Task on line #{line} Please fill vaild start date!"
      end
      unless self.utf8_value(oo.cell(line,'D')).blank? || task_start_date.blank?
        start_time = Time.at self.utf8_value(oo.cell(line,'D')).to_i
        task_start_date = DateTime.parse(start_date + ' ' + start_time.utc.strftime("%H:%M:%S")).strftime("%d-%m-%Y %H:%M:%S")
      end
      if task_start_date.present?  && Date.parse(task_start_date) <= Date.yesterday
        @errors << "Task on line #{line} Please fill start date greater than or equal to Today!"
      end
    end
    unless self.utf8_value(oo.cell(line,'E')).blank?
      due_date = self.utf8_value(oo.cell(line,'E'))
      if due_date.match(date_exp)
        task_due_date = DateTime.parse(due_date)
        if self.utf8_value(oo.cell(line,'F')).blank?
          task_due_date = DateTime.parse(task_due_date.strftime("%d-%m-%Y") + ' 23:59:00').strftime("%d-%m-%Y %H:%M:%S")
        else
          due_time = Time.at self.utf8_value(oo.cell(line,'F')).to_i
          task_due_date = DateTime.parse(task_due_date.strftime("%d-%m-%Y") + ' ' + due_time.utc.strftime("%H:%M:%S")).strftime("%d-%m-%Y %H:%M:%S")
        end
        if task_due_date.present? && Date.parse(task_due_date) <= Date.yesterday
          @errors << "Task on line #{line} Please fill due date greater than or equal to Today!"
        end
      else
        @errors << "Task on line #{line} Please fill vaild due date!"
      end
    end
    
    if self.utf8_value(oo.cell(line,'G')).blank?
      @errors << "Task on line #{line} Please fill Work Sub Type!"
    else
      work_sub_type_name = self.utf8_value(oo.cell(line,'G'))
      work_sub_type = WorkSubtype.find(:first,:conditions =>['name = ?',work_sub_type_name])
      if work_sub_type.blank?
        @errors << "Task on line #{line} Please fill vaild Work Sub Type!"
      else
        task_work_sub_type_id = work_sub_type.id
        task_category_id = work_sub_type.work_type.category.id
        if self.utf8_value(oo.cell(line,'H')).blank?
          complexities = work_sub_type.work_subtype_complexities
          task_complexity = complexities.first unless complexities.blank?
          unless task_complexity.blank?
            task_complexity_id = task_complexity.id
            task_stt = task_complexity.stt
            task_tat = task_complexity.tat
          end
        else
          complexity_level = self.utf8_value(oo.cell(line,'H')).to_i
          task_complexity = work_sub_type.work_subtype_complexities.find(:first,:conditions =>['complexity_level = ?',complexity_level])
          if task_complexity.blank?
            @errors << "Task on line #{line} Please fill vaild Work Sub Type Complexity!"
          else
            task_complexity_id = task_complexity.id
            task_stt = task_complexity.stt
            task_tat = task_complexity.tat
          end
        end
      end
    end
    
    if self.utf8_value(oo.cell(line,'I')).blank?
      task_share_with_client = false
    else
      case self.utf8_value(oo.cell(line,'I')).capitalize
      when 'Yes'
        task_share_with_client = true
      when 'No'
        task_share_with_client = false
      else
        @errors << "Task on line #{line} Please fill valid value of Share With Client !"
      end
    end
    if self.utf8_value(oo.cell(line,'J')).blank?
      @errors << "Task on line #{line} Please fill Lawyer Email Address!"
    else
      email = "#{self.utf8_value(oo.cell(line,'J')).strip}"
      employee_details = Employee.find_by_email(email)
      if employee_details.blank?
        @errors << "Task on line #{line} Please fill vaild Lawyer Email Address!"
      else
        task_assigned_by_employee_id = employee_details.user_id unless employee_details.blank?
        task_company_id = employee_details.company.id
      end
    end
    if self.utf8_value(oo.cell(line,'K')).blank?
      @errors << "Task on line #{line} Please fill Livian Email Address!"
    else
      email = "#{self.utf8_value(oo.cell(line,'K')).strip}"
      user = User.find_by_email(email)
      if user.blank?
        @errors << "Task on line #{line} Please fill vaild Livian Email Address!"
      else
        task_assign_to_user_id = user.id
      end
    end

    #-----------Creating Hash for tasks---------------------

    task_details ={"name"=>task_name,
      "priority"=>task_priority,
      "due_at"=> task_due_date,
      "start_at"=> task_start_date,
      "company_id"=>task_company_id,
      "created_by_user_id"=> current_user_id ,
      "assigned_by_employee_user_id"=>task_assigned_by_employee_id,
      "assigned_by_user_id"=>current_user_id,
      "assigned_to_user_id"=>task_assign_to_user_id,
      "share_with_client"=>task_share_with_client,
      "work_subtype_id"=>task_work_sub_type_id,
      "work_subtype_complexity_id" => task_complexity_id,
      "stt" => task_stt,
      "tat" => task_tat,
      "category_id" => task_category_id,
      "time_zone" => Time.zone.name,
      "note_id"=>nil
    }
    # Create new task Object
    note_details = {"description"=>task_name,
      "note_priority"=>task_priority,
      "company_id"=>task_company_id,
      "created_by_user_id"=> current_user_id ,
      "assigned_by_employee_user_id"=>task_assigned_by_employee_id,
      "assigned_to_user_id"=>task_assign_to_user_id,
      "status" => 'complete'
    }
    if task_start_date && task_due_date
      if Time.parse(task_start_date) > Time.parse(task_due_date)
        @errors << "Task on line #{line} Please fill vaild Start date and Due date"
      end
    end
    #--- Creating hash finished ------------------
    return [note_details,task_details]
  end

  def self.task_entry_process_file(path_to_file, current_user_id)
    total_task = 0
    tasks_notes_obj =[]
    save_task =0
    @errors =[]
    name = File.basename(path_to_file)
    path = path_to_file
    file = File.new(path_to_file, "r").read

    ext = File.extname(name)
    if ext == ".csv" || ext == ".CSV"
      @parser = CSV::Reader.parse(file)
      @parser.each_with_index do |column,i|
        self.expense_parsing_csv(column,i,current_user_id)
      end
    else
      if ext==".xls"
        object = Excel.new(path)
      elsif ext==".xlsx"
        object = Excelx.new(path)
      elsif ext==".ods"
        object = Openoffice.new(path)
      end

      object.default_sheet = object.sheets.first
      tasks_notes_obj=[]
      4.upto(object.last_row) do |line|
        total_task += 1
        tasks_notes_obj << self.tasks_excel_parsing(object,line,current_user_id)
      end
    end
    if @errors.blank?
      tasks_notes_obj.each do |obj|
        note = Communication.new(obj[0])
        note.save
        note.user_tasks.create(obj[1])
        save_task += 1
      end
      return [total_task,save_task,@errors]
    else
      return [total_task,'0',@errors]
    end
  end

end
