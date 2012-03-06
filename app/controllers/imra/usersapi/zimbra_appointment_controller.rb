class Zimbra::Usersapi::ZimbraAppointmentController < ApplicationController
  require 'cgi'
  skip_before_filter :verify_authenticity_token
  
  def update
    data = params
    data.delete(:action)
    data.delete(:controller)
    data[:lawyer_emai] = "mkd@ddiplaw.com" if data[:lawyer_email].eql?("mdickinson@mdick.liviaservices.com")
    @matter_task = MatterTask.find_by_zimbra_task_id_and_lawyer_email_and_category(data[:zimbra_task_id], data[:lawyer_email], "appointment") if data[:zimbra_task_id] && data[:lawyer_email]
    if !@matter_task.blank?
      if (data[:ex_start_date])
        @new_matter_task = @matter_task.clone
        if @new_matter_task
          unless (data[:until].blank?)
            @new_matter_task.until = Date.parse(data[:until])
            data.delete(:until)
          end
        end
        if (data[:mode]=='3')
          @new_matter_task.zimbra_task_id = data[:edit_id]
          data.delete(:zimbra_task_id)
          data.delete(:edit_id)
        end
        @new_matter_task.zimbra_task_status = false
        @new_matter_task.exception_status = false
        @new_matter_task.start_date = ZimbraActivity.set_date_time(data[:start_date], data[:start_time], data[:lawyer_email])
        @new_matter_task.end_date = ZimbraActivity.set_date_time(data[:end_date], data[:end_time], data[:lawyer_email])
        @new_matter_task.exception_start_date = Date.parse(data[:ex_start_date])
        @new_matter_task.exception_start_time = Time.parse(data[:ex_start_time]).utc.strftime("%I:%M %p")
        @new_matter_task.task_id = @matter_task.id
        data.delete(:mode)
        matter_name = Matter.find(@new_matter_task.matter_id).name
        data['name'].slice!("<#{matter_name}>")
        @new_matter_task.name.slice!("<#{matter_name}>")
        @new_matter_task.from_zimbra = true
        @new_matter_task.send(:create_without_callbacks)
        data.delete(:ex_start_time)
        data.delete(:ex_start_date)
      else
        @new_matter_task = MatterTask.find_by_zimbra_task_id_and_lawyer_email_and_category(data[:zimbra_task_id], data[:lawyer_email], "appointment")
        if @new_matter_task
          @new_matter_task.start_date = ZimbraActivity.set_date_time(data[:start_date], data[:start_time], data[:lawyer_email])
          @new_matter_task.end_date = ZimbraActivity.set_date_time(data[:end_date], data[:end_time], data[:lawyer_email])
          if (data[:until])
            if data[:start_date] and data[:start_date] > data[:until] and @new_matter_task.occurrence_type.eql?("until")
              @new_matter_task.start_date = @new_matter_task.until = Date.parse(data[:start_date])
              data.delete(:start_date)
              data.delete(:until)
            else
              @new_matter_task.until = Date.parse(data[:until])
              if (data[:future_instance].eql?('true'))
                @new_matter_task.occurrence_type = "until"
                @new_matter_task.until-=1
                del_instance = []
                del_instance = MatterTask.find(:all,:conditions => ['task_id = ?', @new_matter_task.id])
                if del_instance
                  del_instance.each{|instance| instance.delete if instance.start_date > @new_matter_task.until}
                end
                data.delete(:count)
                data.delete(:ex_start_date)
                data.delete(:ex_start_time)
              end
              data.delete(:until)
            end
            if @new_matter_task.start_date > @new_matter_task.until
              @new_matter_task.until = @new_matter_task.start_date
            end
          else
            data.delete(:until)
          end
        end
      end
      data.delete(:task_id)
      data.delete(:mode)
      data.delete(:start_date)
      data.delete(:end_date)
      data.delete(:start_time)
      data.delete(:end_time)
      data.delete(:future_instance)
      data[:name] = CGI.unescape(data[:name])
      #TODO:
      if(data[:description] != "null")
      end
      if @new_matter_task
        matter_name = Matter.find(@new_matter_task.matter_id).name
        data['name'].slice!("<#{matter_name}>")
      end
      data[:from_zimbra] = true
    else
      @zimbra_activity = ZimbraActivity.find_by_zimbra_task_id(data[:zimbra_task_id])
      if @zimbra_activity
        data = ZimbraActivity.zimbra_appointment_params(data)
        if (data[:ex_start_date])
          @zimbra_new_activity = @zimbra_activity.clone
          if @zimbra_new_activity
            unless (data[:until].blank?)
              @zimbra_new_activity.until = Date.parse(data[:until])
              data.delete(:until)
            end
          end
          if (data[:mode]=='3')
            @zimbra_new_activity.zimbra_task_id = data[:edit_id]
            data.delete(:zimbra_task_id)
            data.delete(:edit_id)
          end
          @zimbra_new_activity.zimbra_status = false
          @zimbra_new_activity.exception_status = false
          @zimbra_new_activity.exception_start_date = ZimbraActivity.set_date_time(data[:ex_start_date], data[:ex_start_time], data[:lawyer_email])
          @zimbra_new_activity.task_id = @zimbra_activity.id
          data.delete(:mode)
          @zimbra_new_activity.from_zimbra = true
          @zimbra_new_activity.send(:create_without_callbacks)
          data.delete(:ex_start_time)
          data.delete(:ex_start_date)
        else
          @zimbra_activity = ZimbraActivity.find_by_zimbra_task_id(data[:zimbra_task_id])
          if @zimbra_activity
            if (data[:until])
              if data[:start_date] and data[:start_date].strftime("%Y-%m-%d")> data[:until] and @zimbra_activity.occurrence_type.eql?("until")
                @zimbra_activity.start_date =  ZimbraActivity.set_date_time(data[:start_date], data[:start_time], data[:lawyer_email])
                @zimbra_activity.until = Date.parse(data[:start_date])
                data.delete(:start_date)
                data.delete(:until)
              else
                @zimbra_activity.until = Date.parse(data[:until])
                if (data[:future_instance].eql?('true'))
                  @zimbra_activity.occurrence_type = "until"
                  @zimbra_activity.until-=1
                  del_instance = []
                  del_instance = ZimbraActivity.find(:all,:conditions => ['task_id = ?', @zimbra_activity.id])
                  if del_instance
                    del_instance.each{|instance| instance.delete if instance.start_date > @zimbra_activity.until}
                  end
                  data.delete(:count)
                  data.delete(:ex_start_date)
                  data.delete(:ex_start_time)
                end
                data.delete(:until)
              end
              if @zimbra_activity.start_date.to_date > @zimbra_activity.until
                @zimbra_activity.until = @zimbra_activity.start_date.to_date
              end
            else
              data.delete(:until)
            end
          end
        end
        data.delete(:task_id)
        data.delete(:mode)
        data.delete(:future_instance)
        data[:name] = CGI.unescape(data[:name])
        #TODO:
        assigned_to_id, company_id = ZimbraActivity.get_user_id(data[:lawyer_email])
        data.delete(:lawyer_email)
        @zimbra_activity.assigned_to_user_id = assigned_to_id
        @zimbra_activity.company_id = company_id
        @zimbra_activity.from_zimbra = true
      end
    end
    respond_to do |format|
      if !@matter_task.blank?
        if @new_matter_task
          if @new_matter_task.update_attributes(data)
            format.xml { render :xml=>{:success => "Appointment is sucessfully updated"} }
          else
            format.xml { render :xml => {:error => "Appointment not updated"} }
          end
        end
      else
        if @zimbra_activity.update_attributes(data)
          format.xml { render :xml=>{:success => "Appointment is sucessfully updated"} }
        else
          format.xml { render :xml => {:error => "Appointment not updated"} }
        end
      end
		end
  end


  def delete
    respond_to do |format|
      begin
        data = params
        data.delete(:mode)
        data[:lawyer_emai] = "mkd@ddiplaw.com" if data[:lawyer_email].eql?("mdickinson@mdick.liviaservices.com")
        zimbra = false
        if data[:zimbra_task_id].present? && data[:lawyer_email].present?
          task = MatterTask.find_by_lawyer_email_and_zimbra_task_id_and_category(data[:lawyer_email],data[:zimbra_task_id],'appointment')
          if task.blank?
            task = ZimbraActivity.find_by_zimbra_task_id(data[:zimbra_task_id])
            zimbra = true
          end
          unless task.blank?
            if data[:ex_start_time]
              # We are deleting an instance in Zimbra.
              new_task = task.clone
              new_task.start_date = Date.parse(data[:instance_date])
              new_task.end_date = Date.parse(data[:instance_date])
              if zimbra
                new_task.exception_start_date = ZimbraActivity.set_date_time(data[:instance_date], data[:ex_start_time], data[:lawyer_email])
              else
                new_task.exception_start_date = Date.parse(data[:instance_date])
                new_task.exception_start_time = Time.parse(data[:ex_start_time]).utc.strftime("%I:%M %p")
              end
              new_task.task_id = task.id
              if zimbra
                new_task.zimbra_status = true
              else
                new_task.zimbra_task_status = false
              end
              new_task.exception_status = true
              new_task.from_zimbra = true
              if new_task.send(:create_without_callbacks)
                task = new_task
              end
            end
            unless task.blank?
              if task.delete
                if task.category.eql?("appointment") and task.task_id.blank?
                  task_instance = []
                  if zimbra
                    task_instance = ZimbraActivity.find(:all, :conditions => ["task_id = ?", task.id])
                  else
                    task_instance = MatterTask.find(:all, :conditions => ["task_id = ?", task.id])
                  end
                  task_instance.each{|x| x.delete} unless task_instance.blank?
                end
                format.xml { render :xml => {:success => "Appointment was successfully deleted"} }
              else
                format.xml { render :xml => {:error => "Appointment not found"} }
              end
            end
          else
            format.xml { render :xml=> {:error=> "Appointment not found" } }
          end
        end
      rescue Exception =>e
        format.xml { render :xml=> {:error=>e } }
      end
    end
  end

end

