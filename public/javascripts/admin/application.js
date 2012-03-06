//////////////////////////////////////////////////////////////////////////////
// * FUNCTIONS FOR LIVIA PORTAL *
//////////////////////////////////////////////////////////////////////////////

var loader = jQuery("<center><img src='/images/loading.gif' /></center>");
var loader2 = jQuery("<img src='/images/loading.gif' />");
var spinner = jQuery("<center><img src='/images/spinner.gif' /></center>");

jQuery(document).ready(function() {
  loader.remove();
});

function show_loader(){
  loader.prependTo("#unassign_users");
}

// function fixAmpersand( str ) moved to common.js
// function validateFieldsForTnEFaceboxForm() removed : duplicate
// function validate_cluster_selection(chk)
// matter budgets : is not used : below function needs to be checked
function check_estimate(){  
  showLoadingGif();
  if(jQuery('#lvalue').val()==''){
    alert('Category cannot be blank');
    return false;
  }
}

// function matterToePopup() duplicate : removed
// function checkfile() : removed as not use in admin
// function checkfilename() : removed as not use in admin
function insertToDo(e, id){
  if (e.checked) {
    jQuery("#" + id).show();
  }else{
    jQuery("#" + id).hide();
  }
}

function getIndex() {
  var elm = document.getElementById("theValue");
  var value = elm.value - 1+2;
  elm.value = value;
  return value;
}

function addNewRecord() {
  var i = getIndex();
  new jQuery.get('/communications/add_new_record', {
    'index' : i
  },
  function(data, status) {
    try {
      var d = document.createElement("div");
      d.setAttribute("id", i);
      d.innerHTML = data;
      var newd = document.getElementById("new_columnDIV");
      newd.appendChild(d);
    }catch(e){
      alert(e.message);
    }
  });
}

function addNewRecord_HOME() {
  var i = getIndex();
  new jQuery.get('/physical/clientservices/add_new_record', {
    'index' : i
  },
  function(data,status) {
    try {
      var d = document.createElement("div");
      d.setAttribute("id", i);
      d.innerHTML = data;
      var newd = document.getElementById("new_columnDIV");
      newd.appendChild(d);
    }catch(e){
      alert(e.message);
    }
  });
}

function removeHighLight(){
  jQuery("#comment_after").css("background", "none");
}

function searchLawyer() {
  var lawyer_val = jQuery("#lawyer_search_query").val();
  if(lawyer_val=="Search"){ }
  else {
    jQuery.ajax({
      type: 'GET',
      url: '/physical/liviaservices/livia_secretaries/search_lawyer/',
      data: {
        'q' : lawyer_val
      },
      success: function(transport){
        jQuery('#searched_lawyers').html(transport);
      }
    });
  }
  return false;
}

// function searchInContact is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
// function searchInOpportunity is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
// function searchInMatter is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
// function searchInCgcMatter is removed : as its not being used anywhere : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
function searchInCommon() {
  var common_val = jQuery("#search_string").val();
  common_val = fixAmpersand(common_val);
  jQuery("#search_string").val(common_val);
    
  jQuery.ajax({
    type: 'GET',
    url: '/physical/clientservices/home/search_result',
    data: {
      'q' : common_val
    },
    success: function(transport) {
      jQuery('#searched_common').html(transport);
    }
  });
  return false;
}

// function searchInCampaign() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function searchInAccount is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
function secrataryDetails(id) {
  jQuery.ajax({
    type: 'GET',
    url: '/physical/liviaservices/managers_select_option',
    data: {
      'secratary_id' : id
    },
    success: function(transport) {
      jQuery("#secratary_details_task_list_DIV").html(transport);
    }
  });
  return false;
}

// function matterDetails( id, status_type ) : removed not in use
function mattertaskDetails(matter_id,status_type) {
  loader.appendTo("#matter_tasks");
  urlStr = (status_type =='All' && matter_id =='0') ? "/matter_clients" : "/task_details"
  jQuery.ajax({
    type: 'GET',
    url: urlStr,
    data: {
      'matter_id' : matter_id,
      'task_type' :status_type
    }
  });
  return false;
}

function mattertaskDetailsClient(matter_id,status_type) {
  var location;
  location = "/task_details";
  loader.appendTo("#matter_task_list_DIV");
  jQuery.get(location,{
    'matter_id': matter_id,
    'task_type' :status_type
  },
  function(data) {
    jQuery("#matter_task_list_DIV").html(data);
  });
  return false;
}

// GetFoldersList() not used in admin : Please do not add again if merge issues occure : Supriya Surve : 14/11/11
// cgc_accounts_detail() is removed : as its not being used : Please do not add again if merge issues occure : Supriya Surve : 14/11/11
function confirm_access(folder_id,access){
  var answer = confirm("Change will be applied to the subfolders also.Are you sure ?")
  if (answer){
    change_livian_access(folder_id,access);
  }
  return false;
}

function change_livian_access(folder_id,access) {
  var nd = "#access_control_" + folder_id;
  var ed = "#explorer_" + folder_id;
  jQuery(nd).html(loader);
  jQuery.ajax({
    type: 'GET',
    url: "/workspaces/change_livian_access",
    data: {
      'folder_id': folder_id,
      'access':access
    },
    success: function(transport) {
      jQuery(nd).html(transport);
      if(access){
        jQuery(ed).html(transport);
      }else{
        jQuery(ed).html(transport);
      }
    },
    complete: function(){
      loader.remove();
    }
  });
  return false;
}

// function companyaccountDetails(company_id) is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function update_taskdiv(new_date) {
  var location;
  loader.appendTo("#task_type_DIV");
  location = "/matter_clients/get_tasks_by_date";
  jQuery.ajax({
    type: 'GET',
    url: location,
    data: {
      'new_date' : new_date
    },
    success: function(transport){
      loader.remove();
    }
  });
}

function secrataryUnassign(id,sect,loc) {
  var location;
  if(loc=="notes"){
    location = "/physical/liviaservices/secratary_details_notes_list";
  } else  {
    location = "/physical/liviaservices/secratary_details_task_list";
  }
  jQuery.ajax({
    type: 'GET',
    url: location,
    data: {
      'secratary_id' :id,
      'secratary' : sect,
      'loc' : loc
    },
    success: function(transport) {
      if(loc=="notes") {
        jQuery("#show_details_list_DIV").html(transport);
      } else if (loc=="task")  {
        jQuery("#show_details_list_DIV").html(transport);
      } else {
        jQuery("#secratary_details_task_list_DIV").html(transport);
      }
    }
  });
  return false;
}

// function views(loc) is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function populatefields(loc){
  loader.appendTo("#comboinputtoggle");
  jQuery.ajax({
    type: 'GET',
    url: loc,
    success: function(transport) {
      jQuery("#comboinputtoggle").html(transport);
    }
  });
  return false;
}

