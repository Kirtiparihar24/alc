module DepartmentsHelper

def get_employee_with_no_parent(department)
  Employee.find(:all,:conditions=>["parent_id IS NULL AND department_id=?", department.id]).map{|r|[r.first_name + ' ' + r.last_name]}.join(", ")
end

end
