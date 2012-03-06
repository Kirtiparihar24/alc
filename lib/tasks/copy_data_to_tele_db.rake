namespace :copy_data_to_tele_db do
  task :copy_data => :environment do

    #Retrive data from livia db
    employees=Employee.find(:all,:with_deleted=>true)
    roles=Role.find(:all)
    users=User.find(:all,:with_deleted=>true)
    service_providers = ServiceProvider.find(:all,:with_deleted=>true)
    user_roles=UserRole.find(:all)
    #emp_mappings=Physical::Liviaservices::ServiceProviderEmployeeMappings.find :all
    emp_mappings=Physical::Liviaservices::ServiceProviderEmployeeMappings.find(:all,:with_deleted=>true,:joins => "INNER JOIN employees ON service_provider_employee_mappings.employee_user_id=employees.user_id",:select => "service_provider_employee_mappings.*, employees.id AS EmployeeID")
    #Form connection to another db
    ActiveRecord::Base.establish_connection(:sqlserver)
    database =  ActiveRecord::Base.connection

    #TRUNCATE tables
    database.execute("truncate table Employees")
    database.execute("truncate table Users")
    database.execute("truncate table Role")
    database.execute("truncate table Roles")
    database.execute("truncate table ServiceProviders")
    database.execute("truncate table ServiceProviderEmployeeMappings")


    #Copy data into tables
    #Copy data from Roles table to Role table
    roles.each do |r|
      rr=Role.new
      rr.Name=r.name
      rr.ID=r.id
      rr.save false
    end
    puts "Roles table copied successfully!!!"

    #Copy data from users table to Users table
    users.each do |ur|
      values=[ur.id,ur.first_name,ur.last_name,ur.username,ur.encrypted_password,1].map { |value| database.quote(value) }.join(",")
      column_names=['ID','FirstName','LastName','UserName','Password','Priority'].map { |name| database.quote_column_name(name) }.join(",")
      database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:Users, column_names, values])
    end

    puts "Users table copied successfully!!!"

    #Copy data from user_roles table to Roles table
    user_roles.each do |ur|
      values=[ur.id,ur.user_id,ur.role_id].map { |value| database.quote(value) }.join(",")
      column_names=['ID','UserID','RoleID'].map { |name| database.quote_column_name(name) }.join(",")
      database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:Role, column_names, values])
    end
    puts "UserRoles table copied successfully!!!"

    #Employees to Employees
    employees.each do |e|
#      emp=Employee.new
#      emp.ID=e.id
#      emp.CreatedAt=e.created_at
#      emp.UpdatedAt=e.updated_at
#      emp.Birthdate = e.birthdate
#      emp.Description = e.description
#      emp.UsersID = e.user_id
#      emp.BillingRate = e.billing_rate
#      emp.RoleID = e.role_id
#      emp.CompanyID = e.company_id
#      emp.DeletedAt = e.deleted_at
#      emp.PermanentDeletedAt =e.permanent_deleted_at
#      emp.CreatedByUserID = e.created_by_user_id
#      emp.FirstName = e.first_name
#      emp.LastName = e.last_name
#      emp.Email =e.email
#      emp.Phone = e.phone
#      emp.Mobile = e.mobile
#      emp.RegisteredNumber= e.registered_number1
#      emp.ParentID= e.parent_id
#      emp.DepartmentID= e.department_id
#      emp.DesignationID= e.designation_id
#      emp.AccessCode= e.access_code
#      emp.save false

        column_names=['ID','CreatedAt','UpdatedAt','Birthdate','Description','UsersID','BillingRate','RoleID',
                       'CompanyID','DeletedAt','PermanentDeletedAt','CreatedByUserID', 'FirstName','LastName',
                       'Email','Phone','Mobile','RegisteredNumber','ParentID','DepartmentID','DesignationID',
                       'AccessCode'].map { |name| database.quote_column_name(name) }.join(",")
        dd = e.deleted_at.to_datetime unless e.deleted_at.nil?
        cd = e.created_at.to_datetime unless e.created_at.nil?
        ud = e.updated_at.to_datetime unless e.updated_at.nil?
        pd = e.permanent_deleted_at.to_datetime unless e.permanent_deleted_at.nil?
        bd = e.birthdate.to_datetime unless e.birthdate.nil?

        values = [e.id,cd,ud,bd,e.description,e.user_id,e.billing_rate,e.role_id,e.company_id,
                  dd,pd,e.created_by_user_id,e.first_name,e.last_name,e.email,e.phone,e.mobile,
                  e.registered_number1,e.parent_id,e.department_id,e.designation_id,
                  e.access_code].map { |value| database.quote(value) }.join(",")
        database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:Employees, column_names, values])
    end
    puts "Employees table copied successfully!!!"

    #Service Providers Table copy
    service_providers.each do |sp|
      #column_names=attrs.keys.map { |name| database.quote_column_name(name) }.join(",")
      bd = sp.birthdate.to_datetime unless sp.birthdate.nil?
      cd = sp.created_at.to_datetime unless sp.created_at.nil?
      ud = sp.updated_at.to_datetime unless sp.updated_at.nil?
      dd = sp.deleted_at.to_datetime unless sp.deleted_at.nil?
      deleted = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(sp.deleted)
      values=[sp.id,cd,ud,deleted,bd,sp.description,sp.user_id,sp.company_id,dd,sp.created_by_user_id].map { |value| database.quote(value) }.join(",")
      column_names=['ID','CreatedAt','UpdatedAt','Deleted','Birthdate','Description','UserID','CompanyID','DeletedAt','CreatedByUserID'].map { |name| database.quote_column_name(name) }.join(",")
      database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:ServiceProviders, column_names, values])
    end
    puts "ServiceProviders table copied successfully!!!"

    emp_mappings.each do |m|
      ID = m.id
      ServiceProvidersID = m.service_provider_id
      EmployeeUserID = m.employee_user_id
      Status = m.status
      Priority = m.priority
      dd = m.deleted_at.to_datetime unless m.deleted_at.nil? 
      cd = m.created_at.to_datetime unless m.created_at.nil?
      ud = m.updated_at.to_datetime unless m.updated_at.nil?
      pd = m.permanent_deleted_at.to_datetime unless m.permanent_deleted_at.nil?
      CreatedByUserID = m.created_by_user_id
      EmployeeID= m.employeeid
      values= [ID,ServiceProvidersID,EmployeeUserID,Status,Priority,dd,cd,ud,pd,CreatedByUserID].map { |value| database.quote(value) }.join(",")
      column_names=['ID','ServiceProvidersID','EmployeeUserID','Status','Priority','DeletedAt','CreatedAt','UpdatedAt','PermanentDeletedAt','CreatedByUserID'].map { |name| database.quote_column_name(name) }.join(",")
      database.execute("INSERT INTO %s(%s) VALUES (%s);" % [:ServiceProviderEmployeeMappings, column_names, values])
    end
    puts "ServiceProviderEmployeeMappings table copied successfully!!!"
  end
end