jQuery.ajaxSetup({
  'beforeSend': function(xhr) {
    xhr.setRequestHeader("Accept", "text/javascript")
  }
})

jQuery.fn.submitWithAjax_with_file = function() {
  this.submit(function() {
    jQuery.post(this.action, jQuery(this).serialize() , uploadfile, "script");
    return false;
  })
  return this;
};

function uploadfile(){
  alert( "Before File Uploaded: ");
  var filename = jQuery('#comment_file').val();
  jQuery.ajax({
    type: 'PUT',
    url: 'comments/create',
    enctype: 'multipart/form-data',
    data: {
      file: filename
    },
    success: function(){
      alert( "After File Uploaded: ");
    },
    failure: function(){
      alert('test');
    }
  });
}

jQuery.fn.submitWithAjax = function() {
  this.submit(function() {
    jQuery.post(this.action,jQuery(this).serialize(), null, "script");
    return false;
  })
  return this;
};

var monthNames = [
"January", "February","March","April","May","June","July","August","September", "October", "November","December"
];

function localTime(date, id) {
  try{
    var lzone = new Date().getTimezoneOffset();//alert(zone);
    var tmp = new Date(date);//zone=Math.abs(zone);
    tmp = tmp.getTime() - (lzone * 60000);
    var localTime = new Date(tmp);
    var s = localTime.getDate();
    s+= " " + monthNames[localTime.getMonth()];
    s+= " " +(localTime.getYear()+1900);
    var h = localTime.getHours();
    var ap = "AM";
    if (h >= 12) ap = "PM";
    s+= " " + (h-12);
    var m = localTime.getMinutes();
    m = m < 10 ? "0"+m : m;
    s+= ":" + m;
    s+= " " + ap;
    s+= " (GMT" + (lzone / 60) + ")";
  }catch(e){
    alert(e.message);
  }
  if (id) document.getElementById(id).innerHTML = s;
  return s;
}

function pickSkillsForLilly(id) {
  try {
    loader.appendTo("#skills_spinner");
    jQuery.get("/physical/liviaservices/liviaservices/pick_skills_for_lilly", {
      'sp_id' : id
    },
    function (data) {
      jQuery("#skills_spinner").html("");
      jQuery("#sec_skills_assign").html(data);
      jQuery("#service_provider_skill_provider_id").val(id);
    });
  } catch(e) {
    alert(e.message);
  }
}

// function getMyAllMatters() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function getMyAllMatterTasks() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function getMyAllAccounts() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function getMyAllContacts() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function getMyAllCampaigns() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function getMyAllOpportunities(type,div)
// function getRejectedContacts() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function assignSkills() {
  var skills = "";
  var elems = jQuery(".unassigned_skills");
  var isNoneChecked = true;
  for (var i=0; i<elems.length; i++ ) {
    if (elems[i].checked) {
      skills += elems[i].value + ";";
      isNoneChecked = false;
    }
  }
  if (isNoneChecked) {
    alert("Please Select Some Skills to Assign.");
    return;
  }
  var sp_id = jQuery("#service_provider_skill_provider_id").val();
  if (sp_id == "") {
    alert("Please select a Secretary first.");
    return;
  }
  loader.appendTo("#skills_spinner");
  jQuery.get("/physical/liviaservices/liviaservices/assign_skills", {
    "skills" : skills,
    "sp_id" : sp_id
  },
  function (data) {
    jQuery("#skills_spinner").html("");
    jQuery("#sec_skills_assign").html(data);
    jQuery("#service_provider_skill_provider_id").val(sp_id);
  }
  );
}

function unassignSkills() {
  var skills = "";
  var elems = jQuery(".assigned_skills");
  var isNoneChecked = true;
  for (var i=0; i<elems.length; i++ ) {
    if (elems[i].checked) {
      skills += elems[i].value + ";";
      isNoneChecked = false;
    }
  }
  if (isNoneChecked) {
    alert("Please Select Some Skills to Unassign.");
    return;
  }
  var sp_id = jQuery("#service_provider_skill_provider_id").val();
  if (sp_id == "") {
    alert("Please select a Secretary first.");
    return;
  }
  loader.appendTo("#skills_spinner");
  jQuery.get("/physical/liviaservices/liviaservices/unassign_skills", {
    "skills" : skills,
    "sp_id" : sp_id
  },
  function (data) {
    jQuery("#skills_spinner").html("");
    jQuery("#sec_skills_assign").html(data);
    jQuery("#service_provider_skill_provider_id").val(sp_id);
  });
}

function checkAllAssigned(e){
  var elems = jQuery(".assigned_skills");
  for (var i=0; i<elems.length; i++ ) {
    elems[i].checked = e.checked;
  }
}

function checkAllUnassigned(e){
  var elems = jQuery(".unassigned_skills");
  for (var i=0; i<elems.length; i++ ) {
    elems[i].checked = e.checked;
  }
}

// function findForSkill(skill_id)
// function initLiviaLoader() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function findForSkill(skill_id)
// function initEditInlineLivia() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function showObject(o,n)  is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function searchInMatterTasks(id)
// Hover effect for Notes/Tasks homepage - by Sanjay Varma
function rolloverToolTip(){
  jQuery('.livia_notestask').hover(
    function() {
      jQuery(this).children("span").css({
        'display':'block'
      });
    },
    function() {
      jQuery(this).children("span").css({
        'display':'none'
      });
      return false;
    });
}

// function addIssueToEvent()
// function addEventToIssue()
function selectCourt() {
  jQuery("#court_selector").html(
    "(<a href='#' onclick='createCourt(); return false;'>Create New</a> or Select Existing)");
  jQuery("#existing_court").show();
  jQuery("#new_court").hide();
}

function hideNewCourt() {
  jQuery("#court_selector").html(
    "(<a href='#' onclick='createCourt(); return false;'>Create New</a>)");
  jQuery("#existing_court").show();
  jQuery("#new_court").hide();
}

function createCourt(i) {
  if (i > 0) {
    jQuery("#court_selector").html(
      "Create New or (<a href='#' onclick='selectCourt(); return false;'>Select Existing</a>)");
  }
  jQuery("#existing_court").hide();
  jQuery("#new_court").show();
}

function selectMatterContact() {
  jQuery("#matter_contact_selector").html(
    "(<a href='#' onclick='createMatterContact(); return false;'>Create New</a> or Select Existing)");
  jQuery("#existing_matter_contact").show();
  jQuery("#new_matter_contact").hide();
}

function hideMatterContact() {
  jQuery("#matter_contact_selector").html(
    "(<a href='#' onclick='createMatterContact(); return false;'>Create New</a>)");
  jQuery("#existing_matter_contact").show();
  jQuery("#new_matter_contact").hide();
}

function createMatterContact(i) {
  if (i > 0) {
    jQuery("#matter_contact_selector").html(
      "Create New or (<a href='#' onclick='selectMatterContact(); return false;'>Select Existing</a>)");
  }
  jQuery("#existing_matter_contact").hide();
  jQuery("#new_matter_contact").show();
}

