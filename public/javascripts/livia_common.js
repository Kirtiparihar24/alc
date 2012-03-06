// function showHideLitigation(show) : removed
function updatename(fName,elementid){
  jQuery('#' + elementid).val((jQuery('#' + fName).val().split(/\\|\//).pop()).replace(/\.[^/.]+$/, ""));
}

// function openDocPop() : removed
// function contact_edit_init()
// function account_combo_toggle() 
function support_uncheck_others(foo){
  var recs = jQuery(".request_lists");
  for (var i=0; i<recs.length; i++) {
    if(recs[i].id != foo){
      recs[i].checked = false
    }
  }
}

// function contact_combo_toggle()
function validate_interim_doc(field_id,msg){
  jQuery('#loader').show();
  var field=jQuery('#'+field_id).val();
  field = jQuery.trim(field);
  if(field==""){
    jQuery('#one_field_error_div')
    .html("<div class='message_error_div'>"+msg+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow')
    jQuery('#loader').hide();
    return false;
  }else{
    return true;
  }
}

// # regarding bug Bug #7984 Unable to Supercede a file
// As this function added to fix bug no 7984 but same code present at validate_field so need to refactore.
function validate_uploadfile_field(field_id,msg){  
  var field=jQuery('#'+field_id).val();
  field = jQuery.trim(field);
  jQuery('#update_status').attr('disabled',true);
  jQuery('#update_status').val('Please wait...');
  jQuery('input[name="save"]').attr('disabled',true);
  jQuery('input[name="save"]').val('Please wait...');
  jQuery('#opportunity_submit').val('Please wait...');
  jQuery('#loader').show();
  if (field==""){
    jQuery('#one_field_error_div')
    .html("<div class='message_error_div'>"+msg+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow');
    jQuery('#update_status').attr('disabled','');
    jQuery('#update_status').val('Update');
    jQuery('input[name="save"]').attr('disabled','');
    jQuery('input[name="save"]').val('Submit');
    jQuery('#supercede').val('Supercede');
    jQuery('#opportunity_submit').val('Save & Exit');
    jQuery('#loader').hide();
    return false;
  }
  return true;
}

/*In contact for _create_opportunity*/
function validate_field(field_id,msg){
  var reqex=/^[A-Za-z\s0-9]*$/;
  var field=jQuery('#'+field_id).val();
  field = jQuery.trim(field);
  jQuery('#update_status').attr('disabled',true);
  jQuery('#update_status').val('Please wait...');
  jQuery('input[name="save"]').attr('disabled',true);
  jQuery('input[name="save"]').val('Please wait...');
  jQuery('#opportunity_submit').val('Please wait...');
  jQuery('#loader').show();
  if (field==""){
    jQuery('#one_field_error_div')
    .html("<div class='message_error_div'>"+msg+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow');
    jQuery('#update_status').attr('disabled','');
    jQuery('#update_status').val('Update');
    jQuery('input[name="save"]').attr('disabled','');
    jQuery('input[name="save"]').val('Submit');
    jQuery('#supercede').val('Supercede');
    jQuery('#opportunity_submit').val('Save & Exit');
    jQuery('#loader').hide();
    return false;
  }else if (!reqex.test(field)){
    jQuery('#one_field_error_div')
    .html("<div class='message_error_div'>"+"Opportunity Special characters are not allowed"+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow');
    jQuery('#update_status').attr('disabled','');
    jQuery('#update_status').val('Update');
    jQuery('input[name="save"]').attr('disabled','');
    jQuery('input[name="save"]').val('Submit');
    jQuery('#supercede').val('Supercede');
    jQuery('#opportunity_submit').val('Save & Exit');
    jQuery('#loader').hide();
    return false;
  }else{
    jQuery('#opportunity_submit').val('Please wait...');
    return true;
  }    
}

function validateTEDocs(field_id,msg){
  var field=jQuery('#'+field_id).val();
  field = jQuery.trim(field);
  if (field==""){
    jQuery('#one_field_error_div')
    .html("<div class='message_error_div'>"+msg+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow');
    return false;
  } else{
    disableAllSubmitButtons('button');
    return true;
  }
}

// function clear_account_id()
function switch_create_campaign(selector){
  if (selector=='new') {
    jQuery('#existing_campaign').hide();
    jQuery('#campaign_id').disabled=true;
    jQuery('#campaign_name').val="";
    jQuery('#method').val='post'
    jQuery('#campFORM' + ' :input').each(function(){
      if ((this.type=='text' || this.type=='textarea') && (this.name!="authenticity_token" && this.name!="button_pressed"))
        jQuery(this).val('');
    });
    jQuery('#campaign_save').val="Save";
    jQuery('#campaign_saveexit').val="Save & Exit";
  } else {
    jQuery('#existing_campaign').show();
    jQuery('#campaign_id').disabled=false;
  }
}

function switch_upload(file, link){
  if (file) {
    jQuery('#file_label').show();    
    jQuery('#link_label').hide();
    jQuery('#doc_1').show();
  }
  if(link)  {
    jQuery('#link_label').show();    
    jQuery('#file_label').hide();
    jQuery('#doc_1').hide();
  }
  jQuery('#document_home_name').val('');
  jQuery('#document_home_tag_array').val('');
  jQuery('#document_home_description').val('');
}

function getCampaigns(type,letter,perpage,stage) {
  if (perpage==''){
    perpage=25
  }
  document.location.href = "/campaigns?mode_type="+type+"&per_page="+perpage+"&letter="+letter+"&stage="+stage;
}

// function getManagedCampaigns removed

function validateFile(){
  var filename=document.getElementById("import_file").value;
  if (filename==""){
    alert("Please input a filename");
    return false;
  } else {
    var arr = filename.split(".");
    var exten = arr[arr.length -1].toUpperCase()
    if (!(exten =="CSV")) {
      alert("Please input CSV file only");
      return false;
    }
  }
}

function campaign_check_all(){    
  var recs = jQuery(".records");
  for (var i=0; i<recs.length; i++) {
    recs[i].checked = jQuery("#check_all:checked").val();
  }
}

function validateImportFile(){
  var filename=jQuery("#import_file").val();
  var fileformat=jQuery("#file_format").val();
  if (filename==""){
    alert("Please select a file to import");
    return false;
  }else {
    var arr = filename.split(".");
    var exten = arr[arr.length -1].toUpperCase()
    if(fileformat=="CSV") {
      if (!(exten =="CSV" || exten =="VCF")) {
        alert("Please specify valid filename");
        return false;
      }
    }
    if(fileformat=="XLS") {
      if (!(exten =="XLS" ||exten =="ODS")){
        alert("Please specify valid filename");
        return false;
      }
    }
  }
}
  
function campaign_check_all_cont(){  
  var recs = jQuery(".recordscampmem");
  for (var i=0; i<recs.length; i++) {
    recs[i].checked = jQuery("#check_all_cont:checked").val();
  }
}

function campaign_status_change(){   
  var notes_div = jQuery('.reason_tds');
  notes_div.show();
}

function echeck(str) {
  var at="@"
  var dot="."
  var lat=str.indexOf(at)
  var lstr=str.length
  // var ldot=str.indexOf(dot)
  if (str.indexOf(at)==-1){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.indexOf(at)==-1 || str.indexOf(at)==0 || str.indexOf(at)==lstr){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.indexOf(dot)==-1 || str.indexOf(dot)==0 || str.indexOf(dot)==lstr){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.indexOf(at,(lat+1))!=-1){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.substring(lat-1,lat)==dot || str.substring(lat+1,lat+2)==dot){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.indexOf(dot,(lat+2))==-1){
    alert("Invalid E-mail ID")
    return false
  }
  if (str.indexOf(" ")!=-1){
    alert("Invalid E-mail ID")
    return false
  }
  return true
}

function ValidateForm(){
  var emailID = jQuery("#contact_email").val();
  var first_name = jQuery("#contact_first_name").val();
  var response = jQuery("#response_response").val();
  if((emailID==null)||(emailID=="") && (first_name==null)||(first_name=="") && (response==null)||(response=="")){
    alert("Please Enter all Details")
    return false
  } else if ((emailID==null)||(emailID=="")){
    alert("Please Enter your Email ID")
    return false
  } else if((first_name==null)||(first_name=="")){
    alert("Please Enter your First Name")
    return false
  } else if((response==null)||(response=="")){
    alert("Please Enter your Response")
    return false
  }
  if (echeck(emailID)==false){
    emailID=""
    return false
  }
  return true
}

function opportunity_status_change(selected, selected_value,closed_won_id) {
  if(selected != selected_value){
    jQuery("#reason").show();
  } else{
    jQuery("#reason").hide();
  }
  // var val = jQuery('#opportunity_stage :selected').text();
  if (closed_won_id.indexOf(selected)!=-1) {
    jQuery("#opp_matter").show();
  } else {
    jQuery("#opp_matter").hide();
  }
}

function getopp(type,opp_stage,perpage,letter){
  if(perpage==''){
    perpage=25
  }
  //cerate to variables to set opp_stage and letter params
  var opp_stage_add = '';
  var letter_add = '';   
  if(letter != ''){
    letter_add = "&letter="+letter  //if letter present set the value
  }
  if(opp_stage != ''){
    opp_stage_add =   "&opp_stage="+opp_stage //if opp_stage present set the value
  } 
  document.location.href = "/opportunities?mode_type="+type+opp_stage_add+"&per_page="+perpage+letter_add;    
}

// function initCampaignsOpportunityToggle1() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11

// First Verify - Not Used
function matterAddComment(comment_user_id,comment_commentable_id,comment_commentable_type,comment_title){
  var user_id = comment_user_id;
  var commentable_id = comment_commentable_id;
  var commentable_type = comment_commentable_type;
  var priv = false;
  var title = comment_title;
  var comment = jQuery("#matter_comment").val();
  jQuery.post("/comments/add_new_comment",{
    "created_by_user_id" : user_id,
    "commentable_id" : commentable_id,
    "commentable_type" : commentable_type,
    "private" : priv,
    "title" : title,
    "comment" : comment
  },
  function(data) {
    if (data.indexOf("OK") == 0) {
      var tr = document.createElement("tr");
      var tds = data.substring(2).split("|");
      for (var i=0; i< tds.length; i++) {
        var td = document.createElement("td");
        td.innerHTML = tds[i];
        tr.appendChild(td);
      }
      var tbl = document.getElementById("comment_list");
      if (tbl) tbl.appendChild(tr);
      jQuery.facebox.close();
    } else {
      jQuery("#comment_info").html(data);
    }
  });
  return false;
}

// function cgcMatterAddComment() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function startEndTimeFormat(id) {
  jQuery(document).ready(function() {
    jQuery('#' + id).timeEntry({
      ampmPrefix: ' ',
      initialField: 0,
      spinnerImage: '/images/spinnerDefault.png',
      show24Hours: false,
      timeSteps: [1,1,1],
      spinnerSize: [0, 0, 8]
    });
  });
}

function matter_task_times_timeentry(start_time_id, end_time_id) {
  jQuery(document).ready(function() {
    jQuery('#'+start_time_id).timeEntry({
      ampmPrefix: ' ',
      spinnerImage: '/images/spinnerDefault.png',
      show24Hours: false,
      timeSteps: [1,1,1]
    });

    jQuery('#'+end_time_id).timeEntry({
      ampmPrefix: ' ',
      spinnerImage: '/images/non-existent-image-spinnerDefault.png',
      show24Hours: false,
      timeSteps: [1,1,1]
    });
  });
}

function save_attendees(get_assignees, people_attendees_emails){
  var len = jQuery("#"+get_assignees+" option").size();
  for(i=0;i<len;i++) {
    jQuery("#"+get_assignees+" option").attr("selected","selected");
  }
  if(jQuery('#'+people_attendees_emails).val() == 'Search or type an email-id') {
    jQuery('#'+people_attendees_emails).attr('disabled', 'disabled');
  }
}

/* Set matter task appointees autocomplete */
function matter_task_attendees_autocomplete(cid, attendees_email){
  jQuery(document).ready(function(){
    var url = "/contacts/attendees_autocomplete";
    var comma = ",";
    jQuery("#"+attendees_email).autocomplete(url, {
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

function matter_task_attendees_autocomplete_new(cid, attendees_email,mat_id){
  jQuery(document).ready(function(){
    var url = "/matter_peoples/attendees_autocomplete_new";
    var comma = ",";
    jQuery("#"+attendees_email).autocomplete(url, {
      multiple : true,
      multipleSeparator : comma,
      cacheLength : 1, 
      extraParams : {
        company_id : cid,
        matter_id : mat_id,
        appointee_ids : function() {
          jQuery("#appointee_ids").val()
        }
      }
    }).result(function(event, data, formatted) {
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

function check_matter_issue_resolved(){
  if (jQuery('#matter_issue_resolved:checked').val()) {
    jQuery("#resolution").show();
  } else {
    jQuery("#resolution").hide();
    jQuery("#matter_issue_resolved_at").val('');
  }
}

function showaccessdetails(selective,check_box) {
  if(selective){
    jQuery("#selective").show();
    jQuery("#selective_doc[data-from_view=document_access_control]").show();
  }else{
    jQuery("#selective").hide();
    jQuery("#selective_doc[data-from_view=document_access_control]").hide();
  }
  if(check_box){
    jQuery("#check_box").show();
    jQuery("#check_box_doc[data-from_view=document_access_control]").show();
  }else{
    jQuery("#check_box").hide();
    jQuery("#check_box_doc[data-from_view=document_access_control]").hide();
  }  
}

// function hideaccessdetails()  is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function validateNotes() {
  var task_type = jQuery("#task_task_of_type option:selected").text();        
  if (task_type == "-- Select --") {
    jQuery("#notes_errors").html("<div class='errorCont'>Please select task type</div>");
    return false;
  } else {
    jQuery.facebox.close();
  }
}

function validateNotes_on_save_and_exit() {
  var task_type = jQuery("#com_notes_entries_textarea");
  if (task_type.val() == "") {
    jQuery("#notes_errors").html("<div class='errorCont'>Notes cannot be empty</div>");
    return false;
  } else {
    jQuery.facebox.close();
  }
}

function validate_blank(id, msg){
  if(jQuery('#'+id+'').val() == ""){
    jQuery("#one_field_error_div")
    .html("<div class='message_error_div'>"+msg+"</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow');
    jQuery("#loader").hide();
    return false;
  }else{
    return true;
  }
}

function validateTasks() {
  var task_type = jQuery("#task_task_of_type option:selected").text();
  if (task_type == "-- Select --") {
    jQuery("#task_errors").html("<div class='errorCont'>Please select task type</div>");
    return false;
  } else {
    jQuery.facebox.close();
  }
}

// function maximize_grid() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function validateTaskType() {
  var task_type = jQuery(".task_of_type option").index(jQuery(".task_of_type option:selected"));      
  if((jQuery(this.checked)) && (task_type == "")) {
    jQuery("#div_errors").html("<div class='errorCont'>Please select task type</div>");
    return false;
  }
}

function common_flash_message(){
  jQuery(document).ready(function() {
    jQuery('#notice')
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow', function() {
      jQuery('#notice').remove();
    });
  });
}

function common_error_flash_message(){
  jQuery(document).ready(function() {
    jQuery('#nameerror')
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow', function() {
      jQuery('#nameerror').remove();
    });
  });
}

function change_password_home() { 
  var cpass = jQuery("#current_password").val();
  var npass = jQuery("#password").val();
  var npass2 = jQuery("#password_confirmation").val();
  jQuery("#password_errors").hide();
  jQuery.post("/users/change_password",{
    "current_password" : cpass,
    "user[password]" : npass,
    "user[password_confirmation]" : npass2
  },
  function(out) {
    if (out != "") {
      jQuery("#password_errors").html(out);
      jQuery("#password_errors").show();
    } else {
      window.location = "/logout?change_password=true";
    }
  });
  return false;
}

// function submitMe(f) is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
/* Submit the password reset form using jQuery-AJAX, handle and display error messages. */
function submitPasswordReset(id) {
  var npass = jQuery("#reset_password").val();
  var npass2 = jQuery("#reset_password_confirmation").val();
  jQuery.post("/users/reset_password/" + id, {
    "user[password]" : npass,
    "user[password_confirmation]" : npass2
  },
  function(out) {
    if (out != "") {
      jQuery("#reset_password_errors").html(out);
      jQuery("#reset_password_errors").show();
    } else {
      jQuery.facebox.close();
      alert("Password was reset successfully!")
    }
  });
  return false;
}

function common_datepicker(){
  jQuery.noConflict();
  jQuery(function() {
    jQuery("#datepicker").datepicker({
      onSelect: function(date) {        
        scheduler.init('scheduler_here',date,"day");        
        Element.show('main_spinner');
        new Ajax.Request('/physical/calendar/calendars/date_select_appointment?date='+date, {
          asynchronous:true,
          evalScripts:false,
          onSuccess:function(request){
            Element.hide('main_spinner')
          }
        })
      },
      selectWeek: true,
      dateFormat: 'mm/dd/yy',
      inline: true,
      startDate: '01/01/2000',
      firstDay: 1
    }
    );
  });
}

// function appointments_grid_init() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
//added Jquery ajax to populate contact staus
function status_change(selected,action,current_value,opportunity, matter){   
  var lead_div = jQuery('#lead');
  var prospect_div = jQuery('#prospect');
  var notes_div = jQuery('#notes');
  var selectedval=jQuery('#contact_contact_stage_id option:selected').val();
  jQuery.ajax({
    type: "GET",
    url: "/contacts/get_company_contact_stages",
    data: {
      'stage_id' : selectedval
    },
    success: function(transport){
      var selectedtxt = transport;
      if (selectedtxt == 'Lead') {
        jQuery('#contact_lead_status').attr('disabled',false)
        lead_div.show();
        prospect_div.hide();
      } else{
        lead_div.hide();
        prospect_div.show();
        jQuery('#contact_lead_status').attr('disabled','disabled')       
        jQuery('#contact_prospect_status').attr('disabled',false)
      }
      if (selected == current_value){
        notes_div.hide();
      } else {
        notes_div.show();
      }
      jQuery('#selected_list_box').val(selectedtxt);
      loader.remove();
    }
  });    
}

function application_layout_init(){
  jQuery.noConflict();
  jQuery(document).ready(function(){
    LoadResolutionCss();
    initAutoComplete();   
    initLiviaHint();
    initLiviaDashBoardView();
    rolloverToolTip();        
    jQuery("#viewHeader").click(function() {
      jQuery("#viewHeaderArea").toggle();
      jQuery(".toggle_view").toggle();
    });
  });
}

function validatefields(){         
  var subject = document.getElementById("email_subject").value;
  var email_id = document.getElementById("email_owners_email").value;
  var reg = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
  if (subject=="") {
    alert("Please specify a subject");
    return false;
  } else if(email_id=="") {
    alert("Please specify a Email ID");
    return false;
  } else if(reg.test(email_id) == false) {
    alert('Invalid Email ID');
    return false;
  } else {
    return true;
  }
}

// function campaign_layout_init() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
// function selected_tab() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
// function matters_layout_init() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function intiToggleIt(){
  jQuery("#sumamrygridToggle").click(function(){
    jQuery("#saved_entries_div").toggle();
    jQuery(".toggle_saved_entries").toggle();
  });
}

// function timeandexpenses_layout_init()
// function matter_client_init()
// function payment_mode_change() removed used admin side
jQuery(function(){
  jQuery('#report_type').change(function(){
    var selectedval = jQuery('#report_type option:selected').val();
    jQuery.ajax({
      url: '/compliances/getlookupdata',
      type: "GET",
      data: {
        "id" : selectedval,
        "report" : true
      },
      dataType: "script"
    });
  });
});

function matter_client_datepicker(){
  jQuery.noConflict();
  jQuery(document).ready(function() {
    jQuery("#datepicker_client_task").datepicker({
      showOn: 'focus',
      closeAtTop: true,
      showOtherMonths: true,
      dateFormat: 'yy-mm-dd',
      onSelect: function(value,date){        
        update_taskdiv(value)
      }
    });
  });
}

custom_flash_msg=function(msg){
  jQuery.facebox.close();
  jQuery('#altnotice').html(msg);
  jQuery('#altnotice').addClass('sucessCont');
  jQuery('#altnotice').fadeIn(2000,function(){
    jQuery('#altnotice').fadeOut(2000)
  });                 
}

// jQuery('#open-items-filter') : removed
// function validate_resolution() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
//*  Used on click event login view for UserName and Password */
function changeValue(field){
  if(field.val()=="Email ID"){
    field.val("");
  }
  if(field.attr('id') =="user_password"){
    field.val("");
  }
  field.removeClass('textgray')
  var current_date = new Date( );
  var gmt_offset = current_date.getTimezoneOffset( );
  jQuery('#target').val(gmt_offset)
}

// * Used on change event login view for UserName and Password */
function trackValue(field, name){
  var this_value = field.val();
  if(this_value==""){
    if(name=="user"){
      field.val('Email ID');
    }else{
      field.val('Password');
    }
    field.addClass('textgray');
  }else if(name=='pass' && this_value!="Password"){
    if(field.hasClass('textgray')){
      field.removeClass('textgray')
    }
  }
}

// function includeCss() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
// function getCssFileName() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function check_logo_field(){
  var val = jQuery("#company_logo").val();
  if(val==""){
    alert("No Image selected");
    return false;
  }else{
    return true;
  }
}

function check_photo_field(){
  var val = jQuery("#employee_photo").val();
  if(val==""){
    alert("No Image selected");
    return false;
  }else{
    return true;
  }
}

//If email-id of contact is changed and  it has associated matters, client's new user would get created
function verify_email(email, email_field, has_matter){
  if (has_matter !='' && has_matter){
    var contact_email = jQuery('#'+email_field).val();
    if (jQuery.trim(email) != '' && jQuery.trim(contact_email) != '') {
      if (jQuery.trim(email) != jQuery.trim(contact_email)) {
        var c = confirm('New client login would be created on updating email-id. Do you want to continue ?')
        if (!c){
          return false;
        }
      }
    }
  }
  return true;
}

var BrowserDetect = {
  init: function () {
    this.browser = this.searchString(this.dataBrowser) || "base";
    this.version = this.searchVersion(navigator.userAgent)
    || this.searchVersion(navigator.appVersion)
    || "an unknown version";
    this.OS = this.searchString(this.dataOS) || "an unknown OS";
  },
  searchString: function (data) {
    for (var i=0;i<data.length;i++)	{
      var dataString = data[i].string;
      var dataProp = data[i].prop;
      this.versionSearchString = data[i].versionSearch || data[i].identity;
      if (dataString) {
        if (dataString.indexOf(data[i].subString) != -1)
          return data[i].identity;
      }
      else if (dataProp)
        return data[i].identity;
    }
  },
  searchVersion: function (dataString) {
    var index = dataString.indexOf(this.versionSearchString);
    if (index == -1) return;
    return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
  },
  dataBrowser: [{
    string: navigator.userAgent,
    subString: "Chrome",
    identity: "Chrome"
  },{
    string: navigator.userAgent,
    subString: "OmniWeb",
    versionSearch: "OmniWeb/",
    identity: "OmniWeb"
  },{
    string: navigator.vendor,
    subString: "Apple",
    identity: "Safari",
    versionSearch: "Version"
  },{
    prop: window.opera,
    identity: "Opera"
  },{
    string: navigator.vendor,
    subString: "iCab",
    identity: "iCab"
  },{
    string: navigator.vendor,
    subString: "KDE",
    identity: "Konqueror"
  },{
    string: navigator.userAgent,
    subString: "Firefox",
    identity: "Firefox"
  },{
    string: navigator.vendor,
    subString: "Camino",
    identity: "Camino"
  },{		
    string: navigator.userAgent,
    subString: "Netscape",
    identity: "Netscape"
  },{
    string: navigator.userAgent,
    subString: "MSIE",
    identity: "Explorer",
    versionSearch: "MSIE"
  },{
    string: navigator.userAgent,
    subString: "Gecko",
    identity: "Mozilla",
    versionSearch: "rv"
  },{ 		
    string: navigator.userAgent,
    subString: "Mozilla",
    identity: "Netscape",
    versionSearch: "Mozilla"
  }],
  dataOS : [{
    string: navigator.platform,
    subString: "Win",
    identity: "Windows"
  },{
    string: navigator.platform,
    subString: "Mac",
    identity: "Mac"
  },{
    string: navigator.userAgent,
    subString: "iPhone",
    identity: "iPhone/iPod"
  },{
    string: navigator.platform,
    subString: "Linux",
    identity: "Linux"
  }]
};
BrowserDetect.init();

/* shifted from accounts/_add_contact  */
function toggle_form(){
  jQuery('#create_new_table').toggle();
  var selector = jQuery('#selector_link');
  var selectorText = selector.text();
  var inputArr = jQuery('.toggle_handler');
  for(i=0; i<inputArr.length; i++){
    if ((selectorText=='Create New')){
      jQuery(inputArr[i]).removeAttr("disabled")
      jQuery(inputArr[i]).removeClass('textgray')
      jQuery('.mandatory_alternate').show();
    } else {
      jQuery(inputArr[i]).attr("disabled",true);
      jQuery(inputArr[i]).addClass('textgray')
      jQuery('.mandatory_alternate').hide();
    }
  }

  if (selectorText=='Create New') {
    jQuery('#_contact_ctl').val('');
    jQuery('#_contact_ctl').attr("disabled",true)
    jQuery('#_contact_ctl').addClass('textgray')
    jQuery('#contact_toggle').hide();
    jQuery('#contact_toggle_s').hide();
    jQuery('#_contact_ctl').hide();
    jQuery('#selector_link').hide();
    selector.text('Select Existing');
    jQuery('#select_existing_s').show();
  }else {
    jQuery('#_contact_ctl').removeAttr("disabled");
    jQuery('#_contact_ctl').removeClass('textgray')
    jQuery('#contact_toggle').show();
    jQuery('#contact_toggle_s').show();
    jQuery('#_contact_ctl').show();
    jQuery('#selector_link').show();
    selector.text('Create New');
    jQuery('#select_existing_s').hide();
  }
  jQuery("#add_contact_errors").hide();
}

function validate_contact_field(){
  if(jQuery('#_contact_ctl').val().trim()==""){
    jQuery('#_contactid').val('');
  }
}

// contacts/_form
function change_tab(link){
  var div_id = jQuery(link).attr('href')
  jQuery("#divid").val(div_id);
  if (jQuery('#divid').val()=='#fragment-1'){
    jQuery(".mandatory").show();
  } else{
    jQuery(".mandatory").hide();
  }
}

function createnew_clear(){
  if (jQuery('#account_name').val()=='Create New'){
    jQuery('#account_name').val('');
  }
}

// matters/new
function contactDetailsAdded(save) {
  if (save) {
    tb_remove();
  } else {
    jQuery('#matter_contact_errors').html('');
    jQuery('#matter_contact_errors').hide();
    tb_remove();
  }
}

function savedMatterContact(id, name) {
  tb_remove();
  jQuery('#_contactid').val(id);
  jQuery('#matter_contact_id').val(id);
  jQuery('#_contact_ctl').val(name);
  formatSequenceOnChange();
  contact_remove_content();
}

function contact_remove_content(){
  jQuery('.contact_content').val('');
}

function clear_previous_contact(){
  jQuery('#_contactid').val('');
  jQuery("#_accconname").val('');
  jQuery("#update_my_email_id").children("input").val(jQuery("#contact_email.contact_content").val());
}

function reset_search(){
  jQuery.ajax({
    type: 'GET',
    url: '/matters/get_contact_accounts',
    dataType: 'script',
    data: {
      'rollback' : "true"
    }
  });
  jQuery.ajax({
    type: 'GET',
    url: '/matters/get_account_contacts',
    dataType: 'script',
    data: {
      'rollback' : "true"
    }
  });
}

function check_client_contact(e){
  var contact_id = jQuery("#_contactid").val();
  if(jQuery('#matter_client_access').is(':checked') && jQuery.trim(jQuery("#contact_email").val())==""){
    var c = confirm("Do you want this client to have client portal access?")
    if(c){
      tb_show('Client Email','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
      return false;
    }else{
      jQuery('#matter_client_access').attr('checked', false);
      return false;
    }
  }
  setButtonPressed(e);
  return true;
}

// matters/ edit
function on_submit_validate(e){
  if (jQuery('#initial_parent_id').val() == jQuery('#matter_parent_id').val()){
    var parent_complete = jQuery('#is_parent_complete').val();
    var is_complete = jQuery('#is_complete').val();
    if((is_complete=='true') && (parent_complete == 'true')){
      if(jQuery('#matter_status_id option:selected').val() != jQuery('#complete_status_id').val()){
        var continue_submit = confirm('This matter is linked to a Parent matter that is Closed. Reopening this will reopen the parent matter too.')
        if(continue_submit){
          return check_client_contact(e);
        }else{
          return false;
        }
      }
    }
  }
  return check_client_contact(e);
}

function radio_button_validation(){
  if(jQuery("#matter_matter_category_nonlitigation").attr("checked")){
    jQuery('#case_number_ID').val("");
    jQuery('#forum_ID').val("");
    jQuery('#hearing_before_ID').val("");
    jQuery('#matter_type_liti').hide();
    jQuery('#matter_type_nonliti').show();
    jQuery("#modal_litigation").hide();
  }
  if (jQuery("#matter_matter_category_litigation").attr("checked")){
    jQuery('#case_number_ID').val("");
    jQuery('#forum_ID').val("");
    jQuery('#hearing_before_ID').val("");
    jQuery('#matter_type_liti').show();
    jQuery("#modal_litigation").show();
    jQuery('#matter_type_nonliti').hide();
  }
}