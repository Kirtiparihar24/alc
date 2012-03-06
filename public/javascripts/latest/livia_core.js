/* this script contains those functions which are used commonly in portal
 * Date: Mon July 19 2010
 * Description : Javscript
 */
jQuery(document).ready(function() {
  // initLeftSidebarAccordian(); removed
  new_tool_tip();
  blink_text();
});

// function initLeftSidebarAccordian() : removed as not in use

/* To display only 5 link pages for pagination : will be called from helper */
function paginate_for_five_links( totalpages ){
  var childEle = jQuery(".willpaginate div").children('a')
  var bottomChildEle = jQuery(".bottom-pagination div").children('a')
  /* current element text */
  var spantext = jQuery(".willpaginate div").children('span.current')
  var bottomSpantext = jQuery(".bottom-pagination div").children('span.current')
  if(childEle.length>5){
    /* hide all anchor tag elements */
    childEle.hide();
    bottomChildEle.hide();
    /* show prev and next links by default */
    jQuery("a.prev_page").show();
    jQuery("a.next_page").show();
    /* conditions apply to show other elements */
    var previous_a = spantext.prev();
    var next_a = spantext.next();
    
    var bottomPrevious_a = bottomSpantext.prev();
    var bottomNext_a = bottomSpantext.next();
    if((spantext.text() >= "3") || (spantext.text() >= 3)){
      if(spantext.text()==totalpages){
        /* show previous 4 links */
        previous_a.show();
        previous_a.prev().show();
        previous_a.prev().prev().show();
        previous_a.prev().prev().prev().show();

        bottomPrevious_a.show();
        bottomPrevious_a.prev().show();
        bottomPrevious_a.prev().prev().show();
        bottomPrevious_a.prev().prev().prev().show();
      }else if(spantext.text()==(totalpages - 1)){
        /* show next 1 and previous 3 links */
        next_a.show();
        previous_a.show();
        previous_a.prev().show();
        previous_a.prev().prev().show();

        bottomNext_a.show();
        bottomPrevious_a.show();
        bottomPrevious_a.prev().show();
        bottomPrevious_a.prev().prev().show();
      }
      else{
        /* show next 2 and previous 2 */
        previous_a.show();
        previous_a.prev().show();
        next_a.show();
        next_a.next().show();

        bottomPrevious_a.show();
        bottomPrevious_a.prev().show();
        bottomNext_a.show();
        bottomNext_a.next().show();
      }
    }else if((spantext.text()=="1")||(spantext.text()==1)){
      next_a.show();
      next_a.next().show();
      next_a.next().next().show();
      next_a.next().next().next().show();

      bottomNext_a.show();
      bottomNext_a.next().show();
      bottomNext_a.next().next().show();
      bottomNext_a.next().next().next().show();
    }else if((spantext.text()=="2")||(spantext.text()==2)){
      /* now we show previous 1 elements */
      previous_a.show();
      /* show next 2 elements */
      next_a.show();
      next_a.next().show();
      next_a.next().next().show();

      bottomPrevious_a.show();
      bottomNext_a.show();
      bottomNext_a.next().show();
      bottomNext_a.next().next().show();
    }
  }
}

/* common tooltip function - 19 July 2010 */
function new_tool_tip(){  
  jQuery('.newtooltip').live('mouseover', function() {
    if (!jQuery(this).data('init')) {
      jQuery(this).data('init', true);
      jQuery('.newtooltip').hoverIntent(function(){
        var pos = jQuery(this).offset();
        var result = jQuery(window).width() - pos.left;
        var right = jQuery(this).parent().width() > 100 ? jQuery(this).parent().width() * 2 : jQuery(this).parent().width() * 3;
        var width = jQuery(this).width();
        var div = jQuery(this).next()
        var height = div.height();
        if(result < 400){
          div.css({
            "margin-left": (width+5) + "px",
            "margin-top": "-" + (height/2) + "px",
            "position": "absolute",
            "right":right+"px"
          });
        }else{
          div.css({
            "margin-left": (width+25) + "px",
            "margin-top": "-" + (height/2) + "px",
            "position": "absolute"
          });
        }
        div.fadeIn(300);
      },
      function() {
        jQuery('.tooltip').fadeOut(100);
      });
      jQuery(this).trigger('mouseover');
    }
  });
  if(jQuery('.livia_newtooltip').length > 0){
    jQuery('.livia_newtooltip').hoverIntent(function(){
      var pos = jQuery(this).offset();
      var result = jQuery(window).width() - pos.left;
      var width = jQuery(this).width();
      var div = jQuery(this).next()
      var height = div.height();
      var right = jQuery(this).parent().width() > 100 ? jQuery(this).parent().width() * 2 : jQuery(this).parent().width() * 3;
      if(result < 400){
        div.css({
          "margin-left": (width+5) + "px",
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute",
          "right":right + "px"
        });
      }else{
        div.css({
          "margin-left": (width+25) + "px",
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute"
        });
      }//end if
      div.fadeIn(300);
    },
    function() {
      jQuery('.tooltip').fadeOut(100);
    });
  }
  if(jQuery('.icon_scrollhover').length > 0){
    jQuery('.icon_scrollhover').hoverIntent(function(){
      jQuery(".icon_scrollhover").next(".tooltip").hide();
      var pos = jQuery(this).offset();
      var result = jQuery(window).width() - pos.left;
      var width = jQuery(this).width();
      var div = jQuery(this).next()
      var height = div.height();
      var right = jQuery(this).parent().width() > 100 ? jQuery(this).parent().width() * 2 : jQuery(this).parent().width() * 3;
      if(result < 400){
        div.css({
          "margin-left": (width+5) + "px",
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute",
          "right":right + "px"
        });
      }else{
        div.css({
          "margin-left": (width+25) + "px", //changes done for mouseover hover alignment ganesh 10052011
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute"
        });
      }//end if
      div.fadeIn(300);
    },
    function() {
      jQuery(".icon_scrollhover").next(".tooltip").hover(function(){
        /* Do nothing when hover */
        },function() {
          /* Close when hover out */
          jQuery('.tooltip').fadeOut(100);
        });

    });
  }
  if(jQuery('.icon_scrollhoverutility').length > 0){
    jQuery('.icon_scrollhoverutility').hoverIntent(function(){
      var pos = jQuery(this).offset();
      var result = jQuery(window).width() - pos.left;
      var width = jQuery(this).width();
      var div = jQuery(this).next()
      var height = div.height();
      var right = jQuery(this).parent().width() > 100 ? jQuery(this).parent().width() * 2 : jQuery(this).parent().width() * 3;
      if(result < 400){
        div.css({
          "margin-left": (width+5) + "px",
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute",
          "right":right + "px"
        });
      }else{
        div.css({
          "margin-left": (width-5) + "px",
          "margin-top": "-" + (height/2) + "px",
          "position": "absolute"
        });
      }//end if
      div.fadeIn(300);
    },
    function() {
      jQuery(".icon_scrollhoverutility").next(".tooltip").hover(function(){
        /* Do nothing when hover */
        },function() {
          /* Close when hover out */
          jQuery('.tooltip').fadeOut(100);
        });
    });
  }
}

function blink_text(){
  if(jQuery(".blink").length > 0){
    setInterval("blink()",777);
  }
}

