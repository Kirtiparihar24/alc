class ExpenseImport < ExcelImport
 
  attr_accessor :current_user_id,:employee_user_id,:company_id,:header_array,:error_path,:employee_user

  EXPENSE_ENTRY_DETAILS = ["expense_entry_date","employee_user_id","matter_id","contact_id","expense_type","description","expense_amount","is_billable","final_expense_amount"]

  HEADERS = ["expense_entry_date","employee_user_id","matter_no","name","first_name","middle_name","last_name","expense_type","description","expense_amount","is_billable","final_expense_amount"]

  EXCEL_HEADERS= ["*Date","*FirstName MiddleName LastName","*Matter ID","*Matter Name","*FirstName","MiddleName","LastName",	"Expense Type","*Description","*Expense Amt($)","Billable","Final Amount($)"]

  def initialize(current_user_id,employee_user_id,company_id,error_path,file_path=nil,options={})
    @employee_user_id,@company_id = employee_user_id,company_id
    @error_path = error_path
    @current_user_id = current_user_id
    @employee_user = User.find(@employee_user_id)
    super(file_path,options)

    #    validate_file unless file_path.is_a?(Array)
  end

  def validate_file
    raise "Invalid file formating" if @header.size != EXCEL_HEADERS.size
    @header.each_with_index do |h,i|
      raise "Invalid file formating" if h != EXCEL_HEADERS[i]
      return
    end
  end

  def import_object_record
    ActiveRecord::Base.transaction do
      @object_records.each do |object|
        begin
          expense_entry = object[0]
          index = object[1]
          if expense_entry.valid?
            expense_entry.created_by_user_id = @current_user_id
            expense_entry.current_lawyer = @current_user_id
            if expense_entry.save
              @valid_records << [expense_entry,@roo_object.row(index+1+@first_row)]
            else
              @invalid_records << [expense_entry,@roo_object.row(index+1+@first_row),expense_entry.errors.full_messages.uniq]
            end
          else
            @invalid_records << [expense_entry,@roo_object.row(index+1+@first_row),expense_entry.errors.full_messages.uniq]
          end
        rescue
          @invalid_records << [expense_entry,@roo_object.row(index+1+@first_row),expense_entry.errors.full_messages.uniq]
        end
      end
    end
  end

  def import_records
    @valid_records = []
    @invalid_records= []
    @object_records = []
    data = import_excel
    @header_array = HEADERS
    record_hash(HEADERS)
    @company = Company.find(company_id)
    @user = User.find(employee_user_id)
    @expense_types = {}
    @company.expense_types.each {|et| @expense_types[et.alvalue]=et.id}
    @hash_records.each_with_index do |record,index|
      flag = false

      if record["expense_entry_date"].strip.blank?
        record["errors"] << "Date can not be blank"
        flag = true
      else
        expense_entry_date = Date.parse(record["expense_entry_date"].strip).strftime("%Y-%m-%d")
        record["expense_entry_date"] = expense_entry_date
      end


      if !record["employee_user_id"].strip.nil? && !record["employee_user_id"].strip.empty?
        
        assigned_to = User.find_by_sql("SELECT * FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{record["employee_user_id"].strip}') ) AND company_id = #{@company.id} LIMIT 1")

		    if assigned_to.empty?
          record["errors"] << "Invalid Employee name"
          flag = true
			  else
				  record["employee_user_id"] = assigned_to.first.user_id
			  end
      else
        record["errors"] << "Name of employee does not exist."
        flag = true
      end

      if record["matter_no"].strip.present? && record["name"].strip.present? && !record["expense_entry_date"].strip.blank?
        matter_no = set_matter_no(record["matter_no"].strip)
        record["matter_no"] = matter_no
        matter = @company.matters.find_by_matter_no_and_name(matter_no,record["name"].strip)
        @matter_inception_date = Date.parse(matter.matter_date.to_s).strftime("%Y-%m-%d") if matter.present?
        if !matter.blank?
          record["matter_id"] = matter.id
        else
           record["errors"] << " Invalid Matter No. or Name  "
           flag = true
        end
        date_check = (expense_entry_date >= @matter_inception_date) if @matter_inception_date.present?
        if !(date_check) && !matter.blank? && !@matter_inception_date.blank?
           record["errors"] << " Date should be grater than inception date of matter  "
           flag = true
        end
      elsif record["matter_no"].strip.blank?
        record["errors"] << " Matter No. can not be blank  "
        flag = true
      elsif record["name"].strip.blank?
        record["errors"] << " Matter Name can not be blank  "
        flag = true
      end

      if record["first_name"].strip.present?
        contact_name = record["first_name"].strip
        c_condition = "trim(first_name)"
        if record["middle_name"].present?
          contact_name = contact_name + ' ' + record["middle_name"].strip
          c_condition += " || ' ' || trim(middle_name)"
        end
        if record["last_name"].present?
          contact_name = contact_name + ' ' + record["last_name"].strip
          c_condition += " || ' ' || trim(last_name)"
        end
        if !record["first_name"].strip and matter.present?
          record["errors"] << " Contact name can not be blank for matter.  "
          flag = true
        end
      else
        record["errors"] << " Contact first name can not be blank.  "
        flag = true
      end

      matter_contact = @company.contacts.find(:all, :conditions => ["("+ c_condition +") ilike ? ", contact_name]) if record["first_name"].present? && matter.present?

      if matter_contact.blank?
        record["errors"] << " Contact is not linked to matter "
        flag = true
      end

      # for managing activity_type id by default is lead id
      if !record["expense_type"].strip.nil? && !record["expense_type"].strip.empty?
        if @expense_types.keys.include?(record["expense_type"])
          record["expense_type"] = @expense_types[record["expense_type"]]
        else
          record["errors"] << "Invalid Expense Type"
          flag = true
        end
      else
        record["errors"] << "Expense Type can not blank ."
        flag = true
      end

      if record["description"].strip.blank?
        record["errors"] << "Description can not be blank"
        flag = true
      else
        record["description"] = record["description"].strip
      end


      if record["expense_amount"].strip.blank?
        record["errors"] << "Expense Amount can not be blank"
        flag = true
      else
        record["expense_amount"] = record["expense_amount"].strip
      end

      record["final_expense_amount"] = record["final_expense_amount"].strip.blank? ? '' :  record["final_expense_amount"]

      if flag
        @invalid_records <<['',@roo_object.row(index+1+@first_row),record["errors"].join(",")]
      else
        expense_entry_info = parse_expense_entry_details(record,@company.id)
        @object_records <<  [Physical::Timeandexpenses::ExpenseEntry.new(expense_entry_info),index]
      end
    end

    import_object_record
    invalid_records_to_excel(@error_path,@invalid_records,["Error",EXCEL_HEADERS].flatten)
  end

  def set_matter_no(val)
    if val.nil? || val.empty?
      val=nil
    else
      val.to_s.gsub('.0', '''').to_s
    end
  end

  def parse_expense_entry_details(record,company_id)
    expense_entry_info= {}
    EXPENSE_ENTRY_DETAILS.each do |ee|
      expense_entry_info[ee] = record[ee]
    end
    #  contact_info["status_type"] = ''
    expense_entry_info["company_id"] = company_id
    expense_entry_info
  end

end