function updateEligibleSecretaries(skillID, commID) {
  var url = "/communications/eligible_secretaries";
  var params = {
    "skillID" : skillID,
    "commID" : commID
  };
  var callback = function(data) {
    jQuery("#eligible_secretaries").html(data);
  };
  jQuery.get(url, params, callback);
}

// function initLiviaFaceBox() commented : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 14/11/11
function closeFaceBox() {
  jQuery.facebox.close();
}

// function comment_textarea()
// function controlCommentButton()
function initLiviaHint(){
  jQuery('input[title!=""]').hint();
}

// function comment_textarea()
// function controlCommentButton
function getContactsAll(type,contact_status) {
  document.location.href = "/contacts?mode_type="+type+"&contact_status="+contact_status;
}

function getaccounts(type,account_status) {
  document.location.href = "/accounts?mode_type="+type+"&account_status="+account_status;
}

function initToggle() {    
  // jQuery("#apptToggle") : removed
  jQuery("#notesToggle").click(function(){
    jQuery("#notes_div").toggle();
    jQuery(".toggle_notes").toggle();
  });
  jQuery("#notes_div").show();
  
  jQuery("#tasksToggle").click(function(){
    jQuery("#task_div").toggle();
    jQuery(".toggle_tasks").toggle();
  });
  jQuery("#task_assigned_DIV").click(function(){
    jQuery("#task_assigned").toggle();
    jQuery("#task_completed").toggle();
    jQuery(".toggle_assigned").toggle();
  });
  jQuery("#task_completed_DIV").click(function(){
    jQuery("#task_completed").toggle();
    jQuery("#task_assigned").toggle();
    jQuery(".toggle_assigned").toggle();
  });

  jQuery("#alerts_toggle").click(function(){
    jQuery("#alerts_div").toggle();
    jQuery(".toggle_alerts").toggle();
    var n = parseInt(jQuery("#alerts_toggle_count").val());
    n += 1;
    jQuery("#alerts_toggle_count").val(n);
  });

  jQuery("#dashboard_toggle").click(function(){
    jQuery("#dashboard_div").toggle();
    jQuery(".toggle_dashboard").toggle();
    var n = parseInt(jQuery("#dashboard_toggle_count").val());
    n += 1;
    jQuery("#dashboard_toggle_count").val(n);
  });

  jQuery("#task_summary_toggle").click(function(){
    jQuery("#task_summary_div").toggle();
    jQuery(".toggle_task_summary").toggle();
    var n = parseInt(jQuery("#task_summary_toggle_count").val());
    n += 1;
    jQuery("#task_summary_toggle_count").val(n);
  });
  
  // Removed
  // jQuery("#budget_estimation_toggle") 
  // jQuery("#matter_management_toggle") 
  // jQuery("#budget_matter_closed_toggle") 
  // jQuery("#budget_matter_open_toggle") 
  // jQuery("#documentsls_div").hide();
  // jQuery("#documentsls_toggle")
  // Removed

  jQuery("#instruction_toggle").click(function(){
    jQuery("#instructions_DIV").toggle();
    jQuery(".toggle_instruction").toggle();
  });
  jQuery("#searchdashboard_toggle").click(function(){
    jQuery("#search_DIV").toggle();
    jQuery(".toggle_searchdashboard").toggle();
  });

  // jQuery("table#contactlistToggle tr.contactlistheader th")

  // jQuery("#clientTaskDiv") : removed
  // jQuery(".clientTaskDiv") : removed

  jQuery("#clientopenmattersDiv").click(function(){
    jQuery("#openclientopenmattersDiv").toggle();
    jQuery(".toggle_openmatters").toggle();
  });
  jQuery("#clientcompletedmatterDIV").click(function(){
    jQuery("#openclientcompletedmatterDIV").toggle();
    jQuery(".toggle_completedmatters").toggle();
  });
  
  // jQuery("#mattertasksDIV")
  // jQuery("#matterdocumentDIV") : removed
  // jQuery("#billingDIV") : removed

  jQuery("#searchbutton").click(function(){
    // jQuery("#searchlistToggle").show();
    // jQuery("#importlistToggle").hide();
    jQuery("#search_results").show();
  });
// jQuery("#importbutton") : removed
// jQuery("table#campaignrecordsToggle tr.campaignrecordsheader th")
// jQuery("#searchimportbutton").hide();
// jQuery(".searchlistToggle").hide();
// jQuery(".importlistToggle").hide();
// if(jQuery("#importlistToggle"))
// if(jQuery("#searchlistToggle"))
}

// function initMatterTasksToggle() : div not in portal
function initAutoComplete(){
  // jQuery("#contact_sphinx_search")
  // jQuery("#account_sphinx_search")
  // jQuery("#campaign_sphinx_search")
  // jQuery("#opportunity_sphinx_search")
  // jQuery("#matter_sphinx_search")
  jQuery("#search_string").keypress(function(e){
    if(e.which == 13){
      searchInCommon();
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#lawyer_search_query").keypress(function(e){
    if(e.which == 13){
      searchLawyer();
      return jQuery(".ac_results").fadeOut();
    }
  });
}

// function initCampaignsOpportunityToggle()
// function initLiviaMatterToggle()
// function show_campaign_combo() : not in admin : used in lawyer login
// function copy_address() : removed
// function editUploadStage() : removed not in use
// function roleInMatter() : removed not used admin side
this.imagePreview= function(){
  /* CONFIG */
  var xOffset = 10;
  var yOffset = 30;
  // these 2 variable determine popup's distance from the cursor
  // you might want to adjust to get the right result

  /* END CONFIG */
  jQuery("a.preview").hover(function(e){
    this.t = this.title;
    this.title = "";
    var c = (this.t != "") ? "<br/>" + this.t : "";
    jQuery("body").append("<p id='preview'><img src='"+ this.id +"' alt='Image preview' />"+ c +"</p>");
    jQuery("#preview")
    .css("top",(e.pageY - xOffset) + "px")
    .css("left",(e.pageX + yOffset) + "px")
    .fadeIn("fast");
  },
  function(){
    this.title = this.t;
    jQuery("#preview").remove();
  });
  jQuery("a.preview").mousemove(function(e){
    jQuery("#preview")
    .css("top",(e.pageY - xOffset) + "px")
    .css("left",(e.pageX + yOffset) + "px");
  });
}

/* Call this function wherever init required. Do *not* use direct code! */
function initLiviaDashBoardView() {
  jQuery(function() {
    jQuery('.liviadashboardview').hover(
      function() {
        jQuery(this).children("span").css({
          'display':'block'
        });
      },
      function() {
        jQuery(this).children("span").css({
          'display':'none'
        });
        return false;
      });
  });
}

// function show_date_div() : removed : not used in admin : lawyer side : duplicate
// function validate_date() : removed
//jQuery(function(){
//  jQuery('.cancelbutton').click(function(){
//    history.back();
//    return false;
//  });
//});

//function removethistr(tr){
//  jQuery('#account_notice').html('Contact Was Removed Successfully from the Account');
//  jQuery('#account_notice').show();
//  jQuery('#'+tr).hide();
//  jQuery('#account_notice')
//  .fadeIn('slow')
//  .animate({
//    opacity: 1.0
//  }, 8000)
//  .fadeOut('slow', function() {
//    jQuery('#account_notice').remove();
//  });
//}

//jQuery(function(){
//  jQuery('.tnehover').hover(
//    function() {
//      jQuery('.hoverspan').css({
//        'display':'block'
//      });
//    },
//    function() {
//      jQuery('.hoverspan').css({
//        'display':'none'
//      });
//      return false;
//    });
//});

// function get_charts(chart_name,fav_id) : removed
function show_report(){
  document.location.href = "/rpt_contacts/current_contact";
}

// function show_cgc_report() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function show_dashboard(){
  document.location.href = "/dashboards/all_category";
}

