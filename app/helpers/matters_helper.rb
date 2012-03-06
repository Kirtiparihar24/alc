module MattersHelper

  def check_association(obj)
    confirm=''
    time_entry=nil
    expense_entry=nil
    doc_home=nil
    fin_trans = nil
    fin_acct = nil
    obj.time_entries.each do |time_entry|
      time_entry=time_entry.status #if time_entry.status
    end

    obj.expense_entries.each do |expense_entry|
      expense_entry=expense_entry.status #if expense_entry.status
    end

    obj.document_homes.each do |doc_home|
      doc_home=doc_home if doc_home
    end

    fin_trans = FinancialTransaction.find_all_by_matter_id_and_company_id(obj.id,obj.company_id)
    fin_acct = FinancialAccount.find_all_by_matter_id_and_company_id(obj.id,obj.company_id)

    if time_entry.eql?('Billed') || expense_entry.eql?('Billed')
      msg="This Matter cannot be deleted as it has a Billed Time / Expense entry."
      confirm=''
    elsif time_entry.eql?('Approved') || expense_entry.eql?('Approved')
      msg="This Matter has an Approved Time / Expense entry. Please change the status to Open if you want to delete this Matter."
      confirm=''
    elsif doc_home.present?
      msg="There is/are document/s uploaded in this Matter. Please delete those documents before deleting this Matter"
      confirm=''
    elsif fin_trans.present?
      msg="There is/are transaction/s of Trust Account for this matter. Please delete those Transactions before deleting this Matter"
      confirm=''
    elsif fin_acct.present?
      msg="There is/are Trust Account for this matter. Please delete those Trust Accounts before deleting this Matter"
      confirm=''
    end

    return msg,confirm
   
  end

  def matter_filesize_to_human(size)
    return '0' if size.nil? || size == 0
    units = %w{B KB MB GB TB}
    e = (Math.log(size)/Math.log(1024)).floor
    s = "%.1f" % (size.to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end


  def close_and_reload(page)  
    page << "tb_remove()"
    page << "window.location.reload()"
  end
  
  def format_ajax_errors(model, page, err_div)
    errs = "<ul>" + model.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"    
    page << "jQuery(\"\##{err_div}\").html(\"#{errs}\").fadeIn('slow').animate({opacity: 1.0}, 8000).fadeOut('slow')"    
  end

  # Used for displaying current matter in matter tabs and sub-modules listings.
  def matter_info
  end

  def matter_color(matter)
    if matter.matter_status && matter.matter_status.lvalue.eql?("Open")
      "#3D80B3"
    elsif matter.matter_status && matter_status.lvalue.eql?("Completed")
      "#ff0000"
    end
  end

  def show_matter_contact_account(matter)
    contact = matter.contact
    account = contact.accounts[0]
    if account
      (contact.full_name + " - " + account.name).html_safe!
    else
      (contact.full_name).html_safe!
    end
  end

  def show_credit_amount(matter)
    amt = matter.credit_amount
    if amt < 0
      amt = amt.abs
      return "<span style='color:red'>($ #{number_with_lformat(amt)})</span>".html_safe!
    elsif amt < nil2zero(matter.min_retainer_fee)
      return ("<span style='font-weight:bold;'>$" + number_with_lformat(amt) + " </span>").html_safe!
    else
      return "$ #{number_with_lformat(amt)}".html_safe!
    end
  end


  def show_bill_payment_or_settlement(matter)
    amt = matter.amt_available_for_bill_payment_or_settlement   
    if amt < 0
      amt = amt.abs      
      return "<span style='color:red'>($ #{number_with_lformat(amt)})</span>".html_safe!
    elsif amt < nil2zero(matter.min_retainer_fee)
      return ("<span style='font-weight:bold;'>$" + number_with_lformat(amt) + " </span>").html_safe!
    else
      return "$ #{number_with_lformat(amt)}".html_safe!
    end
  end

  # Returns truncated hoverable parent name.
  def show_matter_parent(matter)
    unless matter.parent_id.nil?
      conditional_edit(matter.parent)
    end
  end

  # Returns html for radios to select my/all matters.
  def radios_for_my_all_matters
    params[:per_page] =(params[:per_page]||25).to_i
    return %Q{
      <table cellspacing="0" cellpadding="0">
        <tr>
          <td><input type="radio" name="myallradio" style="margin:0 5px 0 2px" value="my" id="myallradio1" onclick="getMyAllMatters('MY','#{@matter_status_id}','#{params[:letter]}','#{params[:per_page]}');" #{"checked" if @mode_type.eql?("MY")} /></td>
          <td><label class="mr8">#{t(:my_lead_matters)}</label></td>
          <td>&nbsp;</td>
          <td><input type="radio" name="myallradio" value="my_all" style="margin:0 5px 0 0px" id="myallradio2" onclick="getMyAllMatters('MY_ALL','#{@matter_status_id}','#{params[:letter]}','#{params[:per_page]}');" #{"checked" if @mode_type.eql?("MY_ALL")} /></td>
          <td><label class="mr8">#{t(:my_matters)}</label></td>
          <td>&nbsp;</td>
          <td><input type="radio" name="myallradio" value="all" style="margin:0 5px 0 0px"  id="myallradio3" onclick="getMyAllMatters('ALL','#{@matter_status_id}','#{params[:letter]}','#{params[:per_page]}');" #{"checked" if @mode_type.eql?("ALL")} /></td>
          <td><label>#{t(:all_matters)}</label></td>
        </tr>
      </table>
    }
  end

  # Returns html for radios to select my/all matter tasks.
  def radios_for_my_all_matter_tasks(mid,cat =nil,letter=nil,page=nil)
    cat = (cat == 'appointment') ? true : false

    return %Q!
      <td><input type="radio" name="myallradio" value="my" id="myallradio1" class="mt5" onclick="getMyAllMatterTasks(#{mid},'MY','#{@matter_status}','#{cat}','#{letter}','#{page}');" #{"checked" if @mode_type.eql?("MY")} /></td>
      <td class="mr8"><label>My Activities</label></td>
      <td>&nbsp;</td>
      <td><input type="radio" name="myallradio" value="all" id="myallradio2" class="mt5" onclick="getMyAllMatterTasks(#{mid},'ALL','#{@matter_status}','#{cat}','#{letter}','#{page}');" #{"checked" if @mode_type.eql?("ALL")} /></td>
      <td><label>All Activities</label></td>
    !
  end

  # Return all the matters task that are assigned to the current lawyer.
  def lawyer_my_matter_tasks
    euid = get_employee_user_id
    my_tasks = []
    matters = Matter.team_matters(euid, current_user.company_id)
    matters.each {|e| my_tasks << e.my_matter_tasks(euid)}
    return my_tasks.flatten
  end

  # Return all matter tasks of this lawyer for which complete_by date has gone.
  def lawyer_overdue_matter_tasks
    euid = get_employee_user_id
    overdue_tasks = []
    matters ||= Matter.team_matters(euid, get_company_id)
    matters.each {|e| overdue_tasks << e.overdue_tasks(e.employee_matter_people_id(euid))}
    return overdue_tasks.flatten
  end

  # Return all matter tasks of this lawyer for which complete_by date is today!
  def lawyer_todays_matter_tasks
    euid = get_employee_user_id
    todays_tasks = []
    matters ||= Matter.team_matters(euid, get_company_id)
    matters.each {|e| todays_tasks << e.todays_tasks(e.employee_matter_people_id(euid))}
    return todays_tasks.flatten
  end


  # Return all matter tasks of this lawyer for which complete_by date has not come yet.
  def lawyer_upcoming_matter_tasks
    euid = get_employee_user_id
    upcoming_tasks = []
    matters ||= Matter.team_matters(euid, get_company_id)
    matters.each {|e| upcoming_tasks << e.upcoming_tasks(e.employee_matter_people_id(euid))}
    return upcoming_tasks.flatten
  end

  # Return all matter tasks of this lawyer for which complete_by date has not come yet.
  def lawyer_view_all_matter_tasks
    euid = get_employee_user_id
    view_all_tasks = []
    matters = Matter.team_matters(euid, get_company_id)
    matters.each {|e| view_all_tasks << e.view_all_tasks(e.employee_matter_people_id(euid))}
    return view_all_tasks.flatten
  end

  # Returns client's comments added for all the tasks assigned to the lawyer.
  def lawyer_client_task_comments(matter)
    euid = get_employee_user_id
    #TOD0: this every expensive -- need to rewrite asap - find counts from direct query ---By Dileep
    tasks = []
    unless matter.nil?
      matters = [matter]
    else
      matters = Matter.team_matters(euid, get_company_id)
    end
    matters.each {|e| 
      #This is patch for firm  mananger 
      if(is_access_matter?)
        tasks << e.matter_tasks
      else
        tasks << e.comment_accessible_matter_tasks(euid)
      end
    }
    tasks = tasks.flatten    
    comments = tasks.collect! {|e| e.comments}
    comments = comments.flatten.uniq.find_all {|e| e.title == "MatterTask Client" || e.title=="MatterTask CGC"}
    unread = []
    read = []
    comments.each {|e|
      if e.is_read.nil? or e.is_read == false
        unread << e
      else
        read << e if (e.created_at >= (Time.zone.now-1.day))
      end
    }
    return unread.size+read.size
  end

  def lawyer_client_task_comments2
    euid = get_employee_user_id
    count = Comment.count(:all, :conditions=>["m.deleted_at is null and mt.deleted_at is null and mp.company_id=? and comments.company_id=? and (comments.is_read is null or comments.is_read=false) and mp.employee_user_id=? and commentable_type='MatterTask' and ((mt.assigned_to_matter_people_id=mp.id or mp.additional_priv & 2 = 2 or mp.employee_user_id=m.employee_user_id)  and (mp.start_date is not null and mp.start_date <= '#{Time.zone.now.to_date}' and (mp.end_date is null OR mp.end_date > '#{Time.zone.now.to_date}' ))) and (title='MatterTask Client' OR title='MatterTask CGC')",get_company_id,get_company_id,euid],:joins=>"inner join matter_tasks mt on commentable_id=mt.id inner join matters m on mt.matter_id=m.id inner join matter_peoples mp on m.id=mp.matter_id and mp.employee_user_id=#{get_employee_user_id}")
  end

  # Returns documents uploaded by the client for a matter task.
  # Returns only those documents which are associated with matter task assigned
  # to current login lawyer.
  def lawyer_client_documents(cid,eid)
    date = Time.zone.now.to_date
    matters = User.find(eid).my_all_matters.find(:all,:include=>[:client_document_homes],:conditions=>["matter_peoples.is_active = 't'
              AND (( matter_peoples.end_date >= '#{date}' AND  matter_peoples.start_date <= '#{date}') or ( matter_peoples.start_date <= '#{date}' and  matter_peoples.end_date is null)
              or ( matter_peoples.start_date is null and  matter_peoples.end_date is null))"])
    matters.collect(& :client_document_homes).flatten.uniq.compact.size
  end

  def matter_name_hover(matter,length)
    name = matter.name
    liti = matter.matter_category.humanize
    type = matter.matter_type_id ? ("<b>Type:</b> " + CompanyLookup.find(matter.matter_type_id).lvalue + "<br />") : ''
    parent = matter.parent ? "<b>Parent:</b> #{h(matter.parent.name)}<br />" : ''
    date = livia_date(matter.created_at)
    str = "<b>Matter:</b> #{h(name)}<br />#{parent}<br /><b>Type:</b><i>#{liti}</i><br /><b>Created On:</b> #{date}"
    return %Q{
        <span class="newtooltip">#{truncate(h(matter.name), :length => length)}</span>
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
                 <div class="center-contentTT">
                  #{str}
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

  def matter_name_hover_link(matter,length,url,date)
    name = matter.name
    liti = matter.matter_category.humanize
    type = matter.matter_type_id ? ("<b>Type:</b> " + CompanyLookup.find(matter.matter_type_id).lvalue + "<br />") : ''
    parent = matter.parent ? "<b>Parent:</b> #{matter.parent.name}<br />" : ''
    strlength = name.length
    #added by ganesh Dt.04052011
    #added conditional div for tooltip scrolling
    put_div_begin=''
    put_div_end=''
    put_span=''
    if strlength <90
      put_span="<span class='newtooltip'>"
      put_div_begin= "<div class='center-contentTT'>"
      put_div_end="</div>"
    else
      put_span="<span class='icon_scrollhover'>"
      put_div_begin= "<div style='overflow-y: auto; height: 150px; width: 260px;'><div class='center-contentTT'>"
      put_div_end="</div></div>"
    end  
    str = "<b>Matter:</b> #{h(name)}<br />#{parent}<br/><b>Type:</b><i>#{liti}</i><br /><b>Created On:</b> #{date}"
    return %Q{
            #{put_span}
              #{link_to(truncate(h(matter.name), :length => length), url)}
              <span class="livia_dashboardroller" style="display:none;">#{str}</span>
            </span>
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
                    #{put_div_begin}
                      #{str}
                    #{put_div_end}

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

  # Returns true if the matter people is the lead lawyer in selected matter.
  def is_matter_people_lead_lawyer?(matter, matter_people)
    get_employee_user_id == matter.employee_user_id && [0,matter.company.client_roles.array_hash_value('lvalue','Lead Lawyer','id')].include?(matter_people.role)
  end

  # Returns true if lawyer is lead lawyer in the selected matter.
  def is_lead_lawyer?(matter)
    get_employee_user_id == matter.employee_user_id    
  end

  # Allow edit only if, the role is not expired for the current lawyer.
  def conditional_edit(matter)
    euid = get_employee_user_id
    me ||= MatterPeople.me(current_user.id, matter.id, current_user.company_id)
    if me && (me.expired? && euid != matter.employee_user_id)
      %Q@<a href='javascript:alert("Your role in this matter has expired. Please contact the Lead Lawyer of this matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    elsif me && (me.not_yet_started? && euid != matter.employee_user_id)
      %Q@<a href='javascript:alert("Your role in this matter is from #{me.start_date}. Please contact the Lead Lawyer of this matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    else
      raw(matter_name_hover_link(matter, 48, edit_matter_path(matter), livia_date(matter.created_at)))
    end
  end

  # Allow edit only if, the role is not expired for the current lawyer.
  def conditional_comments_documents(matter, checkexpired)
    euid = get_employee_user_id
    com = current_user.company_id
    client_docs = matter.client_document_homes.find_all{|e| document_accesible?(e, euid,com, matter)}
    client_comments =  checkexpired[1] == "is not related" ? 0 : lawyer_client_task_comments(matter)
    me = checkexpired[0]
    if checkexpired[1]=="is expired"
      commentlink = %Q@<a href='javascript:alert("Your role in this matter has expired. Please contact the Lead Lawyer of this matter.");void(0);'>#{client_docs.size}</a>@.html_safe!
      doclink = %Q@<a href='javascript:alert("Your role in this matter has expired. Please contact the Lead Lawyer of this matter.");void(0);'>#{client_comments}</a>@.html_safe!
    elsif checkexpired[1] =="is not started"
      commentlink = %Q@<a href='javascript:alert("Your role in this matter is from #{me.start_date}. Please contact the Lead Lawyer of this matter.");void(0);'>#{client_docs.size}</a>@.html_safe!
      doclink = %Q@<a href='javascript:alert("Your role in this matter is from #{me.start_date}. Please contact the Lead Lawyer of this matter.");void(0);'>#{client_comments}</a>@.html_safe!
    elsif checkexpired[1] == "is not related"
      %Q@<a href='javascript:alert("You are not a part of this Matter. Please Contact the Lead Lawyer if you want to Access this Matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    else
      commentlink = %Q{<a href="#{raw matter_client_docs_matter_path(matter, :height=>200, :width=>800)}"  class="thickbox vtip" title="Client Documents" name="Client Documents">#{client_docs.size}</a>}
      doclink = %Q{<a href="#{raw matter_client_comments_matter_path(matter, :height=>250, :width=>900)}" class="thickbox vtip" title="Client Comments" name="Client Comments">#{client_comments}</a>}
    end    
    if client_docs.count > 0
      a = %Q{<span class="vtip" title="Client Documents">#{commentlink}</span>}
    else
      a = %Q{<span class="vtip" title="Client Documents">0</span>}
    end  
    if client_comments > 0
      #num += 1
      b = %Q{<span class="vtip" title="Client Comments">#{doclink}</span>}
    else
      b = %Q{<span class="vtip" title="Client Comments">0</span>}
    end
    if task_available?
      return "#{a} / #{b}"
    else
      return "#{a}"
    end
  end

  # Allow edit only if, the role is not expired for the current lawyer.
  def conditional_edit_matter(matter, checkexpired,extra_params=nil)
    me = checkexpired[0]
    if checkexpired[1]=="is expired"
      %Q@<a href='javascript:alert("Your role in this matter has expired. Please contact the Lead Lawyer of this matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    elsif checkexpired[1] =="is not started"
      %Q@<a href='javascript:alert("Your role in this matter is from #{me.start_date}. Please contact the Lead Lawyer of this matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    elsif checkexpired[1] == "is not related"
      %Q@<a href='javascript:alert("You are not a part of this Matter. Please Contact the Lead Lawyer if you want to Access this Matter.");void(0);'>#{matter_name_hover(matter,48)}</a>@.html_safe!
    else
      raw(matter_name_hover_link(matter, 48, edit_matter_path(matter,extra_params), livia_date(matter.created_at)))
    end
  end

  def checkmatter_expired(matter)
    euid = get_employee_user_id
    cid = get_company_id
    me ||= MatterPeople.me(euid, matter.id, cid)
    unless is_access_matter?
      if me && (me.expired? && euid != matter.employee_user_id)
        matter_expired = "is expired"
      elsif me && (me.not_yet_started? && euid != matter.employee_user_id)
        matter_expired = "is not started"
      elsif me.nil?
        matter_expired = "is not related"
      else
        matter_expired = "link"
      end
    else
      matter_expired = 'link'
    end
    return [me, matter_expired]
  end

  # Allow edit only if, the role is not expired for the current lawyer.
  def conditional_edit_task(matter_task)
  end

  # Allow edit only if, the role is not expired for the current lawyer.
  def conditional_edit_task_completion(matter_task)
  end
  
  def employee_user_id_from_matter_people_id(mpid)
    MatterPeople.find(mpid).employee_user_id
  end

  def select_matter_status
    current_company.matter_statuses.flatten.sort {|x,y|
      x.lvalue == 'Open' ? -1 : 1
    }
  end

  def lawyer_view_all_matter_tasks3
    current_comp_id = current_company.id
    user_id = get_employee_user_id
    user_set_val = get_upcoming_setting
    if user_set_val.nil?
      user_set_val = 7
    else
      user_set_val = user_set_val.setting_value.nil? ? 7 : user_set_val.setting_value
    end
    today = Time.zone.now.to_date.to_s
    matters = Matter.unexpired_team_matters(user_id, current_comp_id, Time.zone.now.to_date).uniq
    op=Time.zone.formatted_offset.first
    off_set=Time.zone.formatted_offset.gsub(/[+-]/,'')
    matterids = []
    matters.each{|matter| matterids << matter.id}
    mattrppl = MatterPeople.find(:all, :select => :id, :conditions => {:employee_user_id => user_id, :matter_id => (matterids)})
    mpids = []
    matter_tasks = []
    mattrppl.each{|mp| mpids << mp.id}
    if(mpids.size > 0)
      matter_tasks = MatterTask.find_by_sql("select count(*) as cnt,'today' as taskst from matter_tasks m where m.matter_id in (#{matterids.join(',')}) and assigned_to_matter_people_id in (#{mpids.join(',')}) and
      (m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') = date('#{today}')
       OR m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time '#{off_set}') = date('#{today}'))
       and m.deleted_at is NULL
      union
      select count(*) as cnt,'overdue' as taskst from matter_tasks m where m.matter_id in (#{matterids.join(',')}) and  m.deleted_at is NULL and assigned_to_matter_people_id in (#{mpids.join(',')}) and
      ((m.category='appointment' and m.completed=false and m.start_date is not null and date(m.start_date #{op} time '#{off_set}') < date('#{today}'))
       OR (m.category !='appointment' and m.completed=false and m.end_date is not null and date(m.end_date #{op} time '#{off_set}') < date('#{today}')))
      union
      select count(*) as cnt,'upcoming' as taskst from matter_tasks m where m.matter_id in (#{matterids.join(',')}) and assigned_to_matter_people_id in (#{mpids.join(',')}) and
      (m.category='appointment' and m.completed=false and m.start_date is not null and (date(m.start_date #{op} time '#{off_set}') > date('#{today}') and date(m.start_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval)))
      OR m.category !='appointment' and m.completed=false and m.end_date is not null and (date(m.end_date #{op} time '#{off_set}') > date('#{today}') and date(m.end_date #{op} time '#{off_set}')<=(date('#{today}') + cast(#{user_set_val} || ' day' as interval))))
      and m.deleted_at is NULL")
    end
    alert_hash ={}
    if(matter_tasks.size > 0)
      matter_tasks.each do |mt|
        alert_hash.merge!(mt.taskst=>mt.cnt.to_i)
      end
    else
      alert_hash.merge!("today"=>0,"overdue"=>0,"upcoming"=>0)
    end
    return alert_hash
  end

  def task_matter_accounts_name(e)
    unless e.matter.nil?
      return "" if e.matter.contact.nil?
      return "" if e.matter.contact.accounts.empty?
      e.matter.contact.accounts[0] ? e.matter.contact.accounts[0].name : ""
    end
  end

end
