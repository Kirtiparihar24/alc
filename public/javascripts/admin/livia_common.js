// function showHideLitigation(show) : removed
function updatename(fName,elementid){
  var fullName = fName;
  var shortName = fullName.match(/[^\/\\]+$/).pop().replace(/\.[^/.]+$/, "");
  document.getElementById(elementid).value = shortName
}

// function openDocPop() : removed
// function contact_edit_init()
// function account_combo_toggle() 
// function contact_combo_toggle()
function validate_field(field_id,msg){  
  var field_value=jQuery.trim('#'+field_id).val();
  field_value = jQuery.trim(field_value)
  if (field_value==""){
    jQuery('#nameerror').children('div').html(msg);
    jQuery('#nameerror').show();
    return false
  }else{
    return true
  }
}

function validate_name(){
  var oppname=jQuery('#opportunity_name').val();
  if (oppname==""){
    jQuery('#nameerror').html("<div class='errorCont'>Please enter Opportunity Name</div>");
    return false;
  }else{
    return true;
  }
}

// function clear_account_id()
function switch_create_campaign(selector){
  if (selector=='new'){
    jQuery('#existing_campaign').hide();    
    jQuery('#campaign_name').val="";
    jQuery('#method').val='post'
    jQuery('#campFORM' + ' :input').each(function(){
      if(this.type=='text' || this.type=='textarea' && this.type!='hidden'){
        jQuery(this).val('');
      }
    });
  }else{
    jQuery('#existing_campaign').show();
    jQuery('#campaign_id').disabled=false;
  }
}

function switch_upload(file, link){    
  if (file){
    jQuery('#file_label').show();
    jQuery('#file_attr').show();
    jQuery('#link_label').hide();
    jQuery('#link_attr').hide();
  }
  if(link){
    jQuery('#link_label').show();
    jQuery('#link_attr').show();
    jQuery('#file_label').hide();
    jQuery('#file_attr').hide();
  }
}

function getCampaigns(type,camp_status) {
  document.location.href = "/campaigns?mode_type="+type+"&camp_status="+camp_status;
}

// function getManagedCampaigns removed
function validateFile(){
  var filename=document.getElementById("import_file").value;
  if (filename==""){
    alert("Please input a filename");
    return false;
  }else{
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

function support_uncheck_others(){
  var recs = jQuery(".request_lists");
  for (var i=0; i<recs.length; i++) {
    alert(recs[i]);
    if(recs[i] == this){
      recs[i].checked = true
    }else{
      recs[i].checked = false
    }
  }
}

function validateImportFile(){
  var filename=document.getElementById("import_file").value;
  var fileformat=document.getElementById("file_format").value;
  if (filename==""){
    alert("Please select a file to import");
    return false;
  }else{
    var arr = filename.split(".");
    var exten = arr[arr.length -1].toUpperCase()
    if(fileformat=="CSV"){
      if (!(exten =="CSV" || exten =="VCF")){
        alert("Please specify valid filename");
        return false;
      }
    }
    if(fileformat=="XLS"){
      if (!(exten =="XLS" ||exten =="XLSX" ||exten =="ODS")){
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
  var notes_div = jQuery('#notes');
  notes_div.show();
}

function ValidateForm(){
  var email_id = jQuery("#email_id").val();
  if ((email_id==null)||(email_id=="")){
    alert("Please Enter your Email ID")
    return false
  }
  if (echeck(email_id)==false){
    email_id=""
    return false
  }
  return true
}
 
function opportunity_status_change(selected, selected_value) {
  if(selected != selected_value)
    jQuery("#reason").show();
  else
    jQuery("#reason").hide();
  var val = jQuery('#opportunity_stage :selected').text();
  if (val == "Closed/Won") {
    jQuery("#opp_matter").show();
  } else {
    jQuery("#opp_matter").hide();
  }
}

function getopp(type,opp_status,opp_stage) {
  document.location.href = "/opportunities?mode_type="+type+"&opp_status="+opp_status+"&opp_stage="+opp_stage;
}

// function initCampaignsOpportunityToggle1() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
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
      tb_remove();
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
      timeSteps: [1,1,1]
    });
  });
}

