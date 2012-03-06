module ApplicationHelper

  def add_to_contact_link(mem, matter, height, width)
    if mem.contact_id
      "<span class='action_pad_inactive'>#{t(:label_add_to_business_contacts)}</span>"
    else
      link_to(t(:label_add_to_business_contacts),  edit_matter_people_form_matter_matter_people_path(matter, mem, :height=>height, :width=>width,:added_to_business_contacts=>1),:class => "thickbox",:name=> mem.people_type.eql?('client_representative') ? "Edit Client Representative" : "Edit Opposing Legal Team")
    end
  end

  # METHOD used in alerts section for lawyer login
  def get_matter_task_count(current_company_id, user_id)
    if  can? :manage, MatterTask
      matter_tasks_count(current_company_id, user_id)
    end
    zimbra_activities_count(user_id)
    all_activities = []
    all_activities << @all_tasks
    all_activities << @activities
    all_activities = all_activities.flatten
    unless all_activities.blank?
      get_task_and_appointment_series(all_activities, true)
    else
      return alert_hash = {"today"=> 0,"overdue"=>0,"upcoming"=>0}
    end
  end

  # METHOD used in alerts section for lawyer login
  def get_opportunity_followup_overdue(cid, eid)
    get_my_overdue_opportunity(cid, eid)
  end

  # METHOD used in alerts section for lawyer login
  def get_lawyer_opportunity_followup_today(cid, eid)
    getlawyer_opportunity_followup_today(cid, eid)
  end

  # METHOD used in alerts section for lawyer login
  def get_lawyer_opportunity_followup_upcoming(cid, eid, user_setting)
    getlawyer_opportunity_coming_up(cid, eid, user_setting)
  end

  #  livia_mouse_hover
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
  def style_sheet
    browser_arr = ['Firefox','Chrome','Safari','Explorer','Opera']
    css = "Firefox.css"
    browser_arr.each do |brow|
      if((request.user_agent.match(/#{brow}/i)))
        css = brow + ".css"
        break
      elsif((request.user_agent.match(/MSIE/i)))
        css = 'Explorer' + ".css"
      end
    end
    return stylesheet_link_tag(css)
  end

  # Bug #10428 Filter error --resolved , removed extra comments and indentation done.
  # Blow code generate alphabet A-Z with link. Is used in pagination code.
  def searching_by_letter(options)
    letter_selected = options[:letter]
    link=''
    "A".upto("Z") do |l|
      link += letter_selected.eql?(l)? "</li>" + "<li class='active'>"+(link_to(l,:params =>options.merge(:letter =>l)))+ "</li>" : "<li>" + (link_to(l,:params =>options.merge(:letter =>l)))
    end
    0.upto(9) do |l|
      link += letter_selected.to_s.eql?(l.to_s)? "</li>" + "<li class='active'>"+(link_to(l,:params =>options.merge(:letter =>l)))+ "</li>" : "<li>" + (link_to(l,:params =>options.merge(:letter =>l)))
    end
    return %Q{
    #{link}
    }.html_safe!
  end

  #  new_label(obj)
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  def path(controller,folder, link_to_self,matter=nil)
    # the base url for a path is always the same:
    unless folder==nil
      url = url_for(:controller => controller, :action => 'folder_list', :id => nil)
      # start with the deepest folder and work your way up
      if link_to_self
        path = h(folder.name)
        id = folder.id.to_s
        # get the folders until folder doesn't have a parent anymore
        # (you're working your way up now)
        until folder.parent == nil
          folder = folder.parent
          path = truncate_hover(folder.name,18,true) + "/" + path +  '&#187;'
        end

        # Finally, make it a link...
        path = ' <a href="#" onclick= "GetFoldersList('+ id + ',true);return false;">' + h(path) + '&#187;  </a>  '
      else
        path = truncate_hover(folder.name,30,false)
        # get the folders until folder doesn't have a parent anymore
        # (you're working your way up now)
        until folder.parent == nil
          folder = folder.parent
          if controller=='workspaces'
            path =' <a href="#" onclick= "GetFoldersList('+ folder.id.to_s + ',true);return false;">' + truncate_hover(folder.name,18,true) + '&#187; </a> '+ path
          elsif controller=='repositories'
            path =' <a href="#" onclick= "GetFoldersListRepository('+ folder.id.to_s + ',true);return false;">' + truncate_hover(folder.name,18,true) + '&#187; </a> '+ path
          elsif controller=='document_homes'
            path =' <a href="#" onclick= "GetFoldersListMatter('+ folder.id.to_s + ',true,this,' + matter.id.to_s + ');return false;">' + truncate_hover(folder.name,18,true) + '&#187; </a> '+ path
          end
        end
        if controller=='document_homes'
          linkto = "/matters/#{+ matter.id }/#{controller}"
          path = '<a href="'+"#{linkto }"+'">' +" Root Folder" + ' &#187; </a>  ' + path
        else
          path = '<a href="/' + "#{controller}" + '">' +" Root Folder" + ' &#187; </a>  ' + path
        end
      end
    else
      path = 'Root Folder'
    end
    return path.html_safe!
  end

  # Extend the built-in class Hash.
  class Hash
    # Slice a hash, based on given keys' list.
    def slice(*keep_keys)
      h = {}
      keep_keys.each do |key|
        h[key] = fetch(key)
      end
      h
    end
  end

  def same_contacts_show
    if @same_contacts.present?
      unless @exist_but_deleted
        s = %Q!<div class="message_warning_div"><span class="fl">Following contacts already have same email address or phone number:</span><br class="clear"/><ul>!
        @same_contacts.each do|sec|
          s += "<li>#{sec.full_name}- #{sec.email} #{sec.phone}</li>"
        end
        s += "</ul>"
        s += %Q!<input type="checkbox" value="1" name="allow_dup" style="width:15px;" /> Allow duplicate</div>!
      else
        s = %Q!<div class="message_warning_div"><span class="fl">Following contact already exist in the deactivated list  </span><br class="clear"/><ul>!
        @same_contacts.each do|sec|
          s += "<li>#{sec.full_name}- #{sec.email} #{sec.phone}</li>"
          s += "<li>#{sec.accounts[0].try(:name)}</li>" if sec.accounts.present?
        end
        s += "</ul>"
        s += %Q!<input type="hidden" value="#{@deleted_cnt_id}" name="deleted_contact_id" style="width:15px;"/>!
        s += %Q!<input type="checkbox" value="1" name="activate" style="width:15px;" /> Activate</div>!
      end
    end
  end
  
  def same_account_show
    if @account_name.present?
      s = %Q!<div class="message_warning_div"><span class="fl">#{t(:label_Account)} with the name ( #{@account_name.name} ) is existing. Are You sure you want to activate ?</span><br class="clear"/><ul>!
      s += "</ul>"
      s += %Q!<input type="checkbox" value="1" name="allow_activate" style="width:15px;" /> Activate</div>!
    end
  end

  def editable_content(options)
    options[:content] = { :element => 'span' }.merge(options[:content])
    options[:url] = {}.merge(options[:url])
    options[:ajax] = { :okText => "'Save'", :cancelText => "'Cancel'"}.merge(options[:ajax] || {})
    script = Array.new
    script << "new Ajax.InPlaceEditor("
    script << "  '#{options[:content][:options][:id]}',"
    script << "  '#{url_for(options[:url])}',"
    script << "  {"
    script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
    script << "  }"
    script << ")"

    content_tag(
      options[:content][:element],
      options[:content][:text],
      options[:content][:options]
    ) + javascript_tag( script.join("\\n") )
  end

  def local_time(d, id)
    t = d.getgm.strftime("%m/%d/%y %I:%M:%S")
    return %Q{
      <span id="local_time_#{id}">
      </span>
      <script type="text/javascript">
        localTime("#{t}", "local_time_#{id}");
      </script>
    }
  end

  # Below code give the lvalue from Look up table.
  def lookup_lvalue(id)
    v = CompanyLookup.find_by_id(id)
    v.lvalue if v
  end

  # Below code give the lvalue from Look up table.
  def lookuplawfirm_lvalue(id)
    CompanyLookup.find_by_id(id).lvalue
  end

  def tabs
    @current_tab ||= :home
    Setting[:tabs].each { |tab| tab[:active] = (tab[:text].downcase.to_sym == @current_tab) }
  end

  def tabless_layout?
    %w(authentications passwords).include?(controller.controller_name) ||
      ((controller.controller_name == "users") && (%w(create new).include?(controller.action_name)))
  end

  #  inline, div_tag, link_to_delete, link_to_edit, link_to_contact, link_to_inline, arrow_for, show_flash, subtitle
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  def link_to_cancel(url)
    link_to_remote("Cancel", :url => url, :method => :get, :with => "{ cancel: true }")
  end

  def link_to_close(url)
    content_tag("div", "x",
      :class => "close", :title => "Close form",
      :onmouseover => "this.style.background='lightsalmon'",
      :onmouseout => "this.style.background='lightblue'",
      :onclick => remote_function(:url => url, :method => :get, :with => "{ cancel: true }")
    )
  end

  #  jumpbox
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  def styles_for(*models)
    render :partial => "common/inline_styles", :locals => { :models => models }
  end

  def hidden;    { :style => "display:none;"       }; end
  
  # hidden_if, invisible_if, exposed, invisible, visible, highlightable, confirm_delete, confirm_not_delete
  
  def spacer(width = 10)
    image_tag "1x1.gif", :width => width, :height => 1, :alt => nil
  end

  #  time_ago
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  # Ajax helper to refresh current index page once the user selects an option.
  def redraw(option, value, url = nil)
    remote_function(
      :url       => url || send("redraw_#{controller.controller_name}_path"),
      :with      => "{ #{option}: '#{value}' }",
      :condition => "$('#{option}').innerHTML != '#{value}'",
      :loading   => "$('#{option}').update('#{value}'); $('loading').show()",
      :complete  => "$('loading').hide()"
    )
  end  

  #  selected_lawyer_box, link_to_home_tab
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  def show_selected_lawyer
    if is_secretary? && is_lawyer_selected?
      return true
    end
    return false
  end

  def show_header_tabs
    unless controller.controller_name.eql?('livia_secretaries')
      if is_secretary_or_team_manager? && is_lawyer_selected?
        return true
      elsif current_user.end_user && !is_secretary?
        return true
      end
    end
    return false
  end

  def is_lawyer_selected?
    if session[:service_session]
      @sp_session = current_service_session
      true
    else
      false
    end
  end

  def search_in_common_span
    return %Q{
            <span onclick="searchInCommon()" style="cursor:pointer;"><img src="/images/icon_sml_search.gif" alt="Search" title="Search" class="" border="0" /></span>
    }
  end

  #  show_bar_graph, is_that_day, render_matters
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012  

  def home_link
    if is_secretary? or is_team_manager
      link_to("Home", physical_liviaservices_livia_secretaries_url,:class =>controller.controller_name.eql?('livia_secretaries')? 'mr10 ml3 active' : 'mr10 ml3')
    elsif is_admin
      link_to("Home", physical_liviaservices_liviaservices_url)
    elsif is_client
      link_to("Home", matter_clients_url, :class => controller.controller_name.eql?('matter_clients')? 'mr10 ml3 active' : 'mr10 ml3')
    else
      link_to("Home", physical_clientservices_home_index_path, :class => controller.controller_name.eql?('home')? 'mr10 ml3 active' : 'mr10 ml3')
    end
  end
  
  def home_logo_link    
    ccompany = current_company rescue nil
    if ccompany.nil?
      return link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'), root_url
    end
    if ccompany.logo
      companylogo = ccompany.logo.url
      access = (companylogo=="/logos/original/missing.png") ? false : true
      if access
        link_to image_tag(companylogo, :alt=>'', :border=>'0', :width => "154", :height => "51"), root_url
      else
        if current_user
          if is_secretary_or_team_manager?
            link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'), physical_liviaservices_livia_secretaries_url
          elsif is_admin
            link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'),physical_liviaservices_liviaservices_url
          elsif is_client
            link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'),matter_clients_url
          elsif is_liviaadmin
            link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'),livia_admins_path
          else
            link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'), physical_clientservices_home_index_url
          end
        else
          link_to image_tag("admin/logo.png", :alt=>'LOGO',:border=>'0'), root_url
        end
      end
    end
  end

  #  login_link, matters_error_div, get_model_field_details, get_user_id_for_account, manager_link, sortlink_class_new
  #  radios_for_my_all_opportunities, radios_for_my_all_opportunities_manage,
  #  radios_for_my_all_campaigns, radios_for_my_all_campaigns_manage
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012  

  # Generates a column head tag that contains a sort link and is given the
  # appropriate class for the current sorting options.
  def column_sort_link(title, column, paramval, width, align, options = {},stage=nil,column_name=nil,assigned_to=nil,dropdown=nil)
    params.merge!(:paramval=>paramval)
    options.merge!({:letter => params[:letter]}) unless (params[:letter].nil? || params[:letter].empty?) 
    if assigned_to && column==column_name
      content_tag 'th', sort_link_new(title, column, paramval, width, align, options)+ (options[:search_item] ? "<div style='position: absolute; bottom: 0;'>#{eval(dropdown)}</div>" : "</div>"),
        :width => width, :align => align,
        :class => (options[:class].blank? ? "tablesorter" : options[:class])
    elsif stage && column==column_name
      content_tag 'th', sort_link_new(title, column, paramval, width, align, options)+ (options[:search_item] ? "<div style='position: absolute; bottom: 0;'>#{eval(dropdown)}</div>" : "</div>"),
        :width => width, :align => align,
        :class => (options[:class].blank? ? "tablesorter" : options[:class])
    else
      content_tag 'th', sort_link_new(title, column, paramval, width, align, options)+ (options[:search_item] ? "<div style='position: absolute; bottom: 0;'><input type='text' style=#{options[:search_items] ? "width:60px;" : "width:60px;display:none;"} size='5' value='#{params[:search] ? params[:search][column.sub(".","--")] || params[:search][column] : ""}' name='search[#{column.sub(".","--")}]' id= 'search_#{column.sub(".","--")}' /></div></div>" : "</div>"),
        :width => width, :align => align,
        :class => (options[:class].blank? ? "tablesorter" : options[:class])
    end
  end

  def sort_link_new(title, column, paramval, width, align, options = {})
    if options.has_key?(:unless)
      condition = options[:unless]
      options.delete(:unless)
    end    
    #----  IF REQUEST IS FROM THIS ARRAY THEN CHANGE THE ORDER OF SORTING(NUMERIC ORDER IS REVERSE) #7988 ---------
    array_for_numeric = ["opportunities.amount","opportunities.probability","contacts.phone","accounts.phone","matters.parent_id","bill_amount","final_invoice_amt","member_count","responded_date","campaign_member_status_type_id","opportunity","opportunity_amount"]
    new_sort_dir = (column == params[:col] ? (( params[:dir] ==  'up') ? 'down' : 'up') : params[:dir])
    secondary_sort_direction = (column == params[:secondary_sort] && params[:secondary_sort_direction] == 'up') ? 'down' : 'up'
    options.delete(:class)
    display_icon = paramval == column ? "display:none" : "display:block"
    
    icon_primary_up = title+'<span class="icon_sort_up fr mt8" title="Primary Sort"></span>'
    icon_primary_down = title+'<span class="icon_sort_down fr mt8" title="Primary Sort"></span>'
    icon_secondary_up = "<span class='icon_sort_up fr mt8' title='Secondary Sort' style='#{display_icon}'></span>"
    icon_secondary_down = "<span class='icon_sort_down fr mt8' title='Secondary Sort' style='#{display_icon}'></span>"
    icon_primary_up_disabled = title+'<span class="icon_sort_up_disabled fr mt8" title="Primary Sort"></span>'
    icon_primary_down_disabled = title+'<span class="icon_sort_down_disabled fr mt8" title="Primary Sort"></span>'
    icon_secondary_up_disabled = "<span class='icon_sort_up_disabled fr mt8' title='Secondary Sort' style='#{display_icon}'></span>"
    icon_secondary_down_disabled = "<span class='icon_sort_down_disabled fr mt8' title='Secondary Sort' style='#{display_icon}'></span>"
    if paramval == column
      # check if primary sorting is applied on current column
      icon_primary = new_sort_dir.eql?('up')? icon_primary_up : icon_primary_down
    else
      icon_primary = new_sort_dir.eql?('up')? icon_primary_up_disabled : icon_primary_down_disabled
    end
    if params[:secondary_sort] == column
      icon_secondary = params[:secondary_sort_direction].eql?('up')? icon_secondary_down : icon_secondary_up
    else
      icon_secondary = params[:secondary_sort_direction].eql?('up')? icon_secondary_down_disabled : icon_secondary_up_disabled
    end
    
    if params[:controller]=="matters"
      hgt = "55"
    elsif params[:controller]=="opportunities"
      hgt = "60"
    else
      hgt = "40"
    end
    primary_sort = params[:col]
    srchitems = params[:search_items]
    params = {:params =>options.merge(:col => column, :dir => new_sort_dir)}
    link_id = params[:params][:ajax_sort].present? ? "popup_sort" : "simple_sort"
    "<div style='position:relative; #{"height: #{hgt}px" if srchitems}'>#{link_to(icon_primary, params,{:id => link_id}) }" + "<br />#{link_to(icon_secondary, params[:params].merge(:secondary_sort => column, :col => primary_sort, :secondary_sort_direction => secondary_sort_direction ),:id => link_id)}"
  end

  #  find_chlidren_fact, find_chlidren_issue, find_chlidren_research
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
  def facebox_link_num(num, url, title)
    if num > 0
      link_to(num, "#", { :class => "vtip", :onclick => "tb_show('#{title}','#{url}','')", :title => title })
    else
      0
    end
  end

  def contact_search_box(id_name, controller_name, selected_name, selected_id,disable ="false", size=20 )
    if selected_name.blank?
      selected_name=""
    end
    if(controller_name=="matters")
      return %Q{
        <input title="Select Existing" size=#{size} class="textgray" type="text" id="_contact_ctl" value="#{selected_name}", #{disable} />
        <input type="hidden" name="#{id_name}" id="_contactid" value="#{selected_id}">
        <input type="hidden" name="acccon_name" id="_accconname">
        
        <script language="javascript">
          jQuery("#_contact_ctl").autocomplete(
              "/contacts/common_contact_search?ctl=#{controller_name}", {width: 'auto',
              formatResult: function(data, value) {
              return (value.split(",")[0]).split("</span>")[1];
           }
          }).result(function(event, data, formatted){
            jQuery("#_contactid").val(formatted);
            jQuery('#account_id').val(jQuery('#_accountid').val());
            if(formatted.split("Email:").length>1){
              jQuery("#contact_email").val(formatted.split("Email:")[1]);
            }else{
              jQuery("#contact_email").val('');
            }
            jQuery('#matter_client_access').attr('checked', false);
            
             jQuery.ajax({
                type: 'GET',
                url: '/matters/get_contact_accounts',
                data: {
                  'id_val' : formatted.split('span')[1].split('>')[1].split('<')[0]
                }
            });
          }).flushCache();

          jQuery("#_contact_ctl").result(function(event, data, formatted) {
             if(data[0].indexOf("Acc:")>0){
                jQuery("#_accconname").val(((data[0].split(",")[1])).split("Acc:"));
                if(jQuery("#_accconname").val()!=""){
                  var accval=jQuery("#_accconname").val().substring(3,jQuery("#_accconname").val().length);
                  jQuery("#_accconname").val(accval);
                 }
              } else{
                jQuery("#_accconname").val((data[0].split(",")[0]).split("</span>")[1]);
               }
              jQuery("#_contactid").val((data[0].split("</span>")[0]).split(">")[1]);
              jQuery("#matter_contact_id").val((data[0].split("</span>")[0]).split(">")[1]);
            formatSequenceOnChange();
          });
        
        </script>
      }
    else
      return %Q{
      <input title="Search Existing" size=#{size} class="textgray" type="text" id="_contact_ctl" value="#{selected_name}", #{disable} />
      <input type="hidden" name="#{id_name}" id="_contactid" value="#{selected_id}">
      <script language="javascript">
        jQuery("#_contact_ctl").autocomplete(
            "/contacts/common_contact_search?ctl=#{controller_name}", {width: 'auto',
            formatResult: function(data, value) {            
            return (value.split(",")[0]).split("</span>")[1];
	       }
        }).result(function(event, data, formatted){
          jQuery("#_contactid").val(formatted);
        }).flushCache();

        jQuery("#_contact_ctl").result(function(event, data, formatted) {
            jQuery("#_contactid").val((data[0].split("</span>")[0]).split(">")[1]);            
        });
      </script>
      }
    end
  end

  def time_entry_matter_search_box(id_name,id,_matter_ctl,spinner_div,value='',matter_id='', disable ="",size="13")
    return %Q{
      <input class="search" type="text" id="#{_matter_ctl}" title='Search' size="#{size}" value="#{value}" #{disable} autocomplete="off" />
      <!-- <span id="#{spinner_div}_matterSpinner" class="icon_search fr"></span>-->
      <input type="hidden" name="#{id_name}" id="#{id}" value="#{matter_id}" />
    }
  end

  def time_entry_contact_search_box(id_name,id,_contact_ctl,spinner_div,value='',contact_id='',disable ="",size="13")
    return %Q{
      <input class="search" type="text" id="#{_contact_ctl}" title='Search' size="#{size}" value="#{value}" #{disable} autocomplete="off" />
      <!-- <span id="#{spinner_div}_contactSpinner" class="icon_search fr"></span>-->
      <input type="hidden" name="#{id_name}" id="#{id}" value="#{contact_id}" / >
    }
  end

  #These two function only for new time entry form to check
  def new_time_entry_matter_search_box(id_name,id,_matter_ctl,spinner_div,value='',matter_id='', disable ="",size="15")
    return %Q{
      <input class="search check_onblur" type="text" id="#{_matter_ctl}" title='Search' size="#{size}" value="#{value}" #{disable} autocomplete="off" />
      <!--<span id="#{spinner_div}_matterSpinner" class="icon_search fr"></span>-->
      <input type="hidden" name="#{id_name}" id="#{id}" value="#{matter_id}" />
    }
  end

  def new_time_entry_contact_search_box(id_name,id,_contact_ctl,spinner_div,value='',contact_id='',disable ="",size="15")
    return %Q{
      <input class="search check_onblur" type="text" id="#{_contact_ctl}" title='Search' size="#{size}" value="#{value}" #{disable} autocomplete="off" />
      <!--<span id="#{spinner_div}_contactSpinner" class="icon_search fr"></span>-->
      <input type="hidden" name="#{id_name}" id="#{id}" value="#{contact_id}" / >
    }
  end

  def opportunity_search_box(id_name, controller_name, selected_name, selected_id,disable ="false" )
    return %Q{
      <input class="txtbox" type="text" id="_opportunity_ctl" value="#{selected_name}", #{disable} />
      <input type="hidden" name="#{id_name}" id="_opportunityid" value="#{selected_id}">
      <script language="javascript">
        jQuery("#_opportunity_ctl").autocomplete(
            "/opportunities/common_opportunity_search?ctl=#{controller_name}", {width: 'auto',
            formatResult: function(data, value) {            
            return (value.split(",")[0]).split("</span>")[1];
	       }
        }).result(function(event, data, formatted){
          jQuery("#_opportunityid").val(formatted);
        }).flushCache();

        jQuery("#_opportunity_ctl").result(function(event, data, formatted) {
            jQuery("#_opportunityid").val((data[0].split("</span>")[0]).split(">")[1]);            
        });
      </script>
    }
  end

  def campaign_search_box(id_name, controller_name, selected_name, selected_id,disable ="false" )
    return %Q{
      <input class="txtbox" type="text" id="_campaign_ctl" value="#{selected_name}", #{disable} />
      <input type="hidden" name="#{id_name}" id="_campaignid" value="#{selected_id}">
      <script language="javascript">
        jQuery("#_campaign_ctl").autocomplete(
            "/campaigns/common_campaign_search?ctl=#{controller_name}", {width: 'auto',
            formatResult: function(data, value) {           
            return (value.split(",")[0]).split("</span>")[1];
	       }
        }).result(function(event, data, formatted){
          jQuery("#_campaignid").val(formatted);
        }).flushCache();

        jQuery("#_campaign_ctl").result(function(event, data, formatted) {
            jQuery("#_campaignid").val((data[0].split("</span>")[0]).split(">")[1]);            
        });
      </script>
    }
  end

  def matter_search_box(id_name, controller_name, selected_name, selected_id,disable ="false" )
    return %Q{
      <input class="txtbox" type="text" id="_matter_ctl" value="#{selected_name}", #{disable} />
      <input type="hidden" name="#{id_name}" id="_matterid" value="#{selected_id}">
      <script language="javascript">
        jQuery("#_matter_ctl").autocomplete(
            "/matters/common_matter_search?ctl=#{controller_name}", {width: 'auto',
            formatResult: function(data, value) {         
            return (value.split(",")[0]).split("</span>")[1];
	       }
        }).result(function(event, data, formatted){
          jQuery("#_matterid").val(formatted);
        }).flushCache();

        jQuery("#_matter_ctl").result(function(event, data, formatted) {
            jQuery("#_matterid").val((data[0].split("</span>")[0]).split(">")[1]);            
        });
      </script>
    }
  end

  #  add_activate_comment, add_deactivate_comment and truncate_hover_center
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  # BELOW METHOD ADDED FOR STANDARDIZATION.
  # IF ANY CHANGES IN TOOLTIP CAN BE DONE IN BELOW METHOD 
  def new_tooltip_div_code(display_text, hidden_text)
    return %Q{
      <span class="newtooltip">#{display_text}</span>
        <div id="liquid-roundTT" class="tooltip" style="display:none;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td width="10"><div class="top_curve_left"></div></td>
              <td width="278"><div class="top_middle"><div class="ap_pixel11"></div></div></td>
              <td width="12"><div class="top_curve_right"></div></td>
            </tr>
            <tr>
              <td class="center_left"><div class="ap_pixel1"></div></td>
              <td><div class="center-contentTT">#{hidden_text}</div></td>
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

  def truncate_hover_link(str, length, url, onclick=nil)
    strng = h(str)
    if str.length > length
      strng = truncate(h(str), :length => length)
    end
    new_tooltip_div_code(link_to(strng, url , {:onclick => onclick}), h(str))
  end

  #  truncate_hover_link_thickbox, truncate_hover_link_facebox
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
  # Below code will give the mouse hover details info.
  def truncate_hover_contacts_link(str, length, url, title, preference, created_at, department)
    mouse_over_detail_info(str, title, preference, created_at, department)
    strng = h(str)
    if str.length > length      
      strng = truncate(h(str), :length => length)
    end
    new_tooltip_div_code(link_to(strng, url), @conINFO)
  end

  # Below code will return @conINFO to 'truncate_hover_contacts_link' give the mouse hover details info.
  def mouse_over_detail_info(str,title,preference,created_at,department)
    @conINFO = ''
    unless title.blank?
      @conINFO += "<b>Title: </b> #{title.to_s}  <br/>"
    end
    @conINFO += "<b>Name: </b> #{str}  <br/>"
    unless preference.blank?
      @conINFO += "<b>Preference: </b> #{preference.to_s}  <br/>"
    end
    @conINFO += "<b>Created On: </b> #{created_at.strftime('%m/%d/%y %H:%M ').to_s}  <br/>"
    unless department.blank?
      @conINFO += "<b>Department: </b> #{department.to_s}  <br/>"
    end
  end
  
  def truncate_hover(str, length, from_path=false)
    unless str.blank?
      str=(str)
      if str.length > length or from_path
        new_tooltip_div_code(truncate(h(str),:length => length), h(str))
      end
      return str
    else
      return ""
    end
  end

  def truncate_hover_contacts(str,length,title,preference,created_at,department)
    # Below code will give the mouse hover details info.
    mouse_over_detail_info(str,title,preference,created_at,department)
    strng = h(str)
    if str.length > length
      strng = truncate(h(str) ,:length => length)
    end
    new_tooltip_div_code(strng, @conINFO)
  end

  def truncate_hover_link_with_created_at(str, createddate, length, url)
    desc = "<b>Name:</b> #{h(str)} <br /> <b>Created On:</b> #{createddate}"
    new_tooltip_div_code(link_to(truncate(h(str),:length=>length), url), desc)
  end

  #  truncate_hover_with_created_at
  #  commented as was used only for accounts which are deactivated.
  #  As per feature 8879
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
  # This Helper generates the action links(comment,history,edit...) for contact index page-------------------------------
  # parameter : contact ---> its a  contact object
  # author: sanil
  # added mode_type in deactivate contact path for redirect as per selected My contact or All contact url Ganesh 06052011
  def contact_action_links(contact)
    msg,confirm=contact.checkassociation(t(:label_Account))
    if msg.present? && confirm.blank?
      link=link_to('Delete',"#", :onclick=> "alert(#{msg.to_json})")
    elsif msg.blank? && confirm.blank?
      link=link_to('Delete',deactivate_contact_contact_path(contact.id,:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:search_items=>params[:search_items],:col=>params[:col],:dir=>params[:dir],:contact_type =>params[:contact_type]), :confirm => 'Are you sure you want to delete this Contact?')
    elsif confirm.present?
      link=link_to('Delete',deactivate_contact_contact_path(contact.id,:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:search_items=>params[:search_items],:col=>params[:col],:dir=>params[:dir],:contact_type =>params[:contact_type]), :confirm => confirm)
    end
    # As per feature 8879 : ACTIVATE - DEACTIVATE CODE NEEDS TO BE REMOVED
    # THIS CODE INCREASES CONDITIONS WHICH ARE NOT NECESSARY
    return %Q{
      <div class="icon_action mt3"><a href="#"></a></div>
        <div id="liquid-roundAP" class="tooltip" style="display:none;">          
          <table width="100%" border="1" cellspacing="0" cellpadding="0">
            #{action_pad_top_blue_links({:edit_path=>"#{edit_contact_path(contact,extra_parameters(params))}",
    :deactivate_path=>"NO",
    :deactivate_link=>link,
    :deactivate_text => "contact",
    :comment_path=>"#{add_comment_with_grid_comments_path(:id=>contact.id,:commentable_type=>'Contact',:path=> contacts_path,:height=>190,:width=>800)}",
    :comment_title => contact.name,
    :document_path=>"#{upload_document_document_homes_path(:mappable_id => contact.id,:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:contact_type =>params[:contact_type], :from=>'contacts')}",
    :history_path=>"#{history_comments_path(:id=>contact.id,:commentable_type=>'Contact' ,:height=>153,:width=>600)}",
    :history_title => "#{t(:text_contact_history)} #{contact.name}"})}
            <tr>
              <td class="ap_middle_left"><div class="ap_pixel"></div></td>
              <td style="background: #fff;">
                <table width="100%" border="1" cellspacing="0" cellpadding="2">
                  <tr><td colspan="5"><div class="ap_pixel15"></div></td></tr>
                  <tr>
                    <td width="7%" align="left" valign="middle"><div class="ap_child_action"></div></td>
                    <td width="40%" align="left" valign="middle" nowrap> #{link_to('<span>Change Stage</span>', "#", :onclick=>"tb_show('Change Stage for #{escape_javascript(contact.full_name)}', '#{change_status_contact_path(contact.id,:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:q=>params[:q],:col=>params[:col],:dir=>params[:dir],:contact_type =>params[:contact_type],:height=>'190',:width=>'500')}', '' ); return false")} </td>
                    <td width="10%" align="center" valign="middle"><div class="ap_child_action"></div></td>
                    <td width="40%" align="left" valign="middle">#{link_to('<span>Create Opportunity</span>', "#", :onclick => "tb_show('#{t(:text_new_opportunity)}', '#{create_opportunity_contact_path(contact.id)}?height=210&width=520','')")}</td>
                  </tr>
                  <tr><td colspan="5"><div class="ap_pixel10"></div></td></tr>
                  <tr><td colspan="5"><div class="ap_pixel10"></div></td></tr>
                </table>
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
    # As per feature 8879 : ACTIVATE - DEACTIVATE CODE NEEDS TO BE REMOVED
    # THIS CODE INCREASES CONDITIONS WHICH ARE NOT NECESSARY
  end
  
  def truncate_hover_comments(str,length)
    if str.length > length
      new_tooltip_div_code(truncate(h(str),:length => length), str)
    else
      return %Q{
         #{h(str)}
      }
    end
  end
  
  def account_search_box(id_name, controller_name, selected_name, selected_id)
    selected_name.blank? ? title_name= "search" :  title_name = "#{selected_name}"
    return %Q{
      <input class="textgray" type="text" id="_account_ctl" value="#{selected_name}" style="font-size:11px; width:27%; margin-left: 2px;" title="#{title_name}" MAXLENGTH="64"/>
      <input type="hidden" name="#{id_name}" id="_accountid" value="#{selected_id}">
      <script language="javascript">
        jQuery("#_account_ctl").autocomplete(
            "/accounts/common_account_search?ctl=#{controller_name}", {width: 'auto',
            formatResult: function(data, value) {                        
            return (value.split(",")[0]).split("</span>")[1];
	       }
        }).result(function(event, data, formatted){          
          jQuery("#_accountid").val(formatted);                
        }).flushCache();

        jQuery("#_account_ctl").result(function(event, data, formatted) {
            jQuery("#_accountid").val((data[0].split("</span>")[0]).split(">")[1]);            
             controller = "#{controller_name}"
    if(controller == 'matters'){
    jQuery('#account_id').val(jQuery('#_accountid').val());
    jQuery.ajax({
    type: 'GET',
    url: '/matters/get_account_contacts',
    dataType: 'script',
    data: {
    'account_id' : jQuery('#_accountid').val()
    }
    });
    }
         });        
        jQuery("#_account_ctl").focus(function(){
        if (jQuery(this).val()=="Select Existing"){
          jQuery(this).val('');
        }
        });
      </script>
    }
  end  

  def show_errors_on_tb(model, page, err_div)
    errs = "<ul>" + model.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
    errs ="<div class='message_error_div'>"+errs+"</div>"
    page << "jQuery(\"\##{err_div}\").html(\"#{errs}\").fadeIn('slow').animate({opacity: 1.0}, 8000).fadeOut('slow')"
  end

  def generate_spinner_my_favorite_link
    return %Q{
      <div  class ="fl" id="loader" style="display:none;"><img src='/images/loading.gif' /></div>
      <div class="fr">#{link_to "My Favorites","#",{:onClick => "list_favorites()"}}</div>
    }
  end

  # CAN BE SHIFTED TO rpt_helper
  def rpt_selection_helper(radiobtn)
    opts = {}
    if params[:date_selected]
      opts[:style] = "margin:0px"
      opts[:checked] = "checked"
    else
      opts[:style] = "display:none; margin:0px"
      opts[:checked] = ""
    end
    if radiobtn == "All" # bug 9611 # changed from radiobtn != "My"
      opts[:all_checked] = "checked"
    else
      opts[:my_checked] = "checked"
    end
    opts
  end

  def rpt_time_selection_helper
    opts = {}
    if params[:report][:duration] == "range"
      opts[:style] = "display:block; margin:0px"
      opts[:checked] = "checked"
    else
      opts[:style] = "display:none; margin:0px"
      opts[:checked] = ""
    end
    if params[:get_records] == "All" # changed from !params[:get_records] == "My"
      opts[:all_checked] = "checked"
    else
      opts[:my_checked] = "checked"
    end
    opts
  end

  #Shows and hides date range selected called in reports matter-revenue -Ketki 10/5/2011
  def rpt_matter_revenue_helper(radiobtn)
    opts = {}
    if params[:date_selected]
      opts[:style] = "margin:0px"
      opts[:checked] = "checked"
    else
      opts[:style] = "display:none; margin:0px"
      opts[:checked] = ""
    end
    if radiobtn == "Basic"
      opts[:basic_checked] = "checked"
    else
      opts[:detail_checked] = "checked"
    end
    opts
  end

  def radios_for_rpt(opts,name)
    return %Q{
    <div class="fl mt1 mb5">
      <table cellspacing="0" cellpadding="0">
        <tr>
          <td><input type="radio" name="get_records" style="margin:0 5px 0 2px;display:inline" id="get_records" value="My" #{opts[:my_checked]} /></td>
          <td><span class="mr8">My #{name}</span></td>
          <td>&nbsp;</td>
          <td><input name="get_records" type="radio" style="margin:0 5px 0 0;" id="get_records" value="All" #{opts[:all_checked]} /></td>
          <td>All #{name}</td>
        </tr>
      </table>
    </div>
    }
  end
  
  def generate_rpt_fav_link(rpt_type)
    if params[:link_to_remove]
      return %Q{
        #{link_to('<span class="icon_remove fl mr5"></span>',{:action => :destroy_favourite,:id => params[:fav_id]},{:confirm => "Are you sure you want to remove this report from favorite list?", :class => "vtip", :title=>"Remove from favorite"})}
      }
    else
      return %Q{
       #{link_to('<span class="icon_add_to_fav fl mr5"></span>',{:action => :add_favourite,:action_name => params[:action],:report_type => rpt_type,:report_name => @header_opts[:r_name], :height => "130", :width => "300"}.merge(@filters), :class => "thickbox vtip", :title => "#{t(:text_favorites)}", :name => "#{t(:text_favorites)}")}
      }
    end
  end

  def generate_send_email_rpt_link(action)
    return %Q{
         #{link_to('<span class="icon_email fl mr5"></span>',{:action => :send_email_rpt,:action_name => params[:action],:report_name => @header_opts[:r_name], :height => "300", :width => "440"}.merge!(@filters), :class => "thickbox vtip", :title => "#{t(:label_send)} #{t(:text_email)}", :name => "#{t(:label_send)} #{t(:text_email)}")}
    }
  end

  def generate_send_email_doc_link(id,name)
    return %Q{
         #{link_to('Send Mail',{:action => 'send_email_doc',:controller=>"document_homes", :doc_name => name,:id => id, :height => "300", :width => "440"}, :class => "thickbox", :name => "#{t(:label_send)} #{t(:text_email)}")}
    }
  end

  def generate_reports_links(action)
    return %Q{
      #{link_to("<span class='icon_pdf fl mr5'></span>" , {:action => action , :format => 'pdf'}.merge(@filters) , {:popup => true,:class=> "vtip",:title=>"PDF"})}
      #{link_to("<span class='icon_xls fl mr5'></span>" , {:action => action , :format => 'xls'}.merge(@filters) , {:popup => true,:class=> "vtip",:title=>"XLS"})}
    }
  end

  def generate_link(label,msg,confirm,account,lbl_acc=nil)
    if  msg.present? && confirm.blank?      
      link = link_to(label, "#", :onclick=> "alert(#{msg.to_json})")
    elsif msg.blank? && confirm.blank?
      if account.contacts.size > 0        
        link = link_to(label, select_contacts_account_path(account,:col=>params[:col],:dir=>params[:dir],:mode_type=>@mode_type,:account_status=>params[:account_status],:letter=>params[:letter],:per_page=>params[:per_page],:height=>'200',:width=>'400',:delete=>label), :class => "thickboxConfirm", :title => "Select contacts to #{label}", :rel => "Are you sure you want to delete this #{lbl_acc}?")
      else
        link=link_to label,account_path(account,:col=>params[:col],:dir=>params[:dir],:mode_type=>@mode_type,:account_status=>params[:account_status],:letter=>params[:letter],:per_page=>params[:per_page]),:onClick => "return confirm_for_module_record_delete(this,'#{account.name} ','#{lbl_acc}','#{session[:_csrf_token]}')"
      end
    elsif confirm.present?
      if account.contacts.size > 0        
        link = link_to(label, select_contacts_account_path(account,:col=>params[:col],:dir=>params[:dir],:mode_type=>@mode_type,:account_status=>params[:account_status],:letter=>params[:letter],:per_page=>params[:per_page],:height=>'200',:width=>'400',:delete=>label), :class => "thickboxConfirm", :title => "Select contacts to #{label}", :rel => confirm)
      else        
        link = link_to label, account, :onClick => "return confirm_for_module_record_delete(this,'#{account.name} ','#{lbl_acc}','#{session[:_csrf_token]}')"
      end
    end
    return link
  end

  def account_action_links(account)
    msg,confirm = account.checkassociation('deactivate', t(:label_Account))
    link = generate_link('Delete',msg,confirm,account, t(:label_Account))
    # As per feature 8879 : ACTIVATE - DEACTIVATE CODE NEEDS TO BE REMOVED
    # THIS CODE INCREASES CONDITIONS WHICH ARE NOT NECESSARY
    return %Q{
        <div class="icon_action mt3"><a href="#"></a></div>
        <div id="liquid-roundAP" class="tooltip" style="display:none;">          
          <table width="100%" border="1" cellspacing="0" cellpadding="0">
            #{action_pad_top_blue_links({:edit_path=>"#{edit_account_path(:id => account.id,:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:col=>params[:col],:dir=>[:dir],:mode_type=>params[:mode_type])}",
    :deactivate_path=>"NO",
    :deactivate_link=>link,
    :deactivate_text => "account",
    :comment_path=>"#{add_comment_with_grid_comments_path(:id=>account.id,:commentable_type=>'Account',:path=> accounts_path,:height=>210,:width=>800)}",
    :comment_title => account.name,
    :document_path=>"#{upload_document_document_homes_path(:mappable_id => account.id, :from=>'accounts',:per_page=>params[:per_page],:page=>params[:page],:letter=>params[:letter],:search=>params[:search],:mode_type=>params[:mode_type])}",
    :history_path=>"#{history_comments_path(:id=>account.id,:commentable_type=> t(:label_Account),:height=>150,:width=>500)}",
    :history_title => "#{t(:text_account_history)} #{account.name}"})}
            <tr>
              <td class="ap_middle_left"><div class="ap_pixel15"></div></td>
              <td style="background: #fff;">
                <table width="100%" border="1" cellspacing="0" cellpadding="2">
                  <tr>
                    <td colspan="4"><div class="ap_pixel10"></div></td>
                  </tr>
                  <tr>
                    <td width="7%" align="left" valign="middle"><div class="ap_child_action"></div></td>
                    <td width="40%" align="left" valign="middle" nowrap>#{link_to 'Add contact', '#', :onclick=>"tb_show('Add Contact', '#{add_contact_accounts_path(:id=>account.id,:height=>320,:width=>500)}', '' ); return false"}</td>
                    <td width="10%" align="center" valign="middle"><div class="ap_child_action"></div></td>
                    <td width="40%" align="left" valign="middle">#{account.contacts.size>1 ? link_to( t(:text_change_primary_contact), "#", :onclick =>"tb_show('#{t(:text_change_primary_contact)}', '/accounts/change_primary_contact/#{account.id}?height=130&width=300','')") : "<span class='action_pad_inactive'>#{t(:text_change_primary_contact)}</span>" }</td>
                  </tr>
                  <tr>
                    <td colspan="4"><div class="ap_pixel10"></div></td>
                  </tr>
                  <tr>
                    <td width="7%" align="left" valign="middle"><div class="ap_child_action"></div></td>
                    <td width="40%" align="left" valign="middle" nowrap>#{link_to 'Linked Matters', '#', :onclick=>"tb_show('Linked Matters', '#{matters_linked_to_account_account_path(:id=>account.id,:height=>320,:width=>800)}', '' ); return false"}</td>
					<td colspan="2"></td>
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
          </table>
        </div>     
    }
    # As per feature 8879 : ACTIVATE - DEACTIVATE CODE NEEDS TO BE REMOVED
    # THIS CODE INCREASES CONDITIONS WHICH ARE NOT NECESSARY
  end

  def get_company_name(id)
    Company.find(id).name
  end

  def get_employee_name(id)
    Employee.find_by_user_id(id).full_name
  end

  def livia_amount(amt)
    amt = (amt.nil? || amt.blank?) ? 0 : amt
    if amt.to_f < 0
      amt = amt.to_f.abs
      return ("<span style='color:#f00;font-weight:bold;'>(" + number_with_lformat(amt) + ")</span>").html_safe!
    else
      return  number_with_lformat(amt)      
    end
  end

  def negative_amount_braces(amt)
    amt = (amt.nil? || amt.blank?) ? 0 : amt
    if amt.to_f < 0
      amt = amt.to_f.abs
      return "<span style='color:red'>($ #{number_with_lformat(amt)})</span>".html_safe!
    else
      return  number_with_lformat(amt)
    end
  end

  def nil2zero(n)
    n.nil? ? 0 : n
  end

  # livia_date_effect and livia_date_time_effect can be combined
  def livia_date_effect(new_date)
    if new_date
      days= (Time.zone.now.to_date - new_date.to_date).to_i
      weekend = new_date.wday
      add_class = ((weekend == 0) || (weekend == 6))? "weekend" : ""
      
      if days ==0
        return %Q{
            <span style="color: #F88158" class="blink #{add_class}">#{new_date.to_time.strftime('%m/%d/%y') if new_date}</span>
        }
      elsif days > 0
        return %Q{
          <span class="#{add_class} red_text"%>#{new_date.to_time.strftime('%m/%d/%y') if new_date}</span>
        }
      else
        return %Q{
          <span class="#{add_class}">#{new_date.to_time.strftime('%m/%d/%y') if new_date}</span>
        }
      end
    else
      return ''
    end
  end

  def livia_date_time_effect(new_date,follow_up_time)
    if new_date
      days= (Time.zone.now.to_date - new_date.to_date).to_i
      weekend = new_date.wday
      add_class = ((weekend == 0) || (weekend == 6))? "weekend" : ""

      if days ==0
        return %Q{
            <span style="color: #F88158" class="blink #{add_class}">#{new_date.to_time.strftime('%m/%d/%y') if new_date}  #{follow_up_time}</span>
        }
      elsif days > 0
        return %Q{
          <span id=red class="#{add_class} red_text"%>#{new_date.to_time.strftime('%m/%d/%y') if new_date}  #{follow_up_time}</span>
        }
      else
        return %Q{
          <span class="#{add_class}">#{new_date.to_time.strftime('%m/%d/%y') if new_date}  #{follow_up_time}</span>
        }
      end
    else
      return ''
    end
  end

  #  livia_date_with_weekend_effect
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
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
      logger.info("The method used is setDataURL.The URL is " + str_url)
    else
      str_flash_vars="chartWidth="+chart_width+"&chartHeight="+chart_height+"&debugmode="+debug_mode_num+"&dataXML="+str_xml
      logger.info("The method used is setDataXML.The XML is " + str_xml)
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

  # returns no. fomatted with 2 decimal points as well as with delimeter ','.
  def number_with_lformat(number)
    number_with_precision(number.to_f, :precision => 2, :separator => ".", :delimiter => ",")
  end

  def mouseover_text_for_t_and_e(img, created_by, created_on)
    desc = "<b>Created By : </b>#{created_by} <br /> <b>Created On : </b>#{created_on}"
    new_tooltip_div_code(img, desc)
  end

	def javascript(*files)
		content_for(:head) { javascript_include_tag(*files) }
	end

	def stylesheet(*files)
		content_for(:head) { stylesheet_link_tag(*files) }
	end

  def product_licence_action_links(product_licence)
    return %Q{
          #{link_to(image_tag('/images/livia_portal/icon_edit.gif',{:alt =>"Edit", :title=>"Edit", :border => 0, :hspace => "0"}), edit_product_licence_path(:id=>product_licence.id))}
          #{link_to(image_tag('/images/livia_portal/icon_delete.gif',{:alt =>"Delete", :title=>"Delete", :border => 0, :hspace => "0"}), {:controller => "product_licences", :action => "delete", :id=>product_licence.id})}
    }
  end

  # product_licence_assign_action_links #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  # Product Actions links
  def product_action_links(product)
    return %Q{
          #{link_to(image_tag('/images/livia_portal/icon_edit.gif',{:alt =>"Edit", :title=>"Edit", :border => 0, :hspace => "0"}), edit_product_path(:id=>product.id))}
    }
  end

  #  subproduct_action_links, lawfirm_employees_action_links, livia_admim_company_action_links
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012

  def is_lawfirmadmin
    current_user && current_user.role?(:lawfirm_admin)
  end

  def invoices_list_action_links(invoice)
    return %Q{
          #{link_to("Show", {:controller=>'invoices', :action=>'show',:id=>invoice.id})}
          #{(current_user.role? :livia_admin)? "| " + link_to("Delete",{:controller => "invoices", :action => "delete", :id=>invoice.id},{:confirm => 'Are you sure?', :method => :delete}): ""}
          #{(invoice.invoice_amount.to_i <= 0)? "" :(invoice.status.to_s.eql?("Paid") ? "| " + 'Paid' :"| " + (link_to 'Pay',{:controller=>'payments',:action=>'new', :id=>invoice.id}))}
    }
  end

  def payments_list_action_links(payment)
    return %Q{
          #{link_to(image_tag('/images/livia_portal/icon_show.gif',{:alt =>"Show", :title=>"Show", :border => 0, :hspace => "0"}), {:controller=>'payments', :action=>'show',:id=>payment.id})}
    }
  end

  # override select_tag to allow the ":include_blank => true" and ":prompt => 'whatever'" options
  include ActionView::Helpers::FormTagHelper
  def custom_select_tag(name, select_options, options = {}, html_options = {})
    # remove the options that select_tag doesn't currently recognise
    include_blank = options.has_key?(:include_blank) && options.delete(:include_blank)
    prompt = options.has_key?(:prompt) && options.delete(:prompt)
    # if we didn't pass either - continue on as before
    return select_tag(name, select_options, options.merge(html_options)) unless include_blank || prompt
    # otherwise, add them in ourselves
    prompt_option  = "<option value=\"\">" # to make sure it shows up as nil
    prompt_option += (prompt ? prompt.to_s : "") + "</option>"
    new_select_options = prompt_option + select_options
    select_tag(name, new_select_options, options.merge(html_options))
  end

  # is_temporary_licence, is_licence_expire, show_custome_message, is_controller?
  #  REMOVED THESE METHODS AS NOT IN USE. DO NOT ADD AGAIN. SUPRIYA SURVE 31 JAN 2012
  
  def session_status
    session[:company_id].blank?? nil : Company.find(session[:company_id]).is_cgc?? nil :session[:company_id]
  end

  def zimbra_search_box(upload_to)
    case  upload_to
    when "opportunities"
      opportunity_search_box('opportunity[id]', "opportunities", "", "")
    when "contacts"
      contact_search_box('contact[id]', "contacts", "", "")
    when "accounts"
      account_search_box('account[id]', "accounts", "", "")
    when "campaigns"
      campaign_search_box('campaign[id]', "campaigns", "", "")
    when "matters"
      matter_search_box('matter[id]',"matters","","")
    end
  end

  def attachment_description_box(upload_to)
    case  upload_to
    when "opportunities"
      text_area_tag 'opportunity[description]'
    when "contacts"
      text_area_tag 'contact[description]'
    when "accounts"
      text_area_tag 'account[description]'
    when "campaigns"
      text_area_tag 'campaign[description]'
    when "matters"
      text_area_tag 'matter[description]'
    end
  end

  # current_month_range

  def companylookup_lvalue(id)
    CompanyLookup.find_by_id(id).lvalue
  end

  # Below 2 methods are used for types
  # These can be moved to application_controller its returning an array
  # Supriya Surve
  def find_model(type)
    if type == "liti_types"
      modeltype = TypesLiti
    elsif type == "nonliti_types"
      modeltype = TypesNonLiti
    elsif type == "activity_types"
      modeltype = Physical::Timeandexpenses::ActivityType
    elsif type == "expense_types"
      modeltype = Physical::Timeandexpenses::ExpenseType
    else
      modeltype = type.singularize.camelize.constantize
    end
    return modeltype
  end

  def find_model_class_data(type)
    modeltype = find_model(type)
    activated, deactivated = [], []
    allentries = modeltype.find_with_deleted(:all, :conditions => ["company_id = #{@company.id}"])
    allentries.each do |entry|
      if entry.deleted_at.blank?
        activated << entry
      else
        deactivated << entry
      end
    end
    return [activated, deactivated]
  end

  # change_templates, custom_error_messages_helper

  # Creates 3 AJAX links for setting per page limit for pagination.
  def create_per_page_limit_remote_links(perpage, update_div, url_hash)
    perpage = (perpage || 25).to_i
    return %Q{
   <div class="fl mlr8">Per Page :   
    #{perpage==25 ? 25 : link_to_remote("25", :update => update_div, :method => :get,  :url => url_hash.merge(:per_page => 25),:before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();")} |
    #{perpage==50 ? 50 : link_to_remote("50", :update => update_div,  :method => :get,:url => url_hash.merge(:per_page => 50),:before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();")} |
    #{perpage==100 ? 100 : link_to_remote("100", :update => update_div, :method => :get, :url => url_hash.merge(:per_page => 100),:before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();")}</div>
    }.html_safe!
  end

  # creates 3 links for applying per page limit on index pages - Supriya
  def create_per_page_limit_links(perpage, options)
    return %Q{
   <div class="fl mlr8">Per Page :   
    #{(perpage=="25" || perpage==25 || !perpage.present? )? "25" : link_to("25", :params =>options.merge(:per_page => 25))} |
    #{(perpage=="50" || perpage==50)  ? "50" : link_to("50", :params =>options.merge(:per_page => 50))} |
    #{(perpage=="100" || perpage==100)? "100" : link_to("100", :params =>options.merge(:per_page => 100))}</div>
    }.html_safe!
  end

  # Adds first and last page link to the pagination and call javascript which will show only 5 page links, the links are AJAX based.
  def paginate_for_five_remote_links(totalpages, update_div, url_hash, page=nil)
    fpage = lpage = nil
    fpage = escape_javascript link_to_remote("", {:update => update_div, :method => :get, :url => url_hash.merge(:page=>1), :before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();"}, :class => "icon_Pprev ml2 fl mt2", :onmouseover=>'calltooltip("First", jQuery(this))', :onmouseout => "hidetooltip()") if page.to_i > 1
    lpage = escape_javascript link_to_remote("", {:update => update_div, :method => :get, :url => url_hash.merge(:page=>totalpages), :before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();"}, :class => "icon_Nnext mr2 fl mt2", :onmouseover=>'calltooltip("Last", jQuery(this))', :onmouseout => "hidetooltip()") unless page.eql?("#{totalpages}")
    return %Q{
      <script type="text/javascript">
      jQuery(document).ready(function() {
        paginate_for_five_links(#{totalpages})  
    jQuery(".willpaginate:first, .bottom-pagination:first").before('#{fpage}')
    jQuery(".willpaginate:last, .bottom-pagination:last").after('#{lpage}');
     });
      </script>
    }
  end

  # added first and last page link to the pagination and call javascript which will show only 5 page links - Supriya
  def paginate_for_five_links(totalpages, options, page=nil)
    return %Q{
      <script type="text/javascript">
      jQuery(document).ready(function() {
        paginate_for_five_links(#{totalpages})  
    jQuery(".willpaginate:first, .bottom-pagination:first").before('#{link_to_unless( (page.nil? || page.eql?(1)),"", {:params =>options} ,:class => "icon_Pprev ml2 fl mt2", :onmouseover=>'calltooltip("First", jQuery(this))', :onmouseout => "hidetooltip()")}');
    jQuery(".willpaginate:last, .bottom-pagination:last").after('#{link_to_unless(page.eql?("#{totalpages}"), "", {:params =>options.merge(:page=>totalpages)}, :class => "icon_Nnext mr2 fl mt2", :onmouseover=>'calltooltip("Last", jQuery(this))', :onmouseout => "hidetooltip()")}');
     });
      </script>
    }
  end

  # default pagination styling - Supriya 30-06-2010
  def all_pagination(obj, perpage, divclass, path, options = {}, show_letter_search = true)
    options.merge!({:letter => params[:letter],:col => params[:col],:dir => params[:dir]})
    letter_search = %(<ul class="alphabetical fl">#{searching_by_letter(options)}</ul>)
    reset_link = %(<div class="fl ml10 mt2">#{link_to "<span class='icon_reset fl'></span>", path}</div>)
    return %Q{
      <div class="pagination_div">
        #{letter_search if show_letter_search}
        #{reset_link if show_letter_search}
          <div class="pagination fr w48">
            #{create_per_page_limit_links(perpage, options) if(obj.total_entries > 25)}
            <div class="fr">
              <div class="fl">#{raw custom_page_entries_info obj}</div>
              <div class="fl ml3 mr3 #{divclass}">#{will_paginate obj, :previous_label => '<span class="previousBtn"></span>', :next_label => '<span class="nextBtn"></span>', :class => 'pagination', :inner_window => 4, :outer_window => 1, :separator => '', :params => {:action => options[:action]}}</div>
              <br class="clear" />
            </div>
            <br class="clear" />
          </div>        
        <br class="clear" />
      </div>
    }
  end

  # this is for common my and all radio buttons - Supriya
  def my_all_radio_button(my, myjs_function, all, alljs_function, mode_type)
    return %Q{
      <div class="fl mt1">
        <table cellspacing="0" cellpadding="0">
          <tr>
            <td><input type="radio" name="myallradio" style="margin:0 5px 0 2px;display:inline" value="my" onclick="#{myjs_function}" #{'checked="checked"' if mode_type.eql?('MY') ||  mode_type.eql?(nil) || mode_type.eql?("")} /></td>
            <td><label class="mr8">#{my}</label></td>
            <td>&nbsp;</td>
            <td><input type="radio" name="myallradio" style="margin:0 5px 0 0;" value="all" onclick="#{alljs_function}" #{'checked="checked"' if mode_type.eql?('ALL') } /></td>
            <td><label>#{all}</label></td>
          </tr>
        </table>
      </div>
    }
  end

  # search and stages select - contacts and opportunities - Supriya
  # search and additional option of 'Add' removed and put based on condition so that can be used at other palces also for stage-filters.  - Ketki 3/5/2011 
  def search_with_stages_select_tag(selectname, stagelabel, stage, selected, onchange, searchname, option=nil,billing=nil)
    if stagelabel.eql?('Manage Stage Filter(s)')
      all_option = ""
      search_box = ""
    else
      all_option =  "<option value='#{option}'>All #{'Open' if selectname =='opp_stage'}</option>"
      search_box = "#{text_field_tag "#{searchname}", '', :size =>'30', :class => 'search'}<span class='icon_search fr'></span>"
    end
    date_start = selected[:selected].eql?(0) ? params[:date_start]:''
    date_end = selected[:selected].eql?(0) ? params[:date_end]:''
    if billing=="billing"
      box= "<table class='fl'>
    <tr>
      <td>&nbsp;&nbsp;&nbsp;#{t(:text_start_date)}</td>
      <td><input type='text' id='date_start' name='date_start' class='fl date_picker' size='10' value='#{date_start}' /></td>
      <td>#{t(:text_end_date)}</td>
      <td><input type='text' id='date_end' name='date_end' class='fl date_picker' size='10' value='#{date_end}' /></td>
      <td><input type='submit' name='commit' value='Go' onclick='searchDate();'/></td>
 </tr>
 </table>"
    end
    return %Q{
      <div class="box_gray mt5 mb5">
        <div class="fl pl5">
          <table cellpadding="0" cellspacing="0">
            <tr>
              <td><strong>#{stagelabel}</strong>&nbsp;&nbsp;</td>
              <td>#{select_tag(selectname, all_option + options_for_select(stage,selected),{:onchange => onchange ,:style=>"height:22px;"})}</td>
            </tr>
          </table>
        </div>
        #{box}
        <div class="fr fix_mr">
          <div class="search_div">#{search_box}</div>
        </div>
        <br class="clear" />
      </div>
    }
  end

  def sphinx_search_field(searchname,billing=nil,date_start=nil,date_end=nil)
    if billing=="billing"
      box= "<table class='fl'>
    <tr>
      <td>#{t(:text_start_date)}</td>
      <td><input type='text' id='date_start' name='date_start'  readonly='true' class='fl date_picker' size='10' value='#{date_start}' /></td>
      <td>#{t(:text_end_date)}</td>
      <td><input type='text' id='date_end' name='date_end'  readonly='true' class='fl date_picker' size='10' value='#{date_end}' /></td>
      <td><input type='submit' name='commit' value='Go' onclick='searchDate();'/></td>
 </tr>
 </table>"
    end
    return %Q{
     #{box}
      <div class="box_gray">
        <div class="fl pl5">  </div>
        <div class="fr fix_mr">
          <div class="search_div">#{text_field_tag "#{searchname}", '', :size =>'30', :class=> 'search'}<span class="icon_search fr"></span></div>
        </div>
        <br class="clear" />
      </div>
    }
  end

  def matter_name_and_id(obj)
    unless obj.matter.nil?
      return obj.matter.name, obj.matter.id
    else
      return '',''
    end
  end

  def contact_name_and_id(obj)
    unless obj.contact_id.nil?
      cont = Contact.find_with_deleted(obj.contact_id)
      return cont.full_name, cont.id
    else
      return '',''      
    end
  end

  def action_pad_top_blue_links(options = {},onclick=nil)
    if options[:width_tb].present? && options[:history_path].present?
      width_tb = "&width="+options[:width_tb]
      options[:history_path] << width_tb
    end
    return %Q{
      <tr>
        <td><div class="ap_top_curve_left"></div></td>
          <td width="500" class="ap_top_middle">
          <table width="330" border="0" cellspacing="0" cellpadding="0">
            <tr><td colspan="6"><div class="ap_pixel15"></div></td></tr>
            <tr>
              <td width="19" valign="bottom" align="left"><div class="#{options[:edit_path]=="NO" ? 'ap_edit_inactive' : 'ap_edit_active'}"></div></td>
              <td width="79" valign="bottom" align="left">#{options[:edit_path]=="NO" ? "<span class='action_pad_inactive'>Edit</span>" : link_to('Edit', (options[:edit_modal] ? "#" : options[:edit_path]), (options[:edit_modal] ? {:onclick => "tb_show('#{escape_javascript(options[:edit_text])}','#{options[:edit_path]}','')"} : {}))} </td>
              <td width="19" valign="bottom" align="left"><div class="#{options[:deactivate_link].present? ? (options[:deactivate_link]=="NO" ? 'ap_deactivate_inactive' : 'ap_deactivate_active') : (options[:deactivate_path]=="NO" ? 'ap_deactivate_inactive' : 'ap_deactivate_active')}"></div></td>
              <td width="82" valign="bottom" align="left">#{options[:deactivate_link].present? ? (options[:deactivate_link]=="NO" ? "<span class='action_pad_inactive'>Delete</span>" : options[:deactivate_link]) : ( (options[:deactivate_path]=="NO")? "<span class='action_pad_inactive'>Delete</span>" : link_to('Delete', options[:deactivate_path], :method => 'delete',:onClick=>onclick, :confirm => "Are you sure you want to delete this #{escape_javascript(options[:deactivate_text])}?"))}</td>
              <td width="19" valign="bottom" align="left">&nbsp;</td>
              <td width="56" valign="bottom" align="left">&nbsp;</td>
            </tr>
            <tr><td colspan="6"><div class="ap_pixel10"></div></td></tr>
            <tr>
              <td valign="bottom" align="left"><div class="#{options[:comment_path]=="NO" ? 'ap_comment_inactive' : 'ap_comment_active'}"></div></td>
              <td valign="bottom" align="left">#{options[:comment_path]=="NO" ? "<span class='action_pad_inactive'>Comment</span>" : link_to('Comment', "#", :onclick=>"tb_show('#{escape_javascript(options[:comment_title])} #{t(:text_comment)}','#{options[:comment_path]}','')") }</td>
              <td valign="bottom" align="left"><div class="#{options[:document_path]=="NO" ? 'ap_document_inactive' : 'ap_document_active'}"></div></td>
              #{
    if options[:document_form_face_box]
    %Q{<td valign="bottom" align="left">#{options[:document_link].present? ? options[:document_link] : (options[:document_path]=="NO" ? "<span class='action_pad_inactive'>Document</span>" : link_to('Document',"#",:onclick=>"tb_show('#{options[:document_header]}  #{t(:text_document)}','#{options[:document_path]}','')") )}</td>}
    else
    %Q{<td valign="bottom" align="left">#{options[:document_link].present? ? options[:document_link] : (options[:document_path]=="NO" ? "<span class='action_pad_inactive'>Document</span>" : link_to('Document', options[:document_path], options[:document_modal] ? { :class => "thickbox", :name => (options[:document_header].present? ? options[:document_header] : "")} : {}))}</td>}
    end
                }
              <td valign="bottom" align="left"><div class="#{options[:history_path]=="NO" ? 'ap_history_inactive' : 'ap_history_active'}"></div> </td>
              <td valign="bottom" align="left">#{options[:history_path]=="NO" ? "<span class='action_pad_inactive'>History</span>" : link_to('History', '#', :onclick=>"tb_show('#{escape_javascript(options[:history_title])}', '#{options[:history_path]}', '' ); return false")}</td>
            </tr>
          </table>
        </td>
        <td><div class="ap_top_curver_right"></div></td>
      </tr>
    }
  end

  def custom_page_entries_info(collection, options = {})
    entry_name = options[:entry_name] ||
      (collection.empty?? 'entry' : collection.first.class.table_name.underscore.sub('_', ' '))
    entryname = entry_name=="tne invoices" ? "Bill" : entry_name.singularize.try(:capitalize)
    if collection.total_pages < 2
      case collection.size
      when 0; "" #"No #{entry_name.pluralize} found"
      when 1; "<div class='pagination fr'> Displaying <b>1</b> </div>"
      else;   "<div class='pagination fr'> Displaying <b>all #{collection.size}</b> </div>"
      end
    else
      %{<div class="fl mlr2">Displaying <b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b></div>} % [
        collection.offset + 1,
        collection.offset + collection.length,
        collection.total_entries
      ]
    end
  end

  # custom_user_setting

  # for new UI please use 'truncate_hover_link' helper - Supriya Surve
  # This is used in matter clients
  def truncate_hover_link_blue_tooltip(str,length,url)
    strng = str
    if str.length > length
      strng = truncate(str, :length => length)      
    end
    return %Q{
        <span class="liviadashboardview">
          #{link_to(strng, url)}
           <span class="livia_dashboardroller" style="display:none;">
            #{str}
           </span>
        </span>
    }
  end
  
  # for new UI please use 'truncate_hover' helper - Supriya
  def truncate_hover_blue_tooltip(str,length)
    unless str.nil?
      if str.length > length
        return %Q{
        <span class="liviadashboardview">
          #{truncate(str,:length => length)}
           <span class="livia_dashboardroller" style="display:none;">
            #{str}
           </span>
        </span>
        }.html_safe!
      end
    end    
    return str
  end

  def get_reports_path
    if (can? :manage, :rpt_contact)
      "/rpt_contacts/current_contact"
    elsif(can? :manage, :rpt_account)
      "/rpt_accounts/current_account"
    elsif(can? :manage, :rpt_campaign)
      "/rpt_campaigns/campaign_status"
    elsif(can? :manage, :rpt_matter)
      "/rpt_matters/matter_master"
    elsif(can? :manage, :rpt_opportunity)
      "/rpt_opportunities/opportunity_pipe"
    elsif(can? :manage, :rpt_time_and_expense)
      "/rpt_time_and_expenses/time_accounted"
    end
  end

  ##############################################################################################
  # Returns date formatted to LIVIA's standard format.
  def livia_date(d)
    unless d.nil?
      d.to_time.strftime("%m/%d/%Y") # %H:%M") no need to show time as it comes 00:00 always. Mandeep
    else
      '-'
    end
  end

  # Returns date and time formatted to LIVIA's standard format.
  def livia_date_time(d)
    unless d.nil?
      d.to_time.strftime("%m/%d/%Y %H:%M")
    else
      ''
    end
  end

  # Returns time formatted to LIVIA's standard format.
  def livia_time(d)
    unless d.nil?
      d.to_time.strftime("%H:%M")
    else
      ''
    end
  end

  def livia_time_zone(d)
    unless d.nil?
      d.to_time.strftime("%I:%M %p")
    end
  end

  def contact_activation_link(contact)
    acc = Account.find_with_deleted(contact.account_contacts.find_only_deleted(:first).account_id) if contact.account_contacts.find_only_deleted(:first)
    if acc && acc.deleted?
      link_to "Activate",ask_activate_account_contact_path(contact.id)+"?height=100&width=440&mode_type=#{params[:mode_type]}" ,:class => "thickbox", :title=> "Activate #{t(:label_accounts)}", :name=> "Activate #{t(:label_accounts)}"
    else
      link_to('Activate', activate_contact_contact_path(contact.id,:mode_type => params[:mode_type],:contact_status=> params[:contact_status]), :confirm => 'Are you sure you want to activate this contact?')
    end
  end

  def notes_count_alert(lawyer_user_ids,livian_user_ids)
    if is_secretary?
      lawyer_user_ids << current_user.id
      Communication.count(:conditions=>['(created_by_user_id in(?) or assigned_to_user_id = ?) and status IS NULL and date(created_at) + 2 < ?',lawyer_user_ids, current_user.id, Time.zone.now.utc.to_date])
    else
      Communication.count(:conditions=>['(assigned_by_employee_user_id in(?) or assigned_to_user_id in(?)  or created_by_user_id in (?))and status IS NULL and date(created_at) + 2 < ?',lawyer_user_ids,livian_user_ids,livian_user_ids,Time.zone.now.utc.to_date])
    end
  end

  def dynamic_select(name,id,type,options,html_options)
    arr =  [['Full ($)',1],['Discount (%)',2],['Markup (%)',4],['Override ($)',3]]
    if(type=='time_entries')
      arr.delete_at(2)
    end
    #  select("post", "person_id", Person.find(:all).collect {|p| [ p.name, p.id ] }, { :include_blank => true })
    select(name,id,arr,options,html_options)
  end
  
  def time_entry_adjustments(time_entry)
    name=""
    adjustment = '0.00'
    final_amount = 0.00
    case time_entry.billing_method_type
    when 2
      name = 'physical_timeandexpenses_time_entry[billing_percent]'
      adjustment = time_entry.billing_percent
    when 3
      name = 'physical_timeandexpenses_time_entry[final_billed_amount]'
      adjustment = time_entry.final_billed_amount
    end
    final_amount = time_entry.calculate_final_billed_amt
    return name,adjustment,final_amount
  end
  
  def truncate_withscroll(str, length)
    strlength = str.length
    if strlength > length
      if strlength <90
        truncate_hover(str, length)
      else
        return %Q{
      <div class="icon_scrollhover">#{truncate(str, length)}</div>
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
                  <div style='overflow-y:auto; width:100%; height:150px; width:225px;'>#{str}</div>
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
      end
    else
      return %Q{ #{str} }
    end
  end

  def get_parent_matter_completed(other_matter_tasks)
    parents_complete = {}
    other_matter_tasks.collect{|parent| parents_complete[parent.id] = parent.completed} if other_matter_tasks
    parents_str = ""
    parents_complete.each do |pid, complete|
      parents_str << %Q{<input type=hidden id=#{pid}_completed value=#{complete} />}
    end
    return parents_str
  end

  def get_verfied_lawyer_name
    if session[:verified_lawyer_id]
      lawyer_id = session[:verified_lawyer_id]
      lawfirm_user = User.find(lawyer_id)
      verified_lawyer = lawfirm_user.full_name
      return verified_lawyer.titleize
    else
      current_user.full_name.titleize
    end
  end

  #Radio button for reports matter-revenue -Ketki 10/5/2011
  def radios_for_revenue_matter_rpt(opts)
    return %Q{
    <div class="fl">
      <table>
        <tr>
          <td><input type="radio" name="get_records" id="get_records" value="Basic" #{opts[:basic_checked]} /></td>
          <td>Basic</td>
          <td>&nbsp;</td>
          <td><input name="get_records" type="radio" id="get_records" value="Detail" #{opts[:detail_checked]} /></td>
          <td>Detail</td>
        </tr>
      </table>
    </div>
    }
  end

  def note_action_links(note)
    return %Q{
        <div class="icon_action mt3"><a href="#"></a></div>
        <div id="liquid-roundAP" class="tooltip" style="display:none;">          
          <table width="100%" border="1" cellspacing="0" cellpadding="0">
            #{action_pad_top_blue_links({
    :edit_path=>"NO",
    :deactivate_path=>"NO",
    :deactivate_text =>"NO",
    :comment_path=>"NO",
    :comment_title =>"NO",
    :document_path=>"#{wfm_new_document_home_path('Communication',note.id,:height=>350,:width=>800)}",
    :history_path=>"NO",
    :history_title =>"NO",
    :document_form_face_box =>"YES",
    :document_header =>truncate(note.description.strip, :length=> 50)
    })}
              <tr>
                <td valign="top" class="ap_bottom_curve_left"></td>
                <td class="ap_bottom_middle"><div class="ap_pixel13"></div></td>
                <td valign="top" class="ap_bottom_curve_right"></td>
              </tr>
            </table>
        </div>
    }
  end

  def open_task_action_links(task)
    return %Q{
        <div class="icon_action mt3"><a href="#"></a></div>
        <div id="liquid-roundAP" class="tooltip" style="display:none;">          
          <table width="100%" border="1" cellspacing="0" cellpadding="0">
            #{action_pad_top_blue_links({
    :edit_path=>"NO",
    :deactivate_path=>"NO",
    :deactivate_text =>"NO",
    :comment_path=>"#{add_comment_with_grid_comments_path(:id=>task.id,:commentable_type=>'UserTask',:path=> root_path,:height=>210,:width=>800)}",
    :comment_title => truncate(task.name.gsub("'","`"),:length => 30),
    :document_path=>"#{wfm_new_document_home_path('UserTask',task.id,:height=>210,:width=>800)}",
    :history_path=>"NO",
    :history_title =>"NO",
    :document_form_face_box =>"YES",
    :document_header =>truncate(task.name.gsub("'","`"),:length=>10)})}
              <tr>
                <td valign="top" class="ap_bottom_curve_left"></td>
                <td class="ap_bottom_middle"><div class="ap_pixel13"></div></td>
                <td valign="top" class="ap_bottom_curve_right"></td>
              </tr>
            </table>
        </div>
    }
  end

  def get_complexity_levels(work_subtype)
    work_subtype_complexities = []
    work_subtype.work_subtype_complexities.collect{|work_subtype_complexity| work_subtype_complexities << work_subtype_complexity.complexity_level if work_subtype_complexity.complexity_level}
    return work_subtype_complexities
  end

  def my_complexity_level(complexity_levels, livian, ws_id)
    livian_complexity_level = []
    user_work_subtype = UserWorkSubtype.find_by_user_id_and_work_subtype_id(livian.id,ws_id)
    work_subtype_complexity_id = user_work_subtype.work_subtype_complexity_id if user_work_subtype && user_work_subtype.work_subtype_complexity_id
    complexity_level = WorkSubtypeComplexity.find(work_subtype_complexity_id).complexity_level if work_subtype_complexity_id
    livian_complexity_level << complexity_level if complexity_level
    return (livian.id.to_s+"-"+ws_id.to_s+"-"+(livian_complexity_level & complexity_levels).to_s).to_a
  end

  def matter_billing_cancel_links(cancelledbills, path, align)
    return %Q{
      <td width="7%" align="#{align}" valign="middle"><img src="/images/icon_child_action.png" width="15" height="14" /></td>
      <td width="40%" align="left" valign="middle" nowrap>#{cancelledbills ? "<span class='action_pad_inactive'>Cancel</span>" : (link_to "Cancel", path, :method => "delete", :confirm => 'Are you sure you want to cancel this invoice?') }</td>
    }
  end

  def get_default_time_appointment
    today_time = Time.zone.now
    if [0, 30].include?(today_time.min)
      return today_time, (today_time + 30.minutes)
    else
      today_time = (today_time.min > 30) ? (today_time + (60 - today_time.min).minutes) : (today_time + (30 - today_time.min).minutes)
      return today_time, (today_time + 30.minutes)
    end
  end

  def activity_name_hover(matter_task, matter, edit_link ='', from_home=false, length = 40)
    is_matter = matter_task.has_attribute?(:matter_id)
    name = matter_task.name
    parent = "<b>Parent:</b> #{h(matter_task.parent_name)}<br />" if (is_matter and matter_task.parent_id and matter_task.assoc_as.eql?("1") )
    completion = (is_matter && matter_task.completed && "<b>Completed on</b>: #{livia_date(matter_task.completed_at)}<br />") || ''
    desc = "#{h(name)}<br /> #{parent} #{completion}"
    link = link_to(truncate(h(name),:length => length), (edit_link.blank? ? edit_matter_matter_task_path(matter, matter_task, :height => 350, :width => 800) : '#'), :onclick => (!edit_link.blank? ? edit_link : ''))
    new_tooltip_div_code(link, desc)
  end

  def edit_path_with_thickbox_for_appointment(activity,is_appointment)
    if is_appointment
      if activity[:activity_is_matter]
        edit_link = "thickboxInstance('#{instance_series_calendars_path(:appointment_id => activity[:activity_id], :height => 120, :width => 250, :matter => activity[:activity_matter], :from => 'matters', :link => (edit_instance_matter_matter_task_path(activity[:activity_matter], activity[:activity_id], :instance_end_time => activity[:activity_end_date].to_time, :instance_end_date => activity[:activity_instance_end_date],:ex_start_time=> activity[:activity_start_date].to_time, :instance_start_date => activity[:activity_instance_start_date], :height => "400", :width => "800")), :series => ("#{edit_matter_activity_calendars_path(:matter_id => activity[:activity_matter_id], :id=>activity[:activity_id], :height => "400", :width=> "800", :cal_action => params[:action])}"))}')"
        activity[:activity_is_instance] ? activity_name_hover(activity[:activity],activity[:activity_matter], edit_link, true, 15) : raw(truncate_hover_link(activity[:activity].name,15,edit_matter_matter_task_path(activity[:activity_matter_id],activity[:activity_id])))
      else
        edit_link = "thickboxInstance('#{instance_series_calendars_path(:appointment_id => activity[:activity_id], :height => 120, :width => 250, :link => (edit_zimbra_instance_calendars_path(:id => activity[:activity_id], :instance_end_time => activity[:activity_end_date].to_time, :instance_end_date => activity[:activity_instance_end_date],:ex_start_time=> activity[:activity_start_date].to_time, :instance_start_date => activity[:activity_instance_start_date], :height => "400", :width => "800")), :series => ("#{edit_activity_calendars_path(:id=>activity[:activity_id], :height => "400", :width=> "800")}"))}')"
        activity[:activity_is_instance] ? activity_name_hover(activity[:activity],activity[:activity_matter], edit_link, true, 15) : non_matter_task(activity)
      end
    else
      if activity[:activity_is_matter]
        edit_link = "thickboxInstance('#{instance_series_calendars_path(:appointment_id => activity[:activity_id], :height => 120, :width => 250, :matter => activity[:activity_matter], :from => 'matters', :link => (edit_instance_matter_matter_task_path(activity[:activity_matter], activity[:activity_id], :instance_end_time => activity[:activity_end_date].to_time, :instance_end_date => activity[:activity_instance_end_date],:ex_start_time=> activity[:activity_start_date].to_time, :instance_start_date => activity[:activity_instance_start_date], :height => "400", :width => "800")), :series => ("#{edit_matter_activity_calendars_path(:matter_id => activity[:activity_matter_id], :id=>activity[:activity_id], :height => "400", :width=> "800", :cal_action => params[:action])}"))}')"
        activity[:activity].repeat.present? ? activity_name_hover(activity[:activity], activity[:activity_matter], edit_link, true) : raw(truncate_hover_link(activity[:activity].name,15,edit_matter_matter_task_path(activity[:activity_matter_id],activity[:activity_id])))
      else
        non_matter_task(activity)
      end
    end
  end

  # MouseOver For Non Matter Related Task ---Sheetal
  def non_matter_task(activity)
    name = activity[:activity_name]
    link = link_to_remote(truncate(h(activity[:activity_name]), :length => 15), :url => edit_activity_calendars_path(:id=> activity[:activity_id],:height=>350,:width=>680,  :home=> true), :class=>"thickbox vtip", :method=>:post)
    new_tooltip_div_code(link, h(name))
  end

  def display_matter_names(matter_id)
    matter_name=Matter.find(matter_id).name
    return matter_name
  end
  
  def active_class
    classes = {
      'products' => 'home',
      "subproducts" =>'home',
      "livia_admins" =>'register',
      "manage_secretary"=>"login",
      "service_providers"=>"login",
      "configurelookups"=>"event",
      "security_questions"=>"thought"

    }
    classes[controller.controller_name + '.' + controller.action_name] || classes[controller.controller_name] || ''
  end

  def hidden_fields_for_return_path(letter=nil,per_page=nil,page=nil,col=nil,dir=nil,mode_type=nil,controller_name=nil)
    return %Q{
   #{(hidden_field_tag  :letter, letter) unless letter.blank?}
   #{(hidden_field_tag  :per_page, per_page) unless per_page.blank?}
   #{(hidden_field_tag  :page, page) unless page.blank?}
   #{(hidden_field_tag  :col, col) unless col.blank?}
   #{(hidden_field_tag  :dir, dir) unless dir.blank?}
   #{(hidden_field_tag  :mode_type, mode_type) unless mode_type.blank?}
   #{(hidden_field_tag :controller_name, controller_name) unless controller_name.blank?}
    }
  end

  def extra_parameters(params=nil,flag=false)
    if flag
      letter_str = params.has_key?('letter') ? 'letter='+params[:letter]+'&' : ''
      col_str = params.has_key?('col') ? 'col='+params[:col]+'&' : ''
      mode_str = params.has_key?('mode_type') ? 'mode_type='+params[:mode_type]+'&' : ''
      per_page_str= params.has_key?('per_page') ? 'per_page='+params[:per_page]+'&' : ''
      page_str = params.has_key?('page') ? 'page='+params[:page] : ''
      return %Q{#{letter_str}#{col_str}#{mode_str}#{per_page_str}#{page_str}}
    else
      unless params[:matter_status].blank?
        return :matter_status=>params[:matter_status],:letter=>params[:letter],:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page]
      else
        return :letter=>params[:letter],:mode_type=>params[:mode_type],:per_page=>params[:per_page],:page=>params[:page]
      end
    end
  end

  def toe_available?
    can? :manage, MatterTermcondition
  end

  def people_legal_team_available?
    can? :manage, MatterPeople
  end

  def task_available?
    can? :manage, MatterTask
  end

  def issue_available?
    can? :manage, MatterIssue
  end

  def fact_available?
    can? :manage, MatterFact
  end

  def risk_available?
    can? :manage, MatterRisk
  end

  def research_available?
    can? :manage, MatterResearch
  end

  def document_available?
    can? :manage, DocumentHome
  end

  def billing_and_retainer_available?
    can? :manage, MatterBilling
    can? :manage, MatterRetainer
  end

  def matter_time_expense_available?
    can? :manage, Physical::Timeandexpenses::TimeAndExpensesController
  end

  def matter_name_initials(matter_name)
    matter_name.strip.scan(/(^\w|\s\w)/).flatten.to_s.gsub(/\s/,".")
  end

  def change_matter_id(matter)
    if (matter.matter_no.present? && matter.matter_no != /#{matter.name}/)
      return matter.matter_no + "_" + matter_name_initials(matter.name)
    else
      return  matter.matter_no
    end
  end

  def get_verfied_lawyer_time_zone
    if session[:verified_lawyer_id]
      lawyer_id = session[:verified_lawyer_id]
      lawyer_time_zone = User.find(lawyer_id).time_zone
      return "Timezone: #{lawyer_time_zone}"
    else
      return ''
    end
  end

  def get_share_with_client(task)
    task.share_with_client ? "YES" : "NO"
  end

  def notification_url(obj)
    type = obj.notification_type
    notify= obj.notification
    if type == "UserTask"
      if notify.status == "Complete"
        if current_user.role?('lawyer')
          url = obj.title == "Document Upload For Task" ? "tb_show('#{truncate(h(notity.name), :length => 15)}','#{wfm_new_document_home_path('UserTask', notify.id,:height=>350,:width=>800)}?height=250&width=700','');" : "tb_show('#{truncate(h(notity.name), :length => 15)}','#{add_comment_with_grid_comments_path(:id=>notify.id,:commentable_type=>'UserTask',:path=> root_path)}?height=250&width=700','');"
        else
          url = wfm_user_task_path(notify)
        end
      else
        if current_user.role?('lawyer')
          url = obj.title == "Document Upload For Task" ? "tb_show('#{truncate(h(notify.name), :length => 15)}','#{wfm_new_document_home_path('UserTask', notify.id)}?height=350&width=800','');" : "tb_show('#{truncate(h(notify.name), :length => 15)}','#{add_comment_with_grid_comments_path(:id=>notify.id,:commentable_type=>'UserTask',:path=> root_path)}?height=350&width=800','');"
        else
          url = edit_wfm_user_task_path(notify)
        end
      end
    else
      if notify.status == "Complete"
        url = wfm_notes_path()
      else
        url = current_usre.role?('lawyer') ? "tb_show('#{truncate(h(notify.name), :length => 15)}','#{wfm_new_document_home_path('Communication', notify.id)}?height=350&width=800','');" : edit_wfm_note_path(notify)
      end
    end
    return url
  end

  def notification_count(notify)
    notifies = Notification.user_unread_notifications(current_user.id, notify.id)
    return notifies.count > 0 ? [notifies.first.id, notifies.count] : []
  end

  ## Following method will check for the public or private activities
  def action_pad_and_link_blocking(activity)
    if activity.class.to_s == "MatterTask" || activity.assigned_to_user_id==get_employee_user_id
      return [true,true,true]
    else
      if activity.mark_as=="PUB"
        return [true,true,true]
      else
        return [false,false,false]
      end
    end
  end
  
  # create only pagination not letter pagination
  def only_pagination(obj, perpage, divclass, path, options = {})
    reset_link = %(<div class="fl ml10 mt2">#{link_to "<span class='icon_reset fl'></span>", path}</div>)

    return %Q{
      <div class="pagination_div">
        #{reset_link}
          <div class="pagination fr w48">
            #{create_per_page_limit_links(perpage, options) if(obj.total_entries > 25)}
            <div class="fr">
              <div class="fl">#{raw custom_page_entries_info obj}</div>
              <div class="fl ml3 mr3 #{divclass}">#{will_paginate obj, :previous_label => '<span class="previousBtn"></span>', :next_label => '<span class="nextBtn"></span>', :class => 'pagination', :inner_window => 4, :outer_window => 1, :separator => '', :params => {:action => options[:action]}}</div>
              <br class="clear" />
            </div>
            <br class="clear" />
          </div>
        <br class="clear" />
      </div>
    }
  end

  def send_attachment_as_email(name)
    description ="Hi,

Please find attached document.

Regards,
#{@current_user.full_name}"
    %Q{
      <tr>
        <td width="25%" height="6%" align="left"> From </td>
        <td height="6%" align="left">#{text_field_tag "email[from]",@current_user.email, :disabled => true, :size => 40, :style=> "color:#444" }</td>
      </tr>
       <tr>
        <td height="6%" align="left"> To <span class="alert_message"> *</span></td>
        <td height="6%" align="left">#{text_field_tag "email[to]",'', :size => 40}</td>
      </tr>
      <tr>
        <td height="6%" align="left">Subject <span class='alert_message'>*</span> </td>
        <td height="6%" align="left">#{text_field_tag "email[subject]", name, :size => 40}</td>
      </tr>
       <tr>
        <td height="6%" align="left" valign="top">Description <span class='alert_message'>*</span></td>
        <td height="6%" align="left">#{text_area_tag "email[description]", description, :rows => 7, :cols => 38}</td>
      </tr>
    }
  end

  def clippy(text, bgcolor='#E8E8E8')
    html = <<-EOF
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
            width="110"
            height="14"
            id="clippy" >
    <param name="movie" value="/flash/clippy.swf"/>
    <param name="allowScriptAccess" value="always" />
    <param name="quality" value="high" />
    <param name="scale" value="noscale" />
    <param NAME="FlashVars" value="text=#{text}">
    <param name="bgcolor" value="#{bgcolor}">
    <embed src="/flash/clippy.swf"
           width="110"
           height="14"
           name="clippy"
           quality="high"
           allowScriptAccess="always"
           type="application/x-shockwave-flash"
           pluginspage="http://www.macromedia.com/go/getflashplayer"
           FlashVars="text=#{text}"
           bgcolor="#{bgcolor}"
    />
    </object>
    EOF
  end

  def financial_account_display_style
    matter_display = account_display='display:none;'
    matter_list_box_display, matter_search_text_field = (@matters && @matters.size > 0) ? [true, "display:none;"] : [false, ""]
    if (@financial_account.matter_id)
      matter_name = @financial_account.matter.name
      matter_display = ''
    elsif((@financial_account.financial_account_type && @financial_account.financial_account_type.lvalue =='linked to matter'))
      matter_display = ''
      matter_search_text_field =""
    end
    if(@financial_account.account_id)
      account_display = ''
      account_name = @financial_account.account.name
    elsif(@financial_account.financial_account_type && @financial_account.financial_account_type.lvalue =='linked to account')
      account_display = ''
    end
    return matter_display, account_display, matter_list_box_display, matter_search_text_field, matter_name, account_name
  end

  def transaction_url_str(tr_action)
    url_str = ''
    if tr_action.inter_transfer
      url_str = update_inter_transfer_financial_account_financial_transaction_path(@financial_account, tr_action)
    elsif tr_action.transaction_type
      url_str =edit_financial_account_financial_transaction_path(@financial_account, tr_action)
    else
      url_str = update_payment_financial_account_financial_transaction_path(@financial_account, tr_action)
    end
    url_str
  end

  def client_specific_balance
    credit = debit = 0.0
    credit = debit =0
    @financial_transactions.each { |x|
      credit += x.amount if x.transaction_type
      debit += x.amount unless x.transaction_type
    }
    balance = (credit - debit)
    balance = balance > 0 ? livia_amount(balance) : 0.00
  end

  def inter_transfer_selected_list_box_ids
    selected_credited_id, selected_debited_id = nil
    if(!@financial_transaction.new_record? )
      selected_credited_id, selected_debited_id = (@financial_transaction.transaction_type) ? [@financial_transaction.financial_account_id, @financial_transaction.inter_relation_transaction.financial_account_id] : [@financial_transaction.inter_relation_transaction.financial_account_id,@financial_transaction.financial_account_id]
    end
    [selected_credited_id, selected_debited_id]
  end

  def get_title_for_site
    contrl = controller_name
    if params[:action]=="helpdesk"
      title = 'Helpdesk'
    elsif contrl.match("^rpt") || contrl=="dashboards"
      title = t(:text_menu_rnd)
    else
      title_hash = {"matter_termconditions" => t(:text_terms_of_engagement),
        "matter_peoples" => t(:text_people_amp_legal_team),
        "matter_tasks" => t(:text_activities),
        "matter_issues" => t(:text_issues),
        "matter_facts" => t(:text_facts),
        "matter_risks" => t(:text_risks),
        "matter_researches" => t(:text_research),
        "matter_billing_retainers" => t(:text_billing_retainer),
        'zimbra_mail' => 'Mail',
        'import_data' => "Import Data",
        "time_and_expenses" => t(:text_menu_tne),
        'tne_invoices' => t(:text_menu_billing),
        'accounts' => t(:text_menu_accounts),
        "document_homes" => t(:text_documents),
        "financial_accounts" => t(:text_financial_accounts)}
      title = title_hash["#{contrl}"]
      if title.blank?
        title = contrl.titleize
      end
    end
    return "#{t(:text_livia_legal)} - #{title}"
  end
  
end