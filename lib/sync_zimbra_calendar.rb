class SyncZimbraCalendar
  
  ACCEPTABLE_DIFF = (-60 .. 60)
  
  def initialize(user)
    @user = user
    @zim_log = AuditLogger.new("#{RAILS_ROOT}/log/#{user.first_name}_#{user.last_name}_#{Time.now.strftime("%Y%m%dT%H%M%S")}.log")
  end
  
  def sync_from_zimbra(appointment_list)
    @zim_log.info "*" * 50
    @zim_log.info "Appointment synchronization started for User : #{@user.full_name} Email : #{@user.email} ID : #{@user.id}, Company ID : #{@user.company_id} "
    @zim_log.info "*" * 50
    #appointment_list = parse_json_appoitment(ZimbraCalendar.import(@user.email))

    appointment_list.each do |appo|
      #app_name = appo["series"]["name"]
      matter_task = MatterTask.find(:first, :conditions => ["category = 'appointment' and zimbra_task_id = ? and company_id = ? and assigned_to_user_id = ?", appo["series"]["zimbra_task_id"], appo["series"]["company_id"], @user.id], :with_deleted => true, :order => "id desc")
      if matter_task
      #if app_name.slice!(/<.*?>/)
      #  matter_name = appo["series"]["name"].match(/<(.*)>/m)[1].strip
      #  Matter.find_by_name_and_zimbra_task_id_and_company_id()
        begin
          tmp_series = convert_to_matter_task(appo["series"])
          MatterTask.transaction do
            series_appo = sync_matter_task_appointment(tmp_series)
  
            appo["exceptions"].each do |excpt_appo|
              excpt_appo = convert_to_matter_task(excpt_appo)
              sync_matter_task_appointment(excpt_appo.merge({"task_id" => series_appo.id}))
            end
          end
        rescue Exception => e
          @zim_log.error "Exception Occured : #{e}"
        end
      else
        begin
          ZimbraActivity.transaction do
            series_appo = sync_zimbra_activity_appointment(appo["series"])
  
            appo["exceptions"].each do |excpt_appo|
              sync_zimbra_activity_appointment(excpt_appo.merge({"task_id" => series_appo.id}))
            end
          end
        rescue Exception => e
          @zim_log.error "Exception Occured : #{e}"
        end
      end
      @zim_log.info "-" * 50
    end
    @zim_log.info "Imported successfully"
  end

  def sync_appointments
    appointment_list = parse_json_appoitment(ZimbraCalendar.import(@user.email))
    sync_from_zimbra(appointment_list)
    # can be improved but main focus or readability 
    sync_from_portal(appointment_list)
    @zim_log.info "Imported successfully"
  end

  def sync_from_portal(appointment_list)
    @zim_log.info "From Portal"
    task_ids = []
    appointment_list.each do |appo|
      task_ids << appo["series"]["zimbra_task_id"]

      # No need to check exception since if exception is getting handled into sync_from_zimbra

      #appo["exceptions"].each do |expt|
      #  task_ids << expt["zimbra_task_id"]
      #end
    end

    [ZimbraActivity, MatterTask].each do |appo_model|
      @zim_log.info "#{appo_model.name} appointments"
      zim_acts = appo_model.find(:all, :conditions => ["category = 'appointment' and assigned_to_user_id = ? and company_id =?", @user.id, @user.company_id], :order => "id asc")
    
      zim_acts.each do |zim_act|
        @zim_log.info "ID : #{zim_act.id}"
        begin
          if zim_act.zimbra_task_id.present?
            if task_ids.include?(zim_act.zimbra_task_id)
              @zim_log.info "Status : Synced, #{zim_act.zimbra_task_id}"
            else
              zim_act.destroy
              @zim_log.info "Status : Deleted into portal, #{zim_act.zimbra_task_id}"
            end
          else
            zim_act.save!
            @zim_log.info "Status : Updated into zimbra, #{zim_act.zimbra_task_id}"
          end
        rescue Exception => ex
          @zim_log.error "Exception occured : #{ex}" 
        end
      end
    end
  end
  
  def sync_zimbra_activity_appointment(appo_hash)
    @zim_log.info "ID : #{appo_hash["zimbra_task_id"]}"
    @zim_log.info "Type : ZimbraActivity"
    appo = ZimbraActivity.find(:first, :conditions => ["category = 'appointment' and zimbra_task_id = ? and assigned_to_user_id = ? and company_id =?", appo_hash["zimbra_task_id"], @user.id, @user.company_id], :with_deleted => true, :order => "id desc")
    if appo
      if appo.deleted_at
        #TODO Go and delete appointment from zimbra
        if appo_hash["deleted_at"].present?
          @zim_log.info "Status : Synced (deleted), #{appo.id}"
        else
          delete_appointment(appo) 
          @zim_log.info "Status : deleted from zimbra, #{appo.id}"
        end
      else
        time_diff = appo_hash["updated_at"] - appo.updated_at
        @zim_log.info "Time Diff : #{time_diff}"
        if time_diff > ACCEPTABLE_DIFF.max
          new_attr_hash = replace_hash(appo_hash, appo.attributes)
          appo.update_attributes(new_attr_hash)
          @zim_log.info "Status : Updated into portal, #{appo.id}"
        elsif time_diff < ACCEPTABLE_DIFF.min
          #TODO Go and update into zimbra
          appo.zimbra_status = true
          appo.save!
          @zim_log.info "Status : Update into zimbra, #{appo.id}"
        else
          # Appointment is already synced
          @zim_log.info "Status : Synced, #{appo.id}"
        end
      end

      appo
    else
      tmp_appo = ZimbraActivity.create!(appo_hash)
      @zim_log.info "Status : Created into portal, #{tmp_appo.id}"

      tmp_appo
    end
  end

  def sync_matter_task_appointment(appo_hash)
    @zim_log.info "ID : #{appo_hash["zimbra_task_id"]}"
    @zim_log.info "Type : MatterTask"
    appo = MatterTask.find(:first, :conditions => ["category = 'appointment' and zimbra_task_id = ? and assigned_to_user_id = ? and company_id =?", appo_hash["zimbra_task_id"], @user.id, @user.company_id], :with_deleted => true, :order => "id desc")
    if appo
      if appo.deleted_at
        #TODO Go and delete appointment from zimbra
        if appo_hash["deleted_at"].present?
          @zim_log.info "Status : Synced (deleted), #{appo.id}"
        else
          delete_appointment(appo) 
          @zim_log.info "Status : deleted from zimbra, #{appo.id}"
        end
      else
        time_diff = appo_hash["updated_at"] - appo.updated_at
        @zim_log.info "Time Diff : #{time_diff}"
        if time_diff > ACCEPTABLE_DIFF.max
          new_attr_hash = replace_hash(appo_hash, appo.attributes)
          appo.update_attributes(new_attr_hash)
          @zim_log.info "Status : Updated into portal, #{appo.id}"
        elsif time_diff < ACCEPTABLE_DIFF.min
          #TODO Go and update into zimbra
          appo.zimbra_task_status = true
          appo.save!
          @zim_log.info "Status : Update into zimbra, #{appo.id}"
        else
          # Appointment is already synced
          @zim_log.info "Status : Synced, #{appo.id}"
        end
      end

      appo
    else
      mt = MatterTask.find_with_deleted(appo_hash["task_id"]).clone.attributes.merge!(appo_hash) 
      tmp_appo = MatterTask.create!(mt)
      @zim_log.info "Status : Created into portal, #{tmp_appo.id}"

      tmp_appo
    end
  end

  def replace_hash(source, target)
    attributes_to_replace = [
                               "name",
                               "description",
                               "category",
                               "assigned_to_user_id",
                               "zimbra_task_id",
                               "reminder",
                               "repeat",
                               "location",
                               "attendees_emails",
                               "show_as",
                               "mark_as",
                               "start_date",
                               "end_date",
                               "all_day_event",
                               "exception_status",
                               "task_id",
                               "exception_start_date",
                               "exception_start_time",
                               "occurrence_type",
                               "count",
                               "until",
                               "updated_at",
                               "deleted_at"
                            ] 
