class ImportMatter
  @queue = :import_matter
  ImportPath="#{RAILS_ROOT}/assets/imports"
  #include MatterSequenceBinarySearch

  def self.perform( path_to_file, company_id, user_id, employee_user_id, file_format )
    if file_format == 'CSV'
      #ImportData::matter_process_file(path_to_file,company_id,user_id,employee_user_id,file_format)
      # Below code is use to parse cvs file.
      @company = Company.find(company_id)
      #      @current_user = User.find(employee_user_id)
      @current_user = User.find(user_id)
      @employee_user = Employee.find_by_user_id(employee_user_id)
      @invalid_matters = []
      @invalid_length = 0
      @valid_length = 0
      file_name = File.basename(path_to_file)
      directory =  File.dirname(path_to_file)
      path = path_to_file
      file = File.new(path_to_file, "r").read

      @parser = CSV::Reader.parse(file)
      @parser.each_with_index do |column,i|
        self.matters_parsing(column, i)
      end
      File.delete("#{ImportPath}/#{file_name}")
      report = Spreadsheet::Workbook.new
      sheet = report.create_worksheet
      sheet.row(0).concat ['','*RequiredFields','','# Either Primary Email or Primary Phone required' ,'','','Data entered should be exactly in the format as in the Portal','','','','','','','','','','','','','','','','','','','','','','','','','','','','']
      sheet.row(1).concat ['','','','','','Contact','','','','Lead Lawyer','','','','','']
      sheet.row(2).concat ['Error Message(s)','Matter ID',' *Matter Name','Status','*Matter Category','*Matter Type',' * Matter Inception Date','*First Name','Last Name','Email','Phone','First Name Middle Name Last Name','Plaintiff']

      @invalid_matters.each_with_index do |invalid_matters, j|
        sheet.row(j+3).concat invalid_matters
      end
      @xls_string_errors = StringIO.new ''
      report.write @xls_string_errors
      begin
        if @invalid_length > 0
          directory = "public/"
          filename = "invalid_matters_report_#{Time.now}.xls"
          path = File.join(directory,filename)
          File.open(path, "wb") { |f| f.write(@xls_string_errors.string) }
        end
        send_notification_for_invalid_matters(path,@current_user,@invalid_length,@valid_length,@employee_user)
        File.delete("#{RAILS_ROOT}/public/#{filename}") if @invalid_length > 0
      rescue Exception=>ex
        # send notification for any failure
        puts ex.message
      end
    else
      #ImportData::matter_process_excel_file(path_to_file,company_id,user_id,employee_user_id,file_format)
      @company = Company.find(company_id)
      @current_user = User.find(user_id)
      @employee_user = Employee.find_by_user_id(employee_user_id)
      file_name = File.basename(path_to_file)
      directory =  File.dirname(path_to_file)
      path = path_to_file
      file = File.new(path_to_file, "r").read
      @invalid_length = 0
      @valid_length = 0
      @invalid_matters = []
      ext = File.extname(file_name).downcase
      if ext == ".xls"
        oo = Excel.new(path)
      elsif ext == ".xlsx"
        oo = Excelx.new(path)
      elsif ext == ".ods"
        oo = Openoffice.new(path)
      end
      oo.default_sheet = oo.sheets.first
      4.upto(oo.last_row) do |line|
        self.matter_parsing_xls(oo,line)
      end
      File.delete("#{ImportPath}/#{file_name}")
      report = Spreadsheet::Workbook.new
      sheet = report.create_worksheet
      sheet.row(0).concat ['','*RequiredFields','','# Either Primary Email or Primary Phone required' ,'','','Data entered should be exactly in the format as in the Portal','','','','','','','','','','','','','','','','','','','','','','','','','','','','']
      sheet.row(1).concat ['','','','','','Contact','','','','Lead Lawyer','','','','','']
      sheet.row(2).concat ['Error Message(s)','Matter ID','* Matter Name','Status','* Matter Category(Litigation/Non-Litigation)','* Matter Type','* Matter Inception Date','* First Name','Last Name','#Email','#Phone','First Name','Last Name','Plaintiff/Defendant']

      @invalid_matters.each_with_index do |invalid_matters, j|
        sheet.row(j+3).concat invalid_matters
      end
      @xls_string_errors = StringIO.new ''
      report.write @xls_string_errors
      begin
        if @invalid_length > 0
          directory = "public/"
          filename = "invalid_matters_report_#{Time.now}.xls"
          path = File.join(directory,filename)
          File.open(path, "wb") { |f| f.write(@xls_string_errors.string) }
        end
        send_notification_for_invalid_matters(path,@current_user,@invalid_length,@valid_length,@employee_user)
        File.delete("#{RAILS_ROOT}/public/#{filename}") if @invalid_length > 0
      rescue Exception=>ex
        # send notification for any failure
        puts ex.message
      end
    end
  end

  def self.matters_parsing( column, i )
    if i > 2
      err_msg = []
      flag = true
      success = false
      matter_id = !column[0].blank? ? column[0] : nil
      if matter_id != nil && matter_id.to_s.include?('.0')
        matter_id = (matter_id.to_s.gsub('.0', '''')).to_s
      end
      matter_name = !column[1].blank? ? column[1] :''
      if !column[2].blank?
        status = column[2].capitalize
      else
        status = 'Open'
      end
      status_value = @company.matter_statuses.find_by_lvalue(status)
      if status_value.present?
        status_id = status_value.id
      else
        flag = false
        err_msg << "Matter status is Invalid."
      end

      if column[3].present?
        if column[3].strip.downcase.eql?('litigation') || column[3].gsub(/(-|\s+)/,"").downcase.eql?('non-litigation')
          if column[3].strip.downcase.eql?('litigation')
            types = @company.liti_types
          elsif column[3].gsub(/(-|\s+)/,"").strip.downcase.eql?('non-litigation')
            types = @company.nonliti_types
          end
        else
          flag = false
          err_msg << "Matter Category Should be either Litigation or Non-litigation"
        end
      else
        flag = false
        err_msg << "Matter Category cannot be blank."
      end
      if column[4].present?
        type = column[4].titleize
        if types.present?
          type_value = types.find_by_lvalue(type)
          if type_value.present?
            type_id = type_value.id
          else
            flag = false
            err_msg << "Matter type is Invalid."
          end
        end
      else
        flag = false
        err_msg << "Matter Type cannot be blank."
      end
      begin
        inception_date = column[5].present? ? Date.parse(column[5]).to_date.strftime("%m/%d/%Y") : Date.today
      rescue Exception => exc
        flag = false
        err_msg << "Invalid inception date"
      end
      contact_first_name = column[6].present? ? column[6].strip.to_s.titleize : ''
      contact_last_name = column[7].present? ? column[7].strip.to_s.titleize : ''
      contact_stage_value = column[8].present? ? column[8].strip.to_s.titleize : ''
      contact_email = column[9].present? ? column[9].strip.to_s : ''

      if column[10] != nil && column[10].include?("'")
        contact_phone = column[10].gsub(/[']/, '''').to_i.to_s
      else
        contact_phone = column[10].present? ? column[10].to_s : ''
      end
      if contact_phone != nil && contact_phone.include?(".0")
        contact_phone = (contact_phone.gsub(/[.0]/, '''')).to_s
      end
      
      contact_stage = @company.contact_stages.find_by_lvalue(contact_stage_value)
      contact_stage_id = contact_stage.id if contact_stage
      contact_stage = @company.contact_stages.find_by_alvalue('Lead') if contact_stage.blank?
      if contact_stage.blank?
        flag = false
        err_msg << " Invalid Contact Stage."
      else
        contact_stage_id = contact_stage.id
      end
            
      uname = (contact_first_name.to_s + ' ' +  contact_last_name.to_s).strip
      Matter.transaction do
        contact_details = {:first_name => contact_first_name, :last_name => contact_last_name, :email => contact_email,
          :phone => contact_phone,:company_id => @company.id, :contact_stage_id => contact_stage_id, :assigned_to_employee_user_id => @employee_user.user_id}
        contacts = Contact.find_by_sql("SELECT id FROM contacts WHERE ((trim(contacts.first_name) || ' ' || trim(coalesce(contacts.last_name, ' ')) iLike '#{uname}') ) AND company_id = #{@company.id} AND (email = '#{contact_email}' OR phone = '#{contact_phone}') LIMIT 1")
        if contacts.empty?
          contact = Contact.new(contact_details)
          if contact.valid? 
            is_contact_new = true
            # flag= true
          else
            flag = false
            contact_errors = []
            contact.errors.full_messages.each do |error|
              contact_errors << "Contact :" + error
            end
            err_msg << contact_errors
          end
        else
          contact = contacts[0]
        end
        lead_lawyer_first_middile_last_name = column[11].present? ? column[11].titleize  : ''
        #        lead_lawyer_last_name = column[12].present? ? column[12].titleize  : ''
        lname = (lead_lawyer_first_middile_last_name).strip
        if lname.blank?
          employee_user_id = @employee_user.user_id
        else
          employee_details = User.find_by_sql("SELECT id FROM users WHERE ((trim(users.first_name) || ' ' || trim(coalesce(users.last_name))) iLike '%#{lname}%')  AND company_id = #{@company.id}  LIMIT 1")
          if employee_details.present?
            employee_user_id = employee_details[0].id
          else
            err_msg << "Invalid Lead Lawyer."
          end
        end

        matter_category = column[3].to_s
        if matter_category.present?
          unless matter_category.strip.downcase.eql?("litigation") || matter_category.strip.downcase.eql?("non-litigation")
            err_msg << "Invalid Matter Category."
          end
        else
          err_msg << "Matter Category is required."
        end

        matter_details ={:matter => {:matter_no => matter_id,:name => matter_name.to_s,:status_id => status_id.to_i,:contact_id => 0,
            :matter_category => matter_category.strip.downcase,:matter_type_id => type_id.to_i,:matter_date => inception_date,
            :employee_user_id => employee_user_id,:company_id => @company.id,:is_internal => false,:created_by_user_id => @current_user.id}}
        User.current_company = @company
        User.current_user = @current_user
        matter = @company.matters.new(matter_details[:matter])
      if err_msg.empty? && flag && matter.valid?
        contact.save! if contact.new_record?
        matter_details[:matter][:contact_id] = contact.id
          matter, success = Matter.save_with_contact_and_opportunity(matter_details, employee_user_id, nil)
          if column[3].present? && column[3].strip.downcase.eql?('litigation')
            if column[12].present?
              plaintiff = column[12].strip.capitalize.eql?('Plaintiff')
            else
              plaintiff = true
            end
            matter.matter_litigations.create("plaintiff"=> plaintiff,"company_id"=>@company.id) if matter && !matter.new_record?
          end
        end
        if success
          @valid_length=@valid_length+1
        else
          @invalid_length=@invalid_length+1
          #          contact.destroy! if contact.errors.empty? && is_contact_new
          if err_msg.empty?
            err_msg << matter.errors.full_messages
          end
          # Below code is use to add unsaved @contact error object in  @invalid_matters array.
          @invalid_matters  << [err_msg.flatten.join(" ;"),column[0], column[1],column[2],column[3],column[4], column[5],column[6],column[7],column[9],column[10],column[11],column[12]]
        end
      end
    end
  end

  def self.matter_parsing_xls(oo,line)
    err_msg = []
    flag = true
    success = false
    matter_id = !oo.cell(line,'A').blank? ? oo.cell(line,'A') : nil
    if matter_id != nil && matter_id.to_s.include?('.0')
      matter_id = (matter_id.to_s.gsub('.0', '''')).to_s
    end
    matter_name = !oo.cell(line,'B').blank? ? oo.cell(line,'B') : ''
    if oo.cell(line,'C').present?
      status = oo.cell(line,'C').capitalize
    else
      status = 'Open'
    end
    status_value = @company.matter_statuses.find_by_lvalue(status)
    if status_value.present?
      status_id = status_value.id
    else
      flag = false
      err_msg << "Matter status is Invalid."
    end
    if oo.cell(line,'D').present?
      if oo.cell(line,'D').strip.downcase.eql?('litigation') || oo.cell(line,'D').gsub(/(-|\s+)/,"").downcase.eql?('non-litigation')
        if oo.cell(line,'D').strip.downcase.eql?('litigation')
          types = @company.liti_types
        elsif oo.cell(line,'D').gsub(/(-|\s+)/,"").strip.downcase.eql?('non-litigation')
          types = @company.nonliti_types
        end
      else
        flag = false
        err_msg << "Matter Category Should be either Litigation or Non-Litigation"
      end
    else
      flag = false
      err_msg << "Matter Category cannot be blank."
    end

    if oo.cell(line,'E').present?
      type = oo.cell(line,'E').titleize
      if types.present?
        type_value = types.find_by_lvalue(type)
        if type_value.present?
          type_id = type_value.id
        else
          flag = false
          err_msg << "Matter type is Invalid."
        end
      end
    else
      flag = false
      err_msg << "Matter Type cannot be blank."
    end
    begin
      inception_date = !oo.cell(line,'F').blank? ? Date.parse(oo.cell(line,'F')).to_date.strftime("%m/%d/%Y") : Date.today
    rescue Exception => exc
      flag = false
      err_msg << "Invalid inception date"
    end
    contact_first_name = oo.cell(line,'G').present? ? oo.cell(line,'G').strip.to_s.titleize : ''
    contact_last_name = oo.cell(line,'H').present? ? oo.cell(line,'H').strip.to_s.titleize : ''
    contact_stage_value = oo.cell(line,'I').present? ? oo.cell(line,'I').strip.to_s.titleize : ''
    contact_email = oo.cell(line,'J').present? ? oo.cell(line,'J').strip.to_s : ''
    if oo.cell(line,'K')!=nil && oo.cell(line,'K').to_s.include?("'")
      contact_phone = oo.cell(line,'K').gsub(/[']/, '''').to_i.to_s
    else
      contact_phone = !oo.cell(line,'K').blank? ? oo.cell(line,'K').to_s : ''
    end
    if contact_phone != nil && contact_phone.include?(".0")
      contact_phone = (contact_phone.gsub(/[.0]/, '''')).to_s
    end

    contact_stage = @company.contact_stages.find_by_lvalue(contact_stage_value)
    contact_stage_id = contact_stage.id if contact_stage
    contact_stage = @company.contact_stages.find_by_alvalue('Lead') if contact_stage.blank?
    if contact_stage.blank?
      flag = false
      err_msg << " Invalid Contact Stage."
    else
      contact_stage_id = contact_stage.id
    end

    uname = (contact_first_name.to_s + ' ' +  contact_last_name.to_s).strip
    Matter.transaction do
      contact_details= {:first_name => contact_first_name, :last_name => contact_last_name, :email => contact_email,
        :phone => contact_phone,:company_id => @company.id, :contact_stage_id => contact_stage_id, :assigned_to_employee_user_id => @employee_user.user_id}
      contacts = Contact.find_by_sql("SELECT id FROM contacts WHERE ((trim(contacts.first_name) || ' ' || trim(coalesce(contacts.last_name, ' '))) iLike '#{uname}') AND company_id = #{@company.id} AND (email = '#{contact_email}' OR phone = '#{contact_phone}') LIMIT 1")
      if contacts.empty?
        contact = Contact.new(contact_details)
        if contact.valid?
          is_contact_new = true
          # flag= true
        else
          flag = false
          contact_errors = []
          contact.errors.full_messages.each do |error|
            contact_errors << "Contact :" + error
          end
          err_msg << contact_errors
        end
      else
        contact = contacts[0]
      end
      lead_lawyer_first_middle_last_name = oo.cell(line,'L').present? ? oo.cell(line,'L').titleize : ''
      #      lead_lawyer_last_name = oo.cell(line,'M').present? ? oo.cell(line,'M').titleize : ''
      lname = (lead_lawyer_first_middle_last_name).strip
      if lname.blank?
        employee_user_id = @employee_user.user_id
      else
        employee_details = User.find_by_sql("SELECT id FROM users WHERE ((trim(users.first_name) || ' ' || trim(coalesce(users.last_name))) iLike '%#{lname}%')  AND company_id = #{@company.id}  LIMIT 1")
        if employee_details.present?
          employee_user_id = employee_details[0].id
        else
          err_msg << "Invalid Lead Lawyer."
        end
      end

      matter_category = oo.cell(line,'D')
      if matter_category.present?
        unless matter_category.strip.downcase.eql?("litigation") || matter_category.strip.downcase.eql?("non-litigation")
          err_msg << "Invalid Matter Category."
        end
      else
        err_msg << "Matter Category is required."
      end
      
      matter_details = {:matter => {:matter_no => matter_id,:name => matter_name.to_s,:status_id => status_id.to_i,
          :contact_id => 0, :matter_category => matter_category.strip.downcase,
          :matter_type_id => type_id.present? ? type_id.to_i : "", :matter_date => inception_date,:employee_user_id => employee_user_id,
          :company_id => @company.id,:is_internal => false, :created_by_user_id => @current_user.id}}
      User.current_company = @company
      User.current_user = @current_user
      matter = @company.matters.new(matter_details[:matter])
      if err_msg.empty? && flag && matter.valid?
        contact.save! if contact.new_record?
        matter_details[:matter][:contact_id] = contact.id
        #TOD0: please refactor the matter create method
        matter, success = Matter.save_with_contact_and_opportunity( matter_details, employee_user_id, nil )
        if oo.cell( line, 'D' ).present? && oo.cell( line, 'D' ).strip.downcase.eql?('litigation')
          if oo.cell( line, 'M' ).present?
            plaintiff = oo.cell( line, 'M' ).strip.capitalize.eql?('Plaintiff')
          else
            plaintiff = true
          end
          matter.matter_litigations.create("plaintiff"=> plaintiff,"company_id"=>@company.id) if matter && !matter.new_record?
        end
      end

      if success
        @valid_length=@valid_length+1
      else
        @invalid_length=@invalid_length+1
        #        contact.destroy! if contact.errors.empty? && is_contact_new
        if err_msg.empty?
          err_msg << matter.errors.full_messages
        end
        # Below code is use to add unsaved @contact error object in  @invalid_contacts array.
        @invalid_matters  << [err_msg.flatten.join(" ;"), self.utf8_value(oo.cell(line,'A')),self.utf8_value(oo.cell(line,'B')), self.utf8_value(oo.cell(line,'C')),self.utf8_value(oo.cell(line,'D')),self.utf8_value(oo.cell(line,'E')),self.utf8_value(oo.cell(line,'F')),self.utf8_value(oo.cell(line,'G')), self.utf8_value(oo.cell(line,'H')),self.utf8_value(oo.cell(line,'J')),self.utf8_value(oo.cell(line,'K')),self.utf8_value(oo.cell(line,'L')),self.utf8_value(oo.cell(line,'M')) ]
      end
    end
  end

  def self.utf8_value(val)
    !val.blank? ? Iconv.conv("UTF-8//IGNORE", "US-ASCII", val.to_s.strip.gsub("'","`")) : nil
  end
end