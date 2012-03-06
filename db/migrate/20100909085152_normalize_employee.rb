class NormalizeEmployee < ActiveRecord::Migration
  def self.up

    add_column(:employees,:designation_id,:integer)
    # retrive employees who has designations
    @employees = Employee.all(:conditions => "designation is not null")
    @employees.each do |employee|
      designation = Designation.find_by_company_id_and_lvalue(employee.company_id,employee.designation)
      # replace designation with designation id from company_lookup
      employee.designation_id = designation.id
      employee.save(false)
    end
    
    # remove unused columns
    remove_column(:employees,:designation)
    remove_column(:employees,:deleted)
    remove_column(:employees,:security_question)
    remove_column(:employees,:security_answer)

  end

  def self.down
    
    add_column(:employees,:designation,:string)
    
    # retrive employees who has designation_id
    @employees = Employee.all(:conditions => "designation_id is not null")
    @employees.each do |employee|
      designation = Designation.find(employee.designation_id)
      # replace designation_id with designation lvalue from company_lookup
      employee.designation = designation.lvalue
      employee.save(false)
    end
    
    remove_column(:employees,:designation_id)
    # add removed columns
    add_column(:employees,:deleted,:boolean)
    add_column(:employees,:security_question,:text)
    add_column(:employees,:security_answer,:string)    
  end
end
