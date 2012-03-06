module GeneralFunction

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def append_value(primary_column,secondary_column)

    condition = []
    secondary_column = "opportunities.stage" if secondary_column.eql?("opportunities_stage")
    condition << ","+primary_column+" "+"as primary_column" unless primary_column.nil?
    condition << ","+secondary_column+" "+"as secondary_column" unless secondary_column.nil?
    return condition
  end

    def parent_name
      unless self.parent_id.nil?
        self.parent.name
      end
    end

    #    def parent
    #      unless self.parent_id.nil?
    #        self.find(self.parent_id)
    #      end
    #    end

    # Returns name, clipped to a fitter length.
    def clipped_name      
      _matter_clip_len = 45
      if self.name.length > (_matter_clip_len-3)
        self.name[0, _matter_clip_len - 3] + "..."
      else
        self.name
      end
    end

    def format_name
      self.name.gsub!(/\b[a-z]/) { |w| w.capitalize }
    end

    # Returns formatted (HH:MM [A|P]M) start time.
    def get_start_time
      unless self.start_date.nil?
        s = self.clone
        s.start_date.strftime("%I:%M %p")
      end
    end

    # Returns formatted (HH:MM [A|P]M) end time.
    def get_end_time
      unless self.end_date.nil?
        e = self.clone
        e.end_date.strftime("%I:%M %p")
      end
    end

    # Returns name, truncated to a given length.
    def name_truncate(len)
      (self.name.length > len) ? (self.name[0,len-3] + "...") : self.name
    end

    #When a users time and expense entry has been changed from Approved to Open by the lead lawyer. (not by self)
    def send_tne_status_update_mail(user, obj)
      if user.id.to_i != obj.performer.id.to_i
        #Updated by Milind to send email to all matter related lawyers
        unless obj.matter.nil?
          email_to = obj.matter.matter_peoples.client.map {|cl| [cl.get_email] unless cl.get_role=="Lead Lawyer" }
          email_to = email_to - [nil]
          email_to.uniq!
          email_to = email_to.join(',')
        else
          email_to = obj.performer.email
        end        
        LiviaMailConfig::email_settings(user.company)
        mail = Mail.new()
        mail.from = get_from_email_for_notification_alerts
        if obj.matter.nil? && obj.contact.nil?
          sub = ''
          msg = ''
        elsif obj.matter.nil?
          sub = "#{obj.contact.try(:full_name)}'s"
          msg = "Contact: #{sub}'s"
        else
          sub = "#{obj.matter.name}'s"
          msg = "Matter: #{obj.matter.name}'s <br></br> Contact: #{obj.contact.try(:full_name)}'s"
        end        
        mail.subject = "#{sub} Time and expense status has been modified"
        str = "Hi #{obj.performer.first_name} #{obj.performer.last_name},"
        str +="<br></br> <br></br> Time and expense status has been modified to #{obj.status} on #{Time.now} <br></br>"
        str +="by #{user.first_name} #{user.last_name} on #{Time.zone.now}<br></br>"
        str +="User:#{obj.performer.full_name}<br></br>"
        str +="#{msg}"
        str +="Date:#{obj.class.name =='Physical::Timeandexpenses::TimeEntry' ?  obj.time_entry_date : obj.expense_entry_date}<br></br>"
        str +="Activity:#{obj.company.company_activity_types.find(obj.activity_type).alvalue}<br></br>"
        str +="Description:#{obj.description}<br></br>"
        str +="Amount:#{obj.class.name =='Physical::Timeandexpenses::TimeEntry' ?  obj.final_billed_amount : obj.final_expense_amount }<br></br>"
        
        str +="Regards,<br></br></br>"
        str +="LIVIA Admin"        
        mail.body = str
        mail.content_type= 'text/html; charset=UTF-8'

        mail.to = obj.performer.email
        mail.deliver
      end
      
    end

    def send_notification_to_email_to_user(user, subject, body)
     if user.present?
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = subject
      mail.body = body
      mail.to = user.email
      mail.deliver!
     end
    end
    
    def send_notification_to_responsible(user,obj,current_user)
     if user.present?
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "You are responsible for #{obj.class}: #{obj.name}"
      str = "Hi #{user.first_name} #{user.last_name},
             You are responsible for #{obj.class}: #{obj.name}
             by #{current_user.first_name} #{current_user.last_name} on #{Time.now.in_time_zone(user.time_zone)}"
      mail.body = str
      mail.to = user.email
      mail.deliver!
     end
    end
    
    def send_notification_from_client(user,obj,current_user,matter_task)
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "Client #{current_user.first_name} posted a message"

      str = "Hi #{user.first_name} #{user.last_name},
Comment for #{obj.commentable.type} : #{matter_task.name} Added.

        #{obj.comment}

by #{current_user.first_name} #{current_user.last_name} on #{Time.zone.now}"
      mail.body = str
      mail.to = user.email
      mail.deliver
    end

    def send_notification_on_user_added(user,obj,current_user)
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "You are responsible for #{obj.class}: #{obj.name}"
      str = "Hi #{user.first_name} #{user.last_name},
You are responsible for #{obj.class}: #{obj.name}
by #{current_user.first_name} #{current_user.last_name} on #{Time.zone.now}"
      mail.body = str
      mail.to = user.email
      mail.deliver
    end

    def send_notificaton_to_attendees(user, obj, to_email)
      to_name = get_attendee_name_from_email(to_email, user.company_id, obj.matter_id)
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.charset = 'UTF-8'
      mail.content_transfer_encoding = "8bit"
      mail.from = user.email
      to_email = to_email.chomp
      mail.subject = " Meeting Invite: \“#{obj.name}\" "
      if to_name
        str = "Dear #{to_email}, \n "
      end
      str = "
This meeting invite is sent to you by #{user.full_name}

Details:

Matter name: #{obj.matter.name}
Start date And Time:  #{obj.start_date.to_date}  #{obj.start_date.to_time}
End date And Time:  #{obj.end_date.to_date}  #{obj.end_date.to_time}
Attendees: #{obj.attendees_emails}
Description: #{obj.description}


