module MatterTasksHelper
  
  # Returns html for matter task delete link, if sub tasks length == 0.
  def matter_task_delete_link(tsk, mtr, uid, frm_cal)
    parent = false
    @parent_tasks.collect{|task| parent = true if task.parent_id == tsk.id } if @parent_tasks
    if parent
      return "NO"
    else
      matter_matter_task_path(mtr, tsk)
    end
  end

  def matter_task_completion_status(matter_task)
    if matter_task.completed
      #return %!<span>Completed</span>!.html_safe!
      return %!<span style="color:green;">Completed</span>!.html_safe!
    elsif matter_task.overdue?
      return %!<span class="red_text">Overdue</span>!.html_safe!
    elsif matter_task.open?
      return %!<span style="color:black;">Open</span>!.html_safe!
    end
  end

  def task_instance_completion_status(matter_task,instance_date)
    if matter_task.completed
      return %!<span style="color:green;">Completed</span>!.html_safe!
    elsif is_overdue?(matter_task,instance_date)
      return %!<span class="red_text">Overdue</span>!.html_safe!
    elsif matter_task.open?
      return %!<span style="color:black;">Open</span>!.html_safe!
    end
  end

  def is_overdue?(matter_task,instance_date)
    day = instance_date.day
    start_time_str = "#{matter_task.start_date.hour}:#{matter_task.start_date.min}:#{matter_task.start_date.sec}"
    date_str = "#{instance_date.year}-#{instance_date.mon}-#{day}"
    if matter_task.is_appointment?
      return Time.zone.parse("'#{date_str} #{start_time_str}'") < Time.zone.now
    else
      return instance_date < Time.zone.now.to_date
    end
  end

  def livia_task_date(task, d)
    if task.category.present? && task.category.eql?("appointment")      
      d.strftime("%m/%d/%Y %H:%M")
    else
      d.strftime("%m/%d/%Y")
    end
  end

  def instance_updated_by_user(instance)
    if instance.updated_by_user_id
      name = User.find(instance.updated_by_user_id).full_name
      return %!<span>Instance was updated on #{livia_date(instance.updated_at)} by #{name}</span>!.html_safe!
    else
      return %!<span>Instance was updated</span>!.html_safe!
    end
  end

  def instance_deleted_by_user(instance)
    unless instance.updated_by_user_id.blank?
      name = User.find(instance.updated_by_user_id).full_name
      return %!<span>Instance was deleted on #{livia_date(instance.deleted_at)} by #{name}</span>!.html_safe!
    else
      return %!<span>Instance was deleted on #{livia_date(instance.deleted_at)}</span>!.html_safe!
    end
  end

  def action_pad_matter_tasks_link(options = {})
    return %Q{
      <tr>
        <td><div class="ap_top_curve_left"></div></td>
          <td width="500" class="ap_top_middle">
          <table width="330" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td colspan="6"><div class="ap_pixel15"></div></td>
            </tr>
            <tr>
              <td width="19" valign="bottom" align="left"><div class="#{options[:edit_path]=="NO" ? 'ap_edit_inactive' : 'ap_edit_active'}"></div></td>
              <td width="79" valign="bottom" align="left">#{options[:edit_path]=="NO" ? "<span class='action_pad_inactive'>Edit</span>" : link_to('Edit', (options[:edit_modal] ? "#" : options[:edit_path]), (options[:edit_modal] ? {:onclick => "tb_show('#{escape_javascript(options[:edit_text])}','#{options[:edit_path]}','')"} : {}))} </td>
              <td width="19" valign="bottom" align="left"><div class="#{options[:deactivate_link].present? ? 'ap_deactivate_active' : (options[:deactivate_path]=="NO" ? 'ap_deactivate_inactive' : 'ap_deactivate_active')}"></div></td>
              <td width="82" valign="bottom" align="left">#{options[:deactivate_link].present? ? options[:deactivate_link] : (options[:deactivate_path]=="NO" ? "<span class='action_pad_inactive'>Delete</span>" : link_to('Delete', options[:deactivate_path], :method => 'delete', :confirm => "Are you sure you want to delete this #{escape_javascript(options[:deactivate_text])}"))}</td>
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
    }
  end
  
end