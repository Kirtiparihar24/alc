namespace :time_entry_time_update do
  task :entry_update => :environment do
    time_actual_duration
  end

private 
  def time_actual_duration
    file = File.new("#{RAILS_ROOT}/public/actual_duration.txt",'w+')
    all_time_entries  =Physical::Timeandexpenses::TimeEntry.all

    file.write("Update Time entry the actual duration")
    all_time_entries.each do |time_entry|
      file.write("______________________________________________" + time_entry.company.name + "______________________________________________________\n")
      file.write("Before updating actual duration data is like this  \n")
      file.write("Time entry ID: " +  time_entry.id.to_s + "\t Start time: "+ time_entry.start_time.to_s + "\t End Date: " + time_entry.end_time.to_s + "\t Actual Duration: " + time_entry.actual_duration.to_s + "\t Final Billed Amount: " + time_entry.final_billed_amount.to_s + "\n")
      if !time_entry.start_time.blank? && !time_entry.end_time.blank?
        file.write("After updating actual duration data is like this  \n")
        actual_duration = calculate_duration(time_entry)
        if time_entry.actual_duration > actual_duration
          file.write("The actual duration is greater than the calculated duration so the start time and end time is set to nil \n")
          time_entry.start_time=time_entry.end_time=nil
        else
          time_entry.actual_duration = calculate_duration(time_entry)
        end
        time_entry.final_billed_amount = time_entry.calculate_final_billed_amt
        #      time_entry.save false
        file.write("Time entry ID: " +  time_entry.id.to_s + "\t Start time: "+ time_entry.start_time.to_s + "\t End Date: " + time_entry.end_time.to_s + "\t Actual Duration: " + time_entry.actual_duration.to_s + "\t Final Billed Amount: " + time_entry.final_billed_amount.to_s + "\n")
      end
    end
    file.close
    puts "rake is finished "
  end

  def calculate_duration(entry)
    duration = entry.end_time - entry.start_time
    if duration > 0
      full_duration = duration / 1.hours
      (full_duration*100).round / 100.0
    else
      0.0
    end
  end


end

