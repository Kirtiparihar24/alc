module CalendarsHelper
  def calendar_day_name(day)
    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][day % 7]
  end

  def calendar_month_name(month)
    ["~", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month]
  end

  def week_time_tracking(time)
    ["12am", "1am","2am","3am","4am","5am","6am","7am","8am","9am","10am","11am","12pm","1pm","2pm","3pm","4pm","5pm","6pm","7pm","8pm","9pm","10pm","11pm"][time]
  end

  def week_heading
    weekstart = @week_start
    weekend = @week_end
    if weekstart.strftime("%Y").to_i == weekend.strftime("%Y").to_i
      if weekstart.strftime("%m").to_i == weekend.strftime("%m").to_i
        startdate = weekstart.strftime("%B %d")
        enddate = weekend.strftime("%d, %Y")
      else
        startdate = weekstart.strftime("%B %d")
        enddate = weekend.strftime("%B %d, %Y")
      end
    else
      startdate = weekstart.strftime("%B %d, %Y")
      enddate = weekend.strftime("%B %d, %Y")
    end
    "#{startdate} to #{enddate}"
  end

  def activity_description(activity, exprd, spanclass, starttime, instance, onclick)
    len = params[:action]=="calendar_month" ? 25 : 28
    name = h(activity.name)
    allow = activity.attribute_present?("matter_id")    
    starttime="12:00 AM" if starttime==" 0:00 AM"
    name = "#{starttime} - #{h(name)}" unless starttime.blank?
    mattername, assignedto = nil, nil
    if activity.category=="appointment"
      at = get_attendees_tooltip(activity)
      unless at.blank?
        attendees = "<b>Attendees:</b> #{h(at)}"
      end
      title = "Edit Appointment"
      startdate = activity.start_date
      enddate = activity.end_date
      date_n_time = "<table><tr><td><b>Date:</b></td><td> #{startdate.to_date} #{startdate.strftime("%l:%M %p")} -</td></tr><tr><td></td><td>#{enddate.to_date} #{enddate.strftime("%l:%M %p")}</td></tr></table>"
    else
      title = "Edit Task"
      date_n_time = "<b>Date:</b> #{activity.start_date.to_date} - #{activity.end_date.to_date} <br />"
    end

    if allow
      mattername = "<b>Matter Name:</b> #{h(activity.matter.name)} <br />"
      assignedto = "<b>Responsibility:</b> #{activity.lawyer_name.blank? ? activity.assigned_to_name : activity.lawyer_name}<br />"
    end
    if instance
      taskname = (link_to truncate(h(name), :length => len), "#this", :onClick => ("#{onclick}"))
    else
      if allow
        taskname = (link_to truncate(h(name), :length => len), "#{edit_matter_activity_calendars_path(:matter_id => activity.matter.id, :id=>activity.id, :height => "400", :width=> "800", :cal_action => params[:action])}", :class=>"thickbox vtip", :title=>title, :name=>title)
      else        
        if activity.assigned_to_user_id==get_employee_user_id
          taskname = (link_to truncate(h(name), :length => len), "#{edit_activity_calendars_path(:id=>activity.id, :height => "400", :width=> "800")}", :class=>"thickbox vtip", :title=>title, :name=>title)
        else
          if activity.mark_as=="PUB"
            taskname = (link_to truncate(h(name), :length => len), "#{edit_activity_calendars_path(:id=>activity.id, :height => "400", :width=> "800")}", :class=>"thickbox vtip", :title=>title, :name=>title)
          else
            taskname = "Day blocked for Task"
          end
          exprd=2
        end
      end
    end    
    
    return %Q{
        <span class="#{spanclass} #{'link_blue' if exprd==1}">#{exprd==0 ? truncate(h(name), :length => len) : taskname}</span>
        <div id="liquid-roundTT" class="tooltip" style="display:none;padding:0;margin:0;">
         	<table width="100%" border="1" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10" style="padding:0;margin:0;"><div class="top_curve_left"></div></td>
              <td width="278" style="padding:0;margin:0;"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12" style="padding:0;margin:0;"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td class="center_left" width="10" style="padding:0;margin:0;"> <div class="ap_pixel1"></div></td>
              <td width="278" style="padding:0;margin:0;" align="left">
                 <div class="center-contentTT" style="text-align:left">
                  <b>Name:</b> #{h(activity.name)} <br /> #{mattername}
                  #{date_n_time}
                  #{assignedto} #{attendees}
                </div>
              </td>
              <td class="center_right" width="12" style="padding:0;margin:0;"><div class="ap_pixel1"></div></td>
            </tr>
            <tr>
              <td valign="top" width="10" style="padding:0;margin:0;"><div class="bottom_curve_left"></div></td>
              <td width="278" style="padding:0;margin:0;"><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
              <td valign="top" width="12" style="padding:0;margin:0;"><div class="bottom_curve_right"></div></td>
            </tr>		
          </table>
        </div>
    }
  end

  def activity_description_with_hash(activity, exprd, spanclass, starttime, instance, onclick)    
    len = params[:action]=="calendar_month" ? 25 : 28
    name = h(activity[:activity_name])
    allow = activity[:activity_matter].present?
    starttime="12:00 AM" if starttime==" 0:00 AM"
    name = "#{starttime} - #{h(name)}" unless starttime.blank?
    mattername, assignedto = nil, nil

    if activity[:activity_category]=="appointment"
      at = get_attendees_tooltip(activity[:activity])
      unless at.blank?
        attendees = "<b>Attendees:</b> #{h(at)}"
      end
      title = "Edit Appointment"
      startdate = activity[:activity].start_date #activity[:activity_instance_start_date]
      enddate = activity[:activity].end_date #activity[:activity_instance_end_date]
      date_n_time = "<table><tr><td><b>Date:</b></td><td> #{activity[:activity_instance_start_date].to_date} #{startdate.strftime("%l:%M %p")} -</td></tr><tr><td></td><td>#{activity[:activity_instance_end_date].to_date} #{enddate.strftime("%l:%M %p")}</td></tr></table>"
    else
      title = "Edit Task"
      date_n_time = "<b>Date:</b> #{activity[:activity].start_date.to_date} - #{activity[:activity].end_date.to_date} <br />"
    end

    if allow
      mattername = "<b>Matter Name:</b> #{h(activity[:activity_matter].name)} <br />"
      assignedto = "<b>Responsibility:</b> #{activity[:activity].lawyer_name.blank? ? activity[:activity].assigned_to_name : activity[:activity].lawyer_name}<br />"
    end
    if instance
      taskname = (link_to truncate(h(activity[:activity_name]), :length => len), "#this", :onClick => ("#{onclick}"))
    else
      if allow
        taskname = (link_to truncate(h(activity[:activity_name]), :length => len), "#{edit_matter_activity_calendars_path(:matter_id => activity[:activity_matter].id, :id=>activity[:activity].id, :height => "400", :width=> "800", :cal_action => params[:action])}", :class=>"thickbox vtip", :title=>title, :name=>title)
      else
        if activity[:activity].assigned_to_user_id==get_employee_user_id
          taskname = (link_to truncate(h(name), :length => len), "#{edit_activity_calendars_path(:id=>activity[:activity_id], :height => "400", :width=> "800")}", :class=>"thickbox vtip", :title=>title, :name=>title)
        else
          if activity[:activity].mark_as=="PUB"
            taskname = truncate(h(name)) #(link_to truncate(h(name), :length => len), "#", :class=>"thickbox vtip", :title=>title, :name=>title)
          else
            taskname = "Day blocked for Task"
          end
          exprd=2
        end
      end
    end

    return %Q{
        <span class="#{spanclass} #{'link_blue' if exprd==1}">#{exprd==0 ? truncate(h(name), :length => len) : taskname}</span>
        <div id="liquid-roundTT" class="tooltip" style="display:none;padding:0;margin:0;">
         	<table width="100%" border="1" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10" style="padding:0;margin:0;"><div class="top_curve_left"></div></td>
              <td width="278" style="padding:0;margin:0;"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12" style="padding:0;margin:0;"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td class="center_left" width="10" style="padding:0;margin:0;"> <div class="ap_pixel1"></div></td>
              <td width="278" style="padding:0;margin:0;" align="left">
                 <div class="center-contentTT" style="text-align:left">
                  <b>Name:</b> #{h(activity[:activity_name])} <br /> #{mattername}
                  #{date_n_time}
                  #{assignedto} #{attendees}
                </div>
              </td>
              <td class="center_right" width="12" style="padding:0;margin:0;"><div class="ap_pixel1"></div></td>
            </tr>
            <tr>
              <td valign="top" width="10" style="padding:0;margin:0;"><div class="bottom_curve_left"></div></td>
              <td width="278" style="padding:0;margin:0;"><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
              <td valign="top" width="12" style="padding:0;margin:0;"><div class="bottom_curve_right"></div></td>
            </tr>
          </table>
        </div>
    }
  end

  def get_attendees_tooltip(activity)
    attendees = activity.attendees_emails.sub(/[,]/, ' ') if activity.attendees_emails
  end

  def generate_calendar_task_grid(viewname)
    @total_data, @total_app, data, app_data = {}, {}, [], []
    if viewname=="bymatter"
      unless @task_todos.blank?
        @task_todos.group_by(&:matter_id).each do |label, matter_tasks|
          matter_tasks.each do |matter_task|
            data << matter_task
          end
          get_task_and_appointment_series(data)
          @total_data[label] = @task_todo
          data = []
        end
      else
        if params[:matters]
          matters = Matter.find(params[:matters])
          matters.each do |matter|
            data << [matter.id, nil]
          end
          @total_data = data
        end
      end

      unless @appointments.blank?
        @appointments.group_by(&:matter_id).each do |label, matter_tasks|
          matter_tasks.each do |appointment|
            app_data << appointment
          end
          get_task_and_appointment_series(app_data)
          @total_app[label] = @task_appt
          app_data = []
        end
      else
        if params[:matters]
          matters = Matter.find(params[:matters])
          matters.each do |matter|
            app_data << [matter.id, nil]
          end
          @total_app = app_data
        end
      end

    else
      useremail = user_email(@userid)
      mp = params[:people].present? ? @mple : @mtrpeople
      mp.group_by(&:employee_user_id).each do |label, people|
        params[:matter_people] = people.collect{|person| person.id}
        matterappointments, mattertasks =[], []
        matterappointments = ZimbraActivity.zimbra_appt_date_range("appointment", @company.id, @cal_date, [label.to_i], params[:start_date], params[:end_date], useremail, params[:status])
        mattertasks = ZimbraActivity.zimbra_appt_date_range("todo", @company.id, @cal_date, [label.to_i], params[:start_date], params[:end_date], nil, params[:status])
        if can? :manage, MatterTask
          unless params[:matters].blank?
            mattertasks << MatterTask.matter_tasks_date_range("todo", @company.id, @cal_date, @cal_date, params, useremail).flatten
            matterappointments <<  MatterTask.matter_tasks_date_range("appointment", @company.id, @cal_date, @cal_date, params, useremail).flatten

            matterappointments.flatten!
            mattertasks.flatten!
          end
        end
        unless mattertasks.nil?
          mattertasks.each do |matter_task|
            data << matter_task
          end
        end

        unless matterappointments.nil?
          matterappointments.each do |appointment|
            app_data << appointment
          end
        end
        all_data = data + app_data
        @task_todo = nil
        @task_appt = nil
        get_task_and_appointment_series(all_data)
        @total_data[label] = @task_todo
        @total_app[label] = @task_appt
        data = []
        app_data = []
      end
    end
  end
  
  def generate_count(i)
    @counttotaltasks = 0
    send_appointments = []
    if !@task_appt.blank? && @task_appt.count>0
      @task_appt.each do |app|
        appointment = app[:activity]
        appointment_start_date = app[:activity_start_date] #appointment.start_date
        appointment_end_date = app[:activity_end_date] #appointment.end_date
        instance, start_date, end_date = app[:activity_is_instance], false, false
        if (app[:activity_instance_start_date].to_date <= @eachdate and appointment_start_date.strftime("%k").to_i == i.to_i)
          appstarttime = appointment_start_date.strftime('%l:%M %p')
          if app[:activity_instance_end_date].to_date > app[:activity_instance_start_date].to_date
            starttim = (appointment_start_date.strftime("%k").to_i)
            divheight = 1488 - ((starttim*60) + appointment_end_date.strftime("%M").to_i + (starttim*2))
          else
            endtim = (appointment_end_date.to_time - appointment_start_date.to_time)/60
            divheight = endtim + ((endtim/60)*2)
          end
          if(app[:activity_instance_start_date].to_date == @eachdate)
            send_appointments << [app, appstarttime, false, divheight, instance, start_date, end_date]
            @counttotaltasks +=1
          end
        elsif i== 0 and app[:activity_instance_start_date].to_date < @eachdate
          edtm = appointment_end_date.strftime("%k").to_i
          endtm = (edtm*60) + appointment.end_date.strftime("%M").to_i + (edtm*2)
          appstarttime = ""
          if (app[:activity_instance_end_date].to_date > @eachdate)
            send_appointments << [app, appstarttime, "full_day", 1488, instance, start_date, end_date]
            @counttotaltasks +=1
          elsif (app[:activity_instance_end_date].to_date == @eachdate)
            unless endtm==0              
              send_appointments << [app, appstarttime, "ends_here", endtm, instance, start_date, end_date]
              @counttotaltasks +=1
            end
          end        
        end
      end
    end
    @matter_appointments = send_appointments
  end

  def truncate_with_scroll(str, length)
    if str.length > length
      return %Q{
      <div class="icon_calhover">#{truncate(str, :length => length)}</div>
      <div id="liquid-roundTT" class="tooltip" style="display:none; padding:0;margin:0;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10" style="padding:0; margin:0;"><div class="top_curve_left"></div></td>
              <td width="278" style="padding:0; margin:0;"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12" style="padding:0; margin:0;"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td  width="10" class="center_left" style="padding:0; margin:0;"><div class="ap_pixel1"></div></td>
              <td width="278" style="padding:0; margin:0;">
                 <div class="center-contentTT">
                  <div style="overflow:auto; width:100%; height:150px;">#{str}</div>
                </div>
              </td>
              <td width="12" class="center_right" style="padding:0; margin:0;"><div class="ap_pixel1"></div></td>
            </tr>
            <tr>
              <td  width="10" valign="top" style="padding:0; margin:0;"><div class="bottom_curve_left"></div></td>
              <td width="278" style="padding:0; margin:0;"><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
              <td  width="12" valign="top" style="padding:0; margin:0;"><div class="bottom_curve_right"></div></td>
            </tr>
          </table>
        </div>
      }
    else
      return %Q{ #{str} }
    end
  end

  def has_multiple_entries(appointment)
    appointment.category.eql?("appointment") && !appointment.repeat.blank? && appointment.task_id.blank?
  end

  def user_email(userid)
    User.find(userid).email
  end

  def appointments_action_pad(options = {})
    %Q{
      <div class="icon_action mt3"><a href="#"></a></div>
      <div id="liquid-roundAP" class="tooltip" style="display:none;">
        <!--Icon table strt here -->
        <table width="100%" border="1" cellspacing="0" cellpadding="0">
         <tr>
        <td><div class="ap_top_curve_left"></div></td>
          <td width="500" class="ap_top_middle">
          <table width="330" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td colspan="6"><div class="ap_pixel15"></div></td>
            </tr>
            <tr>
              <td width="19" valign="bottom" align="left"><div class="#{options[:edit_path]=="NO" ? 'ap_edit_inactive' : 'ap_edit_active'}"></div></td>
              <td width="79" valign="bottom" align="left">#{options[:edit_path]=="NO" ? "<span class='action_pad_inactive'>Edit</span>" : link_to('Edit', (options[:edit_modal] ? "#" : options[:edit_path]), (options[:edit_modal] ? {:onclick => options[:edit_instance] ? options[:edit_path] : "tb_show('#{escape_javascript(options[:edit_text])}','#{options[:edit_path]}','')"} : {}))} </td>
              <td width="19" valign="bottom" align="left"><div class="#{options[:deactivate_link].present? ? 'ap_deactivate_active' : (options[:deactivate_path]=="NO" ? 'ap_deactivate_inactive' : 'ap_deactivate_active')}"></div></td>
              <td width="82" valign="bottom" align="left">#{options[:deactivate_link].present? ? options[:deactivate_link] : (options[:deactivate_path]=="NO" ? "<span class='action_pad_inactive'>Delete</span>" :  options[:deactivate_path])}</td>
              <td width="19" valign="bottom" align="left">&nbsp;</td>
              <td width="56" valign="bottom" align="left">&nbsp;</td>
            </tr>
            <tr>
              <td colspan="6"><div class="ap_pixel10"></div></td>
            </tr>
            <tr>
              <td valign="bottom" align="left"><div class="#{options[:comment_path]=="NO" ? 'ap_comment_inactive' : 'ap_comment_active'}"></div></td>
              <td valign="bottom" align="left">#{options[:comment_path]=="NO" ? "<span class='action_pad_inactive'>Comment</span>" : link_to('Comment', "#", :onclick=>"tb_show('#{escape_javascript(options[:comment_title])} #{t(:text_comment)}','#{options[:comment_path]}','')") }</td>
              <td valign="bottom" align="left"><div class="#{options[:document_path]=="NO" ? 'ap_document_inactive' : 'ap_document_active'}"></div></td>
              <td valign="bottom" align="left">#{options[:document_path]=="NO" ? "<span class='action_pad_inactive'>Document</span>" : link_to('Document', options[:document_path], options[:document_modal] ? { :class => "thickbox", :name => (options[:document_header].present? ? options[:document_header] : "")} : {})}</td>
              <td valign="bottom" align="left"><div class="#{options[:history_path]=="NO" ? 'ap_history_inactive' : 'ap_history_active'}"></div> </td>
              <td valign="bottom" align="left">#{options[:history_path]=="NO" ? "<span class='action_pad_inactive'>History</span>" : link_to('History', '#', :onclick=>"tb_show('#{escape_javascript(options[:history_title])}', '#{options[:history_path]}', '' ); return false")}</td>
            </tr>
          </table>
        </td>
        <td><div class="ap_top_curver_right"></div></td>
      </tr>
          <tr>
            <td class="ap_middle_left"><div class="ap_pixel"></div></td>
            <td style="background: #fff;">
              <div class="w100 mt5">
                <div class="fl"  style="width:165px;">
                  <table width="100%" border="0" cellpadding="2" cellspacing="2">
                    <tr>
                      <td width="12%" align="left"><div class="ap_child_action"></div></td>
                      <td nowrap  align="left">#{options[:time_n_expense_or_reject]=="NO" ? "<span class='action_pad_inactive'>Time & Exp</span>" : options[:time_n_expense_or_reject] }</td>
                    </tr>
                  </table>
                </div>
                <div class="fl"  style="width:165px;">
                  <table width="100%" border="0" cellpadding="2" cellspacing="2">
                    <tr>
                      <td width="12%" align="left">#{ '<div class="ap_child_action"></div>' unless options[:mark_as_done]=="NO"}</td>
                      <td nowrap align="left">#{options[:mark_as_done] unless options[:mark_as_done]=="NO"}</td>
                    </tr>
                  </table>
                </div>
                <br class="clear"/>
              </div>              
            </td>
            <td class="ap_middle_right"><div class="ap_pixel13"></div></td>
          </tr>
          <tr>
            <td valign="top" class="ap_bottom_curve_left"></td>
            <td class="ap_bottom_middle"><div class="ap_pixel13"></div></td>
            <td valign="top" class="ap_bottom_curve_right"></td>
          </tr>
        </table>
      </div>
    }
  end

  def task_action_pad(matter_task, matterid)
    can_delete = ((matter_task.created_by_user_id == get_employee_user_id || matter_task.created_by_user_id == current_user.id) || is_access_matter? || is_lead_lawyer?(matter_task.matter)) if matterid
    if matterid
      appointments_action_pad({
          :edit_path => edit_matter_activity_calendars_path(:matter_id => matter_task.matter.id, :id=>matter_task.id, :height => "400", :width=> "800", :cal_action => params[:action]),
          :edit_text => "Edit Matter Activity",
          :edit_modal => true,
          :deactivate_path => can_delete ? ( link_to('Delete', matter_task_delete_link(matter_task, matter_task.matter, get_employee_user_id,'calendars'), :method => 'delete', :confirm => "Are you sure you want to delete this Task?")) : "NO",
          :deactivate_text => " Task?",
          :comment_path => add_comment_with_grid_comments_path(:id=>matter_task.id,:commentable_type=>'MatterTask',:path=> matter_matter_tasks_path(matter_task.matter), :height=> "100", :width => "800"),
          :document_path => edit_matter_matter_task_path(matter_task.matter, matter_task,:from=>request.request_uri),
          :time_n_expense_or_reject => (link_to "<span>New Time Entry</span>", "#{time_expense_entry_matter_matter_task_path(matter_task.matter, matter_task)}?height=300&width=1020&from=calendars", :class => "thickbox", :title => "#{t(:text_new_time_entry)}", :name => "#{t(:text_new_time_entry)}"),
          :mark_as_done => (link_to "<span>Mark as Done</span>", mark_as_done_form_matter_matter_task_path(matter_task.matter, matter_task, :height=>120, :width=>350), :class => "thickbox", :title => "Mark Completed", :name => "Mark Completed"),
          :delete_task_path => "NO"
        })
    else
      appointments_action_pad({
          :edit_path => edit_activity_calendars_path(:id=>matter_task.id, :height => "400", :width=> "800"),
          :edit_text => "Edit Activity",
          :deactivate_path => (matter_task.assigned_to_user_id == current_user.id) ? (link_to('Delete', zimbra_activity_path(matter_task.id, :parms => params), :method => 'delete', :confirm => "Are you sure you want to delete this Task?")) : "NO",
          :deactivate_text => " Task?",
          :comment_path => "NO",
          :document_modal => "NO",
          :document_path => "NO",
          :edit_modal => true,
          :time_n_expense_or_reject => "NO",
          :mark_as_done => (link_to "<span>Mark as Done</span>", mark_as_done_calendars_path(:id=>matter_task.id, :height=>120, :width=> 350), :class=>"thickbox", :title=> "Mark Completed", :name=> "Mark Completed"),
          :delete_task_path => "NO"
        })
    end
  end

  def generate_count_for_monthview(day)
    send_appointments = []    
    get_task_and_appointment_series(@appointments)
    unless @task_appt.blank?
      @task_appt.each do |app|
        if (app[:activity_instance_start_date].to_date <= day)
          if (app[:activity_instance_start_date].to_date == day)
            send_appointments << [app, false, false, false, false]
          elsif (app[:activity_instance_start_date].to_date < day and app[:activity_instance_end_date].to_date >= day)
            send_appointments << [app, false, true, false, false]
          end
        end
      end
    end
    @matter_appointments = send_appointments
  end

  def truncate_hover_link_with_tooltip(activity, length, onclick)
    matter = activity.attribute_present?("matter_id") ? true : false
    assignedto, attendees = nil, nil
    app = activity.category =="appointment"
    str = activity.name.to_s
    startdate = activity.start_date.to_date
    enddate = activity.end_date.to_date
    if matter
      mattername = "<b>Matter Name:</b> #{activity.matter.name} <br />"
      assignedto = "<b>Responsibility:</b> #{activity.lawyer_name.blank? ? activity.assigned_to_name : activity.lawyer_name}<br />"
    end
    if app
      duration = "#{startdate} #{activity.start_date.strftime('%k:%M%p')} - #{enddate} #{activity.end_date.strftime('%k:%M%p')}"
      at = get_attendees_tooltip(activity)
      unless at.blank?
        attendees = "<b>Attendees:</b> #{at}"
      end
    else
      duration = "#{startdate} - #{enddate}"
    end
    if str.length > length
      link = (link_to truncate(str,:length => length), "#this", :onClick => onclick)
    else
      link = (link_to str, "#this", :onClick => onclick)
    end
    return %Q{
        <span class="newtooltip">#{link} </span>
        <div id="liquid-roundTT" class="tooltip" style="display:none;">
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10"><div class="top_curve_left"></div></td>
              <td width="278"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td class="center_left"><div class="ap_pixel1"></div></td>
              <td>
                 <div class="center-contentTT" style="text-align:left">
                  #{str}<br />
                  #{mattername if matter}                  
                  <b>Date:</b> #{duration}<br />
                  #{assignedto} #{attendees}
                </div>
              </td>
              <td class="center_right"><div class="ap_pixel1"></div></td>
            </tr>
            <tr>
              <td valign="top"><div class="bottom_curve_left"></div></td>
              <td><div class="bottom_middle"><div class="ap_pixel12"></div></div></td>
              <td valign="top"><div class="bottom_curve_right"></div></td>
            </tr>
            </table>
        </div>
    }
    
  end

end
