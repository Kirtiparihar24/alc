module DashboardHelper
include FusionChartsHelper
include MattersHelper

  def get_dashboard(name)
    DashboardChart.find_by_template_name(name)
  end

  def get_single_dashboard(id)
    CompanyDashboard.first(:conditions=>["(company_id =? and employee_user_id=? and dashboard_chart_id=#{id} and is_favorite is null)", get_company_id,get_employee_user_id])
  end

  def get_manage_dashboard(id)
    CompanyDashboard.first(:conditions=>["(company_id =? and employee_user_id=? and dashboard_chart_id=#{id} and is_favorite is null)", get_company_id,get_employee_user_id])
  end

  def get_details(name,fav_id='',closed_opportunities='')
    @title,@dates,@sub_caption,@overdue_task,@open_task,@today_task='',['',''],'','',''
    @dates[1]=Time.zone.now.to_date.end_of_month if closed_opportunities == "closed_opportunities"
    @dates[1]= Time.zone.now.to_date if closed_opportunities == "active_inactive"
    @dates[0]= @dates[1].years_ago(1) if closed_opportunities == "active_inactive"
    @charts_info = get_dashboard(name)
    @parameters = @charts_info.parameters
    if fav_id and fav_id != ""
      @manageobj = CompanyDashboard.find(fav_id)
    else
      @manageobj = get_manage_dashboard(@charts_info.id)
    end
    @threshold= @charts_info.defult_thresholds if @charts_info.defult_thresholds
    if @manageobj
      if @manageobj.parameters
        @parameters = @manageobj.parameters
        @sub_caption = duration_dates(@parameters,@dates,@sub_caption)
        @threshold= @manageobj.thresholds if @manageobj.thresholds
        @today_task="today" if @parameters["Today-Tasks"]=="today"
        @overdue_task="overdue" if @parameters["overdue"]=="overdue"
        @open_task="open_task" if @parameters["open_task"]=="open_task"
        @title = @manageobj.favorite_title if @manageobj.favorite_title
      end
    end
  end

  def completed_by(task_obj,today_tasks,open_tasks,over_due,today_task='',overdue_task='',open_task='')
    thash = lawyer_view_all_matter_tasks2(current_company.id,get_employee_user_id,'Task')
    today_tasks  = thash['today']
    over_due = thash['overdue']
    open_tasks = thash['upcoming']
    return [today_tasks, over_due, open_tasks]
  end


  def duration_dates(parameters,dates,sub_caption)
    today=Time.zone.now.to_date
    if parameters[:duration] == "1months"
      dates[0]=today.months_ago(0).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "(last 1 month)"
    elsif parameters[:duration] == "2months"
      dates[0]=today.months_ago(1).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "(last 2 month)"
    elsif parameters[:duration] == "3months"
      dates[0]=today.months_ago(2).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "(last 3 month)"
    elsif parameters[:duration] == "6months"
      dates[0]=today.months_ago(5).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "(last 6 months)"
    elsif parameters[:duration] == "12months"
      dates[0]=today.months_ago(11).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "(last 1 year)"
    elsif parameters[:duration] == "9months"
      dates[0]=today.months_ago(8).beginning_of_month
      dates[1]=today.end_of_month
      sub_caption = "( last 9 month )"
    elsif parameters[:duration] == "2weeks"
      dates[0]=today.beginning_of_week-1.week
      dates[1]=today
      sub_caption = "( last 2 Weeks )"
    elsif parameters[:duration] == "4weeks"
      dates[0]=today.beginning_of_week-3.week
      dates[1]=today
      sub_caption = "( last 4 Weeks )"
    elsif parameters[:duration] == "current_week"
      dates[0]=today.at_beginning_of_week
      dates[1]=today.end_of_week
      sub_caption = "( Current Week )"
    elsif parameters[:duration] == 'start_of_year'
      dates[0]=today.at_beginning_of_year
      dates[1]=today.end_of_month
      sub_caption = "( From Start Of Year)"
    elsif parameters[:duration] == '5'
      dates[0]=parameters['"created_date"'] if parameters['"created_date"']
      dates[1]=parameters['"to_date"'] if parameters['"to_date"']
      dates[0]=parameters["'From-Date'"] if parameters["'From-Date'"]
      dates[1]=parameters["'To-Date'"] if parameters["'To-Date'"]
      dates[0]=parameters['"from_date"'] if parameters['"from_date"']
      dates[0]=parameters["'from_date'"] if parameters["'from_date'"]
      dates[1]=parameters["'to_date'"] if parameters["'to_date'"]
      sub_caption="( #{dates[0]} - #{dates[1]})"
    end
    return sub_caption
  end
  
  # Renders a chart from the swf file passed as parameter either making use of setDataURL method or
  # setDataXML method. The width and height of chart are passed as parameters to this function. If the chart is not rendered,
  # the errors can be detected by setting debugging mode to true while calling this function.
  # - parameter chart_swf :  SWF file that renders the chart.
  # - parameter str_url : URL path to the xml file.
  # - parameter str_xml : XML content.
  # - parameter chart_id :  String for identifying chart.
  # - parameter chart_width : Integer for the width of the chart.
  # - parameter chart_height : Integer for the height of the chart.
  # - parameter debug_mode :  (Not used in Free version)True ( a boolean ) for debugging errors, if any, while rendering the chart.
  # Can be called from html block in the view where the chart needs to be embedded.
  def render_chart_html(chart_swf,str_url,str_xml,chart_id,chart_width,chart_height,debug_mode,&block)
    chart_width=chart_width.to_s
    chart_height=chart_height.to_s

    debug_mode_num="0"
    if debug_mode==true
      debug_mode_num="1"
    end

    str_flash_vars=""
    if str_xml==""
      str_flash_vars="chartWidth="+chart_width+"&chartHeight="+chart_height+"&debugmode="+debug_mode_num+"&dataURL="+str_url
    else
      str_flash_vars="chartWidth="+chart_width+"&chartHeight="+chart_height+"&debugmode="+debug_mode_num+"&dataXML="+str_xml
    end

    object_attributes={:classid=>"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"}
    object_attributes=object_attributes.merge(:codebase=>"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0")
    object_attributes=object_attributes.merge(:width=>chart_width)
    object_attributes=object_attributes.merge(:height=>chart_height)
    object_attributes=object_attributes.merge(:id=>chart_id)

    param_attributes1={:name=>"allowscriptaccess",:value=>"always"}
    param_tag1=content_tag("param","",param_attributes1)

    param_attributes2={:name=>"movie",:value=>chart_swf}
    param_tag2=content_tag("param","",param_attributes2)

    param_attributes3={:name=>"FlashVars",:value=>str_flash_vars}
    param_tag3=content_tag("param","",param_attributes3)

    param_attributes4={:name=>"quality",:value=>"high"}
    param_tag4=content_tag("param","",param_attributes4)

    param_attributes5={:name=>"wmode",:value=>"transparent"}
    param_tag5=content_tag("param","",param_attributes5)

    embed_attributes={:src=>chart_swf}
    embed_attributes=embed_attributes.merge(:FlashVars=>str_flash_vars)
    embed_attributes=embed_attributes.merge(:quality=>"high")
    embed_attributes=embed_attributes.merge(:width=>chart_width)
    embed_attributes=embed_attributes.merge(:wmode=>'transparent')
    embed_attributes=embed_attributes.merge(:height=>chart_height).merge(:name=>chart_id)
    embed_attributes=embed_attributes.merge(:allowScriptAccess=>"always")
    embed_attributes=embed_attributes.merge(:type=>"application/x-shockwave-flash")
    embed_attributes=embed_attributes.merge(:pluginspage=>"http://www.macromedia.com/go/getflashplayer")
    embed_tag=content_tag("embed","",embed_attributes)
    concat(content_tag("object","\n\t\t\t\t"+param_tag1+"\n\t\t\t\t"+param_tag2+"\n\t\t\t\t"+param_tag3+"\n\t\t\t\t"+param_tag4+"\n\t\t\t\t"+param_tag5+"\n\t\t\t\t"+embed_tag+"\n\t\t",object_attributes),block.binding)
  end
end