function blink(){
  var i =0;
  blinkElements = jQuery('.blink');
  if(blinkElements.length > 0){
    for(i=0; i < blinkElements.length; i++){
      if(blinkElements[i].style.visibility==''){
        blinkElements[i].style.visibility='hidden';
      }else{
        blinkElements[i].style.visibility='';
      }
    }
  }
}

function same_value_check(){
  jQuery("#account_toll_free_phone").focusout(function(){
    if(jQuery("#account_phone").val() ||jQuery("#account_toll_free_phone").val()!=""){
      if(jQuery("#account_phone").val() == jQuery("#account_toll_free_phone").val()){
        alert("Phone 1 and Phone 2 can not be same.");
        jQuery("#account_toll_free_phone").val("");
        jQuery("#account_toll_free_phone").focus();
      }
    }
  });
}

function check_if_matter_available( matterid ){
  jQuery("#loading_imagediv3").show();
  var is_appointment = jQuery("#matter_task_category_appointment_calendar").attr('checked');  
  if(matterid==""){
    jQuery.ajax({
      type: 'GET',
      url: '/calendars/create_activity',
      success: function(transport){
        jQuery("#matter").html(transport);
        jQuery("#loading_imagediv3").hide();
      }
    });
  }else{
    if(jQuery("#new_zimbra_activity").length > 0){
      jQuery.ajax({
        type: 'GET',
        url: '/calendars/create_matter_activity',
        data: {
          'matterid' : matterid,
          'from' : 'calendars'
        },
        success: function(transport){
          jQuery("#matter").html(transport);
          jQuery("#loading_imagediv3").hide();
        }
      });
    }else{
      var inputs = jQuery("#new_matter_task :input");
      var values = [];
      jQuery(inputs).each(function(){
        if(this.type=="checkbox"||this.type=="button"||this.type=="submit"){
        }else{
          if(this.id==""||this.id=="matter_task_assigned_to_matter_people_id"||this.id=="matter_task_submit"){ }
          else{
            values.push(this);
          }
        }
      });
      jQuery.ajax({
        type: 'GET',
        url: '/calendars/create_matter_activity',
        data: {
          'matterid' : matterid,
          'is_appointment' : is_appointment,
          'from' : 'calendars'
        },
        success: function(transport){
          jQuery("#matter").html(transport);
          jQuery(values).each(function(){
            if(this.type=="radio"){
              jQuery("#"+this.id).attr("checked", this.checked);
              if(this.id=="matter_task_category_appointment" || this.id=="matter_task_category_todo"){
                if(this.id=="matter_task_category_appointment" && jQuery("#matter_task_category_appointment").attr("checked")){
                  jQuery("#task_personal_todo_div").hide();
                  jQuery("#task_personal_appointment_div").show();
                }else{
                  jQuery("#task_personal_appointment_div").hide();
                  jQuery("#task_personal_todo_div").show();
                }
              }
            }else{
              jQuery("#"+this.id).val(this.value);
            }
          });
          jQuery("#loading_imagediv3").hide();
        }
      });
    }
  }
}

function zimbra_activities_attendees_autocomplete( cid ){
  jQuery(document).ready(function(){
    var url = "/contacts/attendees_autocomplete";
    var comma = ",";
    jQuery("#zimbra_activity_attendees_emails").autocomplete(url, {
      multiple : true,
      multipleSeparator : comma,
      cacheLength : 1,
      extraParams : {
        company_id : cid,
        appointee_ids : function() {
          jQuery("#appointee_ids").val()
        }
      }
    }).result(function(event, data, formatted) {
      var ids = jQuery("#appointee_ids").val();
      if(ids != ""){
        ids = ids + "," + data[1];
      }else{
        ids = data[1];
      }
      jQuery("#appointee_ids").val(ids);
    });
  });
}

function zimbra_activities_attendees_autocomplete_new( cid ){
  jQuery(document).ready(function(){
    var url = "/matter_peoples/attendees_autocomplete_new";
    var comma = ",";
    jQuery("#zimbra_activity_attendees_emails").autocomplete(url, {
      multiple : true,
      multipleSeparator : comma,
      cacheLength : 1, // NO CACHE!          
      extraParams : {
        company_id : cid,
        appointee_ids : function() {
          jQuery("#appointee_ids").val()
        }
      }
    }).result(function( event, data, formatted ) {
      var ids = jQuery("#appointee_ids").val();
      if(ids=="Search or type an email-id"){
        ids=""
      }
      if (ids != "") {
        ids = ids + "," + data[1];
      } else {
        ids = data[1];
      }
      jQuery("#appointee_ids").val(ids);
      if(jQuery.trim(jQuery("#appointee_ids").val())==""){
        jQuery("#appointee_ids").val("");
        jQuery("#appointee_ids").addClass("textgrey");
        jQuery("#appointee_ids").val("Search or type an email-id");
      }
    });
  });
}

function remove_from_attendees_list( assignees_list, get_assignees, assigned_to, matter_id, from_where, todo_radio_id ){
  var is_todo = jQuery('#'+todo_radio_id).attr('checked');  
  if(!is_todo){
    var assignees = jQuery('#'+assignees_list).size();
    if(assignees > 0){
      jQuery("#loading_imagediv3").show();
      var assgnd_id = jQuery("#"+assigned_to+" option:selected").val();
      var att_len = jQuery("#"+get_assignees+" option").size();
      var attnd_emails = new Array();
      for(i=0;i<att_len;i++){
        attnd_emails.push(jQuery("#"+get_assignees+" option:eq("+i+")").val());
      }
      jQuery.ajax({
        type: 'GET',
        url: '/calendars/search_assignees',
        data: {
          'assgnd_id' : assgnd_id,
          'attnd_emails' : attnd_emails,
          'matter_id' : matter_id,
          'from' : from_where
        },
        success: function(transport){
          jQuery("#loading_imagediv3").hide();
        }
      });
    }
  }
}

function validate_contact_presence(){
  jQuery('#_contact_ctl').change(function(){
    if(jQuery.trim(jQuery('#_contact_ctl').val()) == '' || jQuery('#_contact_ctl').val() == 'Search Existing'){
      jQuery('#_contactid').val('');
      jQuery("#_accconname").val('');
    }
  });
}

//Following 3 methods are used for updating duration and cancel duration, previously it was used for the split duration
function split_entries(btn, id ){
  var newrecrd;
  var old_finalbilled_amt = jQuery("#old_textfield_billed_amt"+id).val();
  var new_record_val = jQuery("#new_duration"+id).val();  
  var old_record_val = jQuery("#old_duration"+id).val();
  if(parseFloat(old_record_val)< 24){
    if(new_record_val==0 || new_record_val==""){
      newrecrd = false
    }
    else{
      newrecrd = true
    }
    cancel_split_entry(btn, id);
    jQuery.ajax({
      type: 'GET',
      url: '/physical/timeandexpenses/time_and_expenses/split_entries',
      data:{
        'newrecrd' : newrecrd,
        'old_id' : id,
        'old_duration': parseFloat(old_record_val).toFixed(2),
        'new_record_val' : parseFloat(new_record_val).toFixed(2),
        'old_finalbilled_amt' : parseFloat(old_finalbilled_amt).toFixed(2)
      },
      success: function(transport){
        window.location.reload();
      }
    });
  }
  else{
    alert("Duration can not be greater than 24 hrs. Enter valid duration");
    return false;
  }
}

