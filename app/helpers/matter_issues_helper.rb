module MatterIssuesHelper

  # Returns truncated hoverable parent name.
  def show_matter_issue_parent(issue, matter)
    unless issue.parent_id.nil?
      truncate_hover_link(issue.parent_name, 40, edit_matter_matter_issue_path(matter, issue.parent)).html_safe!
    end
  end

  # Returns html for delete link, if sub issues length == 0.
  def matter_issue_delete_link(issue, mtr, oid)
    if issue.sub_issues.length == 0
      matter_matter_issue_path(mtr, issue)
    else
      return 'NO'
    end
  end

  def matter_issue_action_pad_bottom_links(matter_issue)
    %Q{
    <tr>
                <td class="ap_middle_left"><div class="ap_pixel15"></div></td>
                <td style="background: #fff;">
                  <table width="100%" border="1" cellspacing="0" cellpadding="2">
                    <tr>
                      <td colspan="4"><div class="ap_pixel10"></div></td>
                    </tr>
                    <tr>
                      <td width="10%" align="left" valign="middle"><div class="ap_child_action"></div></td>
                      <td width="40%" align="left" valign="middle" nowrap>#{link_to("<span>Link Tasks</span>", "#{get_tasks_risks_facts_matter_matter_issue_path(@matter,matter_issue,:col_type => :matter_tasks,:col_type_ids => :matter_task_ids,:label => 'Task')}&height=350&width=500", :class => "thickbox", :title => "Link Tasks", :name => "Link Tasks") } </td>
                      <td width="10%" align="center" valign="middle"><div class="ap_child_action"></div> </td>
                      <td width="40%" align="left" valign="middle" nowrap>#{link_to("<span>Link Facts</span>", "#{get_tasks_risks_facts_matter_matter_issue_path(@matter,matter_issue,:col_type => :matter_facts,:col_type_ids => :matter_fact_ids,:label => 'Fact')}&height=350&width=500", :class => "thickbox", :title => "Link Facts", :name => "Link Facts") }  </td>
                    </tr>
                    <tr>
                      <td colspan="4"><div class="ap_pixel10"></div></td>
                    </tr>
                    <tr>
                      <td width="10%" align="left" valign="middle"><div class="ap_child_action"></div></td>
                      <td width="40%" align="left" valign="middle" nowrap>#{link_to("<span>Resolve</span>", "#{get_issue_resolve_matter_matter_issue_path(@matter,matter_issue)}?height=350&width=500", :class => "thickbox", :title => "Resolve", :name => "Resolve") }  </td>
                      <td width="10%" align="center" valign="middle"><div class="ap_child_action"></div></td>
                      <td width="40%" align="left" valign="middle">#{matter_issue_delete_link(matter_issue, @matter, get_employee_user_id)}</td>
                    </tr>
                    <tr>
                      <td colspan="4"><div class="ap_pixel10"></div></td>
                    </tr>
                  </table>
                </td>
                <td class="ap_middle_right"><div class="ap_pixel13"></div></td>
              </tr>
              <tr>
                <td valign="top" class="ap_bottom_curve_left"></td>
                <td class="ap_bottom_middle"><div class="ap_pixel13"></div></td>
                <td valign="top" class="ap_bottom_curve_right"></td>
              </tr>
    }
  end

end