function matter_task_times_timeentry() {
  jQuery(document).ready(function() {
    jQuery('#matter_task_start_time').timeEntry({
      ampmPrefix: ' ',
      spinnerImage: '/images/spinnerDefault.png',
      show24Hours: false,
      timeSteps: [1,1,1]
    });
    jQuery('#matter_task_end_time').timeEntry({
      ampmPrefix: ' ',
      spinnerImage: '/images/non-existent-image-spinnerDefault.png',
      show24Hours: false,
      timeSteps: [1,1,1]
    });
  });
}

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
      if (ids != "") {
        ids = ids + "," + data[1];
      } else {
        ids = data[1];
      }
      jQuery("#appointee_ids").val(ids);
    });
  });
}

function check_matter_issue_resolved(){
  if (jQuery('#matter_issue_resolved:checked').val()) {
    jQuery("#resolution").show();
    jQuery("#resolution_date").show();
  } else {
    jQuery("#resolution").hide();
    jQuery("#resolution_date").hide();
    jQuery("#matter_issue_resolved_at").val('');
  }
}

function showaccessdetails(selective,check_box) {
  if(selective){
    jQuery("#selective").show();
  }else{
    jQuery("#selective").hide();
  }    
  if(check_box){
    jQuery("#check_box").show();
  }else{
    jQuery("#check_box").hide();
  }    
}

// function hideaccessdetails()  is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function validateNotes() {
  var task_type = jQuery("#task_tasktype option:selected").text();
  var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
  var err='';
  if (task_type == "-- Select --") {
    err+="Please select task type";
  }
  if (assigned_to == "-- Select --") {
    err+="<br>Please select assigned to"
  }
  if (err!=""){
    jQuery("#notes_errors").html("<div class='errorCont'>"+err+"</div>");
    return false;
  } else {
    tb_remove();
  }
}

function validateNotes_on_save_and_exit() {
  var task_type = jQuery("#com_notes_entries_textarea");
  if (task_type.val() == "") {
    jQuery("#notes_errors").html("<div class='errorCont'>Notes cannot be empty</div>");
    return false;
  } else {
    tb_remove();
  }
}

function validate_assigned_to() {
  var task_type = jQuery("#task_tasktype option:selected").text();
  // var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
  var err='';
  if (task_type == "-- Select --") {
    err+="Please select task type";
  }
  if (err!="") {
    jQuery("#notes_errors").html("<div class='errorCont'>"+err+"</div>");
    return false;
  }else {
    tb_remove();
  }
}

function validateTasks() {
  var task_type = jQuery("#task_tasktype option:selected").text();
  // var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
  var err='';
  if (task_type == "-- Select --") {
    err+="Please select task type";
  }
  if (err!=""){
    jQuery("#task_errors").html("<div class='errorCont'>"+err+"</div>");
    return false;
  }else {
    tb_remove();
  }
}
 
// function maximize_grid() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function validateTaskType() {
  var task_type = jQuery(".task_of_type option").index(jQuery(".task_of_type option:selected"));      
  if((jQuery(this.checked)) && (task_type == "")) {
    jQuery("#div_errors").html("<div class='errorCont'>Please select task type</div>");
    return false;
  } else {  }
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

function common_flash_message_name_notice(msg){
  jQuery(document).ready(function() {
    jQuery('#name_notice').html(msg);
    jQuery('#name_notice')
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow', function() {
      jQuery('#name_notice').hide();
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

// function myPasswordSubmit() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
// function submitMe(f) is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function submitPasswordReset(id) {
  var npass = jQuery("#reset_password").val();
  var npass2 = jQuery("#reset_password_confirmation").val();
  jQuery.post("/users/reset_password/" + id, {
    "user[password]" : npass,
    "user[password_confirmation]" : npass2
  },
  function(out) {        
    if (out != "") {      
      loader.remove();
      jQuery("#reset_password_errors").html(out);
      jQuery('#reset_password_errors')
      .fadeIn('slow')
      .animate({
        opacity: 1.0
      }, 8000)
      .fadeOut('slow', function() {
        jQuery('#reset_password_errors').remove();
                    
      });
    } else {
      loader.remove();
      tb_remove();
      alert("Password was reset successfully!")
    }
  });
  return false;
}

function submitTpinReset(id) {
  var npass = jQuery("#tpin").val();
  var npass2 = jQuery("#confirm_tpin").val();
  loader.appendTo("#loader_spinner");
  jQuery("#reset_password_errors").hide();
  jQuery.post("/access_codes/reset_tpin/" + id, {
    "user[tpin]" : npass,
    "user[confirm_tpin]" : npass2
  },
  function(out) {
    jQuery("#loader_spinner").html("");
    if (out != "") {
      jQuery("#reset_password_errors").html(out);
      jQuery("#reset_password_errors").show();
    } else {
      tb_remove();
      window.location.reload();
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
        });
      },
      selectWeek: true,
      dateFormat: 'mm/dd/yy',
      inline: true,
      startDate: '01/01/2000',
      firstDay: 1
    });
  });
}

