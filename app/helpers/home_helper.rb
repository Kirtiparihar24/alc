module HomeHelper

  def get_user_name_or_text_field
    unless current_user.nil?
      current_user.full_name
    else
      text_field_tag 'ticket[email]'
    end
  end

  def get_status_name(statuses,id)
    name=nil
    statuses.each{|s| name=s['name'] if s['id'] ==id }

    case name
    when 'New'

      'New'
    when  'Closed'
      name
    else
      'Work In Progress'
    end
  end
end