// function cgc_show_dashboard() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function show_all_dashboard(){
  document.location.href = "/dashboards/all_category";
}

// function show_dash_categories() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function disply_dashboard() is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
// function db_date_change() : removed : not used in admin : lawyer : dashboards partials
// function validate_checkbox() : removed : not used in admin : lawyer : dashboards partials
// function validate_checkbox_onclick : removed : not used in admin : lawyer : dashboards partials
jQuery(document).ready(function(){
  imagePreview();
  initToggle();
//initLeftSidebar(); removed
});

// function adddependent() : removed and relaced with add_delete_items : common.js
// function deletedependent() : removed and relaced with add_delete_items : common.js

/* This function grants/removes access to matter people from index page of matter people */
function matterPeopleAccessCheckbox(url, val, id) {    
  jQuery("#period_span_" + id).html("");
  loader2.appendTo("#period_span_" + id);
  jQuery.post(
    url,{
      "grant_access" : val
    },
    function(data) {
      jQuery("#period_span_" + id).html(data);
    });
}

// function addsubproduct() : removed and relaced with add_delete_items : common.js
// function deletesubproduct() : removed and relaced with add_delete_items : common.js

// function add_sub_ref() : removed
function populatelawyers(comp_id){
  if (comp_id==""){
    jQuery('#productdiv').html("");
    jQuery('#empdiv').html("");
    return false
  }
  loader.prependTo("#empdiv");
  jQuery.ajax({
    type: "GET",
    url: "/assign_licence/"+comp_id,
    dataType: 'script',
    data: {
      'comp_id' : comp_id,
      'populate' : "employees"
    },
    success: function(){
      loader.remove();
    }
  });
}

function populateproducts(id, comp_id){
  if (id==""){
    jQuery('#productdiv').html("");
    return false
  }
  loader.prependTo("#productdiv");
  jQuery.ajax({
    type: "GET",
    url: "/assign_licence/"+id,
    dataType: 'script',
    data: {
      'id' : id,
      'comp_id' : comp_id,
      'populate' : "products"
    },
    success: function(){
      loader.remove();
    }
  });
}