#   attributes_to_replace.each do |k|
    target.each do |k,v|
      unless ["id", "created_at", "assigned_to_matter_people_id", "assoc_as", "matter_id", "completed", "completed_at", "critical", "client_task", "created_by_user_id", "updated_by_user_id", "progress", "progress_percentage", "lawyer_name", "lawyer_email", "client_task_type", "client_task_doc_name", "client_task_doc_desc", "exception_status", "category_type_id"].include?(k)
        target[k] = source[k]
      end
    end

    target
  end

  def convert_to_matter_task(appo_hash)
    # As user don't have any way to create MatterTask from zimbra so we will consider them as only one scenario of update series and create instances if any 
    # tmp_series = appo_hash.merge({"lawyer_email" => @user.email, "lawyer_name" => @user.full_name })
    appo_name = appo_hash["name"]
    appo_name.slice!(/<.*?>/) if appo_name.match(/<.*?>/)
    appo_hash["name"] = appo_name
    exception_date = appo_hash["exception_start_date"]
    if exception_date.present?
      appo_hash["exception_start_date"] = exception_date.strftime("%Y%m%d")
      appo_hash["exception_start_time"] = exception_date.strftime("%H%M%S")
    end
    appo_hash.delete("user_name")
    appo_hash.delete("zimbra_folder_location")
    appo_hash["zimbra_task_status"] = appo_hash.delete("zimbra_status")
    appo_hash
    #tmp_series["location"] = tmp_series.delete("zimbra_folder_location")
  end

  def delete_appointment(appo)
    zimbra_admin = Company.find(@user.company_id).zimbra_admin_account_email
    if zimbra_admin
      cancel_hash ={
        "at" => appo.attendees_emails,
        "su" => appo.name,
        "content" =>"The following is a new meeting request:

  Subject: #{appo.name}
  Organizer: #{@user.email}
  Invitees: #{appo.attendees_emails}

  *~*~*~*~*~*~*~*~*~*

  #{appo.description}"
        }

      domain = ZimbraUtils.get_domain(@user.email)
      host = ZimbraUtils.get_url(domain)
      key = ZimbraUtils.get_key(domain)
      if ZimbraConfig.find(:domain=>domain)
        unless appo.exception_start_date.blank?

          if appo.respond_to?("exception_start_time")
            # It is Matter Task where for time we have seperate column
            cancel_hash["ex_start_date"] = (appo.exception_start_date).strftime("%Y%m%d")
            cancel_hash["ex_start_time"] = (appo.exception_start_time).strftime("%H%M%S") 
          else
            # It is ZimbraActivity
            cancel_hash["ex_start_date"] = appo.exception_start_date.strftime("%Y%m%d")
            cancel_hash["ex_start_time"] = (appo.exception_start_date).strftime("%H%M%S")
          end
          cancel_hash["tz"] = ZimbraTask.get_prefs_request(key, host,@user.email.to_s,@user.full_name.to_s)
        end
        ZimbraTask.delete_apt(key, host, @user.email, cancel_hash,appo.zimbra_task_id)
      end
    end
  end
  
  def parse_json_appoitment(obj)
    appo_hash_list = []
    
    obj['appt'].each do |zim_appt| 
    
      app_hash = {"series" => "", "exceptions" => []}
      zim_appt['inv'].each do |zim_inv|
        inv_hash = {"category" => "appointment", "company_id" => @user.company_id, "user_name" => @user.full_name, "assigned_to_user_id" => @user.id, "zimbra_status" => false}
        # TODO set zimbra_status field accordingly
        # zimbra_status = true it fire appointment request into zimbra server
        inv_hash["zimbra_folder_location"] = zim_appt['l']
        inv_hash["zimbra_task_id"] = "#{zim_appt['id']}-#{zim_inv['id']}"

        zim_inv['comp'].each do |zim_comp|
          zim_comp.keys.each do |key|
            case key
            when 'ex'
              inv_hash["exception_status"] = false
            when 'name'
              inv_hash["name"] = zim_comp['name']
            when 'status'
              inv_hash["deleted_at"] = Time.at(zim_comp['d'].to_i / 1000) if zim_comp["status"] == "CANC"
            when 'desc'
              # TODO Need to think about fr and descHtml keys
              # Also need to think about \n which are after *~*~*~*~*~*~*~*~*~*
              inv_hash["description"] = zim_comp['desc'][0]['_content'].split("*~*~*~*~*~*~*~*~*~*").last
            when 'loc'
              inv_hash["location"] = zim_comp['loc']
            when 'fb'
              inv_hash["show_as"] = zim_comp['fb']
            when 'class'
              inv_hash["mark_as"] = zim_comp['class']
            when 'allDay'
              inv_hash["all_day_event"] = zim_comp['allDay']
            when 'd'
              inv_hash["created_at"] = Time.at(zim_comp['d'].to_i / 1000)
              inv_hash["updated_at"] = Time.at(zim_comp['d'].to_i / 1000)
            when 'exceptId'
              zim_comp['exceptId'].each do |exd|
                inv_hash["exception_start_date"] = DateTime.parse(exd['d'] + (((zim_inv['tz'][0]['stdoff']*60).to_utc_offset_s).gsub(':', '') rescue '')) 
              end
            when 's'
              zim_comp['s'].each do |sd|
                inv_hash["start_date"] = DateTime.parse(sd['d'] + (((zim_inv['tz'][0]['stdoff']*60).to_utc_offset_s).gsub(':', '') rescue ''))
              end
            when 'e'
              zim_comp['e'].each do |ed|
                inv_hash["end_date"] = DateTime.parse(ed['d'] + (((zim_inv['tz'][0]['stdoff']*60).to_utc_offset_s).gsub(':', '') rescue ''))
              end
            when 'at'
              inv_hash["attendees_emails"] = zim_comp['at'].collect {|e| e["a"]}.join(",")
            when 'alarm'
              zim_comp['alarm'].each do |zim_alarm|
                inv_hash["reminder"] = zim_alarm['trigger'][0]['rel'][0]['m']
              end
            when 'recur'
              zim_comp['recur'].each do |zim_recur|
                zim_recur['add'].each do |zim_add|
                  zim_add['rule'].each do |zim_rule|
                    inv_hash["repeat"] = zim_rule['freq']
                    if zim_rule.has_key?('until')
                      inv_hash["occurrence_type"] = "until"
                      inv_hash["until"] = zim_rule['until'][0]['d']
                    end
                    if zim_rule.has_key?('count')
                      inv_hash["occurrence_type"] = "count"
                      inv_hash["count"] = zim_rule['count'][0]['num']
                    end
                  end
                end
              end
            end
          end
        end
        if inv_hash.has_key?("exception_status")
          app_hash["exceptions"] << inv_hash
        else
          app_hash["series"] = inv_hash
        end
      end
      appo_hash_list  << app_hash  
    end
    appo_hash_list 
  end
end
