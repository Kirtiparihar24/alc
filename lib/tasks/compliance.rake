namespace :compliance do
  task :create_items => :environment do
    Compliance.find(:all).each do |comp|
      comp.create_item
    end      
   end

  task :send_reminder => :environment do
    i =0
    ComplianceItem.find(:all, :conditions=>["primary_status = ? OR primary_status = ?", "open","filed" ]).each do |comp_item|
      if reminder_to_be_send comp_item
        puts i.to_s
        i = i +1
        #comp_item.send_reminder_to_backend
      end
    end
  end

  task :correct_status => :environment do
    ComplianceItem.find(:all).each do |item|
      if item.primary_status != item.primary_status.downcase
         item.update_attribute(:primary_status, item.primary_status.downcase)
      end
      if item.primary_status == "filed and completed"
        item.update_attribute(:primary_status , "completed")
      end
    end
  end
  

  
end

def reminder_to_be_send (item)
  if item.primary_status == 'filed and closed' || item.primary_status == 'closed'
    return false
  end
  tdy = Time.zone.now().to_date
  if !item.reminder_start_date.blank? 
    reminder_start_date = item.reminder_start_date
  elsif item.time_before_due.to_i > 0
    reminder_start_date = item.due_date - item.time_before_due.to_i.day
  end  

  if reminder_start_date == tdy
    return true
  elsif reminder_start_date && (reminder_start_date <=  tdy)
    if item.reminder_frequency == 'daily'
      return true
    elsif item.reminder_frequency == 'weekly'
      ((tdy - reminder_start_date) % 7) == 0
    elsif item.reminder_frequency == 'monthly'
      ((tdy - reminder_start_date) % 30) == 0
    elsif item.reminder_frequency =~ /^([1-7]{1})\.days$/
      days_int = $1.to_i
      ((tdy - reminder_start_date) % days_int) == 0
    end
  else
    return false
  end    
end


