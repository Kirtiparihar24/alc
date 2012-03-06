module ZimbraActivitiesHelper

  def activities_completion_status(activity)
    if activity.activity_completed?
      return %!<span style="color:green;">Completed</span>!.html_safe!
    elsif activity.activity_overdue?
      return %!<span class="red_text">Overdue</span>!.html_safe!
    elsif activity.activity_open?
      return %!<span style="color:black;">Open</span>!.html_safe!
    end
  end

end
