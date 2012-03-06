module OpportunitiesHelper

  # Sidebar checkbox control for filtering opportunities by stage.
  #----------------------------------------------------------------------------
  def opportunity_stage_checbox(stage, count)
    checked = (session[:filter_by_opportunity_stage] ? session[:filter_by_opportunity_stage].split(",").include?(stage.to_s) : count > 0)
    check_box_tag("stage[]", stage, checked, :onclick => remote_function(:url => { :action => :filter }, :with => %Q/"stage=" + $$("input[name='stage[]']").findAll(function (el) { return el.checked }).pluck("value")/))
  end

  def formatString(s)
    unless s.nil?
      s = s.split('_')
      s = s.collect {|a| a.try(:capitalize)}
      s = s.join(' ')
    end
  end

  def defIfNil(a, d)
    unless a.nil?
      a
    else
      d
    end
  end

  def floatIfNil(a)
    unless a.nil?
      a.to_f.fixed_precision(2)
    end
  end

  def lawyer_opportunity_followup(cid, eid)
    @lawyer_opportunity_followup ||=Opportunity.my_followup_open_opportunities(cid, eid)
  end

  def lawyer_opportunity_followup_overdue(cid, eid)
    Opportunity.my_followup_overdue_open_opportunities(cid, eid)
  end

  def lawyer_opportunity_followup_today(cid, eid)
    Opportunity.my_followup_todays_open_opportunities(cid, eid)
  end

  def lawyer_opportunity_followup_upcoming(cid, eid, user_setting)
    Opportunity.my_followup_upcoming_open_opportunities(cid, eid, user_setting)
  end

  def get_close_date(opportunity)
    if opportunity.closes_on
      days=  opportunity.closes_on.to_date - Time.zone.now.to_date

      if opportunity.closes_on.to_date < Time.zone.now.to_date
        "<font color='red'>#{days}</font>".html_safe!
      else
        days
      end
    end
  end

  def get_opportunities_value(opportunities)
    worth= 0
    opportunities.each do |opportunity|
      worth=worth + opportunity.amount.to_f
    end
    return worth
  end
  
end
