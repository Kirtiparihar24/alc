#TODO Might be used after some time
ZIMBRA_TASK_LOG = AuditLogger.new("#{RAILS_ROOT}/log/zimbra_task_#{Time.now.strftime("%Y%m%dT%H%M%S")}.log")

# Get all companies
companies = Company.find(:all,:select=>"id")

# Loop through each company and it's contact
companies.each { |company|
	mtrtasks = MatterTask.find(:all, :conditions => "company_id = #{company.id} and deleted_at is null")
	
	mtrtasks.each { |task|
		begin
		task.save(false)
		rescue => e
			ZIMBRA_TASK_LOG.error "Task : #{task.id} and Company : #{task.company_id} : #{e}"
		end
	}

}
	