// function checkall() : removed
function show_company_licence(id){
  if(id==""){
    jQuery("#buy_licence").css('display','none');
    jQuery("#div_company_licence").css('display','none');
    loader.remove();
    return false
  }
  loader.prependTo("#company_div");
  jQuery.ajax({
    type: "POST",
    url: "/product_licences/get_company_licence",
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

// function populatelicencedlawproducts() : removed

// function unassignsubproduct() : removed and relaced with unassign_reassign_subproduct : common.js
// function unassignlawfirmsubproduct() : removed

// function populatelawfirmemployees() : removed
// function populatelawfirmproducts() : removed

// function reassignsubproduct() : removed and relaced with unassign_reassign_subproduct : common.js
// function reassignlawfirmsubproduct() : removed
// function enable_payment() : removed and relaced with display_div : common.js

// function checkinput() : shifted to common.js
// function checklicenceinput() : shifted to common.js
// function checkinputlicence() : shifted to common.js
// function checkinputprod() : shifted to common.js

// function toggletag(id) : removed
// function populateemployees(id) : removed not in use
// function initmanage_secretary() : removed
// function getsubproductlists(id,user_id,lawyer_id) :removed
// function getsubproduct_lists(id,user_id,lawyer_id) : removed

// function assignSubproducts_to_secretary(user_id,company_id) : removed and relaced with assign_unassign_subproducts_to_secretary : common.js
// function unassignSubproducts_from_secretary(user_id,company_id) : removed and relaced with assign_unassign_subproducts_to_secretary : common.js

// function company_dropdown_selected_new_invoice(selected_company)
function populateuserfields(elm){
  if (elm.checked) {
    jQuery("#userformfield").show();
  } else {
    jQuery("#userformfield").hide();
  }
}

//function company_licence_detail(company_id)
function get_company_licence_by_product(product_id, company_id, user_id){
  if(product_id==""){
    loader.remove();
    jQuery("#div_product_licences").css('display','none');
    jQuery("#div_submit").css('display','none');
    return false
  }
  loader.prependTo("#span_product");
  jQuery.post(
    "/assign_licence/show_licences", {
      'id' : user_id,
      'comp_id' : company_id,
      'prod_id' : product_id
    },
    function(data) {
      // Highlight or other such visual clue.
      jQuery("#div_product_licences").css('display','block');
      jQuery("#div_product_licences").html(data);
      jQuery("#div_submit").css('display','block');
      loader.remove();
    });
}

function expand_collapse_div_details(id, divid, first, second){
  jQuery("#"+divid).toggle();
  jQuery("#"+id+"_"+first).toggle();
  jQuery("#"+id+"_"+second).toggle();
}

// function expand_details(id)
// function expand_userdetails(id) : removed not in use
// function minimize_details(id)
// function minimize_userdetails(id) : removed not in use
// function expand_product_details(id)
// function minimize_product_details(id)
function show_prod_config(id){
  if (id == ""){
    jQuery('#edit_product_config').html("");
    return false
  }
  loader.prependTo("#edit_product_config")
  jQuery.ajax({
    type: "POST",
    url: "/products/edit_product_config",
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

function copy_company_address(elm){
  if(elm.checked){
    jQuery(function() {
      var street = jQuery("#company_billing_address_attributes_0_street").val();
      var city = jQuery("#company_billing_address_attributes_0_city").val();
      var zip = jQuery("#company_billing_address_attributes_0_zipcode").val();
      var country = jQuery("#company_billing_address_attributes_0_country").val();
      var state = jQuery("#company_billing_address_attributes_0_state").val();
      jQuery("#company_shipping_address_attributes_0_street").val(street);
      jQuery("#company_shipping_address_attributes_0_city").val(city);
      jQuery("#company_shipping_address_attributes_0_zipcode").val(zip);
      jQuery("#company_shipping_address_attributes_0_country").val(country);
      jQuery("#company_shipping_address_attributes_0_state").val(state);
    });
  } else {
    jQuery("#company_shipping_address_attributes_0_street").val('');
    jQuery("#company_shipping_address_attributes_0_city").val('');
    jQuery("#company_shipping_address_attributes_0_zipcode").val('');
    jQuery("#company_shipping_address_attributes_0_country").val('');
    jQuery("#company_shipping_address_attributes_0_state").val('');
  }
}


function fetch_data_based_for_company( id, divid, action ){
  if( id == "" ){
    return false
  }
  loader.prependTo("#"+divid)
  jQuery.ajax({
    type: "POST",
    url: "/"+action,
    dataType: 'script',
    data: {
      'company_id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

// function showemployees(id) : removed
// function showusers() : removed and replaced with show_data_for_record : common.js

//function listofusers(id)
function listofuser_secretary(id,company_id){
  if(id==""){
    return false
  }
  loader.prependTo("#spdiv")
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/usersecretary",
    dataType: 'script',
    data: {
      'user_id' : id,
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

function list_company_utility(id, type){    
  if(id==""){
    return false
  }
  loader.prependTo("#spinner_div")
  jQuery.ajax({
    type: "POST",
    url: "/manage_company_utilities/"+type+"?company_id="+id,
    dataType: 'script',
    success: function(){
      loader.remove();
      fetch_data(type, id, '#'+type);
    }
  });
}

//function secretaryassignmentlist() : removed

function show_assigned_cluster_employee_list(id){
  if (id == ""){
    jQuery('#show_assigned_cluster_employee_list').html("");
    return false
  }
  loader.prependTo("#show_assigned_cluster_employee_list")
  jQuery.ajax({
    type: "GET",
    url: "/manage_cluster/show_assigned_cluster_employee_list",
    dataType: 'script',
    data: {
      'cluster_id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

//This function is to call the "show_company_list" function in manage_secretary controller by passing the required parameters which is used to get the required data for company dropdown in Manage Secretary Module for Admin login : Author:Madhu
function show_company_list(id){
  if (id == ""){
    jQuery('#show_company_list').html("");
    return false
  }
  loader.prependTo("#show_company_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/show_company_list",
    dataType: 'script',
    data: {
      'secretary_id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

//This function is to call the "show_employee_list" function in manage_secretary controller by passing the required parameters which is used to get the required data for employee dropdown in Manage Secretary Module for Admin login : Author:Madhu
function show_employee_list(company_id,secretary_id){
  if (company_id == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  loader.prependTo("#show_employee_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/show_employee_list",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

// function show_employee_list_of_cluster() : removed
// function show_employee_list_of_cluster_for_sec() : removed

// This function is to call the "show_employee_list" function in manage_secretary controller by passing the required parameters which is used to get the required data for employee dropdown in Manage Secretary Module for Admin login
function show_company_users_list(company_id,cluster_id){
  if (company_id == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  loader.prependTo("#show_company_users_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/show_company_users_list",
    dataType: 'script',
    data: {
      'cluster_id' : cluster_id,
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

//This function is to call the "unassign_sec_to_cluster" function in manage_cluster controller by passing the required parameters : Author:Madhu
function unassign_emp_to_cluster(cluster_id,lawyer_id){
  loader.appendTo("#show_cluster_employee_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/unassign_emp_to_cluster",
    dataType: 'script',
    data: {
      'cluster_id' : cluster_id,
      'lawyer_id' : lawyer_id
    },
    success: function(){
      loader.remove();
    }
  });
}

//This function is to call the "unassign_sec_to_emp" function in manage_secretary controller by passing the required parameters : Author:Madhu
function unassign_sec_to_emp(secretary_id,lawyer_id){
  loader.prependTo("#show_employee_list");
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/unassign_sec_to_emp",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'lawyer_id' : lawyer_id
    },
    success: function(){
      loader.remove();
    }
  });
}

// checked
function change_priority(secretary_id,mapping_id){
  loader.prependTo("#show_employee_list");
  var p = document.getElementById("setpriority_"+mapping_id).value;
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/update_priority",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'mapping_id' : mapping_id,
      'priority' : p
    },
    success: function(){
      loader.remove();
    }
  });
}

// This function is to call the "assign_sec_to_emp" function in manage_secretary controller by passing the required parameters
function assign_sec_to_emp(secretary_id){
  if (jQuery("#employee_id").val() == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  jQuery("#assign_sec_to_emp").removeAttr('onclick');
  loader.appendTo("#show_employee_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/assign_sec_to_emp",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'lawyer_id' : jQuery("#employee_id").val()
    },
    success: function(){
      loader.remove();
    }
  });
}

//This function is to call the "assign_emp_to_cluster" function in manage_cluster controller by passing the required parameters
function assign_user_to_cluster(cluster_id){    
  if (jQuery("#employee_id").val() == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  jQuery("#assign_user_to_cluster").removeAttr('onclick');
  loader.appendTo("#show_company_users_list")
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/assign_user_to_cluster",
    dataType: 'script',
    data: {
      'lawyer_id' : jQuery("#employee_id").val(),
      'cluster_id' : cluster_id
    },
    success: function(){
    }
  });
}

function update_mapping_priority(secretary_id,mapping_id){
  loader.prependTo("#employee_list_of_cluster");
  var p = document.getElementById("setpriority_"+mapping_id).value;
  jQuery.ajax({
    type: "POST",
    url: "/service_providers/update_mapping_priority",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'mapping_id' : mapping_id,
      'priority' : p
    },
    success: function(){
      loader.remove();
      alert("Priority updated successfully.");
    }
  });
}

// function show_departments()
// function show_sub_departments() : removed not in use
// function show_designations()
function show_email_settings(company_id){
  if(company_id==""){
    return false
  }
  loader.prependTo("#company_email_div")
  loader.prependTo("#show_employee_list")
  jQuery.ajax({
    type: "GET",
    url: "/company_email_settings/list",
    dataType: 'script',
    data: {
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}
function show_import_histories(company_id){
  if(company_id==""){
    return false
  }
  loader.prependTo("#company_email_div")
  loader.prependTo("#show_employee_list")
  jQuery.ajax({
    type: "GET",
    url: "/import_histories/list",
    dataType: 'script',
    data: {
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

//function licencetype_toggle(type){
//  if (jQuery("#product_licence_licence_type").val() == "0") {
//    jQuery("#product_licence_end_date").attr("disabled", false);
//  }else{
//    jQuery("#product_licence_end_date").attr("disabled", true);
//  }
//}

//function deactivated_employees(id)
//function deactivated_users(id)
//function activate_user(company_id,id) : activate_user_employee created in common.js 
//function activate_employee(company_id,id) : activate_user_employee created in common.js
function show_product_pricing(product_id){
  if (product_id==""){
    jQuery("#div_product_pricing").css('display','none');
    jQuery("#div_submit").css('display','none');
    return false
  }
  loader.prependTo("#div_prd_price");
  jQuery.post("/product_licences/product_pricing",{
    'id' : product_id
  },
  function(data) {
    // Highlight or other such visual clue.
    jQuery("#div_product_pricing").html(data);
    jQuery("#div_product_pricing").css('display','block');
    jQuery("#div_submit").css('display','block');
    loader.remove();
  });
}

// function show_product_pricing_lawfirm() : removed
function update_product_price(product_id){
  var total = 0;
  var depqty = document.getElementById("product_licence_" + product_id + "_qty")
  var depprice = document.getElementById("product_licence_" + product_id + "_price")
  var depcost = document.getElementById("product_licence_" + product_id + "_cost")
  var deplicence = document.getElementById("product_licence_id").value
  var deptotal = document.getElementById("product_licence_total")
  depcost.value = depqty.value * depprice.value
  var lic = deplicence.split(",")
  for (var i = 1; i < lic.length; i++){
    total = total + parseInt(document.getElementById("product_licence_" + lic[i] + "_cost").value)
  }
  deptotal.value = total;
}

function licencedetail_toggle(id){
  if (jQuery('#product_licence_'+id).css('display')== "none"){
    jQuery('#product_licence_'+id).show();
  }else{
    jQuery('#product_licence_'+id).hide();
  }    
}

// function showclients(id) : removed and relaced with show_data_for_record : common.js
function showclientdetails(id,company_id){
  if(id==""){
    return false
  }
  loader.prependTo("#spiner")
  jQuery.ajax({
    type: "GET",
    url: "/companies/new_client",
    dataType: 'script',
    data: {
      'cont_id' : id,
      'company_id' :company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

function show_employee_reporting_to_list(dept_id,company_id){
  if (dept_id == "") {
    return;
  }
  loader.prependTo("#userdiv")
  jQuery.ajax({
    type: "POST",
    url: "/employees/show_employee_reporting_to_list",
    dataType: 'script',
    data: {
      'department_id' : dept_id,
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

// added assign_release_moduleaccess : common.js
// modify with above function
// function releasemoduleaccess_from_secretary() : removed and relaced with assign_release_moduleaccess : common.js
// function assignmoduleaccess_to_secretary() : removed and relaced with assign_release_moduleaccess : common.js

// id for company
function ownnextpage(offset,comp_id,req){
  if (offset == "") {
    return;
  }
  loader.prependTo("#div_company_licence")
  jQuery.ajax({
    type: "POST",
    url: "/companies/company_licences",
    dataType: 'script',
    data: {
      "offset" : offset,
      "id" : comp_id,
      "req" : req
    },
    success: function(){
      loader.remove();
    }
  });
}

// function companynextpage(offset,req) : removed
// function companynewcgcinit(elm) : removed
// function show_company_rate_card() : removed and relaced with show_data_for_record : common.js
// function update_company_header() : removed and relaced with show_data_for_record : common.js
// id for company
function deactivate_unassign_licence(id,type){
  if(id==""){
    return false
  }
  loader.prependTo("#productdiv")
  jQuery.ajax({
    type: "POST",
    url: "/product_licences/delete",
    dataType: 'script',
    data: {
      'id' : id,
      'type' : type
    },
    success: function(){
      loader.remove();
    }
  });
}

//function validate_dashboard_name() : removed duplicate in lawyers application.js

function show_msg(div_id,msg){
  jQuery('#'+div_id).html(msg);
  jQuery('#'+div_id).show();
}

// function getSelectBoxId() : removed
// function filterContact() : removed
// function filterCategory() : removed
// function filterOpportunity() : removed

// id for company
function get_fav_charts(id){
  jQuery('#fav_list').css({'display':'none'});
  jQuery('#show_fav').css({'display':'block'});
  loader.prependTo('#show_fav')
  jQuery.ajax({
    type: 'GET',
    url: '/dashboards/show_favs',
    data: {
      'id' : id
    },
    success: function(){
      loader.remove();
    },
    dataType: 'script'
  });
}

jQuery(function(){
  jQuery('.upload_to').change(function(){    
    initautocompleteonchange();
  });
})

jQuery.noConflict();

// function initLeftSidebar() : removed as 8637 integrated
function clear_follow_up_date(id){
  var div_id = "#follow_up_date_" + id;
  if(id==""){
    return false
  }
  loader.prependTo(div_id)
  jQuery.ajax({
    type: "POST",
    url: "/opportunities/clear_follow_up_date",
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(transport){
      jQuery(div_id).html(transport);
    },
    complete: function(){
      loader.remove();
    }
  });
}

function showlookupvalues(type){
  if(type==""){
    return false
  }
  loader.prependTo("#lookupdiv")
  jQuery.ajax({
    type: "GET",
    url: "/configurelookups/list",
    dataType: 'script',
    data: {
      'type' : type
    },
    success: function(){
      loader.remove();
    }
  });
}

function liviadatepicker(){
  jQuery(document).ready(function() {
    jQuery(".date_picker").datepicker({
      showOn: 'both',
      dateFormat: 'mm/dd/yy',
      defaultDate: null,
      onSelect: function(value,date){
      }
    });
  });
}

function livia_datepicker(field){
  jQuery(document).ready(function() {
    jQuery('#'+field).datepicker({
      showOn: 'both',
      buttonImage: '/images/livia_portal/calendar_n.gif',
      buttonImageOnly: true,
      dateFormat: 'mm/dd/yy',
      onSelect: function(value,date){
        var today=new Date();
        var newdate=new Date(value);
        jQuery('#'+field).val((newdate.getMonth()+1)+'/'+newdate.getDate()+'/'+newdate.getFullYear());
      }
    });
  });
}

// function livia_datepicker_other()
//jQuery(function(){
//  jQuery('.removable_cnt').click(function(){
//    var ac_id=this.id.split("ac_id_")[1];
//    var acc_id=this.id.split("ac_id_")[0];
//    loader.prependTo(".gridTable")
//    jQuery.ajax({
//      type: "GET",
//      url: "/accounts/remove_contact",
//      data: {
//        'id' : ac_id,
//        'account_id': acc_id
//      },
//      success: function(){
//        loader.remove();
//        removethistr(ac_id);
//      }
//    });
//    return false
//  })
//})

// function sort_table is removed : as its not being used in admin : Please don not add again if merge issues occure : Supriya Surve : 15/11/11
function sort_comments(commentable_type,commentable_id,dir,action,sort_by,order){
  jQuery.ajax({
    type: "GET",
    url: "/comments/" + action,
    dataType: 'script',
    data: {
      'commentable_type' : commentable_type,
      'commentable_id' : commentable_id,
      'dir' : dir,
      'sort_by' : sort_by,
      'order' : order
    },
    beforeSend: function() {
      jQuery('#loader').show()
    },
    complete: function(){
      jQuery('#loader').hide()
    },
    success: function(){
      loader.remove();
    }
  });
}

function showLoadingGif(){
  jQuery('#submit_cancel_btn').hide();
  jQuery('#loading_gif').show();
  jQuery('body').css("cursor", "wait");
}

function hidewLoadingGif(){
  jQuery('#loading_gif').hide();
  jQuery('body').css("cursor", "default");
  jQuery('#submit_cancel_btn').show();
}

function show_spinner(){
  jQuery('#loader1').show();
}

function show_end_time(repeat){
  if(repeat.value!=""){
    if(repeat.id=='zimbra_activity_repeat' ){
      jQuery('#choose_end_time_zimbra').show();
      jQuery('#mandatory_zimbra').show();
      return false
    }else if(repeat.id=='matter_task_repeat'){
      jQuery('#choose_end_time_matter_task').show();
      jQuery('#mandatory_task').show();
    }
  }else{
    if(repeat.id=='zimbra_activity_repeat' ){
      jQuery('#choose_end_time_zimbra').hide();
      jQuery('#mandatory_zimbra').hide();
      return false
    }else if(repeat.id=='matter_task_repeat'){
      jQuery('#choose_end_time_matter_task').hide();
      jQuery('#mandatory_task').hide();
    }
  }
}

function check_file_format() {
  var fileformat=jQuery('#file_format').val();
  if(fileformat=="XLS"){
    jQuery("#xls").show();
    jQuery("#csv").hide();
  }else{
    jQuery("#csv").show();
    jQuery("#xls").hide();
  }
}

//function add_sticky_note(note,counter) : removed
function assign_service_provider(service_provider_id){
  var answer = jQuery('#accept_permissions').attr('checked','checked');
  if (answer){
    loader.appendTo("#loader_position");
    jQuery.ajax({
      type: 'POST',
      url: '/physical/liviaservices/livia_secretaries/set_service_provider_id_by_telephony',
      data: {
        'service_provider_id' : service_provider_id
      },
      success: function(transport){
        window.location.reload();
        var dt= new Date();
        jQuery('#dateandtime').toggle();
        jQuery('#dateandtime').html(""+dt);
      }
    });
  }
}

function assign_sec_to_cluster(cluster_id){
  loader.prependTo("#service_provider_cluster_list");
  var secretary_id = jQuery("#service_providers_id").val();
  if (secretary_id == "") {
    alert("Please select a Livian first.");
    return;
  }
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/assign_sec_to_cluster",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'cluster_id' : cluster_id
    },
    success: function(){
    }
  });
}

function togal_assign_div(div_id){
  if(div_id == 'assign_lawfirm_user'){
    jQuery('#div_assign_lawfirm_user').show();
    jQuery('#div_assign_employee').hide();
  }else if(div_id == 'unassign_lawfirm_user'){
    jQuery('#div_unassign_lawfirm_user').show();
    jQuery('#div_unassign_employee').hide();
  }else if (div_id == 'unassign_employee'){
    jQuery('#div_unassign_lawfirm_user').hide();
    jQuery('#div_unassign_employee').show();
  }else{
    jQuery('#div_assign_employee').show();
    jQuery('#div_assign_lawfirm_user').hide();
  }
}

//function display_complexity(value){
//  if (value == "2"){
//    jQuery('#complexity_div').show();
//  }else{
//    jQuery('#complexity_div').hide();
//  }
//}

function get_work_subtypes(role_id){
  jQuery('#work_type_list').html("");
  if (role_id){
    loader.appendTo("#work_type_list");
    jQuery.ajax({
      type: "POST",
      url: "/service_providers/get_work_subtypes",
      dataType: 'script',
      data: {
        'role_id' : role_id
      },
      success: function(){
        loader.remove();
      }
    });
  }
}

function show_error_msg(div,msg,classname){
  loader.remove();
  jQuery('#'+div)
  .html("<div class="+classname+">"+msg+"</div>")
  .fadeIn('slow')
  .animate({
    opacity: 1.0
  }, 8000)
  .fadeOut('slow')
  return false;
}

function check_licence(){
  if (jQuery('#role_assign_licence_id').val() == ""){
    alert("Please assign licence first");
    return false;
  }else if (jQuery('#licences_not_available').html() == "Licences Not Available."){
    alert("Please buy a licence first");
    return false;
  }else{
    return true;
  }
}

function show_cluster_list(user_id,user_type){
  if (user_id == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  if (user_type=='ServiceProvider'){
    loader.prependTo("#service_provider_cluster_list")
  }else{
    loader.prependTo("#lawfirm_user_cluster_list")
  }
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/show_cluster_list",
    dataType: 'script',
    data: {
      'id' : user_id,
      'user_type' : user_type
    },
    success: function(){
      loader.remove();
    }
  });
}

function today_date(){
  var d = jQuery("#user_date").val();
  var t = jQuery("#user_time").val();
  //var o = jQuery("#user_of").val();
  var lat_date = new Date(d+","+t);
  return lat_date
}

function check_cluster_for_team_manager(){
  if(jQuery('#role_id option:selected').text() == 'team_manager' && jQuery("#clusters_tr input:checkbox").is(':checked') == false){
    alert('A team manager should be assigned to atleast one cluster');
    return false;
  }
  return true;
}

function show_hide_is_cpa(value){
  if(value=='team_manager' || value=='secretary'){
    jQuery('#service_provider_type').show();
  }else{
    jQuery('#service_provider_type').hide();
  }
}

function toggleCheckboxes(class_name,checked){
  jQuery("."+class_name).each(function(i,el){
    el.checked = checked;
    if(el.id != ""){
      check_disabled_selected_tag(el.value, checked)
    }
  });
}

function show_cluster_view(obj,id){
  jQuery('#clusters_tr').hide();
  jQuery('#skills_tr').hide();
  if(obj.checked){
    jQuery("."+id+"_cluster").show();
    jQuery("."+id+"_skills").show();
    if(id =="bo" || id =="cp"){
      toggleCheckboxes(id+"_cluster",obj.checked);
    }
  }else{
    if(id=='bo'){
      jQuery("."+id+"_skills").hide();
      toggleCheckboxes(id+"_skills",obj.checked);
    }else if (jQuery('.type_livian').attr('checked')==false && jQuery('.type_common_pool').attr('checked')==false){
      jQuery("."+id+"_skills").hide();
      toggleCheckboxes(id+"_skills",obj.checked);
    }
    jQuery("."+id+"_cluster").hide();
    toggleCheckboxes(id+"_cluster",obj.checked);
  }
  jQuery(".cluster").each(function(x,y){
    if(y.checked){
      jQuery('#clusters_tr').show();
      jQuery('#skills_tr').show();
    }
  });
}

function update_page_with_company(company_id, path){
  if(company_id==""){
    return false
  }
  loader.prependTo("#spinner_div")
  jQuery.ajax({
    type: "POST",
    url: path,
    data: {
      "company_id":company_id
    },
    success: function(){
      window.location.href = path
    }
  });
}

// function display_selected_matter_documents() : removed
function check_rate(obj){
  if (isNaN(obj.value)){
    alert('Please enter only number');
    obj.value=''
    obj.focus();
    return;
  }
  var rate = obj.value;
  var frate = parseFloat(rate);
  if ((rate.indexOf('.') != -1) && ((rate.length - rate.indexOf('.') -1) > 2)){
    frate = frate.toFixed(2);
    jQuery('#'+obj.id).val(frate);
  }
  if (frate > 9999.99 || frate < 0.01){
    obj.value=''
    obj.focus();
    alert("Rate should be between 0.01 and 9999.99");
  }
}

function toggle_skills_div(checked,div_id){
  var checked_value = 0;
  var check_boxes, selects;
  if(checked == true){
    jQuery('#'+div_id).show();
    checked_value = 1;
  }else{
    jQuery('#'+div_id).hide();
    checked_value = 0;
  }
  if(div_id == "livian_skills"){
    if(jQuery('.type_livian').is(':checked') || jQuery('.type_common_pool').is(':checked')){
      var check_boxes = jQuery('#livian_skills input');
      var selects = jQuery('#livian_skills select');
      jQuery('#'+div_id).show();
      checked_value = 1;
    }else{
      var check_boxes = jQuery('#'+div_id+' input');
      var selects = jQuery('#'+div_id+' select');
      jQuery('#'+div_id).hide();
      checked_value = 0;
    }
  }
  check_uncheck_select_and_checboxes(checked_value,check_boxes,selects);
}

function check_uncheck_select_and_checboxes(checked_value,check_boxes,selects){
  for (var i = 0; i < check_boxes.length; i++) {
    var myType = check_boxes[i].getAttribute("type");
    if ( myType == "checkbox") {
      check_boxes[i].checked = checked_value;
    }
  }
  for (var i = 0; i < selects.length; i++) {
    selects[i].selectedIndex = checked_value;
  }
}

function check_disabled_selected_tag(obj, checked){
  jQuery('#'+obj).attr('disabled', !checked);
}

function show_clusters(id){
  if(id == ""){
    jQuery("#employees").hide();
  }else{
    loader.prependTo("#empdiv")
    jQuery.ajax({
      type: "GET",
      url: "/companies/"+id+"/employees/show_employee_with_cluster",
      dataType: 'script',
      data: {
        'company_id' : id
      },
      success: function(){
        jQuery("#employees").show();
        loader.remove();
      }
    });
  }
}

function showemployees_clusters(id, company_id){
  loader.prependTo("#empdiv")
  jQuery.ajax({
    type: "GET",
    url: "/companies/"+company_id+"/employees/show_employee_with_cluster",
    dataType: 'script',
    data: {
      'company_id' : company_id,
      'lawyer_id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

function update_cluster_user(action, lawyer_id){
  if((jQuery('#assing_clusters option:selected').length == 0) && (action == 'unassign')){
    alert("Please select cluster(s) to unassign");
    return false;
  }
  if((jQuery('#unassign_clusters option:selected').length == 0) && (action == 'assign')){
    alert("Please select cluster(s) to assign");
    return false;
  }
  var unassigned_clusters = [];
  var assign_clusters = [];
  jQuery('#unassign_clusters :selected').each(function(i, selected){
    unassigned_clusters[i] = jQuery(selected).val();
  });
  jQuery('#assing_clusters :selected').each(function(i, selected){
    assign_clusters[i] = jQuery(selected).val();
  });
  try {
    loader.prependTo("#empdiv");
    jQuery('input:button').attr('disabled',true);
    jQuery.ajax({
      type: "GET",
      url: "/clusters/update_user_cluster",
      dataType: 'script',
      data: {
        'unassigned_clusters[]' : unassigned_clusters,
        'assigned_clusters[]' : assign_clusters,
        'update_user_cluster' : action,
        'lawyer_id' : lawyer_id
      },
      success: function(){
        loader.remove();
        jQuery('input:button').attr('disabled',false);
      }
    });
  } catch(e) {
    alert(e.message);
  }
}

function disableAllSubmitButtons(class_name){
  jQuery('.' + class_name).attr('disabled', 'disabled');
  jQuery('.' + class_name).attr('value', 'Please wait...');
  return true;
}

function enableAllSubmitButtons(class_name){
  jQuery('.' + class_name).attr('disabled', '');
  jQuery('.' + class_name).attr('value', 'Save');
  return true;
}

function update_priority(obj,cluster_id,lawyer,livian){
  loader.prependTo("#show_assigned_cluster_employee_list");
  jQuery(obj).hide();
  jQuery(obj).parent().append(loader);
  jQuery("#priority_types_ :all").attr("disabled",true);
  var prority = jQuery(obj).val();
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/update_priority",
    dataType: 'script',
    data: {
      'priority_types' : prority,
      'cluster_id' : cluster_id,
      'lawyer_id' : lawyer,
      'livian_id' : livian
    },
    success: function(transport) {
      jQuery(obj).show();
      loader.remove();
      jQuery("#priority_types_ :all").attr("disabled",false);
    }
  });
}

function check_stt_tat_complexity(){
  var val = 0;
  jQuery(".check").each(function(index,value){
    if (jQuery(value).val() == ""){
      val = 1;
    }
  });
  if (val == 1){
    alert("Please fill mandatory fields");
    return false;
  }else{
    return true;
  }
}

function check_task_on_work_complexity(obj, class_type, id){
  jQuery(obj).append(loader);
  jQuery.ajax({
    type: "POST",
    url: "/work_subtypes/check_tasks_on_work_complexities/"+id,
    dataType: 'script',
    data:{
      'class_type' : class_type
    },
    success: function(transport){
      loader.remove();
    }
  });
}

function delete_work_subtype(id, varify){
  if(varify == true || confirm('Are you sure ?')){
    jQuery.ajax({
      type: "DELETE",
      url: "/work_subtypes/"+id,
      dataType: 'script',
      success: function(transport) {
        tb_remove();
        loader.remove();
      }
    });
  }
}

function search_livian_for_admin(id){
  jQuery("#"+id).autocomplete(
    "/manage_secretary/filter_livian_by_name", {
      width: 'auto',
      formatResult: function(data, value) {
        return jQuery(value).text();
      }
    }).flushCache();
  jQuery("#"+id).result(function(event, data, formatted) {
    id = formatted.split('id=')[1].split(' >')[0];
    window.location.href = "/service_providers/"+id+"/edit"
  });
}

function redirect_to_livian_edit(obj){
  window.location.href = jQuery(obj).children('a').attr('href');
}