// function appointments_grid_init() is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 16/11/11
function status_change(selected,action,current_value,opportunity, matter){
  var lead_div = jQuery('#lead');
  var prospect_div = jQuery('#prospect');
  var notes_div = jQuery('#notes');
  var selectedtxt = jQuery('#contact_contact_stage_id option:selected').text();
  if (selectedtxt=='Lead'){
    if(matter > 0 || opportunity > 0 ){
      alert("It has a related Opportunity or a Matter");
    }
    jQuery('#contact_lead_status').val("11");
    jQuery('#contact_lead_status').attr('disabled',false)
    lead_div.show();
    jQuery('#contact_prospect_status').attr('disabled','disabled')
    prospect_div.hide();
  }else{
    lead_div.hide();
    prospect_div.show();
    jQuery('#contact_lead_status').attr('disabled','disabled')
    jQuery('#contact_prospect_status').val("7");
    jQuery('#contact_prospect_status').attr('disabled',false)
  }
  if (selected==current_value){
    notes_div.hide();
  }else{
    notes_div.show();
  }
  jQuery('#selected_list_box').val(selectedtxt);
}

function application_layout_init(){
  jQuery.noConflict();
  jQuery(document).ready(function(){
    initAutoComplete();
    initLiviaHint();
    closeFaceBox();
    rolloverToolTip();
    jQuery("#viewHeader").click(function() {
      jQuery("#viewHeaderArea").toggle();
      jQuery(".toggle_view").toggle();
    });
  });
}

function validatefields(){         
  var subject=document.getElementById("email_subject").value;
  var email_id=document.getElementById("email_owners_email").value;
  if (subject=="") {
    alert("Please specify a subject");
    return false;
  } else if(email_id=="") {
    alert("Please specify a Email ID");
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
function payment_mode_change(selected_value){
  jQuery.ajax({
    type: "get",
    url: "/payments/payment_mode_of_selected_id",
    dataType: 'script',
    data: {
      'selected_value' : selected_value
    }
  });
}

jQuery(function(){
  jQuery('#report_type').change(function(){
    var selectedval = jQuery('#report_type option:selected').val();
    jQuery.ajax({
      url: '/compliances/getlookupdata',
      type: "GET",
      data: {
        "id" : selectedval ,
        "report" : true
      },
      dataType: "script"
    });
  });
})

function matter_client_datepicker(){
  jQuery.noConflict();
  jQuery(document).ready(function() {
    jQuery("#datepicker").datepicker({
      showOn: 'focus',
      closeAtTop: true,
      buttonImage: '/images/livia_portal/calendar_n.gif',
      buttonImageOnly: true,
      showOtherMonths: true,
      dateFormat: 'yy-mm-dd',
      onSelect: function(value){
        update_taskdiv(value)
      }
    });
  });
}

custom_flash_msg=function(msg){
  tb_remove();
  jQuery('#altnotice').html(msg);
  jQuery('#altnotice').addClass('sucessCont');
  jQuery('#altnotice').fadeIn(2000,function(){
    jQuery('#altnotice').fadeOut(2000)
  });                 
}

function getCategoryWorktypes(catId){
  if (jQuery('#category').val()==""){
    alert("Please select category");
    return false;
  }
  jQuery.ajax({
    type: 'GET',
    url: '/work_subtypes/get_category_work_types',
    data: {
      'category_id' : catId
    },
    dataType: 'script'
  });
}

function fetch_records_for_company(company_id, action){
  if(company_id==""){
    return false
  }
  jQuery.ajax({
    type: "GET",
    url: "/"+action,
    data: {
      'company_id' : company_id
    },
    success: function(){
      window.location.href = "/"+action
    }
  });    
}

function check_logo_field(){
  var val = jQuery("#logo").val();
  if(val==""){
    alert("Please select a image file to upload");
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

// 1203