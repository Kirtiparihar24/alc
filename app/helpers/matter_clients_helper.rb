module MatterClientsHelper

  # Below code get terms of engagement of the matter.
  def terms_of_engagement(matter)    
    @document_homes=DocumentHome.find(:first,:conditions=>["mapable_type = ? and mapable_id = ? and sub_type =?",'Matter',matter.id,'Termcondition'], :order =>'created_at desc')
  end

  # Below code get all the lawyer details.
  def get_lawyer_info(matter)
    @lawyer = User.find(matter.employee_user_id)
  end

  # Below code will display the status Open,Overdue,Upcoming,Closed. Depanding for the following coditions.
  def matter_alert_count(matters, matter_task_status)
    number=0
    unless matters.class.to_s=='Matter'
      case matter_task_status
      when 'Open'
        matters.each do |matter|
          number += matter.client_tasks_open.size
        end
      when 'Overdue'
        matters.each do |matter|
          number += matter.client_tasks_overdue.size
        end
      when 'Upcoming'
        matters.each do |matter|
          number += matter.client_tasks_upcoming.size
        end
      end
    else
      case matter_task_status
      when 'Open'
        number = matters.client_tasks_open.size
      when 'Overdue'
        number +=matters.client_tasks_overdue.size
      when 'Upcoming'
        number += matters.client_tasks_upcoming.size
      end
    end
    return number.to_i
  end

  # Below helper show task status matter [Open | Overdue | Upcoming | Closed]
  def matter_task_status(matter_task)
    case    
    when  matter_task.upcoming?
      return 'Upcoming'
    when matter_task.overdue?
      return 'Overdue'
    when matter_task.open?
      return 'Open'
    when matter_task.completed
      return 'Closed'
    end
  end

  # Below helper get the matter document type.
  def matter_document_type(matter_document)
    unless matter_document.data_file_name.nil?
      matter_document.data_file_name.split('.').last.nil?? "-" : matter_document.data_file_name.split('.').last.try(:capitalize)
    end
  end

  #surekha currency foramt added
  def get_total_payment(payments)
    amount=0
    payments.each do |payment|
      amount+=payment.amount
    end
    return number_with_lformat(amount)
  end

  def get_total_billing(billings)
    amount=0
    billings.each do |billings|
      amount+=billings.bill_amount
    end
    return number_with_lformat(amount)
  end
  
end
