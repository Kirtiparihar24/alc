class MailNotificationObserver < ActiveRecord::Observer
  include GeneralFunction
  observe "Physical::Timeandexpenses::TimeEntry".constantize, "Physical::Timeandexpenses::ExpenseEntry".constantize

  
  def after_create(record)
       current_user=User.find_by_id(record.created_by_user_id.to_i)
       current_lawyer = current_user.current_lawyer || record.current_lawyer
      
    if current_lawyer && current_lawyer.id!= record.performer.id.to_i
        LiviaMailConfig::email_settings(record.company_id)
        mail = Mail.new()
        mail.from = get_from_email_for_notification_alerts
        if record.matter.nil? && record.contact.nil?
          sub = ''
          msg = ''
        elsif record.matter.nil?
          sub = "#{record.contact.try(:full_name)}'s"
          msg = "Contact: #{sub}'s"
        else
          sub = "#{record.matter.name}'s"
          msg = "Matter: #{record.matter.name}'s <br/> Contact: #{record.contact.try(:full_name)}'s"
        end
         if  record.class.name.eql?('Physical::Timeandexpenses::TimeEntry')
           actual_duration = record.company.duration_setting.setting_value == "1/100th" ?  one_hundredth_timediffernce(record.actual_duration) : one_tenth_timediffernce(record.actual_duration)
            mail.subject = "#{sub} New time entry is created."
            str = "Hi #{record.performer.first_name} #{record.performer.last_name},"
            str +="<br/> #{current_lawyer.first_name} #{current_lawyer.last_name} has made a Time entry for you with the following details:<br/>"
            str +="#{msg}"
            str +="Date:#{record.time_entry_date}<br/>"
            str +="Activity:#{record.company.company_activity_types.find(record.activity_type).alvalue}<br/>"
            str +="Duration(hrs):#{actual_duration}<br/>"
            str +="Billable:#{record.is_billable ? 'Yes': 'No'}<br/>"
            str +="Amount:#{decimal_rounding(record.final_billed_amount)}<br/><br/>"
            str +="Regards,<br/>"
            str +="LIVIA Admin"
            mail.body = str
            mail.content_type= 'text/html; charset=UTF-8'
            mail.to = record.performer.email
            mail.deliver
         elsif record.class.name.eql?('Physical::Timeandexpenses::ExpenseEntry')
            mail.subject = "#{sub} New expense entry is created."
            str = "Hi #{record.performer.first_name} #{record.performer.last_name},"
            str +="<br/> #{current_lawyer.first_name} #{current_lawyer.last_name} has made a Expense entry for you with the following details:<br/>"
            str +="#{msg}"
            str +="Date:#{record.expense_entry_date}<br/>"
            str +="Expense Type:#{record.company.expense_types.find(record.expense_type).alvalue}<br/>"
            str +="Billable:#{record.is_billable ? 'Yes': 'No'}<br/>"
            str +="Amount:#{decimal_rounding(record.final_expense_amount) }<br/><br/>"
            str +="Regards,<br/>"
            str +="LIVIA Admin"
            mail.body = str
            mail.content_type= 'text/html; charset=UTF-8'
            mail.to = record.performer.email
            mail.deliver
         end
    end
  end
end
