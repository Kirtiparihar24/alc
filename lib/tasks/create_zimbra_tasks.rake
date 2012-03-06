namespace :save_task do
  task :lawyer_email  => :environment do
    @matter_tasks = MatterTask.find(:all, :conditions => ["lawyer_email is not null And assigned_to_matter_people_id is not null"])
    @matter_tasks.each do |task|
      mpid = task.assigned_to_matter_people_id
      usr = User.find(MatterPeople.find(mpid).employee_user_id)
      MatterTask.update_all({:lawyer_email => usr.email, :lawyer_name => usr.full_name},{:id =>task.id}) if !usr.email.blank? and !usr.full_name.blank?
    end
  end
	task :create_task_into_zimbra => :environment do
    MatterTask.connection.execute("UPDATE matter_tasks SET zimbra_task_id = null ,exception_status = false WHERE zimbra_task_id is not null and exception_start_date is null")
    matter_tasks = MatterTask.find(:all, :conditions => "exception_start_date is null")
    matter_tasks.each {|task|
      begin
        print task.save(false), "----"
        print task.zimbra_task_id, "\n"
      rescue => e
        print "Task : #{task.id}"
      end
      MatterTask.connection.execute("DELETE from matter_tasks where task_id is not null and exception_start_date is not null;")
      #      matter_tasks = MatterTask.find(:all, :conditions => "task_id is not null")
      #      matter_tasks.each {|task|
      #        begin
      #          task.save(false)
      #        rescue => e
      #          print "Task : #{task.id} Company : #{task.company_id}"
      #        end
      #      }
    }
	end
end