\“This is a system generated email. Kindly do not reply to this email.\” "
      mail.body = str
      mail.to = to_email
      mail.deliver
    end

    def send_notification_for_campaign_mails(user,current_user)
     if user.present?
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "You are responsible for Campaign emails"
      str = "Hi #{user.first_name} #{user.last_name},
              You are responsible for sending Campaign emails.
              by #{current_user.first_name} #{current_user.last_name} on #{Time.zone.now}"
      mail.body = str
      mail.to = current_user.email
      mail.deliver
     end
    end

  end

  def pluralize_record(count, singular, type, plural = nil)
    if type==1
      ( count == 1 || count == '1') ? "Total #{singular} = #{count}" : "Total #{(plural || singular.pluralize)} = #{count}"
    elsif type==0
      ( count == 1 || count == '1')? "#{count} #{singular}" : "#{count} #{(plural || singular.pluralize)}"
    end
  end
  

  def send_notification_to_lead_lawyer(matter_user,matter,user)
    LiviaMailConfig::email_settings(user.company)

    mail = Mail.new do
      from get_from_email_for_notification_alerts
      to "#{matter_user.email}"
      subject "#{user.company.name} : Client Access Created"
      html_part do
        content_type 'text/html; charset=UTF-8'
        body  "<p>Dear #{matter_user.full_name},</p><p>A client access is created.</p><p>For : #{matter.name}</p>
                <p>By : #{user.company.name}</p>



                <br/><p>This is a system generated email</p>"
      end
      
    end
    mail.deliver
  end
  # After perment_delition of matter lead lawer can get mail for the same
  def send_notification_to_lead_lawyer_after_matter_delete(matter,user)
    LiviaMailConfig::email_settings(user.company)
    mail = Mail.new do
      from get_from_email_for_notification_alerts
      to "#{matter.user.email}"
      subject "#{user.company.name} : Matter \"#{matter.name}\"  has been deleted by your administration team."
      html_part do
        content_type 'text/html; charset=UTF-8'
        body  "<p>Dear #{matter.user.name},</p><p>Matter \"#{matter.name}\" has been deleted by your administration team.</p>
                 <p>By : Administration team.</p>
                 <br/><p>This is a system generated email.</p>"
      end
    end
    mail.deliver
  end

  def send_update_notificaton_to_attendees(user, obj, to_email)
    to_name = get_attendee_name_from_email(to_email, user.company_id, obj.matter_id)
    repeats = ''
    MatterTask::REPEAT_OPTIONS.each do |rep|
      repeats = rep[0] if rep.include?(obj.repeat)
    end
    LiviaMailConfig::email_settings(user.company)
    mail = Mail.new()
    mail.charset = 'UTF-8'
    mail.content_transfer_encoding = "8bit"
    mail.from = user.email
    to_email = to_email.chomp
    mail.subject = " Meeting Invite: \“#{obj.name}\" "
    str = ""
    unless to_name.blank?
      str = "Dear #{to_name}

      "
    end
    str += "This revised meeting invite is sent to you by #{user.full_name}

    "
    str += "
Details:

Matter name: #{obj.matter.name}
Start date And Time:  #{obj.start_date.to_date}  #{obj.start_date.to_time.strftime('%H%M')}
End date And Time:  #{obj.end_date.to_date}  #{obj.end_date.to_time.strftime('%H%M')}"
    unless repeats.blank?
      str +="
Repeats: #{repeats}"
    end
    str+="
Attendees: #{obj.attendees_emails}
Description: #{obj.description}