/* this is for spliting the duration in time and expense module */
function split_duration_for_entry( div, id ){
  var divid = "#"+div
  var classes = jQuery(".split_duration_for_entry");
  jQuery(classes).each(function(){
    var thisid = this.id
    var id = thisid.split("pre");
    var v = jQuery("#"+thisid).next().val();
    jQuery("#"+thisid).html("<span class=\"vtip\" title=\"Click to Split/Edit\" onClick=\"split_duration_for_entry('"+thisid+"', '"+id[1]+"')\">"+v+"</span>")
  });
  jQuery.ajax({
    type: 'GET',
    url: '/physical/timeandexpenses/time_and_expenses/split_entries_div',
    data:
    {
      'split_entryid' : id
    },
    success: function(transform){
      jQuery("p#vtip").fadeOut("fast").remove();
      jQuery(divid).html(transform);
      vtip();
    }
  });
}

// For canceling the entry
function cancel_split_entry( link, id ){
  var thisid = "split_duration_for_entry_pre"+id
  var v = jQuery("#"+thisid).next().val();
  jQuery("#"+thisid).html("<span class=\"vtip\" title=\"Click to Split/Edit\" onClick=\"split_duration_for_entry('"+thisid+"', '"+id+"')\">"+v+"</span>")
  jQuery("#billed_amount_"+id).html(jQuery("#old_textfield_billed_amt"+id).val());
  jQuery("#final_billed_amount_"+id).html(jQuery("#prev_amt_bill_amt"+id).val());
  vtip();
}

function update_contact_email( emailid ){
  var emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
  if(emailid=="" || (!emailReg.test(emailid)) ){
    show_error_msg('matter_email_error','Please Enter Valid Email','message_error_div');
  }else{
    jQuery.ajax({
      type: 'GET',
      url: "/matters/validate_email.json",
      data: {
        'email_id' : emailid
      },
      success: function(data){
        if(data.exists){
          show_error_msg('matter_email_error',data.msg,'message_error_div');
        }else{
          tb_remove();
          jQuery("#contact_email").val(emailid);
        }
      }
    });
  }
}

