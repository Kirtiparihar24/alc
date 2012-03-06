module ImportData
  require 'flexible_csv'
  require 'csv'
  require 'spreadsheet'
  include GeneralFunction

  ImportPath="#{RAILS_ROOT}/assets/imports"

  def self.import_file_name_format(company_id, name)
    # format is company_id and timestamp and then name for uniqness of file import
    "#{company_id}_#{Time.now.to_i}_#{name}" 
  end

  def self.save_data_file(import_file, company_id)
    path = File.join(ImportPath, import_file_name_format(company_id, import_file.original_filename))
    File.open(path, "wb") { |f| f.write(import_file.read) }

    path
  end

  def self.contact_process_excel_file(path_to_file,company_id,user_id,employee_user_id)
    # Below code is use to parse xls file.
    company = Company.find(company_id)
    user = User.find(user_id)
    employee_user = Employee.find_by_user_id(employee_user_id)
    name = File.basename(path_to_file)
    directory =  File.dirname(path_to_file)
    path = path_to_file
    file = File.new(path_to_file, "r").read
    #File.open(path, "wb") { |f| f.write(file) }
    ext = File.extname(name).downcase
    if ext==".xls"
      oo= Excel.new(path)
    elsif ext==".xlsx"
      oo= Excelx.new(path)
    elsif ext==".ods"
      oo = Openoffice.new(path)
    end
    #oo= Excel.new(path)
    oo.default_sheet = oo.sheets.first if ext != ('.csv')
    @parser = CSV::Reader.parse(file)
    @assigned_to =[]
    @company=company
    @invalid_length=0
    @valid_length=0
    @invalid_contacts=[]
    @current_user=user
    @employee_user_id=employee_user.user_id
    @cell_str_s = []
    ActiveRecord::Base.connection.execute("SELECT setval('contacts_id_seq', (select max(id) + 1 from contacts));")
    if ext == ('.csv')
      @parser.each_with_index do |column,i|
        self.contacts_parsing(column,i)
      end
    else
      5.upto(oo.last_row) do |line|
        self.contacts_excel_parsing(oo,line)
      end
    end


    report = Spreadsheet::Workbook.new
    sheet = report.create_worksheet
    sheet.row(0).concat ['','','*RequiredFields','','# Either Primary Email or Primary Phone required' ,'','','','','Data entered should be exactly in the format as in the Portal','','','','','','','','','','','','','','','','','','','','','','','','','','','','']
    sheet.row(1).concat ['','Contact Details','','','','','','','','','','','','','','Business Contact Details','','','','','','','','','Personal Details','','','','','','Other','','','','','','','','','','']
    sheet.row(2).concat ['Error Message(s)','Salutation','First Name *','Middle Name','Last Name','Primary Email #','Primary Phone #','Nick Name','Alternate Email','Source','Source Details','Assigned To','Contact Stage *','Company','Title','Street','City','State','Zip Code','Fax','Alternate Phone 1','Alternate Phone 2','Website','Comments','Street','City','State','Zip Code','Mobile','Fax','Skype Account','Linked In Account','Facebook Account','Twitter Account','Other1','Other2','Other3','Other4','Other5','Other6']
    #set the width of the columns in excel and add some formatting
    format = Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre ,:text_wrap =>true
    format1 = Spreadsheet::Format.new :horizontal_align=>:centre ,:text_wrap => true , :shrink => true
    fmt = Spreadsheet::Format.new :text_wrap => true ,:shrink => true
    sheet.row(0).height = 50
    sheet.row(2).default_format = format
    40.times{ |x| sheet.column(x+1).width = 25}
    sheet.column(0).width = 80
    sheet.column(0).default_format = fmt
    (1..40).each{|c| sheet.column(c).default_format = format1}
    (3..100).each {|r| sheet.row(r).height = 80}
    @invalid_contacts.each_with_index do |invalid_contacts, j|
      sheet.row(j+4).concat invalid_contacts
    end
    @xls_string_errors = StringIO.new ''
    report.write @xls_string_errors
    begin
      err_directory = "public/"
      err_filename="invalid_contacts_report_#{Time.now}.xls"
      err_path = File.join(err_directory,err_filename)
      File.open(err_path, "wb") { |f| f.write(@xls_string_errors.string) }
      send_notification_for_invalid_contacts(err_path,@current_user,@invalid_length,@valid_length,employee_user)
      File.delete("#{RAILS_ROOT}/public/#{err_filename}")
      File.delete(path_to_file)
    rescue Exception=>ex
      #send notification for any failure
      puts ex.message
    end
  end

  def self.contact_process_file(path_to_file,company_id,user_id,employee_user_id)
    # Below code is use to parse cvs file.
    company = Company.find(company_id)
    user = User.find(user_id)
    employee_user = Employee.find_by_user_id(employee_user_id)
    name = File.basename(path_to_file)
    directory =  File.dirname(path_to_file)
    path = path_to_file
    file = File.new(path_to_file, "r").read

    @parser = CSV::Reader.parse(file)
    @assigned_to =[]
    @company=company
    @invalid_length=0
    @valid_length=0
    @invalid_contacts=[]
    @current_user=user
    @employee_user_id=employee_user.user_id

    # Below code is use to fetch each parse data.
    @parser.each_with_index do |column,i|
      self.contacts_parsing(column,i)
    end
    File.delete(path_to_file)

    begin
      directory = "public/"
      filename="invalid_contacts_report_#{Time.now}.csv"
      path = File.join(directory,filename)
      File.open(path, "wb") { |f| f.write(@csv_string) }
      send_notification_for_invalid_contacts(path,@current_user,@invalid_length,@valid_length,employee_user)
      File.delete("#{RAILS_ROOT}/public/#{filename}")
    rescue Exception=>ex
      # send notification for any failure
      puts ex.message
    end
  end 

  def self.contacts_excel_parsing(oo,line)
    err_msg = []
    flag = 0
    comments_details = self.utf8_value(oo.cell(line,'AJ')).blank? ? "Imported from file. " : "#{self.utf8_value(oo.cell(line,'AJ'))}:Imported from file. "

    #NOTE:
    #Arrangement of column is done according to the sequence
    #----------------COLUMN START---------------------

    # This below line of code is for adding salutaion_id into contacts table while importing contacts--Rahul P 5/5/2011

    unless self.utf8_value(oo.cell(line,'A')).blank?
      cell_str = self.utf8_value(oo.cell(line,'A')).try(:capitalize)
      salutation = @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @company.id).present? ? @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @company.id).id : 0
    else
      salutation = 0
    end
    if (self.utf8_value(oo.cell(line,'B'))!=nil && (self.utf8_value(oo.cell(line,'B')).present? && self.utf8_value(oo.cell(line,'B')).include?("'")))
      first_name =  (self.utf8_value(oo.cell(line,'B')).gsub(/[']/, '''')).to_s
    else
      first_name =  self.utf8_value(oo.cell(line,'B')).to_s
    end
    if (first_name!=nil && first_name.include?(".0"))
      first_name = (first_name.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'C'))!=nil && self.utf8_value(oo.cell(line,'C')).include?("'")
      middle_name =  (self.utf8_value(oo.cell(line,'C')).gsub(/[']/, '''')).to_s
    else
      middle_name =  self.utf8_value(oo.cell(line,'C')).to_s
    end
    if middle_name!=nil && middle_name.include?(".0")
      middle_name = (middle_name.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'D'))!=nil && self.utf8_value(oo.cell(line,'D')).include?("'")
      last_name  =  (self.utf8_value(oo.cell(line,'D')).gsub(/[']/, '''')).to_s
    else
      last_name  =  self.utf8_value(oo.cell(line,'D')).to_s
    end
    if last_name!=nil && last_name.include?(".0")
      last_name = (last_name.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'E'))!=nil && self.utf8_value(oo.cell(line,'E')).include?("'")
      email  =  (self.utf8_value(oo.cell(line,'E')).gsub(/[']/, '''')).to_s
    else
      email  =  self.utf8_value(oo.cell(line,'E')).to_s
    end

    if self.utf8_value(oo.cell(line,'F'))!=nil && self.utf8_value(oo.cell(line,'F')).include?("'")
      phone  =  (self.utf8_value(oo.cell(line,'F')).gsub(/[']/, '''')).to_i.to_s
    else
      phone  =  self.utf8_value(oo.cell(line,'F')).to_s
    end
    
    phone = (phone.gsub('.0', '''')).to_s if phone!=nil && phone.include?(".0")
    phone = (phone.gsub(/[' ']/, '''')).to_s if phone!=nil && phone.include?(" ")

    if self.utf8_value(oo.cell(line,'G'))!=nil && self.utf8_value(oo.cell(line,'G')).include?("'")
      nick_name  =  (self.utf8_value(oo.cell(line,'G')).gsub(/[']/, '''')).to_s
    else
      nick_name  =  self.utf8_value(oo.cell(line,'G')).to_s
    end
    if nick_name!=nil && nick_name.include?(".0")
      nick_name = (nick_name.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'H'))!=nil && self.utf8_value(oo.cell(line,'H')).include?("'")
      alt_email  =  (self.utf8_value(oo.cell(line,'H')).gsub(/[']/, '''')).to_s
    else
      alt_email  =  self.utf8_value(oo.cell(line,'H')).to_s
    end

    #@cell_str_s << self.utf8_value(oo.cell(line,'I'))
    if self.utf8_value(oo.cell(line,'I'))
      cell_str_s = self.utf8_value(oo.cell(line,'I')).to_s
      lookup_lead_source = @company.company_sources.find_by_alvalue(cell_str_s)#.find_by_lvalue(cell_str_s)#.id
      if lookup_lead_source.nil?
        lookup_lead_source = nil # @company.company_sources.find_by_alvalue('Other')#.find_by_lvalue_and_company_id('Other', @company.id)#
      else
        lookup_lead_source = lookup_lead_source.id
      end
    else
      lookup_lead_source = nil #@company.company_sources.find_by_alvalue('Other') # find_by_lvalue_and_company_id('Other', @company.id)#
    end

    if self.utf8_value(oo.cell(line,'I')) && self.utf8_value(oo.cell(line,'I')).present?  && (cell_str_s.downcase).include?("none")
      lookup_lead_source = nil
    end

    if self.utf8_value(oo.cell(line,'J')) && self.utf8_value(oo.cell(line,'J')).include?("'")
      source_detail  =  (self.utf8_value(oo.cell(line,'J')).gsub(/[']/, '''')).to_s
    else
      source_detail  =  self.utf8_value(oo.cell(line,'J'))
    end

    #Add few required fields details Assigned Lawyers id.
    assigned_false = false
    if  self.utf8_value(oo.cell(line,'K'))
      name = self.utf8_value(oo.cell(line,'K')).split(' ')
      uname = "#{self.utf8_value(oo.cell(line,'K')).strip}"
      #employee_details = User.find(:first, :conditions =>["trim(first_name) || ' ' ||trim(last_name) ilike ? and company_id = ?", uname,@company.id])
      employee_details = User.find_by_sql("SELECT user_id FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{uname}') ) AND company_id = #{@company.id} LIMIT 1")
      if employee_details.empty?
        assigned_false = true
        assigned_to = @employee_user_id
      else
        assigned_to = employee_details.kind_of?(Array) ? employee_details.first.user_id : employee_details.user_id
      end
    else
      assigned_to = @employee_user_id
    end
    if self.utf8_value(oo.cell(line,'K')) && (uname.downcase).include?("none")
      assigned_to = nil
      assigned_false = false
    end
    
    if self.utf8_value(oo.cell(line,'L')) && self.utf8_value(oo.cell(line,'L')).include?("'")
      stage  =  (self.utf8_value(oo.cell(line,'L')).gsub(/[']/, '''')).to_s
    else
      stage  =  self.utf8_value(oo.cell(line,'L')).to_s
    end
    if stage!=nil && stage.include?(".0")
      stage = (stage.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'M')) && self.utf8_value(oo.cell(line,'M')).include?("'")
      organisation  =  (self.utf8_value(oo.cell(line,'M')).gsub(/[']/, '''')).to_s
    else
      organisation =  self.utf8_value(oo.cell(line,'M')).to_s
    end
    if organisation!=nil && organisation.include?(".0")
      organisation = (organisation.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'N')) && self.utf8_value(oo.cell(line,'N')).include?("'")
      title  =  (self.utf8_value(oo.cell(line,'N')).gsub(/[']/, '''')).to_s
    else
      title  =  self.utf8_value(oo.cell(line,'N')).to_s
    end
    if title!=nil && title.include?(".0")
      title = (title.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'O')) && self.utf8_value(oo.cell(line,'O')).include?("'")
      business_street  =  (self.utf8_value(oo.cell(line,'O')).gsub(/[']/, '''')).to_s
    elsif self.utf8_value(oo.cell(line,'O'))
      business_street  =  self.utf8_value(oo.cell(line,'O')).to_s
    end
    if business_street!=nil && business_street.include?(".0")
      business_street = (business_street.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'P')) && self.utf8_value(oo.cell(line,'P')).include?("'")
      business_city  =  (self.utf8_value(oo.cell(line,'P')).gsub(/[']/, '''')).to_s
    elsif self.utf8_value(oo.cell(line,'P'))
      business_city  =  self.utf8_value(oo.cell(line,'P')).to_s
    end
    if business_city!=nil && business_city.include?(".0")
      business_city = (business_city.to_s.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'Q')) && self.utf8_value(oo.cell(line,'Q')).include?("'")
      business_state  =  (self.utf8_value(oo.cell(line,'Q')).to_s.gsub(/[']/, '''')).to_s
    elsif self.utf8_value(oo.cell(line,'Q'))
      business_state  =  self.utf8_value(oo.cell(line,'Q')).to_s
    end
    if business_state!=nil && business_state.include?(".0")
      business_state = (business_state.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'R'))
      if self.utf8_value(oo.cell(line,'R')).include?("'")
        business_postal_code = (self.utf8_value(oo.cell(line,'R')).gsub(/[']/, '''')).to_s
      else
        business_postal_code = self.utf8_value(oo.cell(line,'R')).to_s
      end
    end
    if business_postal_code!=nil && business_postal_code.include?(".0")
      business_postal_code = (business_postal_code.gsub('.0', '''')).to_s
    end
    if self.utf8_value(oo.cell(line,'S'))
      if self.utf8_value(oo.cell(line,'S')).to_s.include?("'")
        business_fax = ((self.utf8_value(oo.cell(line,'S')).gsub(/[']/, '''')).to_i).to_s
      else
        business_fax = self.utf8_value(oo.cell(line,'S')).to_s
      end
    end

    business_fax = (business_fax.gsub('.0', '''')).to_s if business_fax!=nil && business_fax.include?(".0")
    business_fax = (business_fax.gsub(/[' ']/, '''')).to_s if business_fax && business_fax.include?(" ")

    if self.utf8_value(oo.cell(line,'T'))
      if self.utf8_value(oo.cell(line,'T')).include?("'")
        business_phone  =  ((self.utf8_value(oo.cell(line,'T')).gsub(/[']/, '''')).to_i).to_s
      else
        business_phone  =  self.utf8_value(oo.cell(line,'T')).to_s
      end
    end

    business_phone = (business_phone.gsub('.0', '''')).to_s if business_phone!=nil && business_phone.include?(".0")
    business_phone = (business_phone.gsub(/[' ']/, '''')).to_s if business_phone!=nil && business_phone.include?(" ")

    if self.utf8_value(oo.cell(line,'U'))
      if self.utf8_value(oo.cell(line,'U')).include?("'")
        businessphone2  =  ((self.utf8_value(oo.cell(line,'U')).gsub(/[']/, '''')).to_i).to_s
      else
        businessphone2  =  self.utf8_value(oo.cell(line,'U')).to_s
      end
    end

    businessphone2 = (businessphone2.gsub('.0', '''')).to_s if businessphone2!=nil && businessphone2.include?(".0")
    businessphone2 = (businessphone2.gsub(/[' ']/, '''')).to_s if businessphone2!=nil && businessphone2.include?(" ")

    if self.utf8_value(oo.cell(line,'V')) && self.utf8_value(oo.cell(line,'V')).include?("'")
      website  =  (self.utf8_value(oo.cell(line,'V')).gsub(/[']/, '''')).to_s
    else
      website  =  self.utf8_value(oo.cell(line,'V')).to_s
    end

    if self.utf8_value(oo.cell(line,'W')) && self.utf8_value(oo.cell(line,'W')).include?("'")
      comments  =  (self.utf8_value(oo.cell(line,'W')).gsub(/[']/, '''')).to_s
    else
      comments  =  self.utf8_value(oo.cell(line,'W')).to_s
    end
    if comments!=nil && comments.include?(".0")
      comments = (comments.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'X')) && self.utf8_value(oo.cell(line,'X')).include?("'")
      street  =  (self.utf8_value(oo.cell(line,'X')).gsub(/[']/, '''')).to_s
    else
      street  =  self.utf8_value(oo.cell(line,'X')).to_s
    end
    if street!=nil && street.include?(".0")
      street = (street.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'Y')) && self.utf8_value(oo.cell(line,'Y')).include?("'")
      city  =  (self.utf8_value(oo.cell(line,'Y')).gsub(/[']/, '''')).to_s
    else
      city  =  self.utf8_value(oo.cell(line,'Y')).to_s
    end
    if city!=nil && city.include?(".0")
      city = (city.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'Z')) && self.utf8_value(oo.cell(line,'Z')).include?("'")
      state  =  (self.utf8_value(oo.cell(line,'Z')).gsub(/[']/, '''')).to_s
    else
      state  =  self.utf8_value(oo.cell(line,'Z')).to_s
    end
    if state!=nil && state.include?(".0")
      state = (state.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AA'))
      if  self.utf8_value(oo.cell(line,'AA')).include?("'")
        zip_code  =  ((self.utf8_value(oo.cell(line,'AA')).gsub(/[']/, '''')).to_i).to_s
      else
        zip_code  =  self.utf8_value(oo.cell(line,'AA')).to_s
      end
    end
    if zip_code!=nil && zip_code.include?(".0")
      zip_code = (zip_code.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AB')) && self.utf8_value(oo.cell(line,'AB')).include?("'")
      mobile  =  ((self.utf8_value(oo.cell(line,'AB')).gsub(/[']/, '''').to_s).to_i).to_s
    else
      mobile  =  self.utf8_value(oo.cell(line,'AB'))
    end
    if mobile!=nil && mobile.include?(".0")
      mobile = (mobile.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AC')) && self.utf8_value(oo.cell(line,'AC')).include?("'")
      fax  =  ((self.utf8_value(oo.cell(line,'AC')).gsub(/[']/, '''')).to_i).to_s
    else
      fax  =  self.utf8_value(oo.cell(line,'AC'))
    end
    if fax!=nil && fax.include?(".0")
      fax = (fax.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AD')) && self.utf8_value(oo.cell(line,'AD')).include?("'")
      skype_account  =  (self.utf8_value(oo.cell(line,'AD')).gsub(/[']/, '''')).to_s
    else
      skype_account  =  self.utf8_value(oo.cell(line,'AD')).to_s
    end
    if skype_account!=nil && skype_account.include?(".0")
      skype_account = (skype_account.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AE')) && oo.cell(line,'AE').include?("'")
      linked_in_account  =  (self.utf8_value(oo.cell(line,'AE')).gsub(/[']/, '''')).to_s
    else
      linked_in_account  =  self.utf8_value(oo.cell(line,'AE')).to_s
    end
    if linked_in_account!=nil && linked_in_account.include?(".0")
      linked_in_account = (linked_in_account.gsub('.0', '''')).to_s
    end

    if self.utf8_value(oo.cell(line,'AF')) && self.utf8_value(oo.cell(line,'AF')).include?("'")
      facebook_account  =  (self.utf8_value(oo.cell(line,'AF')).gsub(/[']/, '''')).to_s
    else
      facebook_account  =  self.utf8_value(oo.cell(line,'AF')).to_s
    end
    if facebook_account!=nil && facebook_account.include?(".0")
      facebook_account = (facebook_account.to_s.gsub('.0', '''')).to_s
    end
    if self.utf8_value(oo.cell(line,'AG')) && self.utf8_value(oo.cell(line,'AG')).include?("'")
      twitter_account  =  (self.utf8_value(oo.cell(line,'AG')).gsub(/[']/, '''')).to_s
    else
      twitter_account  =  self.utf8_value(oo.cell(line,'AG')).to_s
    end
    if twitter_account!=nil && twitter_account.include?(".0")
      twitter_account = (twitter_account.gsub('.0', '''')).to_s
    end

    others1 = self.utf8_value(oo.cell(line,'AH'))
    others2 = self.utf8_value(oo.cell(line,'AI'))
    others3 = self.utf8_value(oo.cell(line,'AJ'))
    others4 = self.utf8_value(oo.cell(line,'AK'))
    others5 = self.utf8_value(oo.cell(line,'AL'))
    others6 = self.utf8_value(oo.cell(line,'AM'))
    department = self.utf8_value(oo.cell(line,'AN'))
    business_country = self.utf8_value(oo.cell(line,'AO'))
    country = self.utf8_value(oo.cell(line,'AP'))
    preference = self.utf8_value(oo.cell(line,'AQ'))

    contact_stage = @company.contact_stages.find_by_alvalue('Lead')
    contact_stage_id = contact_stage.id if contact_stage
    contact_stage = @company.contact_stages.find_by_alvalue(stage) unless stage.blank?
    if contact_stage.nil?
      flag = 1
      err_msg << " Invalid Contact Stage. "
    else
      contact_stage_id = contact_stage.id
    end
    # do not remove this code, as validation for uniqueness is getting failed so this one added - Sumanta Das
    if first_name.present? && (phone.present? || email.present?)
      conditions = " first_name = '#{first_name.capitalize}' "
      email.blank? ? conditions += " AND email IS NULL " : conditions += " AND email = '#{email}' "
      phone.blank? ? conditions += " AND phone IS NULL " :  conditions += " AND phone = '#{phone}' "
      last_name.blank? ? conditions +=  " AND last_name IS NULL " : conditions += " AND last_name = '#{last_name.capitalize}' "
      conditions += " AND company_id = #{@company.id}"
      count = Contact.first(:conditions => conditions )
      if count && count.id > 0
        flag = 1
        err_msg << " This Contact Is Already Present In The System. "
      end
    end
    #-----------Creating Hash for contacts---------------------
    # DO NOT CHANGE THE SYMBOL TO STRING, AS FOR EACH ITARION IT WILL TAKE MORE MEMORY - SUMANTA DAS
    @contact_details ={:salutation_id=>salutation.to_s, :first_name=>first_name, :middle_name=> middle_name,
      :last_name => last_name, :nickname => nick_name, :email => email, :phone => phone,
      :mobile=>mobile,:fax => fax, :website => website, :title => title,
      :assigned_to_employee_user_id => assigned_to ,:department => department,
      :alt_email=>alt_email, :preference =>preference,:organization => organisation,
      :created_by_user_id => @employee_user_id, :user_comment => comments_details,
      :source_details => source_detail,:company_id => @company.id, :source => lookup_lead_source,
      :contact_stage_id => contact_stage_id, :status_type => ''}
    # Create new contact Object
    @contact_obj =Contact.new(@contact_details)


    # Below code is use to add Contact Information form fields information in addresses table.
    @address = @contact_obj.build_address(:street => street, :city => city, :state => state ,
      :zipcode => zip_code, :company_id => @contact_obj.company_id)

    @contact_additional_details = @contact_obj.build_contact_additional_field(:business_street => business_street,
      :business_city => business_city, :business_state => business_state ,:business_postal_code => business_postal_code,
      :business_fax => business_fax, :business_phone => business_phone, :businessphone2=> businessphone2,
      :skype_account => skype_account, :linked_in_account => linked_in_account, :facebook_account => facebook_account,
      :twitter_account => twitter_account, :others_1 => others1, :others_2 => others2, :others_3 => others3,
      :others_4 => others4, :others_5 => others5, :others_6 => others6, :company_id => @contact_obj.company_id)

    #--- Creating hash finished ------------------
    if !assigned_false && flag == 0 && @contact_obj.valid?
      con = ActiveRecord::Base.connection

      first_name = "'" + first_name.to_s  + "'"
      middle_name.blank? ? middle_name = "NULL" : middle_name =  ("'" + middle_name.to_s  + "'")
      last_name.blank? ? last_name = "NULL" : last_name =  ("'" + last_name.to_s  + "'")
      source_detail.blank? ? source_detail = "NULL" : source_detail =  ("'" + source_detail.to_s  + "'")
      email.blank? ? email = "NULL" : email = ( "'" + email.to_s  + "'")
      alt_email.blank? ? alt_email = "NULL" : alt_email =  ("'" + alt_email.to_s  + "'")
      phone.blank? ? phone = "NULL" : phone =  ("'" + phone.to_s  + "'")
      mobile.blank? ? mobile = "NULL" : mobile =  ("'" + mobile.to_s  + "'")
      website.blank? ? website = "NULL" : website =  ("'" + website.to_s  + "'")
      department.blank? ? department = "NULL" : department =  ("'" + department.to_s  + "'")
      fax.blank? ? fax = "NULL" : fax = ("'" + fax + "'")
      preference.blank? ? preference = "NULL" : preference = ( "'" + preference.to_s  + "'")
      nick_name.blank? ? nick_name = "NULL" : nick_name =  ("'" + nick_name.to_s  + "'")
      salutation.blank? ? salutation = "NULL" : salutation = salutation.to_s

      con.execute("SELECT setval('contacts_id_seq', (select max(id) + 1 from contacts));")
      sql = "INSERT INTO contacts(assigned_to_employee_user_id, first_name, middle_name,last_name, title, organization, source, source_details,email, alt_email, phone, mobile, website, department, fax, preference, nickname, company_id,created_by_user_id, salutation_id, created_at, updated_at,contact_stage_id) VALUES ("+ (assigned_to.present? ? assigned_to.to_s : "NULL" ).to_s + ", " + first_name.to_s + ", " +  middle_name.to_s + ", " + last_name.to_s + ", " + (title.present? ? ("'" + title.slice(0..63).to_s + "'"): "''") + ", " + (organisation.present? ? ("'" + organisation.slice(0..63).to_s + "'") : "''") + ", " + (lookup_lead_source.present? ? lookup_lead_source.to_s : "NULL" ) + ", " + source_detail.to_s + " ," + email.to_s + ", " + alt_email.to_s + " , " + phone.to_s + ", " + mobile.to_s + ", " + website.to_s + ", " + department.to_s + ", "+ fax.to_s + ", " + preference.to_s + ", " + nick_name.to_s + ", " + (@company.id).to_s + ", " + (@employee_user_id).to_s + ", " + salutation.to_s + ", '" + (Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')).to_s + "', '" + (Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')).to_s + "', " +  contact_stage_id.to_s + ") RETURNING id\;"
      @contact = Contact.find_by_sql(sql)
      @contact.each do |c|
        @contact_id = c.id
      end

      con.execute("SELECT setval('addresses_id_seq', (select max(id) + 1 from addresses));")
      con.execute("INSERT INTO addresses(street, city, country, zipcode, state, contact_id, company_id) VALUES
       ('#{street}', '#{city}','#{country}', '#{zip_code.to_s}','#{state}', #{@contact_id}, #{@company.id});")
      con.execute("SELECT setval('contact_additional_fields_id_seq', (select max(id) + 1 from contact_additional_fields));")
      con.execute("INSERT INTO contact_additional_fields(business_street, business_city, business_state,
                  business_country, business_postal_code, business_fax, business_phone, businessphone2,
                  linked_in_account, twitter_account, facebook_account, skype_account,
                  others_1,others_2,others_3,others_4,others_5,others_6,
                  contact_id, company_id) VALUES
                  ('#{business_street ? business_street.slice!(0..63) : ''}',
                  '#{business_city ? business_city.slice!(0..63) : ''}',
                  '#{business_state ? business_state.slice!(0..63) : ''}',
                  '#{business_country ? business_country.slice!(0..63) : ''}',
                  '#{business_postal_code}', '#{business_fax}',
                  '#{business_phone ? business_phone.slice!(0..15) : ''}',
                  '#{businessphone2 ? businessphone2.slice!(0..15) : ''}',
                  '#{linked_in_account ? linked_in_account.slice!(0..63) : ''}',
                  '#{twitter_account ? twitter_account.slice!(0..63) : ''}',
                  '#{facebook_account ? facebook_account.slice!(0..63) : ''}',
                  '#{skype_account ? skype_account.slice!(0..63) : ''}',
                  '#{others1}','#{others2}','#{others3}','#{others4}','#{others5}','#{others6}',
                  #{@contact_id}, #{@company.id});")

      if comments.present?
        con.execute("SELECT setval('comments_id_seq', (select max(id) + 1 from comments));")
        con.execute("INSERT INTO comments(comment, created_at,permanent_deleted_at,commentable_type,
                      title,commentable_id,private,updated_at,deleted_at,is_read,share_with_client,company_id,created_by_user_id)
                      VALUES('#{comments}','#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}', NULL,'Contact','Comment',#{@contact_id}, NULL, '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}', NULL, NULL, NULL, #{@company.id}, #{@employee_user_id});")
      end

      @valid_length = @valid_length + 1
    else
      @invalid_length = @invalid_length + 1
      #error_message = first_name.blank? ? "Contact First Name can't be Blank. " : ""
      @contact_obj.errors.add(' ', 'Assigned To Is Invalid') if assigned_false
      @contact_obj.errors.add(' ', 'Please Enter Contact Stage.') if stage.blank?
      @invalid_contacts << [(@contact_obj.errors.full_messages + err_msg).flatten.to_s,self.utf8_value(oo.cell(line,'A')),first_name,
        middle_name,last_name,email, phone, nick_name, alt_email, self.utf8_value(oo.cell(line,'I')),source_detail,
        self.utf8_value(oo.cell(line,'K')),stage, organisation, title, business_street, business_city, business_state,
        business_postal_code, business_fax, business_phone, businessphone2, website,comments,street, city, state, zip_code,
        mobile, fax, skype_account, linked_in_account, facebook_account,twitter_account, others1, others2, others3,
        others4, others5, others6]
    end
  end

  def self.contacts_parsing(column,i)
    err_msg = []
    flag = 0
    if i >= 4

      comments_details = self.utf8_value(column[36]) ? "Imported from file. " : "#{self.utf8_value(column[36])}:Imported from file. "
      # This below line of code is for adding salutaion_id into contacts table while importing contacts--Rahul P 5/5/2011
      if self.utf8_value(column[0])
        cell_str = self.utf8_value(column[0]).try(:capitalize)
        salutation = @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @company.id).present? ? @company.salutation_types.find_by_lvalue_and_company_id(cell_str, @company.id).id : 0
      else
        salutation = 0
      end

      first_name = self.utf8_value(column[1])
      middle_name =self.utf8_value(column[2])
      last_name = self.utf8_value(column[3])
      email = self.utf8_value(column[4])
      phone = self.utf8_value(column[5])
      nick_name = self.utf8_value(column[6])
      alt_email = self.utf8_value(column[7])
      source = self.utf8_value(column[8])
      source_detail = self.utf8_value(column[9])
      assigned_to = self.utf8_value(column[10])
      stage=self.utf8_value(column[11])
      company = self.utf8_value(column[12])
      title = self.utf8_value(column[13])
      b_street = self.utf8_value(column[14])
      b_city = self.utf8_value(column[15])
      b_state = self.utf8_value(column[16])
      b_zip_code = self.utf8_value(column[17])
      b_fax = self.utf8_value(column[18])
      alt_phone_1 = self.utf8_value(column[19])
      alt_phone_2 = self.utf8_value(column[20])
      website = self.utf8_value(column[21])
      comments= self.utf8_value(column[22])
      p_street = self.utf8_value(column[23])
      p_city = self.utf8_value(column[24])
      p_state = self.utf8_value(column[25])
      p_zip_code = self.utf8_value(column[26])
      mobile = self.utf8_value(column[27])
      p_fax = self.utf8_value(column[28])
      skype = self.utf8_value(column[29])
      linked = self.utf8_value(column[30])
      facebook = self.utf8_value(column[31])
      twitter = self.utf8_value(column[32])
      others_1 = self.utf8_value(column[33])
      others_2 = self.utf8_value(column[34])
      others_3 = self.utf8_value(column[35])
      others_4 = self.utf8_value(column[36])
      others_5 = self.utf8_value(column[37])
      others_6 = self.utf8_value(column[38])
      department = self.utf8_value(column[39])
      business_country = self.utf8_value(column[40])
      country = self.utf8_value(column[41])
      preference = self.utf8_value(column[42])

      contact_stage = @company.contact_stages.find_by_alvalue('Lead')
      contact_stage_id = contact_stage.id if contact_stage
      contact_stage = @company.contact_stages.find_by_alvalue(stage) unless stage.blank?
      if contact_stage.blank?
        flag = 1
        err_msg << " Invalid Contact Stage. "
      else
        contact_stage_id = contact_stage.id
      end


      # Below code will create a new hash with mandatory fields [first_name,last_name,email,phone] and othere fields [topic,notes,user_id].
      @contact_details ={"salutation_id"=>salutation.to_s,"first_name"=>first_name,"middle_name"=> middle_name,"last_name"=>last_name,"nickname"=>nick_name,"email"=>email,"phone"=>phone,"mobile"=>mobile,"fax"=>p_fax,"website"=>website,"title"=>title,"assigned_to_employee_user_id" => assigned_to ,"department"=>department,"alt_email"=>alt_email,"preference"=>preference,"organization"=>company,"created_by_user_id" => @employee_user_id,:user_comment=>comments_details,"source_details" => source_detail,"contact_stage_id" => contact_stage_id,"status_type"=> ''}
      #      @contact_details ={"salutation"=>oo.cell(line,'A').to_s,"first_name"=>oo.cell(line,'B').to_s,"last_name"=>oo.cell(line,'C').to_s,"nickname"=>oo.cell(line,'F'),"email"=>email.to_s,"phone"=>phone.to_s,"mobile"=>mobile.to_s,"fax"=>fax,"website"=>oo.cell(line,'R'),"title"=>oo.cell(line,'J'),"assigned_to_employee_user_id"=>oo.cell(line,'H'),"department"=>oo.cell(line,'AK'),"alt_email"=>oo.cell(line,'G'),"preference"=>oo.cell(line,'AL'),"organization"=>oo.cell(line,'I'),"created_by_user_id" => get_employee_user_id,:current_user_name=>get_user_name,:user_comment=>comments_details}
      # Find Lookup lead source id for "others"
      @cell_str_s=[]
      @cell_str_s << source
      unless source.blank?
        cell_str_s = source
        lookup_lead_source = @company.company_sources.find_by_alvalue(cell_str_s)#find_by_lvalue(cell_str_s)#.id
        #salutation = salutation_check.blank? ? '' : salutation_check.id
        if lookup_lead_source.nil?
          lookup_lead_source = nil # @company.company_sources.find_by_alvalue('Other')# find_by_lvalue('Other')
        else
          lookup_lead_source = lookup_lead_source.id
        end
      else
        lookup_lead_source = nil #@company.company_sources.find_by_alvalue('Other')#.find_by_lvalue('Other')
      end
      #lookup_lead_source = @company.company_sources.find_by_lvalue('Other')

      #Add few required fields details Assigned Lawyers id.
      assigned_false = false
      if assigned_to
        name = assigned_to.split(' ')
        uname = "#{assigned_to.strip}"
        #employee_details = User.find(:first, :conditions =>["trim(first_name) || ' ' ||trim(last_name) = ? and company_id = ?", uname,@company.id])
        employee_details = User.find_by_sql("SELECT employees.user_id FROM employees WHERE ((trim(employees.first_name) || ' ' || trim(employees.last_name) iLike '#{uname}') ) AND company_id = #{@company.id} LIMIT 1")
        if employee_details.empty?
          assigned_false = true
          assigned_to = @employee_user_id
        else
          assigned_to = employee_details.kind_of?(Array) ? employee_details.first.user_id : employee_details.user_id
        end
      else
        assigned_to = @employee_user_id
      end

      if source.present? && (cell_str_s.downcase).include?("none")
        lookup_lead_source = nil
      end
    
      if self.utf8_value(column[10]) && (uname.downcase).include?("none")
        assigned_to = nil
        assigned_false = false
      end
      # Add assigned_to,law_firm_id,source in @contact_details hash.
      @contact_details.merge!("assigned_to_employee_user_id" => assigned_to,"company_id" =>@company.id,:source=>lookup_lead_source)


      #end
      # Add the status_details in @contact_details hash.
      # @contact_details.merge!(status_details)

      # Create new contact Object

      @contact_obj =Contact.new(@contact_details)

      # Below code is use to add Contact Information form fields information in addresses table.
      @address = @contact_obj.build_address("street"=> p_street,
        "city"=> p_city,
        "state"=> p_state ,
        "zipcode"=> p_zip_code,
        #        "country"=>!column[14].blank??column[14]:'',
        "company_id"=>@contact_obj.company_id)
      @contact_additional_details = @contact_obj.build_contact_additional_field("business_street"=> b_street,
        "business_city"=> b_city,
        "business_state"=> b_state ,
        "business_postal_code"=> b_zip_code,
        "business_fax"=> b_fax,#business_fax,
        "business_phone"=> alt_phone_1,
        "businessphone2"=> alt_phone_2,
        "skype_account"=> skype,
        "linked_in_account"=> linked,
        "facebook_account"=> facebook,
        "twitter_account"=> twitter,
        "others_1"=> others_1,
        "others_2"=> others_2,
        "others_3"=> others_3,
        "others_4"=> others_4,
        "others_5"=> others_5,
        "others_6"=> others_6,
        "company_id"=>@contact_obj.company_id)
      # do not remove this code, as validation for uniqueness is getting failed so this one added - Sumanta Das
      
      if first_name.present? && (phone.present? || email.present?)
        conditions = " first_name = '#{first_name.capitalize}' "
        email.blank? ? conditions += " AND email IS NULL " : conditions += " AND email = '#{email}' "
        phone.blank? ? conditions += " AND phone IS NULL " :  conditions += " AND phone = '#{phone}' "
        last_name.blank? ? conditions +=  " AND last_name IS NULL " : conditions += " AND last_name = '#{last_name.capitalize}' "
        conditions += " AND company_id = #{@company.id}"
        count = Contact.first(:conditions => conditions )
      
        if count && count.id > 0
          flag = 1
          err_msg << " This Contact Is Already Present In The System. "
        end
      end
      # Below code is user to save the contact object.
      if !assigned_false && flag == 0 && @contact_obj.valid?
        #@contact.save
        con = ActiveRecord::Base.connection
        con.execute("SELECT setval('contacts_id_seq', (select max(id) + 1 from contacts));")
        first_name = "'" + first_name.to_s  + "'"
        (middle_name.blank? || middle_name.nil?)  ? middle_name = "NULL" : middle_name =  ("'" + middle_name.to_s  + "'")
        (last_name.blank? || last_name.nil?) ? last_name = "NULL" : last_name =  ("'" + last_name.to_s  + "'")
        (source_detail.blank? || source_detail.nil?) ? source_detail = "NULL" : source_detail =  ("'" + source_detail.to_s  + "'")
        (email.blank? || email.nil?) ? email = "NULL" : email = ( "'" + email.to_s  + "'")
        (alt_email.blank? || alt_email.nil?) ? alt_email = "NULL" : alt_email =  ("'" + alt_email.to_s  + "'")
        (phone.blank? || phone.nil?) ? phone = "NULL" : phone =  ("'" + phone.to_s  + "'")
        (mobile.blank? || mobile.nil?) ? mobile = "NULL" : mobile =  ("'" + mobile.to_s  + "'")
        (website.blank? || website.nil?) ? website = "NULL" : website =  ("'" + website.to_s  + "'")
        (department.blank? || department.nil?) ? department = "NULL" : department =  ("'" + department.to_s  + "'")
        (p_fax.blank? || p_fax.nil?) ? p_fax = "NULL" : p_fax = ("'" + p_fax + "'")
        (preference.blank? || preference.nil?) ? preference = "NULL" : preference = ( "'" + preference.to_s  + "'")
        (nick_name.blank? || nick_name.nil?) ? nick_name = "NULL" : nick_name =  ("'" + nick_name.to_s  + "'")
        (salutation.blank? || salutation.nil?) ? salutation = "NULL" : salutation = salutation.to_s

        sql = "INSERT INTO contacts(assigned_to_employee_user_id, first_name, middle_name,last_name, title, organization, source, source_details,email, alt_email, phone, mobile, website, department, fax, preference, nickname, company_id,created_by_user_id, salutation_id, created_at, updated_at,contact_stage_id) VALUES ("+ (assigned_to.present? ? assigned_to.to_s : "NULL" ).to_s + ", " + first_name.to_s + ", " +  middle_name.to_s + ", " + last_name.to_s + ", " + (title.present? ? ("'" + title.slice(0..63).to_s + "'"): "''") + ", " + (company.present? ? ("'" + company.slice(0..63).to_s + "'") : "''") + ", " + (lookup_lead_source.present? ? lookup_lead_source.to_s : "NULL" ) + ", " + source_detail.to_s + " ," + email.to_s + ", " + alt_email.to_s + " , " + phone.to_s + ", " + mobile.to_s + ", " + website.to_s + ", " + department.to_s + ", "+ p_fax.to_s + ", " + preference.to_s + ", " + nick_name.to_s + ", " + (@company.id).to_s + ", " + (@employee_user_id).to_s + ", " + salutation.to_s + ", '" + (Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')).to_s + "', '" + (Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')).to_s + "', " +  contact_stage_id.to_s + ") RETURNING id\;"
        @contact = Contact.find_by_sql(sql)

        @contact.each do |c|
          @contact_id = c.id
        end

        con.execute("SELECT setval('addresses_id_seq', (select max(id) + 1 from addresses));")
        con.execute("INSERT INTO addresses(street, city, country, zipcode, state, contact_id, company_id) VALUES ('#{p_street}', '#{p_city}', '#{country}', '#{p_zip_code}', '#{p_state}', #{@contact_id}, #{@company.id});")
        con.execute("SELECT setval('contact_additional_fields_id_seq', (select max(id) + 1 from contact_additional_fields));")
        con.execute("INSERT INTO contact_additional_fields(business_street, business_city, business_state,
                  business_country, business_postal_code, business_fax, business_phone, businessphone2,
                  linked_in_account, twitter_account, facebook_account, skype_account,
                  others_1,others_2,others_3,others_4,others_5,others_6,
                  contact_id, company_id) VALUES
                  ('#{b_street.slice!(0..63) if b_street}',
                  '#{b_city.slice!(0..63) if b_city}',
                  '#{b_state.slice!(0..63) if b_state}',
                  '#{business_country.slice!(0..63) if business_country}',
                  '#{b_zip_code}', '#{b_fax}',
                  '#{alt_phone_1.slice!(0..15) if alt_phone_1}',
                  '#{alt_phone_2.slice!(0..15) if alt_phone_2}',
                  '#{linked.slice!(0..63) if linked}',
                  '#{twitter.slice!(0..63) if twitter}',
                  '#{facebook.slice!(0..63) if facebook}',
                  '#{skype.slice!(0..63) if skype}',
                  '#{others_1}','#{others_2}','#{others_3}','#{others_4}','#{others_5}','#{others_6}',
                  #{@contact_id}, #{@company.id});")
        # Below code is use to keep count of saved object.

        if comments.present?
          con.execute("SELECT setval('comments_id_seq', (select max(id) + 1 from comments));")
          con.execute("INSERT INTO comments(comment, created_at,permanent_deleted_at,commentable_type,
                      title,commentable_id,private,updated_at,deleted_at,is_read,share_with_client,company_id,created_by_user_id)
                      VALUES('#{comments}','#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}', NULL,'Contact','Comment',#{@contact_id}, NULL, '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}', NULL, NULL, NULL, #{@company.id}, #{@employee_user_id});")
        end

        @valid_length=@valid_length+1
      else
        @contact_obj.errors.add(' ', 'Assigned To Is Invalid') if assigned_false
        # Below code is use to keep count of unsaved object.
        @invalid_length=@invalid_length+1
        # Below code is use to add unsaved @contact error object in  @invalid_contacts array.
        #@invalid_contacts << @contact_obj

        @assigned_to << assigned_to.to_s
        c=@contact_obj
        salutation_check = @company.salutation_types.find_by_id(c.salutation_id)
        salutation = salutation_check.blank? ? '' : salutation_check.lvalue
        @invalid_contacts << [(c.errors.full_messages + err_msg).flatten.to_s,self.utf8_value(column[0]),c.first_name,c.middle_name,
          c.last_name,c.email,c.phone,c.nickname,c.alt_email, cell_str_s, c.source_details,self.utf8_value(column[10]),
          stage,c.organization,c.title, c.contact_additional_field.business_street,c.contact_additional_field.business_city,
          c.contact_additional_field.business_state,c.contact_additional_field.business_postal_code,
          c.contact_additional_field.business_fax,c.contact_additional_field.business_phone,
          c.contact_additional_field.businessphone2,c.website,comments,c.address.street,c.address.city,c.address.state,
          c.address.zipcode,c.mobile,c.fax,c.contact_additional_field.skype_account,
          c.contact_additional_field.linked_in_account,c.contact_additional_field.facebook_account,
          c.contact_additional_field.twitter_account,c.contact_additional_field.others_1,
          c.contact_additional_field.others_2,c.contact_additional_field.others_3,
          c.contact_additional_field.others_4,c.contact_additional_field.others_5,
          c.contact_additional_field.others_6]
      end
    end
    # Below code is use to generate new csv file for error object which was unable to save in database.
    @csv_string = FasterCSV.generate do |csv|
      # Below code is use to create colum head for the generated csv.
      csv <<  ['','','*RequiredFields','','# Either Primary Email or Primary Phone required' ,'','','','','Data entered should be exactly in the format as in the Portal','','','','','','','','','','','','','','','','','','','','','','','','','','','','']
      csv <<  ['','Contact Details','','','','','','','','','','','','','','Business Contact Details','','','','','','','','','Personal Details','','','','','','Other','','','','','','','','','','']
      csv <<  ['Error Message(s)','Salutation','First Name *','Middle Name','Last Name','Primary Email #','Primary Phone #','Nick Name','Alternate Email','Source','Source Details','Assigned To','Contact Stage *','Company','Title','Street','City','State','Zip Code','Fax','Alternate Phone 1','Alternate Phone 2','Website','Comments','Street','City','State','Zip Code','Mobile','Fax','Skype Account','Linked In Account','Facebook Account','Twitter Account','Other1','Other2','Other3','Other4','Other5','Other6']
      j = 0
      @invalid_contacts.each do |c|
        csv << c
        j +=1
      end
    end
  end

  def self.campaign_member_csv_file(path_to_file,company,current_user,employee_user,campaign_id)
    @campaign = Campaign.find(campaign_id)
    @company = Company.find(company)
    company_id = @company.id
    @current_user = User.find(current_user)
    owner_employee_user = @campaign.owner_employee_user_id.blank? ? @current_user : Employee.find_by_user_id(@campaign.owner_employee_user_id)
    @invalid_members=[]
    @invalid_member_length= 0
    @valid_member_length= 0
    directory = "public/"
    filename="invalid_campaign_members_report_#{Time.now}.csv"
    path = File.join(directory,filename)
    #Here Fastercsv.foreach was not used cause the first 2 rows of the file were headers and only one row of header could be skipped
    #So in order to skip the first 2 rows of headers first file is opened then the first 2 rows are dropped.
    open_csv_file = FasterCSV.open(path_to_file)
    open_csv_file.drop(3).each do |row|
      # fetching salutation for the company
      unless self.utf8_value(row[0]).try(:capitalize).blank?
        salutation_str = self.utf8_value(row[0]).try(:capitalize)
        salutation = @company.salutation_types.find(:first,:conditions=>["lvalue ILIKE ? and company_id =?","%#{salutation_str}%",@company.id])
        salutation_id = salutation.present? ? salutation.id : 0
      end
      
      @campaign_member = CampaignMember.new(:campaign_id=>@campaign.id, :campaign_member_status_type_id=>@company.campaign_member_status_types.find_by_lvalue('New').id,:salutation_id => salutation_id,:first_name=>row[1], :last_name=> row[2], :nickname=>row[3],:email=> row[4], :alt_email => row[5], :phone=>row[6], :mobile=>row[7],:fax=>row[8],:website=>row[9],:title=>row[10], :company_id=> @campaign.company_id, :employee_user_id=> employee_user, :created_by_user_id=>current_user.id  )
      # added address details for it feature 6380 new requirement
      @campaign_member.build_address(:street => row[11], :city => row[12], :state => row[13] , :zipcode => row[14], :country => row[15],:company_id => company_id)
      if @campaign_member.valid?
        @campaign_member.save
        @valid_member_length += 1
      else
        @invalid_member_length += 1
        @invalid_members << @campaign_member
      end
    end
    File.delete(path_to_file)
    #Generate the file with invalid members
    begin
      FasterCSV.open(path, "wb") do |csv|
        csv <<  ['Error Message(s)','Salutation',        'First name',        'Last name',        'Nick name',        'Email',        'Alternate email',        'Phone',        'Mobile',        'Fax',        'Website',        'Title',        'Street',        'City',        'State',        'Zip code',        'Country','','']
        @invalid_members.each_with_index do |c,j|
          csv << [c.errors.full_messages.to_s,c.salutation_id,c.first_name,c.last_name,c.nickname,c.email,c.alt_email,c.phone,c.mobile,c.fax,c.website,c.title,'','']
        end
      end
      send_notification_for_invalid_contacts(path,@current_user,@invalid_member_length,@valid_member_length,owner_employee_user)
      File.delete("#{RAILS_ROOT}/public/#{filename}")
    rescue Exception=>ex
      puts ex.message
    end
  end

  def self.campaign_member_excel_file(path_to_file,company,current_user,employee_user,campaign_id)
    @campaign = Campaign.find(campaign_id)
    @company = Company.find(company)
    company_id = @company.id
    @current_user = User.find(current_user)
    owner_employee_user = @campaign.owner_employee_user_id.blank? ? @current_user : Employee.find_by_user_id(@campaign.owner_employee_user_id)
    @invalid_members = []
    @invalid_member_length = 0
    @valid_member_length = 0
    name = File.basename(path_to_file)
    path = path_to_file
    ext = File.extname(name).downcase
    if ext == ".xls"
      oo = Excel.new(path)
    elsif ext==".xlsx"
      oo = Excelx.new(path)
    elsif ext==".ods"
      oo = Openoffice.new(path)
    end
    oo.default_sheet = oo.sheets.first
    4.upto(oo.last_row) do |line|
      if oo.cell(line,'E').present?
        email=oo.cell(line,'E').to_s
      end
      zipcode = oo.cell(line,'O').present? ? oo.cell(line,'O') : ""
      
      phone_column_value = oo.cell(line,'G')
      phone = phone_column_value.present? && phone_column_value.to_s.length > 0 ? phone_column_value.to_s : ''

      mobile_column_value = oo.cell(line,'H')
      mobile = mobile_column_value.present? && mobile_column_value.to_s.length > 0 ? mobile_column_value.to_s : ''

      unless self.utf8_value(oo.cell(line,'A')).try(:capitalize).blank?
        salutation_str = self.utf8_value(oo.cell(line,'A')).try(:capitalize)
        salutation = @company.salutation_types.find(:first,:conditions=>["lvalue ILIKE ? and company_id =?","%#{salutation_str}%",@company.id])
        salutation_id = salutation.present? ? salutation.id : 0
      end
      
      @campaign_member = CampaignMember.new(:campaign_id=>@campaign.id, :campaign_member_status_type_id=>@company.campaign_member_status_types.find_by_lvalue('New').id,:salutation_id => salutation_id,:first_name=>oo.cell(line,'B').to_s, :last_name=> oo.cell(line,'C').to_s, :nickname=>oo.cell(line,'D'),:email=> email, :alt_email=>oo.cell(line,'F'), :phone=>phone.to_s, :mobile=>mobile.to_s,:fax=>oo.cell(line,'I').to_s,:website=>oo.cell(line,'J'),:title=>oo.cell(line,'K'), :company_id=> @campaign.company_id, :employee_user_id=> employee_user, :created_by_user_id=>current_user.id )
      # add address for it feature 6380 new requirement
      @campaign_member.build_address(:street => oo.cell(line,'L').to_s, :city =>oo.cell(line,'M').to_s, :state => oo.cell(line,'N').to_s , :zipcode => zipcode, :country => oo.cell(line,'P').to_s,:company_id => company_id)

      if @campaign_member.valid?
        @campaign_member.save
        @valid_member_length += 1
      else
        @invalid_member_length = @invalid_member_length+1
        @invalid_members << @campaign_member
      end
    end
    report = Spreadsheet::Workbook.new
    sheet = report.create_worksheet
    # setting the width of the columns and also some formatting
    format = Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre
    format1 = Spreadsheet::Format.new :horizontal_align=>:centre
    fmt = Spreadsheet::Format.new :text_wrap => true ,:shrink => true
    sheet.row(0).default_format = format
    12.times{ |x| sheet.column(x+1).width = 25}
    sheet.column(0).width = 85
    sheet.column(0).default_format = fmt
    (1..12).each{|c| sheet.column(c).default_format = format1}
    (1..50).each {|r| sheet.row(r).height = 80}
    sheet.row(0).concat  ['Error Message(s)','Salutation',        'First name',        'Last name',        'Nick name',        'Email',        'Alternate email',        'Phone',        'Mobile',        'Fax',        'Website',        'Title',        'Street',        'City',        'State',        'Zip code',        'Country''','']
    @invalid_members.each_with_index do |c,j|
      sheet.row(j+1).concat [c.errors.full_messages.to_s,c.salutation_id,c.first_name,c.last_name,c.nickname,c.email,c.alt_email,c.phone,c.mobile,c.fax,c.website,c.title,'','']
    end

    @xls_string_errors = StringIO.new ''
    report.write @xls_string_errors
    begin
      err_directory = "public/"
      err_filename="invalid_campaign_members_report_#{Time.now}.xls"
      err_path = File.join(err_directory,err_filename)
      File.open(err_path, "wb") { |f| f.write(@xls_string_errors.string) }
      send_notification_for_invalid_contacts(err_path,@current_user,@invalid_member_length,@valid_member_length,owner_employee_user)
      File.delete("#{RAILS_ROOT}/public/#{err_filename}")
      File.delete(path_to_file)
    rescue Exception=>ex
      #send notification for any failure
      puts ex.message
    end
  end
  
  def self.time_entry_process_excel_file(path_to_file,current_user_id,company_id,employee_user_id)
    company = Company.find(company_id)
    current_user = User.find(current_user_id)
    employee_user = Employee.find_by_user_id(employee_user_id)
    directory =  File.dirname(path_to_file)
    name = File.basename(path_to_file)
    path = path_to_file
    file = File.new(path_to_file, "r").read
    ext = (File.extname(name)).downcase
    if ext==".xls"
      object = Excel.new(path)
      object.default_sheet = object.sheets.first
    elsif ext==".xlsx"
      object = Excelx.new(path)
    elsif ext==".ods"
      object = Openoffice.new(path)
    end
    @parser = CSV::Reader.parse(file)
    object.default_sheet = object.sheets.first if ext != ('.csv')
    @company = company
    @current_user = current_user
    @e_f_n = []
    @e_l_n = []
    @matt = []
    @report = nil
    @sheet = nil
    @invalid_entries = []
    @invalid_length = 0
    @valid_length = 0
    if ext == ('.csv')
      @parser.each_with_index do |column,i|
        self.time_parsing_csv(column,i,employee_user_id)
      end
    else
      4.upto(object.last_row) do |line|
        self.time_entry_excel_parsing(object,line,employee_user_id)
      end
    end
    report = Spreadsheet::Workbook.new
    sheet = report.create_worksheet
    #    sheet.row(0).concat ['Date','Emp First Name','Emp Last Name','Matter Name','First Name','Middle Name','Last Name','Activity Type','Description','Start Time','End Time','Duration','Rate/Hr','Billable','Final Amount','Error Message']
    sheet.row(0).concat ['','*RequiredField','','','# Contact name must be there, if matter name present','','','','Data entered should be exactly in the format as in the Portal','','','','','','','']
    sheet.row(1).concat ['','mm/dd/yyyy','Employee Details','','Matter Details','Contact Details','','','','','','','','','(Yes/No)','']
    sheet.row(2).concat ['Error Message(s)','* Date','* Emp First Middle Last Name','Matter ID','Matter Name#','* First Name','Middle Name','Last Name','* Activity Type','* Description','* Duration','* Rate/Hr($)','Billable','Final Amount($)']
    # first define formats required , then set the column and rows width and height. also text wrap and shrink to fit the cells
    format = Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre ,:text_wrap => true
    format1 = Spreadsheet::Format.new :horizontal_align=>:centre ,:text_wrap => true , :shrink => true
    fmt = Spreadsheet::Format.new :text_wrap => true ,:shrink => true
    sheet.row(0).height = 50
    sheet.row(2).default_format = format
    16.times{ |x| sheet.column(x+1).width = 25}
    sheet.column(0).width = 80
    sheet.column(0).default_format = fmt
    (1..16).each{|c| sheet.column(c).default_format = format1}
    (3..50).each {|r| sheet.row(r).height = 80}
    @invalid_entries.each_with_index do |invalid, j|
      sheet.row(j + 3).concat invalid
    end
    @xls_string = StringIO.new ''
    report.write(@xls_string)
    begin
      err_directory = "public/"
      err_filename="invalid_time_entries_report_#{Time.now}.xls"
      err_path = File.join(err_directory,err_filename)
      File.open(err_path, "wb") { |f| f.write(@xls_string.string) }
      send_notification_for_invalid_entry(err_path,@current_user,@invalid_length,@valid_length,employee_user,'Time Entries')
      File.delete("#{RAILS_ROOT}/public/#{err_filename}")
      File.delete(path_to_file)
    rescue Exception=>ex
      #send notification for any failure
      puts ex.message
    end
  end

  def self.time_parsing_csv(column,i,verified_employee_user_id = nil)
    flag = 0; errmsg = [];matter_contact_name = false
    if i > 2
      matter = contact = matter_id = employee_id = activity_type_id = nil
      time_entry_date = Date.parse(self.utf8_value(column[0]).to_s) rescue nil
      emp_first_middle_last_name = self.utf8_value(column[1]).to_s
      matter_no = self.utf8_value(column[2]).to_s
      matter_name = self.utf8_value(column[3]).to_s
      contact_name = self.utf8_value(column[4]).to_s
      cont_middle_name = self.utf8_value(column[5]).to_s
      cont_last_name = self.utf8_value(column[6]).to_s
      activity_type = self.utf8_value(column[7]).to_s
      description = self.utf8_value(column[8]).to_s
      duration = self.utf8_value(column[9]).to_s
      rate = self.utf8_value(column[10]).to_s
      billable = self.utf8_value(column[11]).to_s.downcase
      final_amt = self.utf8_value(column[12])
      is_billable = (billable == 'yes') ? true : false
      if duration.blank?
        duration = 0
      end
      unless activity_type.blank?
        activity_type = @company.company_activity_types.first(:conditions => ["lvalue ilike ? OR alvalue ILike ? ",activity_type, activity_type])
        if(activity_type)
          activity_type_id = activity_type.id
        else
          errmsg << " Activity Type does not exist. "
        end
      else
        errmsg << " Activity Type can't be blank. "
      end
      time_entry_date = time_entry_date.to_date.strftime("%Y-%m-%d") unless time_entry_date.blank?
      unless emp_first_middle_last_name.blank?
        e_condition = "trim(first_name) || ' ' || trim(last_name)"
        employee_user = @company.employees.find(:first, :conditions => ["("+ e_condition +") ilike ?", emp_first_middle_last_name])
        if employee_user
          employee_id = employee_user.id
        else
          errmsg << " employee doesn't exist "
        end
      else
        errmsg << " employee Name can't be blank. "
      end
      is_matter_no_or_name_blank = false
      if(matter_no.blank?)
        is_matter_no_or_name_blank = true
        errmsg << " Matter ID not be blank "
      elsif(matter_name.blank?)
        is_matter_no_or_name_blank = true
        errmsg << " Matter Name not be blank "
      end
      unless matter_name.blank? && matter_no.blank?
        matter = @company.matters.first(:conditions => ['matter_no = ? and name ilike ?',matter_no,matter_name])
      end
      if matter
        matter_id = matter.id
      elsif(!is_matter_no_or_name_blank)
        errmsg << " Matter does not exist. "
      end
      unless(contact_name.blank?)
        condition = "trim(first_name)"
        unless cont_middle_name.blank?
          contact_name = contact_name + ' ' + cont_middle_name
          condition += " || ' ' || trim(middle_name)"
        end
        unless cont_last_name.blank?
          contact_name = contact_name + ' ' + cont_last_name
          condition += " || ' ' || trim(last_name)"
        end
      end
      if matter_id && !contact_name.blank?
        contact = @company.contacts.find(:first, :conditions => ["("+ condition +") ilike ? AND matters.id =? ", contact_name,matter.id],:joins =>"INNER JOIN matters ON matters.contact_id=contacts.id")
      end
      if contact
        @contact_id = contact.id
      end
      if !contact && matter_id
        errmsg << " Contact name does not exist / Invalid contact name for this matter. "
      elsif contact_name == ""
        errmsg << " Contact name is blank "
      end

      time_entries = {"employee_user_id" => employee_id, "created_by_user_id" => @current_user.id,
        "activity_type" => activity_type_id, "description" => description.to_s,
        "time_entry_date" => time_entry_date, 
        "actual_duration" => duration.to_f*60, "billing_method_type" => 1,
        "final_billed_amount" => final_amt, "contact_id" => @contact_id, "matter_id" => matter_id,
        "company_id" => @company.id, "status" => 'Open', "is_billable" => is_billable,
        "is_internal" => false, "actual_activity_rate" => rate, "activity_rate" => rate
      }
      new_entry = Physical::Timeandexpenses::TimeEntry.new(time_entries)

      if new_entry.valid? && errmsg.empty?
        @valid_length += 1
        new_entry.current_lawyer = User.find(verified_employee_user_id)
        new_entry.save
      else
        @invalid_entries <<  [(new_entry.errors.full_messages.to_s.gsub("Activity type can't be blank","Invalid Activity Type") + "\n" + errmsg.to_s),
          self.utf8_value(column[0]).to_s, self.utf8_value(column[1]).to_s, self.utf8_value(column[2]).to_s,
          self.utf8_value(column[3]).to_s, self.utf8_value(column[4]).to_s, self.utf8_value(column[5]).to_s,
          self.utf8_value(column[6]).to_s, self.utf8_value(column[7]).to_s, self.utf8_value(column[8]).to_s,
          self.utf8_value(column[9]).to_s, self.utf8_value(column[10]).to_s, self.utf8_value(column[11]).to_s,
          self.utf8_value(column[12]).to_s, self.utf8_value(column[13]).to_s ]
        @invalid_length = @invalid_length + 1
      end
    end
  end

  def self.time_entry_excel_parsing(object,line,verified_employee_user_id)
    errmsg = []; flag = 0; matter_contact_name = false
    time_entry_date = Date.parse(self.utf8_value(object.cell(line,'A')).to_s) rescue nil
    matter = contact = matter_id = activity_type_id = nil
    activity_type = self.utf8_value(object.cell(line,'H')).to_s.strip
    unless(activity_type.blank?)
      activity_type = @company.company_activity_types.find(:first, :conditions => ["lvalue ilike ? ",activity_type])
      activity_type_id = activity_type.id if activity_type
    end
    description = self.utf8_value(object.cell(line,'I')).to_s
    duration = (self.utf8_value(object.cell(line,'J'))).to_f.roundf2(2)
    rate = self.utf8_value(object.cell(line,'K'))
    billable = self.utf8_value(object.cell(line,'L')).to_s.downcase
    is_billable = (billable == 'yes') ? true : false
    final_amt = self.utf8_value(object.cell(line,'M'))
    if duration.blank?
      duration = 0
    end
    employee_name = self.utf8_value(object.cell(line,'B')).to_s.strip
    unless employee_name.blank?
      e_condition = "trim(first_name) || ' ' || trim(last_name)"
      employee_user = @company.employees.find(:first, :conditions => ["("+ e_condition +") ilike ?",employee_name])
      if employee_user == nil
        errmsg << " Employee doesn't exist "
      else
        employee_user_id = employee_user.user_id
      end
    else
      errmsg << " First name of employee can not be blank. "
    end
    matter_no = self.utf8_value(object.cell(line,'C')).to_s.strip
    matter_name = self.utf8_value(object.cell(line,'D')).to_s.strip
    is_matter_no_or_name_blank = false
    if(matter_no.blank?)
      is_matter_no_or_name_blank = true
      errmsg << " Matter ID not be blank "
    elsif(matter_name.blank?)
      is_matter_no_or_name_blank = true
      errmsg << " Matter Name not be blank "
    end
    unless matter_name.blank? && matter_no.blank?
      matter = @company.matters.first(:conditions => ['matter_no = ? and name ilike ?',matter_no,matter_name])
    end
    if matter
      matter_id = matter.id
    elsif(!is_matter_no_or_name_blank)
      errmsg << " Matter does not exist. "
    end
    contact_name = self.utf8_value(object.cell(line,'E')).to_s.strip
    unless(contact_name.blank?)
      condition = "trim(first_name)"
      middle_name = self.utf8_value(object.cell(line,'F')).to_s.strip
      unless middle_name.blank?
        contact_name = contact_name + ' ' + middle_name
        condition += " || ' ' || trim(middle_name)"
      end
      last_name = self.utf8_value(object.cell(line,'G')).to_s.strip
      unless last_name.blank?
        contact_name = contact_name + ' ' + last_name
        condition += " || ' ' || trim(last_name)"
      end
    end
    if matter_id && !contact_name.blank?
      contact = @company.contacts.find(:first, :conditions => ["("+ condition +") ilike ? AND matters.id =? ", contact_name,matter.id],:joins =>"INNER JOIN matters ON matters.contact_id=contacts.id")
    end
    if contact
      @contact_id = contact.id
    end
    if !contact && matter_id
      errmsg << " Contact name does not exist / Invalid contact name for this matter. "
    elsif contact_name == ""
      errmsg << " Contact name is blank "
    end
    
    if self.utf8_value(object.cell(line,'E')).present?
      contact = @company.contacts.find(:all, :conditions => ["("+ condition +") ilike ? ", contact_name])
    end
    if(time_entry_date.blank?)
      errmsg << " Date Invalid format"
    end

    time_entries = {"employee_user_id" => employee_user_id, "created_by_user_id" => @current_user.id,
      "activity_type" => activity_type_id, "description" => description.to_s,
      "time_entry_date" => time_entry_date,
      "actual_duration" => duration.to_f*60, "billing_method_type" => 1,
      "final_billed_amount" => final_amt, "contact_id" => @contact_id, "matter_id" => matter_id,
      "company_id" => @company.id, "status" => 'Open', "is_billable" => is_billable,
      "is_internal" => false, "actual_activity_rate" => rate, "activity_rate" => rate
    }

    new_entry = Physical::Timeandexpenses::TimeEntry.new(time_entries)

    if new_entry.valid? && errmsg.empty?
      new_entry.current_lawyer = User.find(verified_employee_user_id)
      #new_entry.send(:create_without_callbacks)
      new_entry.save
      @valid_length = @valid_length+1
    else
      @invalid_entries <<  [new_entry.errors.full_messages.to_s.gsub("Activity type can't be blank","Invalid Activity Type") + "\n" + errmsg.to_s,
        self.utf8_value(object.cell(line,'A')), self.utf8_value(object.cell(line,'B')), self.utf8_value(object.cell(line,'C')),
        self.utf8_value(object.cell(line,'D')), self.utf8_value(object.cell(line,'E')), self.utf8_value(object.cell(line,'F')),
        self.utf8_value(object.cell(line,'G')), self.utf8_value(object.cell(line,'H')), self.utf8_value(object.cell(line,'I')),
        self.utf8_value(object.cell(line,'J')), self.utf8_value(object.cell(line,'K')), self.utf8_value(object.cell(line,'L')),
        self.utf8_value(object.cell(line,'M'))]
      @invalid_length = @invalid_length + 1
    end
  end

  def self.expense_entry_process_file(path_to_file, current_user_id, company_id, employee_user_id)
    company = Company.find(company_id)
    current_user = User.find(current_user_id)
    employee_user = Employee.find_by_user_id(employee_user_id)
    name = File.basename(path_to_file)
    directory =  File.dirname(path_to_file)
    path = path_to_file
    file = File.new(path_to_file, "r").read
    
    ext = File.extname(name)
    @company = company
    @current_user = current_user
    @e_f_n = []
    @e_l_n = []
    @matt = []
    @report = nil
    @sheet = nil
    @invalid_entries = []
    @invalid_length = 0
    @valid_length = 0
    if ext == ".csv" || ext == ".CSV"
      @parser = CSV::Reader.parse(file)
      @parser.each_with_index do |column,i|
        self.expense_parsing_csv(column,i,employee_user_id)
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

      4.upto(object.last_row) do |line|
        self.expense_entry_excel_parsing(object,line,employee_user_id)
      end
    end

    report = Spreadsheet::Workbook.new
    sheet = report.create_worksheet
    #    sheet.row(0).concat ['Date','Emp First Name','Emp Last Name','Matter Name','First Name','Middle Name','Last Name','Expense Type','Description','Expense Amount','Billable','Final Amount','Error Message']
    sheet.row(0).concat ['','*RequiredField','','','# Contact name must be there, if matter name present','','','','Data entered should be exactly in the format as in the Portal','','','','']
    sheet.row(1).concat ['','mm/dd/yyyy','Employee Details','','Matter ID','Matter Details','Contact Details','','','','','','(Yes/No)','']
    sheet.row(2).concat ['Error Message(s)','* Date','* Emp First Middle Last Name','*Matter ID','*Matter Name','* First Name','Middle Name','Last Name','* Expense Type','* Description','* Expense Amt($)','Billable','Final Amount($)']
    # first define formats required , then set the column and rows width and height. also text wrap and shrink to fit the cells
    format = Spreadsheet::Format.new :color => :black, :weight=> :bold,  :size => 11 , :horizontal_align=>:centre ,:text_wrap => true
    format1 = Spreadsheet::Format.new :horizontal_align=>:centre ,:text_wrap => true , :shrink => true
    fmt = Spreadsheet::Format.new :text_wrap => true ,:shrink => true
    sheet.row(0).height = 50
    sheet.row(2).default_format = format
    13.times{ |x| sheet.column(x+1).width = 25}
    sheet.column(0).width = 80
    sheet.column(0).default_format = fmt
    (1..14).each{|c| sheet.column(c).default_format = format1}
    (3..50).each {|r| sheet.row(r).height = 80}
    @invalid_entries.each_with_index do |invalid, j|
      sheet.row(j + 3).concat invalid
    end
    @xls_string = StringIO.new ''
    report.write(@xls_string)
    begin
      err_directory = "public/"
      err_filename="invalid_expense_entries_report_#{Time.now}.xls"
      err_path = File.join(err_directory,err_filename)
      File.open(err_path, "wb") { |f| f.write(@xls_string.string) }
      send_notification_for_invalid_entry(err_path,@current_user,@invalid_length,@valid_length,employee_user,'Expense Entries')
      File.delete("#{RAILS_ROOT}/public/#{err_filename}")
      File.delete(path_to_file)
    rescue Exception=>ex
      #send notification for any failure
      puts ex.message
    end
  end

  def self.expense_entry_excel_parsing(object,line,verified_employee_user_id)
    flag = 0; errmsg= []; matter_contact_name = false
    matter = matter_id = contact_name = contact = nil
    expense_entry_date = self.utf8_value(object.cell(line,'A'))
    expense_entry_date = Date.parse(expense_entry_date) rescue nil
    expense_type = self.utf8_value(object.cell(line,'H')).to_s.strip
    expense_type = @company.expense_types.find(:first, :conditions => ["lvalue ilike ? ",expense_type])
    expense_type_id = !expense_type.blank? ? expense_type.id : nil
    description = self.utf8_value(object.cell(line,'I'))
    expense_amt = self.utf8_value(object.cell(line,'J'))
    final_amt =  self.utf8_value(object.cell(line,'L'))
    final_amt = expense_amt if(final_amt.blank?)
    if final_amt.blank?
      errmsg << " Expense Amount and Final Amount Both Are Blank. "
      flag = 1
    end
    billable = self.utf8_value(object.cell(line,'J')).to_s.downcase
    is_billable = billable == 'yes' ? true : false
    
    employee_present = true
    employee_name = self.utf8_value(object.cell(line,'B')).to_s.strip
    unless employee_name.blank?
      e_condition = "trim(first_name)  || ' ' || trim(last_name)"
    else
      flag = 1
      e_condition = '1'
      errmsg << " Employee name does not exist. "
    end

    unless employee_name.blank?
      employee_user = @company.employees.find(:first, :conditions => ["("+ e_condition +") ilike ?",employee_name]);
    end
    
    if employee_user.present?
      employee_user_id = employee_user.user_id
    else
      employee_present = false
    end

    matter_no = self.utf8_value(object.cell(line,'C')).to_s.strip
    matter_name = self.utf8_value(object.cell(line,'D')).to_s.strip
    is_matter_no_or_name_blank = false
    if(matter_no.blank?)
      is_matter_no_or_name_blank = true
      errmsg << " Matter ID not be blank "
    elsif(matter_name.blank?)
      is_matter_no_or_name_blank = true
      errmsg << " Matter Name not be blank "
    end
    unless matter_name.blank? && matter_no.blank?
      matter = @company.matters.first(:conditions => ['matter_no = ? and name ilike ?',matter_no,matter_name])
    end
    if matter
      matter_id = matter.id
    elsif(!is_matter_no_or_name_blank)
      errmsg << " Matter does not exist. "
    end
    contact_name = self.utf8_value(object.cell(line,'E')).to_s.strip
    unless(contact_name.blank?)
      condition = "trim(first_name)"
      middle_name = self.utf8_value(object.cell(line,'F')).to_s.strip
      unless middle_name.blank?
        contact_name = contact_name + ' ' + middle_name
        condition += " || ' ' || trim(middle_name)"
      end
      last_name = self.utf8_value(object.cell(line,'G')).to_s.strip
      unless last_name.blank?
        contact_name = contact_name + ' ' + last_name
        condition += " || ' ' || trim(last_name)"
      end
    end
    if matter_id && !contact_name.blank?
      contact = @company.contacts.find(:first, :conditions => ["("+ condition +") ilike ? AND matters.id =? ", contact_name,matter.id],:joins =>"INNER JOIN matters ON matters.contact_id=contacts.id")
    end
    if contact
      @contact_id = contact.id
    end
    if !contact && matter_id
      errmsg << " Contact name does not exist / Invalid contact name for this matter. "
    elsif contact_name == ""
      errmsg << " Contact name is blank "
    end


    expense_entries = {"employee_user_id" => employee_user_id, "created_by_user_id" => @current_user.id,
      "expense_type" => expense_type_id, "description" => description.to_s,
      "expense_entry_date" => expense_entry_date, "billing_method_type" => 1,
      "expense_amount" => expense_amt, "final_expense_amount" => final_amt,
      "contact_id" => @contact_id, "matter_id" => matter_id,
      "company_id" => @company.id, "status" => 'Open', "is_billable" => is_billable,
      "is_internal" => false
    }

    new_entry = Physical::Timeandexpenses::ExpenseEntry.new(expense_entries)

    if(new_entry.valid? && employee_present && flag == 0 && errmsg.empty?)
      new_entry.current_lawyer = User.find(verified_employee_user_id)
      new_entry.save

      @valid_length = @valid_length+1
    else
      new_entry.errors.add(' ', 'Employee Detail Is Not Valid') unless employee_present
      @invalid_entries <<  [(new_entry.errors.full_messages.to_s.gsub("Expense type can't be blank","Invalid Expense Type") + "\n"+ errmsg.to_s),
        self.utf8_value(object.cell(line,'A')).to_s, self.utf8_value(object.cell(line,'B')).to_s, self.utf8_value(object.cell(line,'C')).to_s,
        self.utf8_value(object.cell(line,'D')).to_s, self.utf8_value(object.cell(line,'E')).to_s, self.utf8_value(object.cell(line,'F')).to_s,
        self.utf8_value(object.cell(line,'G')).to_s, self.utf8_value(object.cell(line,'H')).to_s, self.utf8_value(object.cell(line,'I')).to_s,
        self.utf8_value(object.cell(line,'J')).to_s, self.utf8_value(object.cell(line,'K')).to_s,self.utf8_value(object.cell(line,'L')).to_s]
      @invalid_length = @invalid_length + 1
    end


  end

  def self.expense_parsing_csv(column,i,verified_employee_user_id)
    flag = 0; errmsg = []; matter_contact_name = false
    matter = matter_id = contact_name = contact = nil
    if(i > 2)
      if self.utf8_value(column[0]).present?
        expense_entry_date = self.utf8_value(column[0]).to_s
        expense_entry_date = Date.parse(expense_entry_date)
      end
      if self.utf8_value(column[7]).present?
        expense_type = self.utf8_value(column[7])
        expense_type = @company.expense_types.find(:first, :conditions => ["lvalue ilike ? ",expense_type])
        expense_type_id = expense_type.present? ? expense_type.id : nil
      else
        expense_type_id = nil
      end

      if self.utf8_value(column[8]).present?
        description = self.utf8_value(column[8])
      end
      if self.utf8_value(column[9]).present?
        expense_amt = self.utf8_value(column[9])
        if (self.utf8_value(column[11]).present?)
          final_amt = self.utf8_value(column[11])
        else
          final_amt = expense_amt
        end
      else
        if self.utf8_value(column[11]).present?
          final_amt = self.utf8_value(column[11])
        else
          errmsg << " Expense Amount and Final Amount Both Are Blank"
          flag = 1
        end
      end

      if self.utf8_value(column[10]).present?
        billable = self.utf8_value(column[10])
        if billable.eql?('Yes')
          is_billable = true
        else
          is_billable = false
        end
      else
        is_billable = false
      end


      #      if column[11].present?
      #        final_amt = column[11]
      #      end
      employee_present = true
      if self.utf8_value(column[1]).present?
        employee_name = self.utf8_value(column[1]).to_s.strip
        e_condition = "trim(first_name) || ' ' || trim(last_name)"
        if employee_name.blank?
          flag = 1
          errmsg << " Last name does not exist. "
        end
      end

      if self.utf8_value(column[1])
        employee_user = @company.employees.find(:first, :conditions => ["("+ e_condition +") ilike ?",employee_name]);
      end

      if employee_user.present?
        employee_user_id = employee_user.user_id
      else
        employee_present = false
      end
      matter_no =  self.utf8_value(column[2]).to_s.strip
      matter_name =  self.utf8_value(column[3]).to_s.strip
      is_matter_no_or_name_blank = false
      if(matter_no.blank?)
        is_matter_no_or_name_blank = true
        errmsg << " Matter ID not be blank. "
      elsif(matter_name.blank?)
        is_matter_no_or_name_blank = true
        errmsg << " Matter Name not be blank. "
      end
      unless matter_name.blank? && matter_no.blank?
        matter = @company.matters.first(:conditions => ['matter_no = ? and name ilike ?',matter_no,matter_name])
      end
      if matter
        matter_id = matter.id
      elsif(!is_matter_no_or_name_blank)
        errmsg << " Matter does not exist. "
      end

      contact_name = self.utf8_value(column[4]).to_s.strip
      unless(contact_name.blank?)
        condition = "trim(first_name)"
        middle_name = self.utf8_value(column[5]).to_s.strip
        unless middle_name.blank?
          contact_name = contact_name + ' ' + middle_name
          condition += " || ' ' || trim(middle_name)"
        end
        last_name = self.utf8_value(column[6]).to_s.strip
        unless last_name.blank?
          contact_name = contact_name + ' ' + last_name
          condition += " || ' ' || trim(last_name)"
        end
      end
      if matter_id && !contact_name.blank?
        contact = @company.contacts.find(:first, :conditions => ["("+ condition +") ilike ? AND matters.id =? ", contact_name,matter.id],:joins =>"INNER JOIN matters ON matters.contact_id=contacts.id")
      end
      if contact
        @contact_id = contact.id
      end
      if !contact && matter_id
        errmsg << " Contact name does not exist / Invalid contact name for this matter. "
      elsif contact_name == ""
        errmsg << " Contact name is blank "
      end

      expense_entries = {"employee_user_id" => employee_user_id, "created_by_user_id" => @current_user.id,
        "expense_type" => expense_type_id, "description" => description.to_s,
        "expense_entry_date" => expense_entry_date, "billing_method_type" => 1,
        "expense_amount" => expense_amt, "final_expense_amount" => final_amt,
        "contact_id" => @contact_id, "matter_id" => matter_id,
        "company_id" => @company.id, "status" => 'Open', "is_billable" => is_billable,
        "is_internal" => false
      }

      new_entry = Physical::Timeandexpenses::ExpenseEntry.new(expense_entries)
      if(new_entry.valid? && employee_present && flag == 0 && errmsg.empty?)
        #new_entry.send(:create_without_callbacks)
        new_entry.current_lawyer = User.find(verified_employee_user_id)
        new_entry.save
        @valid_length = @valid_length + 1
      else

        new_entry.errors.add(' ', 'Employee Detail Is Not Valid') unless employee_present
        @invalid_entries <<  [(new_entry.errors.full_messages.to_s.gsub("Expense type can't be blank","Invalid Expense Type")+"\n" + errmsg.to_s),
          self.utf8_value(column[0]).to_s, self.utf8_value(column[1]).to_s, self.utf8_value(column[2]).to_s,
          self.utf8_value(column[3]).to_s, self.utf8_value(column[4]).to_s, self.utf8_value(column[5]).to_s,
          self.utf8_value(column[6]).to_s, self.utf8_value(column[7]).to_s, self.utf8_value(column[8]).to_s,
          self.utf8_value(column[9]).to_s, self.utf8_value(column[10]).to_s,self.utf8_value(column[11]).to_s]
        @invalid_length = @invalid_length + 1
      end
    end
  end

  def self.utf8_value(val)
    !val.blank? ? Iconv.conv("UTF-8//IGNORE", "US-ASCII", val.to_s.strip.gsub("'","`")) : nil
  end

  def self.tasks_excel_parsing(oo,line)
    unless self.utf8_value(oo.cell(line,'A')).blank?
      task_name = self.utf8_value(oo.cell(line,'A')).try(:capitalize)
    end
    if (self.utf8_value(oo.cell(line,'B'))!=nil && ["Normal","Urgent"].include?(self.utf8_value(oo.cell(line,'B')).capitalize))
      task_priority = self.utf8_value(oo.cell(line,'B')).capitalize.eql?('Normal') ? '1' : '2'
    end
    unless self.utf8_value(oo.cell(line,'C')).blank?
      due_date = self.utf8_value(oo.cell(line,'C'))
      task_due_date = DateTime.parse(due_date).strftime("%d-%m-%Y %H:%M:%S")
    end
    unless self.utf8_value(oo.cell(line,'D')).blank?
      work_sub_type_name  =  self.utf8_value(oo.cell(line,'D'))
      work_sub_type = WorkSubtype.find(:first,:conditions =>['name ilike ?',work_sub_type_name])
      task_work_sub_type_id = work_sub_type.id unless work_sub_type.blank?
    end
    unless self.utf8_value(oo.cell(line,'E')).blank?
      task_share_with_client = self.utf8_value(oo.cell(line,'E')).capitalize.eql?('Yes') ? true : false
    end
    unless self.utf8_value(oo.cell(line,'F')).blank?
      uname = "#{self.utf8_value(oo.cell(line,'F')).strip}"
      employee_details = Employee.find(:first, :conditions =>["trim(first_name) ilike ? or trim(last_name) ilike ? ", uname,uname])
      task_assigned_by_employee_id = employee_details.user_id unless employee_details.blank?
      task_company_id = employee_details.company.id unless employee_details.blank?
    end
    unless self.utf8_value(oo.cell(line,'G')).blank?
      uname  =  "#{self.utf8_value(oo.cell(line,'G')).strip}"
      user =  User.find(:first, :conditions =>["trim(first_name) ilike ? or trim(last_name) ilike ?", uname,uname])
      task_assign_by_user_id = user.id unless user.blank?
    end
    unless self.utf8_value(oo.cell(line,'H')).blank?
      uname  =  "#{self.utf8_value(oo.cell(line,'H')).strip}"
      user =  User.find(:first, :conditions =>["trim(first_name) ilike ? or trim(last_name) ilike ?", uname,uname])
      task_assign_to_user_id = user.id unless user.blank?
    end
    unless self.utf8_value(oo.cell(line,'I')).blank?
      uname  =  "#{self.utf8_value(oo.cell(line,'I')).strip}"
      user =  User.find(:first, :conditions =>["trim(first_name) ilike ? or trim(last_name) ilike ?", uname,uname])
      task_create_by_user_id = user.id unless user.blank?
    end
    unless self.utf8_value(oo.cell(line,'J')).blank? && work_sub_type.blank?
      complexity_level  =  self.utf8_value(oo.cell(line,'J')).to_i
      task_complexity = work_sub_type.work_subtype_complexities.find(:first,:conditions =>['complexity_level = ?',complexity_level])
    end
    
    #-----------Creating Hash for tasks---------------------

    task_details ={"name"=>task_name,
      "priority"=>task_priority,
      "due_at"=> task_due_date,
      "company_id"=>task_company_id,
      "created_by_user_id"=> task_create_by_user_id ,
      "assigned_by_employee_user_id"=>task_assigned_by_employee_id,
      "assigned_by_user_id"=>task_assign_by_user_id,
      "assigned_to_user_id"=>task_assign_to_user_id,
      "share_with_client"=>task_share_with_client,
      "work_subtype_id"=>task_work_sub_type_id,
      "work_subtype_complexity_id" => task_complexity,
      "time_zone" => Time.zone.name,
      "note_id"=>nil
    }
    # Create new task Object
    note_details = {"description"=>task_name,
      "note_priority"=>task_priority,
      "company_id"=>task_company_id,
      "created_by_user_id"=> task_create_by_user_id ,
      "assigned_by_employee_user_id"=>task_assigned_by_employee_id,
      "assigned_to_user_id"=>task_assign_to_user_id,
      "status" => 'Complete'
    }
    note_obj = Communication.new(note_details)
    task_obj = UserTask.new(task_details)
    #--- Creating hash finished ------------------
    if note_obj.valid? && task_obj.valid?
      note_obj.save
      note_obj.user_tasks.create(task_details)
      save_task += 1
    else
      errors = "Data is not proper and complete on row n. #{task_obj.errors.full_messages.to_s}"
    end
  end

  def self.task_entry_process_file(path_to_file, current_user_id)
    total_task = 0
    @save_task =0
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

      3.upto(object.last_row) do |line|
        total_task += 1
        self.tasks_excel_parsing(object,line)
      end
    end

    [total_task,@save_task]
  end

end
