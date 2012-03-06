class Department < ActiveRecord::Base
  belongs_to :company
  has_many :users
  has_many :employees
  acts_as_tree :order=>"name"
  acts_as_paranoid
  named_scope :company_id, lambda { |company_id|{ :conditions=>["company_id IN (?) ",company_id] }  }
  named_scope :sub_departments, lambda { |company_id|{ :conditions=>["parent_id IS NULL AND company_id=?",company_id] }  }
  named_scope :sub_departments_id, lambda { |department_id,departmentcompany_id|{ :conditions=>["parent_id IS NULL AND id NOT IN(?) AND company_id=?",department_id,departmentcompany_id] }  }

  validates_presence_of :name
  validates_presence_of :location
  validates_presence_of :company_id

  def self.get_department_data_chart(company_id)
    @orgdata = []
    @empdata = []
    @depempdata = []
    @orgempdata = []
    @company = Company.find(company_id)
    @company.name = @company.name.split(" ").blank?? @company.name.try(:capitalize) : @company.name.split(" ").each{|word| word.capitalize!}.join(" ")
    companydisp = "{v:'#{@company.id}_#{@company.name}', f:'<div style=background-color:#FFFFFF;min-width:80px;min-height:40px;><font face=verdana color=red><b>#{@company.name}</b></font></div>'}"
    @compdata = [companydisp, '', 'Law Firm']
    @orgdata << @compdata
    department = Department.scoped_by_company_id(company_id)
    employees = Employee.scoped_by_company_id(company_id)

    #---------Organization Code------------------------------
    department.each do |dep|
      dep.name = dep.name.split(" ").blank?? dep.name.try(:capitalize) : dep.name.split(" ").each{|word| word.capitalize!}.join(" ")
      dep.location = dep.location.split(" ").blank?? dep.location.try(:capitalize) : dep.location.split(" ").each{|word| word.capitalize!}.join(" ") unless dep.location.blank?
      dep_name = "{v:'#{dep.id}_#{dep.name}', f:'<div style=background-color:#6BA3CE;text-color:blue;min-width:80px;min-height:40px; font-style:italic><font color=purple face=verdana><b>#{dep.name}</b></font><br/>#{dep.location}</div>'}"
      if dep.parent_id
        parent_dep = find(dep.parent_id) rescue nil        
        @orgdata << [dep_name, "#{parent_dep.id}_#{parent_dep.name}", "Department"] unless parent_dep.nil?
        @orgdata << [dep_name, "#{@company.id}_#{@company.name}", "Department"] if parent_dep.nil?
      else
        @orgdata << [dep_name, "#{@company.id}_#{@company.name}", "Department"]
      end
      orgemp = Employee.find_all_by_company_id_and_department_id(company_id, dep.id)
      orgemp.each do |oemp|
        oemp.first_name = oemp.first_name.split(" ").blank?? oemp.first_name.try(:capitalize) : oemp.first_name.split(" ").each{|word| word.capitalize!}.join(" ")
        oemp_name = "{v:'#{oemp.id}', f:'<div style=background-color:yellow;text-color:blue;width:auto;min-width:80px;min-height:40px; font-style:italic><font color=blue face=verdana><b>#{oemp.first_name}</b></font><br/>#{CompanyLookup.get_employee_designation(oemp.designation_id) rescue '-'}</div>'}"
        @depempdata << [oemp_name, "#{dep.id}_#{dep.name}", 'Employee']
      end
      @orgempdata = @orgdata + @depempdata
    end
    #----------Organization Ends------------------------------

    #----------Employee Code----------------------------------
    employees.each do |emp|
      emp_name = emp.first_name.split(" ").blank?? emp.first_name.try(:capitalize) : emp.first_name.split(" ").each{|word| word.capitalize!}.join(" ")
      format_emp = "{v:'#{emp.id}_#{emp_name}', f:'<div style=background-color:yellow;text-color:blue;width:auto;min-width:80px;min-height:40px;font-style:italic><font color=blue face=verdana><b>#{emp_name}</b></font><br/>#{CompanyLookup.get_employee_designation(emp.designation_id) rescue '-'}</div>'}"
      if emp.parent_id
        parent_emp = Employee.find(emp.parent_id) rescue nil
        @empdata << [format_emp, "#{parent_emp.id}_#{parent_emp.first_name}", 'Employee'] unless parent_emp.nil?
        @empdata << [format_emp, "#{@company.id}_#{@company.name}", 'Employee'] if parent_emp.nil?
      else
        @empdata << [format_emp, "#{@company.id}_#{@company.name}", 'Employee']
      end
    end
    @empdata << @compdata
    
    [@company, @orgdata, @orgempdata, @empdata]
  end



  def deptname_with_location
    if self.location.present?
      "#{self.name} (#{self.location})"
    else
      "#{self.name}"
    end
  end

  # return all the parent department ids in array
  DEPT = []
  def self.find_parents(id)      
    obj = Department.find(id)
    DEPT << obj.id
    if obj.parent_id
      find_parents(obj.parent_id)
    else
      DEPT
    end
  end
end

# == Schema Information
#
# Table name: departments
#
#  id         :integer         not null, primary key
#  parent_id  :integer
#  name       :string(255)     not null
#  location   :string(255)
#  company_id :integer         not null
#  deleted_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

