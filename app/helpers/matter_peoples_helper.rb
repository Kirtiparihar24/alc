module MatterPeoplesHelper

  # Find employee from the given matter people id.
  def employee_from_matter_people_id(mpid)
    User.find(MatterPeople.find_with_deleted(mpid).employee_user_id)
  end

  # Find employee user id from the given matter people id.
  def employee_id_from_matter_people_id(mpid)
    e = MatterPeople.find(mpid)
    e.employee_user_id
  end
  
end
