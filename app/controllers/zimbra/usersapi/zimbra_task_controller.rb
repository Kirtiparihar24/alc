class Zimbra::Usersapi::ZimbraTaskController < ApplicationController
  require 'cgi'
  skip_before_filter :verify_authenticity_token

  # It is used to update zimbra business task. Zimbra call this function when task edit is performed at their side.
  def update
    begin
      data = params
      data[:lawyer_email] = "mkd@ddiplaw.com" if data[:lawyer_email].eql?("mdickinson@mdick.liviaservices.com")
      data.delete(:action)
      data.delete(:controller)
      data[:start_date] = data[:start_date].to_date if data[:start_date]
      data[:end_date] = data[:end_date].to_date if data[:end_date]
      attributes = data
      @task = MatterTask.find_by_zimbra_task_id_and_lawyer_email_and_category(attributes[:zimbra_task_id], attributes[:lawyer_email], "todo")
      if @task
        attributes[:zimbra_task_status] = true
        # if the task is completed at zimbra mark it's completion in the portal also -- Mandeep (21/04/10).
        if attributes[:progress].eql?("COMP") && attributes[:progress_percentage].eql?("100")
          attributes.merge!({:completed => true, :completed_at => Time.zone.now.to_date})
        end
        # if the task is changed from completed to other, need to change it in portal -- Ketki (23/09/2010).
        if @task.completed and !attributes[:progress].eql?("COMP")
          attributes.merge!({:completed => false, :completed_at => nil})          
        end
        @task.progress = attributes[:progress]
        @task.progress_percentage = attributes[:progress_percentage]
        data[:name] = CGI.unescape(data[:name])
        matter_name = Matter.find(@task.matter_id).name
        data[:name].slice!("<#{matter_name}>")
        if(data[:description] != "null")
          data[:description] =CGI.unescape(data[:description])
        end
        if @task.update_attributes(attributes)
          render :xml=>{:success => "Task is sucessfully updated"}          
        else
          render :xml=>{:error => @task.errors}
        end
      else
        @task = ZimbraActivity.find_by_zimbra_task_id(data[:zimbra_task_id])
        if @task
          data = ZimbraActivity.zimbra_task_params(data)
          data[:name] = CGI.unescape(data[:name])
          if @task.update_attributes(data)
            render :xml=>{:success => "Task is sucessfully created"}
          else
            render :xml=>{:error => @task.errors}
          end
        else
          render :xml => "Hash not found"
        end
      end
    rescue Exception=>e
      render :xml=>{:error=>e}
    end
  end

  def delete
    begin
      data = params
      data[:laywer_email] = "mkd@ddiplaw.com" if data[:laywer_email].eql?("mdickinson@mdick.liviaservices.com")
      if data[:delete_tasks_ids].present? && data[:laywer_email].present?
        delete_task_ids = data[:delete_tasks_ids].split(',')
        tasks = []
        delete_task_ids.each { |zimbra_task_id|
          task = MatterTask.find_by_lawyer_email_and_zimbra_task_id_and_category(data[:laywer_email],zimbra_task_id,'todo')
          task = ZimbraActivity.find_by_zimbra_task_id(zimbra_task_id) unless task          
          if task
            if !task.destroy
              tasks << {:et => {:eid => zimbra_task_id, :estatus => task.errors}}
            end
          else
            tasks << {:pt => zimbra_task_id}
          end
        }
        render :xml=> "Tasks are successfully deleted"
      end
    rescue Exception=>e
      render :xml=>{:error=>e}
    end
  end
  
end