\“This is a system generated email. Kindly do not reply to this email.\” "
    mail.body = str
    mail.to = to_email
    mail.deliver
  end

  def send_notification_for_campaign_mails(user,current_user)
     if user.present?
      LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "You are responsible for Campaign emails"
      str = "Hi #{user.first_name} #{user.last_name},
              You are responsible for sending Campaign emails.
              by #{current_user.first_name} #{current_user.last_name} on #{Time.zone.now}"
      mail.body = str
      mail.to = current_user.email
      mail.deliver
     end
  end

  def lawyer_view_all_matter_tasks2(current_comp_id,user_id,activity=nil)
    user_set_val = UserSetting.find_by_user_id(user_id)
    if user_set_val.nil?
      user_set_val = 7
    else
      user_set_val = user_set_val.setting_value.nil? ? 7 : user_set_val.setting_value
    end
    #        matter_tasks = MatterTask.find(:all, :joins=>:matter_people, :conditions =>
    #            ["matter_peoples.company_id = ? and matter_tasks.assigned_to_matter_people_id = matter_peoples.id AND matter_peoples.employee_user_id IS NOT NULL AND matter_peoples.employee_user_id = ? AND is_active AND matter_peoples.deleted_at is NULL",
    #            current_company.id, get_employee_user_id])
    today = Time.zone.now.to_date.to_s
    op=Time.zone.formatted_offset.first
    off_set=Time.zone.formatted_offset.gsub(/[+-]/,'')
    matters = Matter.unexpired_team_matters(user_id, current_comp_id, Time.zone.now.to_date).uniq
    matterids = []
    matters.each{|matter| matterids << matter.id}
    mattrppl = MatterPeople.find(:all, :select => :id, :conditions => {:employee_user_id => user_id, :matter_id => (matterids)})
    mpids = []
    mattrppl.each{|mp| mpids << mp.id}
    tday = ""
    oday = ""
    upday = ""
    matter_tasks = []
    if activity=='Task'
      tday = "m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time '#{off_set}') = date('#{today}')"
      oday = "m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time' #{off_set}') < date('#{today}')"
      upday = "m.category !='appointment' and m.completed=false and m.end_date is not null and (date(m.end_date #{op} time '#{off_set}') > date('#{today}') and date(m.end_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval)))"
    elsif activity=='App'
      tday = "m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') = date('#{today}')"
      oday = "m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') < date('#{today}')"
      upday = "m.category='appointment' and m.completed=false and m.start_date is not null and (date(m.start_date #{op} time '#{off_set}') > date('#{today}') and date(m.start_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval)))"
    else
      tday = "m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') = date('#{today}')
              OR m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time '#{off_set}') = date('#{today}')"
      oday = "m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') < date('#{today}')
              OR m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time' #{off_set}') < date('#{today}')"
      upday = "m.category='appointment' and m.completed=false and m.start_date is not null and (date(m.start_date #{op} time '#{off_set}') > date('#{today}') and date(m.start_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval)))
              OR m.category !='appointment' and m.completed=false and m.end_date is not null and (date(m.end_date #{op} time '#{off_set}') > date('#{today}') and date(m.end_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval)))"
    end
    if mpids.size > 0
      matter_tasks =  MatterTask.find_by_sql(
        "select count(*) as cnt,'today' as taskst from matter_tasks m inner join matter_peoples mp on m.assigned_to_matter_people_id = mp.id
        where mp.company_id=#{current_comp_id}
        and m.matter_id in (#{matterids.join(',')})
        and assigned_to_matter_people_id in (#{mpids.join(',')})
        and mp.employee_user_id=#{user_id}
        and mp.employee_user_id IS NOT NULL AND is_active
        and (
              #{tday}
            )
        and m.deleted_at is NULL and mp.deleted_at is NULL
      union
        select count(*) as cnt,'overdue' as taskst from matter_tasks m inner join matter_peoples mp on m.assigned_to_matter_people_id = mp.id
        where mp.company_id=#{current_comp_id}
        and mp.employee_user_id=#{user_id} and mp.employee_user_id IS NOT NULL AND is_active
        and m.matter_id in (#{matterids.join(',')})
        and assigned_to_matter_people_id in (#{mpids.join(',')})
        and (
              #{oday}
            )
        and m.deleted_at is NULL and mp.deleted_at is NULL
      union
        select count(*) as cnt,'upcoming' as taskst from matter_tasks m inner join matter_peoples mp on m.assigned_to_matter_people_id = mp.id
        inner join user_settings ust on mp.employee_user_id=ust.user_id
        where mp.company_id=#{current_comp_id}
        and mp.employee_user_id=#{user_id}
        and mp.employee_user_id IS NOT NULL AND is_active
        and m.matter_id in (#{matterids.join(',')})
        and assigned_to_matter_people_id in (#{mpids.join(',')})
        and (
              #{upday}
            )
        and m.deleted_at is NULL and mp.deleted_at is NULL and ust.setting_type='upcoming'")
    end
    alert_hash ={}
    if(matter_tasks.size > 0)
      matter_tasks.each do |mt|
        alert_hash.merge!(mt.taskst=>mt.cnt.to_i)
      end
    else
      alert_hash.merge!("today"=>0,"overdue"=>0,"upcoming"=>0)
    end

    alert_hash
  end

  def matter_tasks_count(current_comp_id, user_id, activity=nil)
    @all_tasks = []   
    user = User.find(user_id)
    date = Time.zone.now.to_date
    # find todo and apointments 
    # It will find user matter tasks for those matter where its role is not expired on a givendate
    if activity.blank?
      #findout todo and appoinment
      @all_tasks = user.matter_tasks.find_with_deleted(:all,:include=>[:matter=>[:contact=>[:accounts]]],
        :conditions=>["matter_peoples.is_active = 't'
              AND (( matter_peoples.end_date >= '#{date}' AND  matter_peoples.start_date <= '#{date}') or ( matter_peoples.start_date <= '#{date}' and  matter_peoples.end_date is null)
              or ( matter_peoples.start_date is null and  matter_peoples.end_date is null)) and (completed is null or completed = false or category ='appointment')"])
    else
      #find out appointment
      @all_tasks = user.matter_tasks.find_with_deleted(:all,:include=>[:matter=>[:contact=>[:accounts]]],
        :conditions=>["matter_peoples.is_active = 't'
              AND (( matter_peoples.end_date >= '#{date}' AND  matter_peoples.start_date <= '#{date}') or ( matter_peoples.start_date <= '#{date}' and  matter_peoples.end_date is null)
              or ( matter_peoples.start_date is null and  matter_peoples.end_date is null)) and (category ='#{activity}')"])
  end
   
    
  end
  
  def old_matter_tasks_count(current_comp_id, user_id, activity=nil)
    matters = Matter.unexpired_team_matters(user_id, current_comp_id, Time.zone.now.to_date).uniq
    matters.each do |e|
      @all_tasks << e.view_all_tasks(e.employee_matter_people_id(user_id))
      @all_tasks = @all_tasks.flatten

      if activity.blank?
        @all_tasks = @all_tasks.reject{|task| (task.completed? and task.category.eql?('todo') )}
      else
        @all_tasks = @all_tasks.reject{|task| task.category.eql?('appointment')}
      end
    end

  end

  def zimbra_activities_count(user_id)
    activities = ZimbraActivity.find_with_deleted(:all,:conditions => {:assigned_to_user_id => user_id})
    @activities = activities.reject{|activity| (activity.category.eql?('todo') and activity.activity_completed?)}
  
  end

  def get_my_overdue_opportunity(cid, eid)
     today = Time.zone.now.to_date
     get_my_opportunity(cid,eid).find_all { |e| e.follow_up && e.follow_up.to_date < today }
 end

  def get_my_opportunity(cid, eid)
    Opportunity.find(:all,:joins=>[:opportunity_stage_type],:include=>[:contact],
       :conditions => ["company_lookups.lvalue not in (?) AND opportunities.company_id = ? AND opportunities.assigned_to_employee_user_id = ? ",['Closed/Won','Closed/Lost'],cid, eid])
  end

  def getlawyer_opportunity_followup_today(cid, eid)
    today = Time.zone.now.to_date
    get_my_opportunity(cid,eid).find_all { |e| e.follow_up && e.follow_up.to_date == today }
  end

   def getlawyer_opportunity_coming_up(cid, eid, user_setting)
     today = Time.zone.now.to_date
    future_count = user_setting.setting_value.to_i
    future_date = today + future_count
    get_my_opportunity(cid,eid).find_all {|e| e.follow_up && ((e.follow_up.to_date > today) && (e.follow_up.to_date <= future_date))}
   end

  def send_notification_for_invalid_contacts(path,user,invalid_contacts,valid_contacts,employee)
    
    LiviaMailConfig::email_settings(user.company)
    total=valid_contacts + invalid_contacts
    mail = Mail.new do
      from get_from_email_for_notification
      to "#{user.email}"
      subject "#{employee.company_full_name}- Business Contact Upload Status notification"
      part :content_type => "multipart/alternative"  do |p|
        p.html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Hi,</p>

<p>Your Contacts have been successfully imported into the LIVIA system. Below is the status of the same:</p>

<p>Law firm name : #{employee.company_full_name}<br/>
User name     : #{employee.full_name}</p>


<p>Valid imports :  #{valid_contacts}<br/>
Invalid imports  :  #{invalid_contacts}<br/>
Total            :  #{total}</p>


<p>Please find attached a detailed report on the invalid contacts if any.</p>

<p>In case you face any issues please contact your LIVIAN or raise a helpdesk ticket.</p>

<p>Regards,</p>

<p>Team LIVIA</p>"
         
        end
      end
    end
    if invalid_contacts>0
      mail.add_file "#{RAILS_ROOT}/#{path}"
    end
    mail.deliver
  end

  def send_notification_for_invalid_matters(path,user,invalid_matters,valid_matters,employee)

    LiviaMailConfig::email_settings(user.company)
    total=valid_matters + invalid_matters
    mail = Mail.new do
      from get_from_email_for_notification
      to "#{user.email}"
      subject "#{employee.company_full_name}- Matters Upload Status notification"
      part :content_type => "multipart/alternative"  do |p|
        p.html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Hi,</p>

<p>Your Matters have been successfully imported into the LIVIA system. Below is the status of the same:</p>

<p>Law firm name : #{employee.company_full_name}<br/>
User name     : #{employee.full_name}</p>


<p>Valid imports :  #{valid_matters}<br/>
Invalid imports  :  #{invalid_matters}<br/>
Total            :  #{total}</p>


<p>Please find attached a detailed report on the invalid matters if any.</p>

<p>In case you face any issues please contact your LIVIAN or raise a helpdesk ticket.</p>

<p>Regards,</p>

<p>Team LIVIA</p>"

        end
      end
    end
    if invalid_matters>0
      mail.add_file "#{RAILS_ROOT}/#{path}"
    end
    mail.deliver
  end

  def send_notification_for_invalid_entry(path,user,invalid_count,valid_count,employee,entry_type)
    LiviaMailConfig::email_settings(user.company)
    total = invalid_count + valid_count
    mail = Mail.new do
      from get_from_email_for_notification
      to "#{user.email}"
      subject "#{employee.company_full_name}- #{entry_type} Upload Status notification"
      part :content_type => "multipart/alternative"  do |p|
        p.html_part do
          content_type 'text/html; charset=UTF-8'
          body  "<p>Hi,</p>

            <p>Your #{entry_type} have been successfully imported into the LIVIA system. Below is the status of the same:</p>

            <p>Law firm name : #{employee.company_full_name}<br/>
            User name     : #{employee.full_name}</p>


            <p>Valid imports :  #{valid_count}<br/>
            Invalid imports  :  #{invalid_count}<br/>
            Total            :  #{total}</p>


            <p>Please find attached a detailed report on the invalid entries if any.</p>

            <p>In case you face any issues please contact your LIVIAN or raise a helpdesk ticket.</p>

            <p>Regards,</p>

            <p>Team LIVIA</p>"

        end
      end
    end
    if invalid_count>0
      mail.add_file "#{RAILS_ROOT}/#{path}"
    end
    mail.deliver
  end

  def send_notification_for_appointment_synchronization(user)
    LiviaMailConfig::email_settings(user.company)
    mail = Mail.new do
      from get_from_email_for_notification
      to "#{user.email}"
      subject "#{user.company_full_name}- Appointment synchronization notification"
      content_type 'text/html; charset=UTF-8'
      body  "<p>Hi,</p>

<p>Your appointment synchronization have been done successfully.</p>

<p>In case you face any issues please contact your LIVIAN or raise a helpdesk ticket.</p>

<p>Regards,</p>

<p>Team LIVIA</p>"
         
    end
    mail.deliver
  end
   
  def create_documentsubcategory_for_company(company,lvalue_txt=nil)
    article_sub_category = [ 'Legal', 'General','Other']
    template_sub_category = [ 'Forms', 'Formats','Other']
    other_sub_category = ['Other']
    if lvalue_txt.nil?
      company.document_categories.each do |category|
        if category.lvalue == 'Article'
          article_sub_category.each do |sub_category|
            DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category, :category_id=>category.id, :company_id=>company.id)
          end
        elsif category.lvalue == 'Template'
          template_sub_category.each do |sub_category|
            DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category,:category_id=>category.id, :company_id=>company.id)
          end
        elsif category.lvalue == 'Other'
          other_sub_category.each do |sub_category|
            DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category,:category_id=>category.id , :company_id=>company.id)
          end
        end
      end
    else
      category = company.document_categories.find_all_by_lvalue(lvalue_txt,:order => 'created_at desc')
      if lvalue_txt == 'Article'
        article_sub_category.each do |sub_category|
          DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category, :category_id=>category[0].id, :company_id=>company.id)
        end
      elsif lvalue_txt == 'Template'
        template_sub_category.each do |sub_category|
          DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category,:category_id=>category[0].id, :company_id=>company.id)
        end
      elsif lvalue_txt == 'Other'
        other_sub_category.each do |sub_category|
          DocumentSubCategory.create(:lvalue=>sub_category, :alvalue=>sub_category,:category_id=>category[0].id , :company_id=>company.id)
        end
      end
    end
  end
  
  private
  # Return 'from' email address to be used for notification emails.
  # FIXME: Uses ENV[HOST_NAME], need a better way to detect which 'from' address to use.
  def get_from_email_for_notification_alerts
    if ENV["HOST_NAME"].present?
      ENV["HOST_NAME"].include?('liviaservices') ? "noreply.alerts@liviaservices.com" : "support.test@liviatech.com"
    else
      "support.test@liviatech.com"
    end
  end
  def get_from_email_for_notification
    if ENV["HOST_NAME"].present?
      ENV["HOST_NAME"].include?('liviaservices') ? "noreply@liviaservices.com" : "support.test@liviatech.com"
    else
      "support.test@liviatech.com"
    end
  end

  def decimal_rounding(val)
    val.to_f.fixed_precision(2)
    #    sprintf("%.2f", val).to_f
  end
  
  # Excepts a activities hash (matter_tasks and zimbra_activities). Please make sure that you include deleted activities as well. 
  # This is to ensure that any deleted instance of a series does not get filtered out by the scope that is added by acts_as_paranoid
  # Deleted instances are required to get exception dates (just like edited instances are required) so that activities for such
  # exceptions are not created again.
  
  # The method basically iterates through all the activities and depending on the type of activity (for ex: appointment and of type repeat 
  # a date array is created depending on parameters like repeat frequency etc). 
  # The method later calls the get_alert_tasks and get_alert_appointments before getting into the sorting algo and finally returning back the array
  def get_task_and_appointment_series(activities, from_matter = false, parameter=nil)
	   parameter =params if parameter.blank?

    unless from_matter
      parameter[:date_start] = parameter[:start_date] if parameter[:start_date].present?
      parameter[:date_end] = parameter[:end_date] if parameter[:end_date].present?
    end
    if parameter[:date_start].blank?
      today_date = Time.zone.now.to_date
      parameter[:date_start] = today_date
      parameter[:date_end] = today_date + 7
    end
    if parameter[:date_end].blank?
      if parameter[:date_start].blank?
        parameter[:date_end] = Time.zone.now.to_date + 7
      else
        parameter[:date_end] = Date.parse(parameter[:date_start].to_s) + 7
      end
    end
    parameter[:date_start] = Date.parse(parameter[:date_start].to_s)
    parameter[:date_end] = Date.parse(parameter[:date_end].to_s)
    if activities.present?
      appt_data, task_data = [], []
      activities.each do |activity|        
        in_upcoming = false

        if activity.present?
          is_matter = activity.has_attribute?(:matter_id)
          upcoming_setting = set_upcoming_value(activity, is_matter)
          if activity.category.eql?('appointment')
            contact = (is_matter ? activity.matter.contact : nil)
            account = (is_matter ? ((contact.accounts[0] ? activity.matter.contact.accounts[0].name : "") unless contact.accounts.blank?) : nil)
            assigned_to_user_name = (is_matter ? activity.lawyer_name : activity.user_name )
            created_by_user = (is_matter ? activity.created_by_user_id : activity.assigned_to_user_id)
            is_no_end_repeat = false
            count = nil
            start_date_arr, end_date_arr = [], []
            is_repeat = false
            has_multiple_entries = activity.category.eql?("appointment") && activity.repeat.present?
            #&& activity.task_id.blank?
            if has_multiple_entries
              is_repeat = true
              unless activity.occurrence_type.blank? or (activity.count.blank? and activity.until.blank?)
                count = activity.task_count_instances
              else
                is_no_end_repeat =true
                custom_days = upcoming_setting.setting_value.to_i
                if parameter[:task_type]=="upcoming"
                  parameter[:date_end] = Date.parse((today_date + custom_days.days).to_s) if parameter[:date_end].blank?
                  count = activity.task_count_for_no_end_repeat(parameter[:date_end])
                else                  
                  parameter[:date_end] = Date.parse((Time.zone.now.to_date + custom_days.days).to_s) if parameter[:date_end].blank?
                  count = activity.task_count_for_no_end_repeat(parameter[:date_end])
                end
              end
              start_date_arr = activity.instance_start_date(count) if count > 1
              end_date_arr = activity.instance_end_date(count) if count > 1
            end

            in_upcoming = check_upcoming_activity(activity, upcoming_setting, is_repeat, start_date_arr, is_matter)
           
            appt_data << {
              :activity_id => activity.id,
              :activity_name => activity.name,
              :activity_category => activity.category,
              :activity_repeat => is_repeat,
              :activity_is_matter => is_matter,
              :activity_matter => (is_matter ? activity.matter : nil),
              :activity_matter_id => (is_matter ? activity.matter_id : nil),
              :activity_matter_name => (is_matter ? activity.matter.name : nil),
              :activity_no_end_repeat => is_no_end_repeat,
              :activity_count => count,
              :activity_start_date => activity.start_date,
              :activity_end_date => activity.end_date,
              :activity_contact => contact,
              :activity_account_name => account,
              :activity_user_name => assigned_to_user_name,
              :activity_created_by_user_id => created_by_user,
              :activity_start_date_array => start_date_arr,
              :activity_end_date_array => end_date_arr,
              :activity_in_upcoming => in_upcoming,
              :activity_upcoming_setting => upcoming_setting,
              :activity_is_instance => false,
              :activity_instance_start_date => nil,
              :activity_instance_end_date => nil
            }
            appt_data.last[:activity] = activity
          else
            task_data << activity if activity.deleted_at.nil?
          end
        end
      end

      @task_todo, task_ovd, task_upc, task_tday = [], [], [], []
      @task_appt, appt_upc, appt_tday = [], [], []
    
      @task_todo, task_ovd, task_tday, task_upc = get_alert_tasks(task_data, from_matter,parameter)
      @task_appt, appt_tday, appt_upc = get_alert_appointments(appt_data,parameter) unless appt_data.blank?

      if parameter[:task_type]=="today"
        @task_todo = task_tday
        @task_appt = appt_tday
      elsif parameter[:task_type]=="overdue"
        @task_todo = task_ovd
      elsif parameter[:task_type]=="upcoming"
        @task_todo = task_upc
        @task_appt = appt_upc
      end
      unless parameter[:column_name].blank?

        if parameter[:dir].blank? || parameter[:dir].eql?("down")
          case parameter[:column_name]
          when "matter_tasks.name"
            @task_appt = @task_appt.sort{|a, b| b[:activity_name].upcase <=> a[:activity_name].upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| b[:activity_name].upcase <=> a[:activity_name].upcase} unless @task_todo.blank?
          when "matter_tasks.start_date"           
            @task_appt = @task_appt.sort{|a, b| Date.parse(b[:activity_instance_start_date_with_time].to_s) <=> Date.parse(a[:activity_instance_start_date_with_time].to_s)} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| Date.parse(b[:activity_start_date].to_s) <=> Date.parse(a[:activity_start_date].to_s)} unless @task_todo.blank?
          when "matter_tasks.end_date"           
            @task_appt = @task_appt.sort{|a, b| Date.parse(b[:activity_instance_end_date_with_time].to_s) <=> Date.parse(a[:activity_instance_end_date_with_time].to_s)} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| Date.parse(b[:activity_end_date].to_s) <=> Date.parse(a[:activity_end_date].to_s)} unless @task_todo.blank?

            #@task_appt = @task_appt.sort{|a, b| Date.parse(a[:activity_instance_end_date].to_s) <=> Date.parse(b[:activity_instance_end_date].to_s)} unless @task_appt.blank?
            #@task_todo = @task_todo.sort{|a, b| Date.parse(a[:activity_end_date].to_s) <=> Date.parse(b[:activity_end_date].to_s)} unless @task_todo.blank?
#          when "matter_tasks.completed_at"
#            @task_todo = @task_todo.sort{|a, b| (a[:activity].completed_at.blank? ? "" : Date.parse(a[:activity].completed_at.to_s)) <=> (b[:activity].completed_at.nil? ? "" : Date.parse(b[:activity].completed_at.to_s))} unless @task_todo.blank?
          when "matters.name"
            @task_appt = @task_appt.sort{|a, b| b[:activity_matter].name.upcase <=> a[:activity_matter].name.upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| b[:activity_matter].name.upcase <=> a[:activity_matter].name.upcase} unless @task_todo.blank?
          when "matter_peoples.name"
            @task_appt = @task_appt.sort{|a, b| b[:activity_contact].name.upcase <=> a[:activity_contact].name.upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| b[:activity_contact].name.upcase <=> a[:activity_contact].name.upcase} unless @task_todo.blank?
          end
        else
          case parameter[:column_name]
          when "matter_tasks.name"
            @task_appt = @task_appt.sort{|a, b| a[:activity_name].upcase <=> b[:activity_name].upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| a[:activity_name].upcase <=> b[:activity_name].upcase} unless @task_todo.blank?
          when "matter_tasks.start_date"
              @task_appt = @task_appt.sort{|a, b| Date.parse(a[:activity_instance_start_date_with_time].to_s) <=> Date.parse(b[:activity_instance_start_date_with_time].to_s)} unless @task_appt.blank?
              @task_todo = @task_todo.sort{|a, b| Date.parse(a[:activity_start_date].to_s) <=> Date.parse(b[:activity_start_date].to_s)} unless @task_todo.blank?
          when "matter_tasks.end_date"
              @task_appt = @task_appt.sort{|a, b| Date.parse(a[:activity_instance_end_date_with_time].to_s) <=> Date.parse(b[:activity_instance_end_date_with_time].to_s)} unless @task_appt.blank?
              @task_todo = @task_todo.sort{|a, b| Date.parse(a[:activity_end_date].to_s) <=> Date.parse(b[:activity_end_date].to_s)} unless @task_todo.blank?
            #@task_appt = @task_appt.sort{|a, b| Date.parse(a[:activity_instance_end_date].to_s) <=> Date.parse(b[:activity_instance_end_date].to_s)} unless @task_appt.blank?
            #@task_todo = @task_todo.sort{|a, b| Date.parse(a[:activity_end_date].to_s) <=> Date.parse(b[:activity_end_date].to_s)} unless @task_todo.blank?
#          when "matter_tasks.completed_at"
#              @task_todo = @task_todo.sort{|a, b| Date.parse(b[:activity].completed_at.to_s) <=> Date.parse(a[:activity].completed_at.to_s)} unless @task_todo.blank?
          when "matters.name"
            @task_appt = @task_appt.sort{|a, b| a[:activity_matter].name.upcase <=> b[:activity_matter].name.upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| a[:activity_matter].name.upcase <=> b[:activity_matter].name.upcase} unless @task_todo.blank?
          when "matter_peoples.name"
            @task_appt = @task_appt.sort{|a, b| a[:activity_contact].name.upcase <=> b[:activity_contact].name.upcase} unless @task_appt.blank?
            @task_todo = @task_todo.sort{|a, b| a[:activity_contact].name.upcase <=> b[:activity_contact].name.upcase} unless @task_todo.blank?
          end
        end        
      else
        new_array = []
        unless @task_appt.blank?
          #@task_appt = @task_appt.sort_by{|a| a[:activity_instance_start_date].to_time}
          if parameter[:dir].blank? || parameter[:dir].eql?("down")
            @task_appt = @task_appt.sort{|a, b| Date.parse(a[:activity_instance_start_date_with_time].to_s) <=> Date.parse(b[:activity_instance_start_date_with_time].to_s)} unless @task_appt.blank?
          else

            @task_appt = @task_appt.sort{|a, b| Date.parse(b[:activity_instance_start_date_with_time].to_s) <=> Date.parse(a[:activity_instance_start_date_with_time].to_s)} unless @task_appt.blank?
          end
          @task_appt.flatten.each do |apt|
            apt[:activity_instance_start_date]=apt[:activity_start_date].to_date if apt[:activity_instance_start_date]==nil
            apt[:activity_instance_end_date]=apt[:activity_end_date].to_date if apt[:activity_instance_end_date]==nil
            if parameter[:date_start]  && apt[:activity_instance_start_date] >= parameter[:date_start].to_date
              new_array << apt
            end
          end
        end
        new_array = new_array.flatten!
        @task_appt = new_array unless new_array.blank?
        if parameter[:dir].blank? || parameter[:dir].eql?("down")
          @task_todo = @task_todo.sort{|a, b| Date.parse(a[:activity_start_date].to_s) <=> Date.parse(b[:activity_start_date].to_s)} unless @task_todo.blank?
        else          
          @task_todo = @task_todo.sort{|a, b| Date.parse(b[:activity_start_date].to_s) <=> Date.parse(a[:activity_start_date].to_s)} unless @task_todo.blank?
        end
      end
      alert_hash = {}      
      alert_hash.merge!("today"=> (task_tday.size + appt_tday.size), "overdue"=> (task_ovd.size), "upcoming"=> (task_upc.size + appt_upc.size))
    end
  end
  
  # Finds out the exception appointments that have a task id present. Task id = id of activity to which it belongs
  # then removes all the deleted appointments since it is no longer required
  # Calls get_total_appointments, get_today_appointments and get_upcoming appointments and returns them
  def get_alert_appointments(appointments,parameter=nil)

    total_data, tday, upc = [], [], []

    unless appointments.blank?
      today_date = Time.zone.now.to_date 
      exception_appointments = appointments.select{|appointment| appointment[:activity].task_id.present?}
      appointments = appointments.select{|appointment| appointment[:activity].deleted_at.blank?}
      total_data = get_total_appointments(appointments, exception_appointments, today_date,parameter)
      tday = get_today_appointments(appointments, exception_appointments, today_date,parameter)
      upc = get_upcoming_appointments(appointments, exception_appointments, today_date,parameter)

      [total_data, tday, upc]
    end
  end

  def get_alert_tasks(activities, from_matter,parameter)
    task_data, ovd, tday, upc = [], [], [], []
 
    unless activities.blank?
      activities.each do |activity|
        if activity.category.eql?('todo')
          is_matter = activity.has_attribute?(:matter_id)
          upcoming_setting = set_upcoming_value(activity, is_matter)
          contact = (is_matter ? activity.matter.contact : nil)
          account = (is_matter ? ((contact.accounts[0] ? activity.matter.contact.accounts[0].name : "") unless contact.accounts.blank?) : nil)
          assigned_to_user_name = (is_matter ? activity.lawyer_name : activity.user_name )
          created_by_user = (is_matter ? activity.created_by_user_id : activity.assigned_to_user_id)
          in_upcoming = check_upcoming_activity(activity, upcoming_setting, false, [], is_matter)
          task_data << {
            :activity_id => activity.id,
            :activity_name => activity.name,
            :activity_category => activity.category,
            :activity_is_matter => is_matter,
            :activity_matter => (is_matter ? activity.matter : nil),
            :activity_matter_id => (is_matter ? activity.matter_id : nil),
            :activity_matter_name => (is_matter ? activity.matter.name : nil),
            :activity_start_date => activity.start_date.to_date,
            :activity_end_date => activity.end_date.to_date,
            :activity_contact => contact,
            :activity_account_name => account,
            :activity_user_name => assigned_to_user_name,
            :activity_created_by_user_id => created_by_user,
            :activity_in_upcoming => in_upcoming,
            :activity_upcoming_setting => upcoming_setting
          }
          task_data.last[:activity] = activity
          if is_matter
            if activity.overdue?
              ovd << task_data.last
            elsif activity.today?
              tday << task_data.last
            elsif activity.upcoming?
              upc << task_data.last
            end
          else
            if activity.activity_overdue?
              ovd << task_data.last
            elsif activity.activity_today?
              tday << task_data.last
            elsif activity.activity_upcoming?
              upc << task_data.last
            end
          end
        end
      end
    end

    [task_data, ovd, tday, upc]
  end
  
  def get_total_appointments(appointments, exception_appointments, today_date,parameter=nil)
    total_appointments = []
    appointments.each do |appointment|
      unless appointment[:activity_repeat]
      
        if appointment[:activity_start_date].to_date >= parameter[:date_start] and appointment[:activity_start_date].to_date <= parameter[:date_end]
          appointment[:activity_is_instance] = false
          appointment[:activity_instance_start_date] = appointment[:activity_start_date].to_date
          appointment[:activity_instance_start_date_with_time] = appointment[:activity_start_date]
          appointment[:activity_instance_end_date] = appointment[:activity_end_date].to_date
          appointment[:activity_instance_end_date_with_time] = appointment[:activity_end_date]
          total_appointments << appointment
        end
      else
        appointment[:activity_start_date_array].each_with_index do |start_date, idx|
          is_exception = false
          parameter[:date_start] = Date.parse(parameter[:date_start].to_s)
          parameter[:date_end] = Date.parse(parameter[:date_end].to_s)
          if start_date >= parameter[:date_start] and start_date <= parameter[:date_end]
            exception_appt_dates = exception_appointments.collect{|appt|
              appt[:activity].exception_start_date.to_date.to_s if ((appt[:activity].task_id.to_s == appointment[:activity_id].to_s) && (appt[:activity].exception_start_date.to_date == start_date.to_date unless appt[:activity].exception_start_date.blank?))
            }.compact
            #is_exception = exception_appt_dates.include?(start_date.to_s)
            exception_appt_dates.size>0 ? is_exception=true : is_exception=false
            unless is_exception              
              appt = appointment.clone
              appt[:activity_is_instance] = true
              appt[:activity_instance_start_date] = start_date
              appt[:activity_instance_start_date_with_time] = "#{start_date} #{appt[:activity_start_date].strftime("%H:%M:%S")}"
              appt[:activity_instance_end_date] = appt[:activity_end_date_array][idx]
              appt[:activity_instance_end_date_with_time] = "#{appt[:activity_instance_end_date]} #{appt[:activity_end_date].strftime("%H:%M:%S")}"
              total_appointments << appt
            end
          end
        end
      end
      total_appointments = total_appointments.flatten
    end

    total_appointments
  end
  
  # Iterates through the appointments hash to identify between repeat and non repeat ones [For today only]
  # For non repeat appointments the activity_is_instance is set to false
  # For repeat appointments activity_is instance is set to true and instance is created unless the date is an exception
  def get_today_appointments(appointments, exception_appointments, today_date,parameter)
    tday = []
    tday_appointments = appointments.reject{|appt| appt[:activity_start_date].to_date > today_date}
    tday_appointments.each do |appointment|
      is_exception = false
      if (appointment[:activity_start_date].to_date == today_date) or (appointment[:activity_start_date_array].include?(today_date))
        unless appointment[:activity_repeat]
          unless is_exception
            appointment[:activity_is_instance] = false
            appointment[:activity_instance_start_date] = appointment[:activity_start_date].to_date
            appointment[:activity_instance_start_date_with_time] = appointment[:activity_start_date]
            appointment[:activity_instance_end_date] = appointment[:activity_end_date].to_date
            appointment[:activity_instance_end_date_with_time] = appointment[:activity_end_date]
          end
        else
          unless appointment[:activity_start_date_array].blank?
            idx = appointment[:activity_start_date_array].index{|start_date| start_date == today_date}
            # Find exception dates for all appointments that have task_id equal to parent activity's id 
            # and exception start date = start_date_array[idx]
            # It is important to convert the exception_start_date to date format (from datetime)
            exception_appt_dates = exception_appointments.collect{|appt| appt[:activity].exception_start_date.to_date if ((appt[:activity].task_id == appointment[:activity_id]) and (appt[:activity].exception_start_date.to_date == appointment[:activity_start_date_array][idx])) }
            is_exception = exception_appt_dates.include?(appointment[:activity_start_date_array][idx])
            unless is_exception
              #create an instance
              appointment[:activity_is_instance] = true
              appointment[:activity_instance_start_date] = appointment[:activity_start_date_array][idx]
              appointment[:activity_instance_start_date_with_time] = "#{appointment[:activity_instance_start_date]} #{appointment[:activity_start_date].strftime("%H:%M:%S")}"
              appointment[:activity_instance_end_date] = appointment[:activity_end_date_array][idx]
              appointment[:activity_instance_end_date_with_time] = "#{appointment[:activity_instance_end_date]} #{appointment[:activity_end_date].strftime("%H:%M:%S")}"
            end
          end
        end
        unless appointment.blank?
          if appointment[:activity_instance_start_date]==Time.zone.now.to_date
            tday << appointment
          end
        end
      end
    end
    tday = tday.flatten

    tday
  end
  
  # Iterates through the appointments hash to identify between repeat and non repeat ones [For upcoming only]
  # For non repeat appointments the activity_is_instance is set to false
  # For repeat appointments activity_is instance is set to true and instance is created unless the date is an exception
  def get_upcoming_appointments(appointments, exception_appointments, today_date,parameter)
    upc = []
    exception_appt_dates = exception_appointments.collect{|a| a[:activity].exception_start_date.to_date unless a[:activity].exception_start_date.nil?}
    appointments.each do |appointment|
      is_exception = false
      if appointment[:activity_in_upcoming]
        upcoming_setting = appointment[:activity_upcoming_setting]
        custom_days = upcoming_setting.setting_value.to_i
        upcoming_dates = []
        unless appointment[:activity_repeat]
          unless is_exception
            if appointment[:activity_start_date].to_date>Time.zone.now.to_date
              appointment[:activity_is_instance] = false
              appointment[:activity_instance_start_date] = appointment[:activity_start_date]
              appointment[:activity_instance_start_date_with_time] = appointment[:activity_start_date]
              appointment[:activity_instance_end_date] = appointment[:activity_end_date]
              appointment[:activity_instance_end_date_with_time] = appointment[:activity_end_date]
              upc << appointment
            end
          end
        else
          appointment[:activity_start_date_array].each do |the_date|
            if (the_date && the_date > today_date && the_date <= (today_date + custom_days.days))
              exception_appt_dates = exception_appointments.collect{|appt| appt[:activity].exception_start_date.to_date if appt[:activity].exception_start_date && ((appt[:activity].task_id == appointment[:activity_id]) and (appt[:activity].exception_start_date.to_date == the_date))}
              is_exception = exception_appt_dates.include?(the_date)
              upcoming_dates << the_date unless is_exception
              is_exception = false
            end
          end
          unless upcoming_dates.blank?
            upcoming_dates.each do |upc_date|              
              appt = appointment.clone              
              appt[:activity_is_instance] = true
              idx = appt[:activity_start_date_array].index(upc_date)
              appt[:activity_instance_start_date] = appt[:activity_start_date_array][idx]
              appt[:activity_instance_start_date_with_time] = "#{appt[:activity_instance_start_date]} #{appt[:activity_start_date].strftime("%H:%M:%S")}"
              appt[:activity_instance_end_date] = appt[:activity_end_date_array][idx]
              appt[:activity_instance_end_date_with_time] = "#{appt[:activity_instance_end_date]} #{appt[:activity_end_date].strftime("%H:%M:%S")}"              
              if appt[:activity_instance_start_date].to_date>Time.zone.now.to_date
                upc << appt
              end
            end
          end
        end
      end
    end
    upc = upc.flatten

    upc
  end
  
  # Upcoming value is set to 7 if value is not set by user or system for any reason
  def set_upcoming_value(activity, is_matter)
    user_setting = User.current_lawyer.upcoming
    if user_setting.nil?
      user_setting = activity.matter.user.upcoming if is_matter
      if user_setting.nil?
        user_setting = Upcoming.create(:user_id => (is_matter ? activity.matter.employee_user_id : get_employee_user_id), :setting_type => 'Upcoming',:setting_value => 7, :company_id => activity.company_id)
      else
        if user_setting.setting_value.nil?
          user_setting.update_attribute(:setting_value,7)
        end
      end
    end

    user_setting
  end

  def check_upcoming_activity(activity, upcoming_setting, is_repeat, start_date_arr = [], is_matter=false)
    unless activity.blank?
      custom_days = upcoming_setting.setting_value.to_i
      today = Time.zone.now.to_date
      if activity.category.eql?("appointment")
        if activity.start_date.to_date <= (today + custom_days.days)
          if is_repeat            
            start_date_arr.collect{|start_date| return true if (start_date > today and start_date <= (today + custom_days.days))} unless start_date_arr.blank?
            return false
          else
            activity.start_date > today and activity.start_date < (today + custom_days.days)
          end
        else
          return false
        end        
      else
        the_date = activity.end_date.to_date
        if is_matter
          activity.open? && (the_date && the_date > today && the_date <= (today + custom_days.days))
        else
          activity.activity_open? && (the_date && the_date > today && the_date <= (today + custom_days.days))
        end
      end
    end
  end


  def send_data_from_reports(report_type, pdf_file, xls_file, email,report_name)
      if report_type.eql?('pdf')    
        send_report(pdf_file, email, report_type, report_name)
      elsif report_type.eql?('Xls')
        send_report(xls_file, email, report_type, report_name)
      end

    render :update do |page|
      flash[:notice] =  "Mail sent succsessfully"
      page << "tb_remove();"
      page << "window.location.reload();"
      page << "jQuery('#loader').hide();"
    end
  end

  # sending an report attachment by Email
  def get_expense_type_and_activity_types(company)
    arr = company.expense_types.collect {|v| [v.id,v.alvalue ] }.sort{|a,b| a[1] <=> b[1]}
   expense_types = ActiveSupport::OrderedHash[arr].to_json
   activity_types = {}
   current_company.company_activity_types.collect {|v| activity_types.merge!(v.id=>v.alvalue) }
   activity_types = activity_types.to_json
   [expense_types,activity_types]
  end

   def send_mail_task_update(user, task)
     LiviaMailConfig::email_settings(user.company)
      mail = Mail.new()
      mail.from = get_from_email_for_notification_alerts
      mail.subject = "Task Status"
      mail.body = "Task Name : #{task.name} <br/> Task Status : Complete"
      mail.to = user.email
      mail.deliver
   end

   #used for the liquid methods in campaign and campaign_members
   def format_full_name( salutation = "", f_name = "", m_name = "", l_name = "", n_name = "" ,format = nil)
     salutation = salutation + " " if salutation.present?
     #   f_name = f_name + " " if f_name.present?
     m_name = m_name + " " if m_name.present?
     l_name = l_name + " " if l_name.present?
     unless n_name.present?
       n_name = f_name
     end

     if format == "formal"
       salutation.to_s  + l_name.to_s + f_name.to_s
     elsif format == "informal"
       n_name = f_name unless n_name.present?
       salutation.to_s + l_name.to_s + n_name.to_s
     end
   end

   def one_tenth_timediffernce(minutesDifference)
     diff = (minutesDifference.to_i).divmod(60)
     return final = (minutesDifference.to_f)/60.0 if diff[1]== 0
     return final = (diff[0] + 1).to_f if diff[1] > 54
     reminder = diff[1] % 60
     if reminder!=0
       diff1 = (diff[1].to_i).divmod(6)
       return final = (minutesDifference.to_f)/60.0 if diff1[1]==0
       first = diff[0].to_i;
       second = diff1[0].to_i;
       second = second + 1;
       final = first.to_s + "." + second.to_s

       final.to_f
     end
   end


  def one_hundredth_timediffernce(minutesDifference)
    final = (minutesDifference.to_f/60.0)
    ("%0.2f"%final).to_f
  end
   
 end