function check_contact(){
  var contact_ctl=jQuery("#_contact_ctl").val();
  var contact_id=jQuery("#_contactid").val();
  if(jQuery('#matter_client_access').is(':checked')){
    if(contact_ctl=="" || contact_ctl=="Search Existing"){
      alert("Please select the contact");
      jQuery('#matter_client_access').attr('checked', false);
    }else{
      if(jQuery("#contact_email").val()==""){
        var c=confirm("Do you want this client to have client portal access?")
        if(c){
          tb_show('Client Email','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
        }else{
          jQuery('#matter_client_access').attr('checked', false);
        }
      }
    }
  }
}

function check_matter_contact(){
  var contact_id=jQuery("#matter_contact_id").val();
  if(jQuery('#matter_client_access').is(':checked')){
    if(jQuery("#contact_email").val()==""){
      tb_show('New Matter Client','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
    }
  }
}

function check_for_share_with_client( matter_id, permn, mattercontactid, select ){
  jQuery('#contact_email').removeClass('selected');
  var contact_id=jQuery("#matter_contact_id").val();
  jQuery('body').css("cursor", "wait");
  jQuery.ajax({
    type: 'GET',
    url: "/matters/get_client_contact",
    data: {
      'contact_id' : contact_id,
      'matter_id'  : matter_id
    },
    beforeSend: function(){
      jQuery('#matter_client_access').attr('disabled', true);
    },
    complete: function(){
      jQuery('#matter_client_access').attr('disabled', false);
    },
    success: function(transport){
      jQuery('body').css("cursor", "default");
      if(jQuery("#contact_email").val()=="" && jQuery('#contact_email').hasClass('selected') ){
        var c=confirm("Do you want this client to have client portal access?")
        if(c){
          tb_show('Client Email','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
        }else{
          jQuery('#matter_client_access').attr('checked', false);
        }
      }
    }
  });
}

function show_email_validation( checkbox ){  
  var contact_id=jQuery("#matter_contact_id").val();  
  if(checkbox.checked){
    if(contact_id == "")
      {
        alert('Please select/create new contact');
        jQuery('#matter_client_access').attr('checked', false);
        return false;
      }
    if(jQuery("#contact_email").val()==""){
      var c=confirm("Do you want this client to have client portal access?")
      if(c){
        tb_show('Client Email','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
      }else{
        jQuery('#matter_client_access').attr('checked', false);
      }
    }
  }
}

//this function added for the Bug #6688 Reason Field does not display -- Rahul P.
function stage_reason( action, contact_change_status ){
  if (action == 'update' && contact_change_status == 'true'){
    jQuery('#notes').show();
  }else{
    jQuery('#notes').hide();
  }
}

/* Creator vs Owner : * Supriya Surve - 26th May 2011 - 15:53 */
function check_owner_and_people_access( selection, user, secretary, action, owner, access_rights ){
  var select_tag = jQuery("select#document_home_owner_user_id");
  var checkboxes = jQuery("#selective").children('td').children("table").children("tbody").children("tr");
  var employeeid, employee_name, option_tag;  
  if(selection=="private"){
    checkboxes.each(function(){
      employeeid = jQuery(this).children("td:first").attr("name");
      employee_name = jQuery(this).children("td:last").html();
      option_tag = select_tag.children('option[value='+employeeid+']');
      if(option_tag.length==0){
        select_tag.children('option:first').before("<option value='"+employeeid+"'>"+employee_name+"</option>");
      }
    });
    if(select_tag.children("option:selected").val()!=user && user==owner){
      select_tag.children("option:selected").removeAttr("selected");
      select_tag.children('option[value='+user+']').attr("selected", "selected");
    }
  }else if(selection=="select"){
    if(user==owner){
      select_tag.removeAttr("disabled");
    }
    checkboxes.each(function(){
      employeeid = jQuery(this).children("td:first").attr("name");
      var checkbx = jQuery(this).children("td:first").children("input");
      if(action=="edit"){
        if(checkbx.attr("disabled")){
          checkbx.attr("checked", 'checked');
          var checkval = checkbx.val();
          jQuery(".check_owner_creator"+checkval).remove();
          if(jQuery(".check_owner_creator"+checkval).length==0){
            checkbx.after("<input type=\"hidden\" value='"+checkval+"' name=\"document_home[matter_people_ids][]\" id=\"document_home_matter_people_ids_\" class=\"check_owner_creator"+checkval+"\">")
          }
        }
      }
      if(!(jQuery(this).children("td:first").children("input").attr("checked"))){
        select_tag.children('option[value='+employeeid+']').remove();
      }
    });
  }else{
    if(select_tag.attr("disabled") && user==owner){
      select_tag.removeAttr("disabled");
    }
    checkboxes.each(function(){
      employeeid = jQuery(this).children("td:first").attr("name");
      employee_name = jQuery(this).children("td:last").html();
      option_tag = select_tag.children('option[value='+employeeid+']');
      if(option_tag.length==0){
        select_tag.children('option:first').before("<option value='"+employeeid+"'>"+employee_name+"</option>");
      }
    });
  }
}

function check_owner( checkbox, id, name ){
  var select_tag = jQuery("select#document_home_owner_user_id");
  var option_tag = select_tag.children('option[value='+id+']');
  if(checkbox.checked){
    if(jQuery(checkbox).attr("checked")){
      jQuery(checkbox).attr("checked", "checked");
    }
    if(option_tag.length==0){
      select_tag.children('option:first').before("<option value='"+id+"'>"+name+"</option>");
    }
  }else{
    jQuery(checkbox).removeAttr('checked');
    if(option_tag.length>0){
      option_tag.remove();
    }
  }
}

function check_if_selective(){
  if(jQuery("#access_control_selective").attr("checked")){
    var select_tag = jQuery("select#document_home_owner_user_id");
    var checkboxes = jQuery("#selective").children('td').children("table").children("tbody").children("tr");
    checkboxes.each(function(){
      var employeeid = jQuery(this).children("td:first").attr("name");
      var checkbox = jQuery(this).children("td:first").children("input");
      if(!checkbox.attr("checked")){
        select_tag.children('option[value='+employeeid+']').remove();
      }
      if(checkbox.attr("disabled")){
        checkbox.attr("checked", 'checked');
        var checkval = checkbox.val();
        jQuery(".check_owner_creator"+checkval).remove();
        if(jQuery(".check_owner_creator"+checkval).length==0){
          checkbox.after("<input type=\"hidden\" value='"+checkval+"' name=\"document_home[matter_people_ids][]\" id=\"document_home_matter_people_ids_\" class=\"check_owner_creator"+checkval+"\">")
        }
      }
    });
  }
}

function check_document_access_rights( param1, param2, param3, note, access, selected_employee, secretary, action, owner,access_rights ){
  showaccessdetails(param1, param2);
  jQuery('#document_home_client_access').attr('disabled', param3);
  jQuery('#help_message_doc').text(note);
    jQuery('#help_message').text(note);
  check_owner_and_people_access(access, selected_employee, secretary, action, owner, access_rights);
}

function check_access_for_submit(btn){
  if((jQuery("#matter_people_can_access_matter").attr("checked") && jQuery("#share_with_client").val()=="true")&& (jQuery.trim(jQuery("#matter_people_email").val())=="" && jQuery.trim(jQuery("#matter_people_name").val())=="")){
    jQuery(".matters").removeAttr("disabled");
    jQuery(btn).val("Save");
    show_error_msg('matter_client_contact_errors',"Email can't be blank <br/> First Name can't be blank",'message_error_div');
    return false;
  }else if((jQuery("#matter_people_can_access_matter").attr("checked") && jQuery("#share_with_client").val()=="true")&& jQuery.trim(jQuery("#matter_people_email").val())==""){
    jQuery(".matters").removeAttr("disabled");
    jQuery(btn).val("Save");
    show_error_msg('matter_client_contact_errors',"Email can't be blank",'message_error_div');
    return false;
  }
  return true;
}

//On toggle between appointment and todo in new activity page following fields need to be toggled - Ketki 08/06/2011
function toggle_todo_appointment_for_activity( category, task_todo, task_appointment, mandatory_task, subtask, sub_task_label, act_type_app, act_type_todo, appointment_category, todo_category, complete_span, matter_task_completed ){
  if(category == 'todo'){
    jQuery('#'+task_todo).show();
    jQuery('#'+task_appointment).hide();
    jQuery('#'+mandatory_task).hide();
    jQuery('#'+subtask).show();
    jQuery('#'+sub_task_label).show();
    jQuery('#'+act_type_app).hide();
    jQuery('#'+act_type_todo).show();
    jQuery('#'+appointment_category).attr('disabled','disabled');
    jQuery('#'+todo_category).attr('disabled',false);
    jQuery('#'+complete_span).show();
    jQuery('#'+matter_task_completed).attr('disabled','');
  }else{
    jQuery('#'+task_todo).hide();
    jQuery('#'+task_appointment).show();
    jQuery('#'+subtask).hide();
    jQuery('#'+sub_task_label).hide();
    jQuery('#'+act_type_app).show();
    jQuery('#'+act_type_todo).hide();
    jQuery('#'+todo_category).attr('disabled','disabled');
    jQuery('#'+appointment_category).attr('disabled',false);
    jQuery('#'+complete_span).hide();
    jQuery('#'+matter_task_completed).attr('disabled','disabled');
  }
}

// On checking or unchecking completed in activity new/edit page it's date picker needs to be toggled -Ketki 08/06/2011
function showCompletionTable( completed_div_hide ){
  jQuery('#'+completed_div_hide).toggle();
}

function redirect_to_new_action(entrytype, params){
  var action, location;
  if(entrytype=="time"){
    action = "new_time_entry"
    location = '/physical/timeandexpenses/'+action+"?time_entry_date="+params
  }else{
    action = "add_expense_entry"
    location = '/physical/timeandexpenses/'+action+"?expense_entry_date="+params
  }
  window.location.href=location;
}

function filterInvoice(mode,cancelled_status){
  if(cancelled_status==undefined || cancelled_status=='')
    document.location.href = "/tne_invoices?mode_type="+mode;
  else
    document.location.href = "/tne_invoices?mode_type="+mode+"&status="+cancelled_status;
}

function calculate_primary_secondary_tax(){
  var p_entryid, s_entryid;
  var view = jQuery("#tne_invoice_view_by").val();
  var ttotal=0,etotal=0,grand_total = 0,tmp=0;
  if(jQuery("#apply_primary_tax").attr("checked")){
    var ptaxrate = parseFloat(jQuery("#tne_invoice_primary_tax_rate").val());
    var ptaxary = 0;
    jQuery(".p_tax_time:checked").each(function(){
      p_entryid = jQuery(this).next().attr("id").split("_")[4];
      tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"time");
      jQuery(this).next().val(tmp);
      ttotal += tmp;
    });
    jQuery(".p_tax_expense:checked").each(function(){
      p_entryid = jQuery(this).next().attr("id").split("_")[4];
      tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"expense");
      jQuery(this).next().val(tmp);
      etotal += tmp;
    });
    grand_total = ttotal + etotal;
    grand_total = floatToTwoDecimalPlaces(grand_total);

    if(view=="Summary"){
      ptaxary += grand_total;
    }else{
      ptaxary = calculateChangesPrimaryTax(".time_entry_p_tax_time", "time", ptaxrate);
      ptaxary += calculateChangesPrimaryTax(".time_entry_p_tax_expense", "expense", ptaxrate);
    }
    jQuery("#primary_tax_value").val(addCommas(ptaxary));
  }

  if(jQuery("#apply_secondary_tax").attr("checked")){
    var staxrate = parseFloat(jQuery("#tne_invoice_secondary_tax_rate").val());
    var staxary = 0;
    var secondary_tax_rule = jQuery('#tne_invoice_secondary_tax_rule').val();
    ttotal=0,etotal=0,grand_total = 0,tmp=0;
    jQuery(".s_tax_time:checked").each(function(){
      s_entryid = jQuery(this).next().attr("id").split("_")[4];
      tmp = CalculateSummarySecondaryTax(s_entryid,staxrate,"time",secondary_tax_rule);
      jQuery(this).next().val(tmp);
      ttotal += tmp;
    });
    jQuery(".s_tax_expense:checked").each(function(){
      s_entryid = jQuery(this).next().attr("id").split("_")[4];
      tmp = CalculateSummarySecondaryTax(s_entryid,staxrate,"expense",secondary_tax_rule);
      jQuery(this).next().val(tmp);
      etotal += tmp;
    });
    grand_total = ttotal + etotal;
    grand_total = floatToTwoDecimalPlaces(grand_total);
    if(view=="Summary"){
      staxary += grand_total;
    }else{
      staxary = calculateChangesSecondaryTax(".time_entry_s_tax_time","time",staxrate,secondary_tax_rule,ptaxrate);
      staxary += calculateChangesSecondaryTax(".time_entry_s_tax_expense","expense",staxrate,secondary_tax_rule,ptaxrate);
    }
    jQuery("#secondary_tax_value").val(addCommas(staxary));
  }

  var chkd = 0
  if(jQuery('#apply_final_discount').attr("checked")){
    chkd = parseFloat(jQuery("#tne_invoice_discount").val().replace(/\,/g,''));
  }
  jQuery("#tne_invoice_discount").val(addCommas(chkd));
    
  var primary_tax= jQuery("#primary_tax_value");
  var secondary_tax = jQuery("#secondary_tax_value");
  if (secondary_tax.val() == ""){
    secondary_tax.val("0.00");
  }
  if (primary_tax.val()== ""){
    primary_tax.val("0.00");
  }
  var v = parseFloat(jQuery("#tne_invoice_invoice_amt").val().replace(/\,/g,'')) + parseFloat(primary_tax.val().replace(/\,/g,'')) + parseFloat(secondary_tax.val().replace(/\,/g,''));
  jQuery("#tne_invoice_final_invoice_amt").val(addCommas(parseFloat(v - chkd)));
  return false;
}

//entry_type is to distinguish between time and expense entry 
function check_uncheck_sub_entries( chk, id, invoice, entry_type ){
  var view = jQuery("#tne_invoice_view_by").val();
  if(jQuery(chk).hasClass("p_tax")){
    jQuery(".tne_p_tax_"+id).each(function(){
      var c = jQuery(this).children("input.time_entry_p_tax_"+entry_type);
      if(chk.checked){
        c.removeAttr("disabled");
        c.attr("checked", true);
        if(view=="Summary"){
          c.attr("disabled", true);
          c.next().next().attr("name", c.attr("name"));
          c.next().next().val(true);
        }else{
          c.next().next().val(true);
        }
      }else{
        c.removeAttr("disabled", false);
        c.attr("checked", false);
        if(view=="Summary"){
          c.attr("disabled", true);
          c.next().next().attr("name", c.attr("name"));
          c.next().next().val(false);
        }else{
          c.next().next().val(false);
        }
      }
    });
  }else{
    jQuery(".tne_s_tax_"+id).each(function(){
      var c = jQuery(this).children("input.time_entry_s_tax_"+entry_type);
      if(chk.checked){
        c.removeAttr("disabled");
        c.attr("checked", true);
        if(view=="Summary"){
          c.attr("disabled", true);
          c.next().next().attr("name", c.attr("name"));
          c.next().next().val(true);
        }else{
          c.next().next().val(true);
        }
      }else{
        c.removeAttr("disabled", false);
        c.attr("checked", false);
        if(view=="Summary"){
          c.attr("disabled", true);
          c.next().next().attr("name", c.attr("name"));
          c.next().next().val(false);
        }else{
          c.next().next().val(false);
        }
      }
    });
  }
}


function check_uncheck_main_tax(checkbox, type, id, invoice, entry_type){
  if(checkbox.checked) {
    if(type=="ptax") {
      jQuery("#" + entry_type + "_header_ptax_hidden_"+id).prev().attr("checked", true);
    } else {
      jQuery("#" + entry_type + "_header_stax_hidden_"+id).prev().attr("checked", true);
    }
  } else {
    if (type=="ptax" && jQuery("." + entry_type + "_primary_" + id +":checked").length == 0) {
      jQuery("#" + entry_type + "_header_ptax_hidden_"+id).prev().attr("checked", false);
    } else if (jQuery("." + entry_type + "_secondary_" + id +":checked").length == 0) {
      jQuery("#" + entry_type + "_header_stax_hidden_"+id).prev().attr("checked", false);
    }
  }
}

function can_access_matter_checked(){
  matter_access_checked();
  matter_primary_checked();
  jQuery("#matter_people_can_access_matter").click(function(){
    matter_access_checked();
  });
  jQuery("#primary_matter_contact").click(function(){
    matter_primary_checked();
  });
}

function  matter_access_checked(){
  var email_mandatory = jQuery("#email_mandatory")
  if(jQuery("#matter_people_can_access_matter").attr("checked")){
    email_mandatory.html("&#42;");
    jQuery('#either').hide();
    jQuery('#phone_mandatory').hide();
  }else{
    email_mandatory.html("&#35;");
    jQuery('#either').show();
    jQuery('#phone_mandatory').show();
  }
}

function matter_primary_checked(){
  if(jQuery("#primary_matter_contact").attr("checked")){
    jQuery("#matter_people_role_text").val("Primary Matter Contact");
    jQuery("#matter_people_role_text").attr("readonly", true);
  }else{
    jQuery("#matter_people_role_text").removeAttr("readonly");
    jQuery("#matter_people_role_text").val("");
  }
}

function add_external_assignees( btn ){
  var textarea = jQuery(btn).parent().prev().children("textarea");
  var textarea_value = textarea.val();
  if(!textarea_value=="Search or type an email-id" || !jQuery.trim(textarea_value)==""){    
    var textarea_value_array = textarea_value.split(",");
    jQuery.each(textarea_value_array, function(){
      var email = jQuery.trim(this)
      if(!email==""){
        if(jQuery("#matter_task_attendees_emails option[value='"+email+"']").length==0){
          jQuery("#matter_task_attendees_emails").append("<option value="+email+" class='external'>"+email+"</option>");
          jQuery(email).replaceWith("");
        }else{
          alert("Email ID '"+email+"' already present in attendees list.")
        }
      }
    });
    textarea.val("");
  }
}

function remove_external_assignees( btn, assignees_id ){
  var textarea = jQuery(btn).parent().prev().children("textarea");
  var select_tag_options = jQuery("#matter_task_attendees_emails option:selected");
  select_tag_options.each(function(){
    var textarea_value = textarea.val();
    if(jQuery(this).hasClass("external")){
      textarea.val(textarea_value+this.value+",")
    }else{
      jQuery("#"+assignees_id).append("<option value="+this.value+">"+jQuery(this).attr("class")+"</option>");
    }
    jQuery(this).remove();
  });
}

function add_assignees(assignees_id, get_assignees_id){
  var assignee_ids = jQuery("#"+assignees_id).val();
  if(assignee_ids && assignee_ids.length > 0){
    jQuery("#loading_imagediv2").show()
    var a_ids = new Array();
    a_ids = jQuery("#"+assignees_id).val();
    for(var i in a_ids){
      var idx = jQuery("#"+assignees_id+" option").index(jQuery("#"+assignees_id+" option[value='"+a_ids[i]+"']"));
      var add_opt_name = jQuery("#"+assignees_id+" option:eq("+idx+")").html();
      var add_opt_val = jQuery("#"+assignees_id+" option:eq("+idx+")").val();
      jQuery("#"+get_assignees_id+" select").append("<option value="+add_opt_val+" class='"+add_opt_name+"'>"+add_opt_val+"</option>");
      jQuery("#"+assignees_id+" option:eq("+idx+")").remove();
    }
    jQuery("#loading_imagediv2").hide();
  }
}

function remove_assign(){
  var selected_value= jQuery('#matter_task_assigned_to_matter_people_id option:selected').text();
  jQuery('#matter_task_attendees_emails option').each(function(){
    var chkvalue=jQuery(this).text();
    if(selected_value== chkvalue){
      jQuery(this).remove();
    }
  });
}

function remove_assignees( get_assignees_id, assignees_id, textarea ){
  textarea = jQuery("#"+textarea);
  var select_tag_options = jQuery("#matter_task_attendees_emails option:selected");
  select_tag_options.each(function(){
    var textarea_value = textarea.val();
    if(jQuery(this).hasClass("external")){
      textarea.val(textarea_value+this.value+",")
    }else{
      if(jQuery(this).attr("class")){
        jQuery("#"+assignees_id).append("<option value="+this.value+">"+jQuery(this).attr("class")+"</option>");
      }
    }
    jQuery(this).remove();
  });
}

function remove_gray_text( obj ){
  if(obj.value=='Search or type an email-id'){
    obj.value ='';
    jQuery('#'+obj.id).removeClass('textgray');
  }
}

function add_gray_text( obj, people_attendees_emails ){
  if(obj.id == people_attendees_emails && jQuery.trim(jQuery(obj).val()) == ''){
    obj.value = 'Search or type an email-id';
    jQuery('#'+obj.id).addClass('textgray')
  }
}

function display_internal_external( link ){
  jQuery(".tabLink").removeClass("activeLink");
  jQuery(link).addClass("activeLink");
  jQuery(".tabcontent").addClass("hide");
  jQuery("#"+link.id+"-1").removeClass("hide");
  return false;
}

function replace_delimitor( number ){
  number = number.replace(/\,/g,'');
  return number;
}

function validate_end_date( start_dateid, end_dateid, input ){
  var enddate = new Date(jQuery(end_dateid).val());
  var startdate = new Date(jQuery(start_dateid).val());
  if(enddate != "" && startdate != ""){
    if(enddate < startdate){
      alert("End Date should be greater than Start Date");
      input.value = ""
    }
  }
}

function openThicboxForInvoice(link){ 
  jQuery("#TB_window").css("display","block");
  tb_show("New Invoice <span class='title_value'>  </span>",link,"","");
  jQuery("#TB_ajaxWindowTitle").html("New Invoice <span class='title_value'>  </span>");
}

function displayInvoiceNo( obj ){
  //if not opened through openThicboxForInvoice
  jQuery("#TB_ajaxWindowTitle").html("New Invoice <span class='title_value'>  </span>");
  var invoice_no =jQuery(obj).val();
  jQuery('.title_value').text(invoice_no);
}

/* Below functions are used in document manager : Pratik : 31-10-11 */
function enable_search(){
  jQuery('#submit_search').val('Search');
  jQuery('#submit_search').attr("disabled",false);
  jQuery("#contextual_search").attr("src",'/images/zoom_icon.png');
}

function enable_date(){
  livia_datepicker();
  jQuery('#search_date_type').attr('disabled', false);
  jQuery('#search_from_date').attr('disabled', false);
  jQuery('#search_to_date').attr('disabled', false);
  jQuery('.ui-datepicker-trigger').attr('disabled', false);
  livia_matter_inception_datepicker_new("#search_from_date");
  livia_matter_inception_datepicker_new("#search_to_date");
}

function disable_date(){
  jQuery('#search_date_type').attr('disabled', true);
  jQuery('#search_from_date').attr('value', '');
  jQuery('#search_to_date').attr('value', '');
  jQuery('#search_from_date').attr('disabled', true);
  jQuery('#search_to_date').attr('disabled', true);
  jQuery('.ui-datepicker-trigger').attr('disabled', true);
}

function search_date_enable_disable(){
  if (jQuery('input[name=search_date]:checked').val() == 5){
    enable_date();
  }else{
    disable_date();
  }
}

function get_privilege(){
  var access_rights = new Array();
  i = 0;
  jQuery('.search_ckb_privilege:checked').each(function(){
    access_rights[i++] = jQuery(this).val();
  });
  return access_rights;
}

function reset_advance_search_form(){
  resetForm('toggle_busi_cont_detail_div');
  jQuery('#matter_div').hide();
  jQuery('#opportunity_div').hide();
  jQuery('#tne_div').hide();
  jQuery('#campaign_div').hide();
  jQuery('#contact_div').hide();
  jQuery('#account_div').hide();
  jQuery('#document_name_adv').focus();
  jQuery('#search_date_type').val('<%=t(:text_modified_date)%>');
}

function document_managers_search( link, url ){
  if ( validate_search_date() ){
    var advance_search = jQuery("#advance_search").css('display')=='block';
    var loader = '/images/loading.gif'
    var contextual_text= ''
    var mapable =[]
    jQuery(link).attr("src",loader);
    if (link.id == 'submit_search'){
      jQuery('#submit_search').val('Please wait..');
      jQuery('#submit_search').attr("disabled",true);
    }
    jQuery('input[name=mapable_type\\[\\]]').each(function (){
      if (this.checked) {
        mapable.push(this.value);
      }
    });
    if (advance_search==false){
      mapable = [jQuery("#mapable").val()]
      if (jQuery('#text_search').attr("class")!='textgray'){
        contextual_text = jQuery('#text_search').val();
      }
      if (contextual_text==''){
        jQuery('#notice').fadeIn('slow').animate({
          opacity: 1.0
        }, 1000)
        .fadeOut('slow');
        enable_search();
        return false;
      }
    }else{
      if (jQuery('#document_name_adv').val()==''){
        jQuery('#notice').fadeIn('slow').animate({
          opacity: 1.0
        }, 6000)
        .fadeOut('slow');
        enable_search();
        return false;
      }
    }
    var data_1 = {
      'general_search' : contextual_text,
      'advance_search' : advance_search,
      'name' : jQuery('#document_name_adv').val(),
      'extension' : jQuery('#document_extension').val(),
      'description' : jQuery('#document_description').val(),
      'uploaded_by' : jQuery('#uploaded_by').val(),
      'access_rights' : get_privilege,
      'owner' : jQuery('#owner').val(),
      'tag' : jQuery('#document_tag').val(),
      'date' : jQuery('input[name=search_date]:checked').val(),
      'date_type' : jQuery('#search_date_type').val(),
      'date_from' : jQuery('#search_from_date').val(),
      'date_to' : jQuery('#search_to_date').val(),
      'mapable_type' : mapable,
      'matter_name' : jQuery('#matter_name').val(),
      'matter_lead_lawyer' : jQuery('#matter_lead_lawyer').val(),
      'matter_contact' : jQuery('#matter_contact').val(),
      'matter_access' : jQuery('#matter_access').val(),
      'matter_sub_matter' : jQuery('#matter_sub_matter').attr("checked"),
      'opportunity_name' : jQuery('#opportunity_name').val(),
      'opportunity_contact' : jQuery('#opportunity_contact').val(),
      'tne_employee_name' : jQuery('#tne_employee_name').val(),
      'tne_activity' : jQuery('#tne_activity').val(),
      'contact_name' : jQuery('#contact_name').val(),
      'account_name' : jQuery('#account_name').val(),
      'accounts_primary_contact' : jQuery('#accounts_primary_contact').val(),
      'campaigns_name' : jQuery('#campaigns_name').val(),
      'parent_campaign' : jQuery('#parent_campaign').val(),
      'document_type' : jQuery('#search_document_type').val(),
      'privilege' : jQuery('#privilege').val(),
      'client_docs' : jQuery('#client_docs').attr("checked")
    }
    var path_url =''
    if(typeof(url) != 'undefined' && url.length<=0){
      path_url= '/document_managers/search_document';
    }else{
      path_url = url
    }
    jQuery.get(
      path_url, data_1,
      function (data){
        jQuery('#resultant-content').html(data);
        enable_search();
      });
  }
}

function toggle_advance_search(advance_search){
  jQuery('#search').toggle();
  jQuery('#advance_search').toggle();
  if (advance_search == false){
    if (jQuery("#text_search").attr("class")!='textgray'){
      jQuery("#document_name_adv").val(jQuery("#text_search").val());
    }
  }else{
    if (jQuery("#document_name_adv").val()==''){
      jQuery("#text_search").val(jQuery('.jstree-clicked').text());
    }else{
      jQuery("#text_search").val(jQuery("#document_name_adv").val());
    }
  }
}

function set_data( current_node ){
  jQuery("#mapable").val(current_node.id);
  return {
    selected_node : current_node.id
  }
}

function send_ajax_to_documents_list( current_anchor_tag ){
  jQuery.ajax({
    //  method where the requets is sent to construct the right side  pane
    url : '/document_managers/documents_list',
    type : 'GET' ,
    data : set_data( current_anchor_tag ),

    success : function(data){
      // The below code is just remove to he loader image on completion
      jQuery(current_anchor_tag).attr('class',''),
      jQuery("#fileTree").jstree("deselect_all");
      jQuery("#fileTree").jstree("select_node",current_anchor_tag);
      // The below code is jsut replace the html of recieved from the ajax request on the corresponding div
      jQuery('#resultant-content').html(data);
      var innertext = jQuery(current_anchor_tag).text();
      jQuery("#text_search").val(innertext);
      jQuery("#text_search").addClass('textgray');
    }
  });
}

function anchor_tag_live(){
  jQuery("#folder-links a").live('click',function(event,data){
    var current_anchor_tag = event.currentTarget;
    jQuery(current_anchor_tag).attr('class','loading');
    send_ajax_to_documents_list(current_anchor_tag);
  });

  jQuery("#fileTree a").live('click',function(event,data) {
    var current_anchor_tag = event.currentTarget;
    jQuery(current_anchor_tag).attr('class','jstree-loading');
    jQuery('.search_hidden').val(set_data(current_anchor_tag).selected_node);
    send_ajax_to_documents_list(current_anchor_tag);
  });
}

/* Added for matter access periods : Shripad Joshi : 02-11-11 */
function assignAdditionalPriv() {
  jQuery(".additional_priv").show();
}

function clone_remove(){
  jQuery('.new_end_date_picker').remove();
}

function add_id_and_date_for_start(random_no ){
  var random_id = "matter_date_" + random_no + "_start_date"
  var random_name = "matter_date[" + random_no + "][start_date]";
  jQuery('.new_start_date_picker').last().attr('id', random_id);
  jQuery('.new_start_date_picker').last().attr('name', random_name);
  datepicker_matter_access_periods("#" + random_id);
  var prev_end_date = jQuery("#"+random_id).parent().parent().parent().parent().parent().prev().children().children().children().children().next().first().children('input').val();
  var incr_date = ""
  if(prev_end_date!=undefined){
    var d = new Date(prev_end_date);
    incr_date = d.date_increments(1);
  }else{incr_date = new Date();}
  jQuery("#"+random_id).val((incr_date.getMonth()+1)+'/'+incr_date.getDate()+'/'+incr_date.getFullYear());
}

function add_id_and_date_for_end(random_no ){
  var random_id = "matter_date_" + random_no + "_end_date"
  var random_name = "matter_date[" + random_no + "][end_date]";
  jQuery('.new_end_date_picker').last().attr('id', random_id);
  jQuery('.new_end_date_picker').last().attr('name', random_name);
  datepicker_matter_access_periods("#" + random_id);
}

function showHideFromToDates(show) {
  if (show) {
    jQuery(".from_date").show();
    jQuery("#clone").show();
  } else {
    jQuery(".from_date").hide();
    jQuery("#clone").hide();
  }
}

function get_randomno(){
  var d= new Date();
  var random_values = Math.floor(Math.random()*11);
  var random_no= d.getMilliseconds()+"_"+random_values;
  return random_no;
}

function matter_access_live_events(){

jQuery("#clone").click(function(){
    add_new();
    return false;
  });

}

function check_dates(btn){
  var prev_end_date = jQuery(btn).parent().parent().prev().children('input').val();
  if(prev_end_date==""){
    jQuery("#clone").show();
   }
  jQuery(btn).parent().parent().parent().parent().parent().remove();
}

function datepicker_matter_access_periods(field){
  jQuery(field).datepicker({
    showOn: 'both',
    dateFormat: 'mm/dd/yy',
    changeMonth: true,
    changeYear: true,
    onSelect: function(value,date){
      var newdate=new Date(value);
      jQuery(field).val((newdate.getMonth()+1)+'/'+newdate.getDate()+'/'+newdate.getFullYear());
      if(jQuery(field).hasClass("new_end_date_picker")){
        var prev_input_val = jQuery(field).parent().prev().children('input').val();
        if((new Date(prev_input_val)).getTime()>(new Date(jQuery(field).val())).getTime()){
          alert("Member from date cannot be less than to date");
          jQuery(field).val('');
          jQuery("#clone").hide();
        }else{
          jQuery("#clone").show();
        }
      }      
      if(jQuery(field).hasClass("new_start_date_picker")){
        var next_input_val = jQuery(field).parent().next().children('input').val();
        if((new Date(next_input_val)).getTime()<(new Date(jQuery(field).val())).getTime()){
          alert("Member from date cannot be less than to date");
          jQuery(field.split('_start_date')[0]+"_end_date").val('');
          jQuery("#clone").hide();
        }else{
          if(jQuery(field).parent().next().children('input').val()==''){
            jQuery("#clone").hide();
          }
          else{
            jQuery("#clone").show();
          }
        }
      }
    }
  });
}

// add n number of days
Date.prototype.date_increments = function(days) {
  new_date = new Date(this.getTime()+days*86400000);
  return new_date;
}

function searchDate(){
  var mode_type= jQuery('.mode_type:checked').val();
  var status= jQuery('#status option:selected').val();
  var cancelled_status = jQuery('#status').val();
  var start_date = jQuery('#date_start').val();
  var end_date = jQuery('#date_end').val();
  status = status == 'All'? '': status;
  status = status == undefined? cancelled_status:status;
  window.location.href='/tne_invoices?date_start='+start_date+'&date_end='+end_date+'&status='+status+'&mode_type='+mode_type;
}

function filterInvoiceStatus( date_start, date_end, start_date_present, end_date_present, selected_option, all_start, all_end ){
  var status= jQuery('#status option:selected').val();
  if (start_date_present=='true' && end_date_present=='true' && status == selected_option){
    jQuery("#date_start").val(date_start);
    jQuery("#date_end").val(date_end);
  }else{
    if(status=='All'){
      jQuery("#date_start").val(all_start);
      jQuery("#date_end").val(all_end);
    }else{
      if(start_date_present=='true' && end_date_present=='true' && status==undefined){
        jQuery("#date_start").val(date_start);
        jQuery("#date_end").val(date_end);
      }else{
        jQuery("#date_start").val("");
        jQuery("#date_end").val("");
      }
    }
  }
}

function check_for_deleted(node){
  if (node.match(/recycle_bin_(\d+)/)){
    alert('Please restore the folder containing this file to view this file.');
    return false;
  }
  else if(node.match("recycle_bin")){
    alert('Please restore the file to view it.')
    return false;
  }else{
    return true;
  }
}
function editAccessPeriod(matter_id, matter_people_id, id_val, access_id){
  if(jQuery('#matter_access_end_date_'+id_val).val()=="")
    {
      alert("Please Select End Date");
      return false;
    }
     var start_date_val, end_date_val;
     start_date_val = jQuery('#matter_access_start_date_'+id_val).val();
     end_date_val = jQuery('#matter_access_end_date_'+id_val).val();
      jQuery.ajax({
        type: "GET",
        url: "/matters/"+matter_id+"/matter_peoples/edit_matter_access_periods",
        data: {
          matter_people_id : matter_people_id,
          start_date : start_date_val,
          end_date : end_date_val,
          id_val : id_val
        }
      });
    
  }

//To Restore Document / Link from recycle bin : Pratik AJ : 29/11/2011
function restoreDocumentLinkFolder( path, flash_msg ){
  jQuery('#loader1').show();
  jQuery.ajax({
    url : path,
    type : 'GET',
    success : function(transport){
      jQuery('#resultant-content').html(transport);
      show_error_msg('altnotice', flash_msg+' restored successfully.', 'message_sucess_div');
      jQuery('#loader1').hide();
    },
    error :function (xhr, ajaxOptions, thrownError){
      show_error_msg('altnotice', 'Unable to Restore '+flash_msg, 'message_error_div');
      jQuery('#loader1').hide();
    }
  });
}

//To Delete Document / Link : Pratik AJ : 29/11/2011
function deleteDocumentLinkFolder( path, msg, flash_msg ){
  var delete_doc = confirm(msg);
  if ( delete_doc == false ){
    return false
  }
  jQuery('#loader1').show();
  jQuery.ajax({
    url : path,
    type : 'DELETE',
    success : function(transport){
      enableAllSubmitButtons("button");
      jQuery('#resultant-content').html(transport);
      show_error_msg('altnotice', flash_msg + ' Deleted Successfully.', 'message_sucess_div');
      jQuery('#loader1').hide();
    },
    error :function (xhr, ajaxOptions, thrownError){
      show_error_msg('altnotice','Unable to Delete '+flash_msg,'message_error_div');
      jQuery('#loader1').hide();
    }
  });
}

function createFolder( path ){
  jQuery('#create_folder').val("Please wait ...");
  jQuery('#loader').show();
  if (jQuery('#folder_name').val()==""){
    jQuery('#one_field_error_div').html('Name Cannot Be Blank');
    jQuery('#one_field_error_div').fadeIn(1000,function(){
      jQuery('#one_field_error_div').fadeOut(4000)
    });
    jQuery('#loader').hide();
    jQuery('#create_folder').val("Create");
    return false
  }
  jQuery.ajax({
    url : path,
    type : 'POST',
    data :{
      'folder[name]' : jQuery('#folder_name').val()
    },
    success : function(transport){
      tb_remove();
      jQuery('#resultant-content').html(transport);
      jQuery('#altnotice').html('Folder Created Successfully.');
      jQuery('#altnotice').addClass('message_sucess_div');
      jQuery('#altnotice').fadeIn(2000,function(){
        jQuery('#altnotice').fadeOut(4000)
      });
      jQuery('#loader1').hide();
    },
    error :function (xhr, ajaxOptions, thrownError){
      show_error_msg('one_field_error_div','Name Has Already Been Taken','message_error_div');
      jQuery('#loader1').hide();
      jQuery('#create_folder').val("Create");
    }
  });
  jQuery('#loader').hide();
}

//Feature #9924
function check_bill_address_update(check_classname,check_variable,total_open_invoices,action){
  if(check_variable == true && total_open_invoices > 0 && action == 'edit'){
    var confirmation_popup = confirm("There are open invoice(s) for this Contact / Account. Do you want the changes to reflect in the Open invoice(s)");
    if (confirmation_popup==true){
      jQuery('#'+check_classname+'_change_bill_address').val("true");
    }
  }
}
//Feature #9924

//Added By Pratik AJ : Feature #10277
function openMoveAccessWindow(title, path, msg , radio){
  var document_home_ids = []
  jQuery('input[name=private_document\\[\\]]').each(function (){
    if (this.checked) {
      document_home_ids.push(this.value);
    }
  });
  if (document_home_ids.length > 0){
    tb_show(title, path, '');
  }else{
    alert(msg);
    jQuery(radio).attr('checked',false);
    return false;
  }
}

function moveMultipleDocuments(matter_id){
  if (jQuery('#document_home_folder_id').val() == '-1'){
    show_error_msg('move_doc_error','Please select destination folder.','message_error_div');
    jQuery('#move').val("Move");
    return false;
  }
  var document_home_ids =[]
  jQuery('input[name=private_document\\[\\]]').each(function (){
    if (this.checked) {
      document_home_ids.push(this.value);
    }
  });
  jQuery.ajax({
    url : '/document_homes/move_multiple_doc',
    type : 'POST',
    data :{
      'document_home_ids' : document_home_ids,
      'matter_id' : matter_id,
      'folder_id' : jQuery('#document_home_folder_id').val()
    },
    success : function(transport){
      tb_remove();
      jQuery("#private_doc").html(transport);
      jQuery('#private_document').show();
      show_error_msg('flash_notice',document_home_ids.length + ' File(s) moved to Workspace Successfully.','message_sucess_div');
    }
  });
}


function changeAccessControl(matter_id){
  var document_home_ids =[]
  var matter_people_ids =[]
  jQuery('input[name=private_document\\[\\]]').each(function (){
    if (this.checked) {
      document_home_ids.push(this.value);
    }
  });
  jQuery('.selective_document').each(function (){
    if (this.checked) {
      matter_people_ids.push(this.value);
    }
  });
  jQuery.ajax({
    url : '/document_homes/multi_documents_access_control',
    type : 'POST',
    data :{
      'document_home_ids' : document_home_ids,
      'matter_id' : matter_id,
      'access_control' : jQuery('input[name=access_control]:checked').val(),
      'document_home[repo_update]' : jQuery('#document_home_repo_update').attr('checked'),
      'document_home[matter_people_ids]' : matter_people_ids,
      'document_home[owner_user_id]' : jQuery('#owner_user_id').val()
    },
    success : function(transport){
      tb_remove();
      jQuery("#all_documents").html(transport);
      jQuery('#document').show();
      jQuery('#private_document').show();
      show_error_msg('flash_notice','Access Rights Of The Documents Changed Successfully.','message_sucess_div');
    }
  });
}
