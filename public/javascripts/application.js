// Last Updated by Milind - 17-09-2010
// Added comment 'Not Being used' for the functions which are not used

var loader = jQuery("<center><img src='/images/loading.gif' /></center>");
var loader2 = jQuery("<img src='/images/loading.gif' />");
var spinner = jQuery("<center><img src='/images/spinner.gif' /></center>");

//This function code is used for limiting number of character in Repository/add_tags.html.erb/ for text_area_tag -By :Pratik Jadhav
function imposeMaxLength( limitField, limitNum ){
  if (limitField.value.length > limitNum) {
    limitField.value = limitField.value.substring(0, limitNum);
  }
}

jQuery(function(){
  jQuery(".number").live('keypress',function(e){
    var val;
    if (e.charCode == undefined){
      e.charCode = e.keyCode;
    }
    var chr = String.fromCharCode(e.charCode);
    val = e.target.value;
    val = val+chr;
    if (e.charCode !=0 && (val.match(/^\d*$/) == null)){
      e.preventDefault();
    }
  });
  jQuery('.number').live('blur',function(e){
    try{
      var number = parseFloat(e.target.value);
      if(isNaN(number)){
        e.target.value='';
      }
    }catch(exception){
      e.target.value='';
    }
  });

  //please remove after consulting Milind Sir
  //previous code is jQuery(".amount").live('keypress',function(e){
  jQuery(".amount_old").live('keypress',function(e){
    var val;
    if (e.charCode == undefined){
      e.charCode = e.keyCode;
    }
    var chr = String.fromCharCode(e.charCode);
    val = e.target.value;
    val = parseInt(val+chr);
    var keyValue = parseInt(e.charCode);
     //if ((val.toString().match(/(^\d{1,8})(\.\d{0,2})?$/) == null) && keyValue !=0){ //Previous condition, please remove after consulting Milind Sir
    if ((val.toString().match(/(\.d{1,8})(\.\d{0,2})?$/) == null)) {
      e.preventDefault();
    }
  });
  
  jQuery('.amount').live('blur',function(e){
    try{
      var inputAmount = parseFloat(e.target.value);
      if(isNaN(inputAmount)){
        e.target.value='';
      }
    }catch(exception){
      e.target.value='';
    }
  });
});

function show_loader(){
  jQuery("#loader1").show();
}

function hide_loader(){
  jQuery("#loader1").hide();
}

function update_ticket_sub_types( ticket_type ){
  jQuery("#suggestion").hide();
  jQuery('#brief_value').attr("value","");
  jQuery('#descript_value').val(" ");
  jQuery("#request_sub_types").html(loader2)
  jQuery.ajax({
    type: "GET",
    url: "/home/get_ticket_sub_types",
    dataType: 'script',
    data: {
      'request_type_id' : ticket_type.value
    },
    success: function(transport){
      loader2.remove();
      jQuery("#request_sub_types").html(transport);
      jQuery('#brief_value').val(jQuery("input[name='ticket[request_sub_type_id]']:checked").attr('rel'));
    }
  });
}

function suggestion_display( ticket_sub_type_id, sub_type_name ){
  if (ticket_sub_type_id == ''){
    jQuery("#suggestion").hide();
    jQuery('#brief_value').attr("value","");
    jQuery('#descript_value').val("");
  }else{
    if(jQuery('.request_lists').is(':checked') || (sub_type_name != ''))
    {
      jQuery("#suggestion").html(loader);
      jQuery.ajax({
        type: 'GET',
        url: '/home/get_suggestions',
        dataType: 'script',
        data: {
          'request_sub_type_id' : ticket_sub_type_id
        },
        success: function(transport){
          loader.remove();
          jQuery("#suggestion").slideDown(500, function(){
            jQuery(this).html(transport);
          });
          jQuery('#brief_value').attr("value",sub_type_name);        
        }
      });
    }else{
      jQuery("#suggestion").hide();
      jQuery('#brief_value').attr("value","");
      jQuery('#descript_value').val("");
    }
  }
}

function update_sub_products( product ){
  if(product == ''){
    jQuery('#sub_product_list').html("Select a product to continue");
  }else{
    jQuery("#sub_product_list").html(loader);
    jQuery.ajax({
      type: "GET",
      url: "home/get_sub_products",
      dataType: 'script',
      data: {
        'product_id' : product.value
      },
      success: function(transport){
        loader.remove();
        jQuery("#sub_product_list").html(transport);
      }
    });
  }
}

function disableWithPleaseWait( button_id, disable, val ){
  jQuery('#' + button_id).attr('disabled', disable);
  if(disable){
    jQuery('#' + button_id).attr('value', "Please wait ...");
  }else{
    jQuery('#' + button_id).attr('value', val);
  }
  return true;
}

// Is Being Used
function validateFieldsForTnEFaceboxForm(button_id){
  disableWithPleaseWait(button_id, true, '');
  jQuery("#errors_div_for_tne_facebox").hide();
  var err = "";
  var dateVal = jQuery("#physical_timeandexpenses_time_entry_time_entry_date").val();
  var matterVal = jQuery("#physical_timeandexpenses_time_entry_matter_id").val();
  var contactVal = jQuery("#physical_timeandexpenses_time_entry_contact_id").val();
  var durVal = jQuery("#physical_timeandexpenses_time_entry_actual_duration").val();
  var descVal = jQuery("#physical_timeandexpenses_time_entry_description").val();
  var rateVal = jQuery("#physical_timeandexpenses_time_entry_actual_activity_rate").val().replace(/\,/g,'');
  var expdes1Val = jQuery("#1_expense_entry_description").val();
  var expamt1Val = jQuery("#1_expense_entry_expense_amount").val();
  var expdes2Val = jQuery("#2_expense_entry_description").val();
  var expamt2Val = jQuery("#2_expense_entry_expense_amount").val();
  var start_val = jQuery("#physical_timeandexpenses_time_entry_start_time").val();
  var end_val = jQuery("#physical_timeandexpenses_time_entry_end_time").val();
  var time_start = (new Date (today_date().toDateString() + ' ' + start_val));
  var time_end = (new Date (today_date().toDateString() + ' ' + end_val));
  var difference = time_end.getTime() - time_start.getTime();
    
  if (dateVal == "") {
    err += "<li>Date can't be blank.</li>";
  }
  if ((expamt1Val == "" && expdes1Val !="")  || (expamt1Val != "" && expdes1Val =="") ){
    err += "<li>Please enter Amt and description for expense entry 1.</li>";
  }

  if ((expamt2Val == "" && expdes2Val !="")  || (expamt2Val != "" && expdes2Val =="") ){
    err += "<li>Please enter Amt and description for expense entry 2 .</li>";
  }

  if (matterVal == "" && contactVal == "") {
    err += "<li>Please select either a Matter or Contact.</li>";
  }
  if (durVal == "") {
    if((start_val != "00:00 PM" || end_val != "00:00 PM") && difference <= 0 ){
      err +="<li>End time should be greater than Start time</li>";
    }
    err += "<li>Duration can't be blank.</li>";
  }
  if (durVal <=0 || durVal > 24) {
    err += "<li> Please enter duration between 0.01 to 24.00</li>";
  }
  if (descVal == "") {
    err += "<li>Description can't be blank.</li>";
  }
  if (rateVal == "") {
    err += "<li>Rate can't be blank.</li>";
  }
  if (rateVal <= 0 || rateVal >=10000 ) {
    err += "<li>Rate should be between 0.01 and 9999.99</li>";
  }

  if (err != "") {
    jQuery("#errors_div_for_tne_facebox").html("<ul>" + err + "</ul>");
    jQuery("#errors_div_for_tne_facebox").show();
    jQuery('#loader').hide();
    disableWithPleaseWait(button_id, false, 'Save');
    return false;
  }
  return true;
}

// Is Beign Used
function check_estimate(){
  showLoadingGif();
  if(jQuery('#lvalue').val()==''){
    alert('Category cannot be blank');
    return false;
  }
}

function checkfile(div_name){
  if(jQuery(div_name).val()==''){
    alert('Please select a file to supersede.');
    return false;
  }else if (jQuery('#document_home_data').val() == ''){
    show_error_msg('matter_toe_error','Please select a document to upload.','message_error_div');
    jQuery('#loader').hide();
    return false;
  }else{
    return true;
  }
}

function checkfilename(){ 
  if(jQuery('#document_home_document_attributes_data').val() == ''){
    show_error_msg('matter_toe_error','Please select a document to upload.','message_error_div');
    jQuery('#loader').hide();
    return false;
  }else if(jQuery('#document_home_document_attributes_name').val()==''){
    show_error_msg('matter_toe_error','Document name can not be blank.','message_error_div');
    jQuery('#loader').hide();
    return false;
  }else{
    return true;
  }
}

function insertToDo( e, id ){
  if(e.checked){
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

function addNewRecord(emp_id) {
  loader.appendTo('#loader');
  var i = getIndex();
  new jQuery.get('/communications/add_new_record', {
    'index' : i,
    'emp_id': emp_id
  },
  function(data, status) {
    loader.remove();
    try {
      var d = document.createElement("div");
      d.setAttribute("id", i);
      d.innerHTML = data;
      var newd = document.getElementById("new_columnDIV");
      newd.appendChild(d);
      SearchAutocomplete();
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

// Not Being used
function show_selected_opportunity( obj, stage, current_stage ){
  jQuery('#'+obj).addClass("ui-tabs-selected");
  jQuery.ajax({
    type: 'GET',
    url: '/opportunities/manage_opportunities',
    data: {
      'stage' : stage,
      'current_stage' : current_stage
    },
    success: function(transport){}
  });
}

function Change_to_favourites( fav_type, atag, flag){
  jQuery("ul.tabSlider > li").removeClass("ui-tabs-selected");
  var add_fav_form = jQuery('a.add_fav_form')
  var title;
  if (fav_type == 'RSSFeed'){
    jQuery('#rssfeed').addClass("ui-tabs-selected");
    title = 'Add to '+jQuery('#rssfeed a').text()
    if(add_fav_form.css('display','none')){
      add_fav_form.show();
    }
  }
  if (fav_type == 'External'){
    jQuery('#external').addClass("ui-tabs-selected");
    title = 'Add to '+ jQuery('#external a').text()
    if(add_fav_form.css('display','none')){
      add_fav_form.show();
    }
  }
  if (fav_type == 'Internal'){
    jQuery('#internal').addClass("ui-tabs-selected");    
    add_fav_form.hide();
  }
  add_fav_form.attr('title', title);
  add_fav_form.attr('name', title);
  if(flag!='add'){
    loader.appendTo("#loader_container");
  }
  jQuery.ajax({
    type: 'GET',
    url: '/physical/clientservices/show_favourites',
    data:{
      'fav_type' : fav_type
    },         
    success: function(transport){            
      if (fav_type == 'RSSFeed'){        
        jQuery('#Tab0').show();
        jQuery('#Tab1').hide();
        jQuery('#Tab2').hide();
        jQuery('#Tab0').html(transport);
        tb_init('#Tab0 a.thickbox');                
      }
      if (fav_type == 'External'){        
        jQuery('#Tab1').show();
        jQuery('#Tab0').hide();
        jQuery('#Tab2').hide();
        jQuery('#Tab1').html(transport);               
      }
      if (fav_type == 'Internal'){        
        jQuery('#Tab2').show();
        jQuery('#Tab0').hide();
        jQuery('#Tab1').hide();
        jQuery('#Tab2').html(transport);                
      }
    },
    complete: function(){
      loader.remove();
    }
  });
  return false;
}

function delete_favourite( id, fav_type ) {
  var answer = confirm("Are you sure you want to Delete this Favorite?")
  if (answer){    
    jQuery.ajax({
      type: 'post',
      url: '/physical/clientservices/delete_favourite',
      data: {
        'id' : id,
        'fav_type'  :   fav_type
      },            
      success: function(transport){
        if (fav_type == 'RSSFeed'){          
          jQuery('#Tab0').show();
          jQuery('#Tab1').hide();
          jQuery('#Tab2').hide();
          jQuery('#Tab0').html(transport);
          tb_init('#Tab0 a.thickbox');
        }
        if (fav_type == 'External'){          
          jQuery('#Tab1').show();
          jQuery('#Tab0').hide();
          jQuery('#Tab2').hide();
          jQuery('#Tab1').html(transport);
        }
        if (fav_type == 'Internal'){          
          jQuery('#Tab2').show();
          jQuery('#Tab0').hide();
          jQuery('#Tab1').hide();
          jQuery('#Tab2').html(transport);
        }
        loader.remove();
      }
    });
  }
  return false;
}

function edit_favourite( id ){
  jQuery.ajax({
    type: 'post',
    url: '/physical/clientservices/edit_favourite',
    data: {
      'id' : id
    }
  });
}

function searchLawyer() {
  var lawyer_val = jQuery("#lawyer_search_query").val();
  if(lawyer_val=="Search"){ }else {
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

function searchInContact( act, my ) {
  var contact_val = jQuery("#contact_sphinx_search").val();
  contact_val = fixAmpersand(contact_val);
  jQuery("#contact_sphinx_search").val(contact_val);
  var mode_type_value = jQuery("input[name='myallradio']:checked").val().toUpperCase();
  jQuery.ajax({
    type: 'GET',
    url: '/contacts/display_selected_contact',
    data: {
      'q' : contact_val,
      'act' : act,
      'type' : my ? 'my' : 'all',
      status : window.location.href.search(/inactive/) == -1 ? 'active' : 'deactive',
      'mode_type' : mode_type_value
    },
    success: function(transport) {
      jQuery('#contacts').html(transport);
      jQuery('#pagin').hide();
      new_tool_tip();
    }
  });
  return false;
}

function fixAmpersand(str){
  str = str.replace(/&amp;/g, "&");
  return str;
}

function searchInOpportunity( act, my ) {
  var oppor_val = jQuery("#opportunity_sphinx_search").val();
  oppor_val = fixAmpersand(oppor_val);
  jQuery("#opportunity_sphinx_search").val(oppor_val);
  var mode_type_value = jQuery("input[name='myallradio']:checked").val().toUpperCase();
  jQuery.ajax({
    type: 'GET',
    url: '/opportunities/display_selected_opportunity',
    data: {
      'q' : oppor_val,
      'act' : act,
      'type' : my ? 'my' : 'all',
      'mode_type' : mode_type_value
    },
    success: function(transport) {
      jQuery('#searched_opportunities').html(transport);
      new_tool_tip();
      LiviaTooltipAP();
    }
  });
  return false;
}

function searchInMatter(act, my) {
  var val = jQuery("#matter_sphinx_search").val();
  val = fixAmpersand(val);
  jQuery("#matter_sphinx_search").val(val);
  var matter_status = jQuery("#matter_status").val();
  var mode_type = jQuery("input[name='myallradio']:checked").val().toUpperCase();
  jQuery.ajax({
    type: 'GET',
    url: '/matters/display_selected_matter',
    data: {
      'q' : val,
      'act' : act,
      'type' : my ? 'my' : 'all',
      'matter_status' : matter_status,
      'mode_type' : mode_type
    },
    success: function(transport) {
      jQuery('#matters_div').html(transport);
      new_tool_tip();
      LiviaTooltipAP();
      tb_init('a.thickbox');
    }
  });
  return false;
}

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

function searchInCampaign() {
  var camp_val = jQuery("#campaign_sphinx_search").val();
  camp_val = fixAmpersand(camp_val);
  jQuery("#campaign_sphinx_search").val(camp_val);
  var  mode_type_value = jQuery("input[name='myallradio']:checked").val().toUpperCase();
  var stage_id=jQuery("#stage").val()
  jQuery.ajax({
    type: 'GET',
    url: '/campaigns/display_selected_campaign',
    data: {
      'q' : camp_val,
      'mode_type' : mode_type_value,
      'stage' : stage_id
    },
    success: function(transport) {
      jQuery('#searched_campaigns').html(transport);
      new_tool_tip();
      LiviaTooltipAP();
    }
  });
  return false;
}

function searchInAccount( my ) {
  var account_val = jQuery("#account_sphinx_search").val();
  account_val = fixAmpersand(account_val);
  jQuery("#account_sphinx_search").val(account_val);
  var  mode_type_value = jQuery("input[name='myallradio']:checked").val().toUpperCase();
  jQuery.ajax({
    type: 'GET',
    url: '/accounts/display_selected_account',
    data: {
      'q' : account_val,
      'type' : my ? 'my' : 'all',
      'mode_type' : mode_type_value
    },
    success: function(transport) {            
      jQuery('#searched_accounts').html(transport);      
      new_tool_tip();
      LiviaTooltipAP();
    }
  });
  return false;
}

function secrataryDetails( id ) {
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

function Get_children( dir ) {
  jQuery.ajax({
    type: 'GET',
    url: "/workspaces/get_children",
    data: {
      'dir': dir
    },
    success: function() {
      jQuery("#fileTree").fileTree({
        script: '/workspaces/get_children?update_list=true',
        loadMessage:'Loading...',
        expandSpeed: 750,
        collapseSpeed: 750,
        expandEasing: 'easeOutBounce',
        collapseEasing: 'easeOutBounce'
      });
    }
  });
  return false;
}

function GetFoldersList( folder_id, update_list, link, recyclebin, link_id ) {
  loader.prependTo("#"+link_id);
  jQuery.ajax({
    type: 'GET',
    url: "/workspaces/folder_list",
    data: {
      'parent_id': folder_id,
      'recycle_bin':recyclebin
    },
    success: function(transport) {
      jQuery("#document_home_folder_id").val(folder_id);
      if(update_list != "false")
        jQuery("#browser").html(transport);
      loader.remove();
      jQuery('#root').removeClass('selected');
      toggle_plus_minus(link);
      LiviaTooltipAP();
    }
  });
  return false;
}

function GetFoldersListRepository( folder_id, update_list, link, recyclebin, link_id, category) {
  loader.prependTo("#"+link_id);
  jQuery.ajax({
    type: 'GET',
    url: "/repositories/folder_list",
    data: {
      'parent_id': folder_id,
      'recycle_bin':recyclebin,
      'category' : category
    },
    success: function(transport) {
      jQuery("#document_home_folder_id").val(folder_id);
      if(update_list!="false"){
        jQuery("#searchresults_DIV").html(transport);
      }
      loader.remove();
      jQuery('#root').removeClass('selected');
      toggle_plus_minus(link);
      LiviaTooltipAP();
    }
  });
  return false;
}

function GetFoldersListMatter( folder_id, update_list, link, matter_id ) {
  jQuery.ajax({
    type: 'GET',
    url: "/matters/"+matter_id+"/document_homes/folder_list",
    data: {
      'parent_id': folder_id
    },
    success: function(transport) {
      jQuery("#document_home_folder_id").val(folder_id);
      if(update_list !='false'){
        jQuery("#browser").html(transport);
      }
      toggle_plus_minus(link);
      LiviaTooltipAP();
    }
  });
  return false;
}

function search_display_none(){
  jQuery("#column_left_accordion").hide();
  jQuery("#column_right_tabs").css({
    "width" : "100%"
  });
}

function confirm_access( folder_id, access ){
  var answer = confirm("Change will be applied to the subfolders also.Are you sure ?")
  if (answer){
    change_livian_access(folder_id,access);
  }
  return false;
}

function change_livian_access( folder_id, access ) {
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

function update_taskdiv( new_date ) {
  var location;
  loader.appendTo("#task_type_DIV");
  location = "/matter_clients/get_tasks_by_date";
  jQuery.get(location, {
    'new_date': new_date
  },
  function(data) {
    jQuery("#task_type_DIV").html(data);
  });
  return false;
}

function secrataryUnassign( id, sect, loc ) {
  var location;
  if(loc=="notes"){
    location = "/physical/liviaservices/secratary_details_notes_list";
  }else{
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
      }else if (loc=="task")  {
        jQuery("#show_details_list_DIV").html(transport);
      }else{
        jQuery("#secratary_details_task_list_DIV").html(transport);
      }
    }
  });
  return false;
}

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

jQuery.fn.submitWithAjax_with_file = function(){
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

jQuery(document).ready(function() {
  jQuery("#searchform").submitWithAjax();
});

var monthNames = [
"January", "February","March","April","May","June","July","August","September", "October", "November","December"
];

function localTime(date, id) {
  try{
    var lzone = new Date().getTimezoneOffset();
    var tmp = new Date(date);
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
  }
  catch(e){
    alert(e.message);
  }
  if (id) document.getElementById(id).innerHTML = s;
  return s;
}

function pickSkillsForLilly(id) {
  try {
    loader.appendTo("#skills_spinner");
    jQuery.get("/physical/liviaservices/liviaservices/pick_skills_for_lilly",{
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

function getMyAllMatters( mode_type, matter_status, letter, perpage ){
  if (perpage==''){
    perpage=25
  }
  window.location = "/matters?mode_type=" + mode_type + "&matter_status=" + matter_status+"&per_page="+perpage+"&letter="+letter;
}

function getMyAllMatterTasks(mid, mode_type, matter_status, cat ,letter,page){
  if(cat=='true'){
    window.location = "/matters/" + mid + "/matter_tasks?mode_type=" + mode_type+"&cat=appointment"+ ((typeof letter != "undefined" && letter.length > 0)  ? "&letter="+letter : "")+((typeof page != "undefined" && page.length > 0)  ? "&per_page="+page : "") ;
  }else{ 
    window.location = "/matters/" + mid + "/matter_tasks?mode_type=" + mode_type+ ((typeof letter!= "undefined" && letter.length > 0) ? "&letter="+letter : "")+((typeof page != "undefined" && page.length > 0)  ? "&per_page="+page : "");
  }
}

function getMyAllCampaigns(type) {
  jQuery.get("/campaigns/get_my_all_campaigns",{
    "type":type
  },
  function(data) {
    jQuery("#searched_campaigns").html(data);
  });
}

function selectCampaign(parent_id) {
  jQuery.get('/campaigns/search_campaign', {
    "parent_id":parent_id
  },
  function(data) {
    jQuery("#new_form").html(data);
    jQuery("select#campaign_parent_id").children('option[value='+parent_id+']').attr("selected", "selected");
  });
}
// Not Being Used
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
  if(i > 0){
    jQuery("#court_selector").html(
      "Create New or (<a href='#' onclick='selectCourt(); return false;'>Select Existing</a>)");
  }else{}
  
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

function closeFaceBox() {
  if  (jQuery.facebox){
    jQuery.facebox.close();
  }
}

function initLiviaHint(){
  jQuery('input[title!=""]').hint();
}

function getContactsAll(type,letter,perpage,contact_type) {
  if (perpage==''){
    perpage=25
  }
  document.location.href = "/contacts?mode_type="+type+"&letter="+letter+"&per_page="+perpage+"&contact_type="+contact_type;
}

function getaccounts(type,letter,perpage) {
  if (perpage==''){
    perpage=25
  }
  document.location.href = "/accounts?mode_type="+type+"&letter="+letter+"&per_page="+perpage;
}

function initToggle() {    
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

jQuery("#instruction_toggle").click(function(){
    jQuery("#instructions_DIV").toggle();
    jQuery(".toggle_instruction").toggle();
  });

  jQuery("#searchdashboard_toggle").click(function(){
    jQuery("#search_DIV").toggle();
    jQuery(".toggle_searchdashboard").toggle();
  });

  jQuery("#clientopenmattersDiv").click(function(){
    jQuery("#openclientopenmattersDiv").toggle();
    jQuery(".toggle_openmatters").toggle();
  });
  jQuery("#clientcompletedmatterDIV").click(function(){
    jQuery("#openclientcompletedmatterDIV").toggle();
    jQuery(".toggle_completedmatters").toggle();
  });

  jQuery("#searchbutton").click(function(){
    jQuery("#search_results").show();
  });
}

function initAutoComplete(){
  jQuery("#contact_sphinx_search").autocomplete(
    "/contacts/search_contacts", {
      width: 'auto',
      extraParams:{
        status: function(){
          return window.location.href.search(/inactive/) == -1 ? 'active' : 'deactive'
        }
      },
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();


  jQuery("#contact_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInContact('false', 'index');
  });
  jQuery("#contact_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInContact('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#account_sphinx_search").autocomplete(
    "/accounts/search_account", {
      width: 'auto',
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();
  jQuery("#account_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInAccount('false', 'index');
  });
  jQuery("#account_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInAccount('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#campaign_sphinx_search").autocomplete(
    "/campaigns/sphinx_search_campaign?", {
      width: 'auto',
      formatResult: function(data, value) {
        return value.split(",")[0];
      },
      extraParams : {
        stage:jQuery('#stage').val()
      }
    }).flushCache();
  jQuery("#campaign_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInCampaign('false', 'index');
  });
  jQuery("#campaign_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInCampaign('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#opportunity_sphinx_search").autocomplete(
    "/opportunities/search_opportunity", {
      width: 'auto',
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();
    
  jQuery("#opportunity_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInOpportunity('false', 'index');
  });

  jQuery("#opportunity_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInOpportunity('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#matter_sphinx_search").autocomplete(
    "/matters/search_matter", {
      width: 'auto',
      extraParams: {
        mode_type: jQuery("input[name='myallradio']:checked").val(),
        matter_status: function() {
          return jQuery("#matter_status").val();
        }
      },
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();
  jQuery("#matter_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInMatter('false', 'index');
  });
  jQuery("#matter_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInMatter('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#search_string").keypress(function(e){
    if(e.which == 13){
      searchInCommon();
      return jQuery(".ac_results").fadeOut();
    }
  });

  // Need to check if used on lawyers login
  jQuery("#lawyer_search_query").keypress(function(e){
    if(e.which == 13){
      searchLawyer();
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#invoice_sphinx_search").autocomplete(
    "/tne_invoices/search_invoice", {
      extraParams: {
        width: 'auto',
        status : (jQuery('#status').val()=='All'? "" : jQuery('#status').val() ),
        type: function() {
          return jQuery('#client_radio').attr("checked") ? "client" : "";
        }
      },
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();

  jQuery("#invoice_sphinx_search").result(function(event, data, formatted) {
    jQuery(this).parent().next().find("input").val(data[0]);
    searchInInvoice('false', 'index');
  });

  jQuery("#invoice_sphinx_search").keypress(function(e){
    if(e.which == 13){
      searchInInvoice('false', 'index');
      return jQuery(".ac_results").fadeOut();
    }
  });

  jQuery("#comm_matter_sphinx_search").autocomplete(
    "/communications/get_matter_details", {
      width: 'auto',      
      formatResult: function(data, value) {
        return value.split(",")[0];
      }
    }).flushCache();
}

function searchInInvoice(act, client) {
  var invoice_val = jQuery("#invoice_sphinx_search").val();
  invoice_val = fixAmpersand(invoice_val);
  var status=(jQuery('#status').val()=='All'? "" : jQuery('#status').val() );
  jQuery("#invoice_sphinx_search").val(invoice_val);
  var client_radio = jQuery("#client_radio").attr("checked")
  jQuery.ajax({
    type: 'GET',
    url: '/tne_invoices/search_invoice',
    data: {
      'q' : invoice_val,
      'act' : act,
      'display' : true,
      'type' : client_radio ? 'client' : 'matter',
      'status' : status
    },
    success: function(transport) {
      jQuery('#'+(client_radio ? 'client_radio' : 'matter_radio')).checked = true;
      jQuery('#searched_invoices').html(transport);
    }
  });
  return false;
}

// This method will show the available campaign for the perticular source,
// This method is modified to bar unnecessary ajax request
function show_campaign_combo(){
  jQuery("#spinnerDefault").html(loader);
  var msg=jQuery('#source_combo option:selected').val();
  if(parseInt(msg)>0 && jQuery('#source_combo option:selected').text()=='Campaign'){
    jQuery.ajax({
      type: "GET",
      url: "/opportunities/get_company_source_name",
      data: {
        'source' : msg
      },
      success: function(transport){
        show_hide_campaign_combo('show');
        loader.remove();
      }
    });
  }else{
    show_hide_campaign_combo('hide');
    loader.remove();
  }
}

//this function will show/hide the campaign combo box
function show_hide_campaign_combo(to_do){
  if (to_do=='hide'){
    jQuery('#campaign_combo').hide();
    jQuery('#campaign_combo1').hide();
  }else{
    jQuery('#campaign_combo').show();
    jQuery('#campaign_combo1').show();
  }
}

function copy_address(bln){   
  var street=bln ? (jQuery('#account_billingaddresses_attributes_0_street').val()) : "";
  var city=bln ? (jQuery('#account_billingaddresses_attributes_0_city').val()) : "";
  var state=bln ? (jQuery('#account_billingaddresses_attributes_0_state').val()) : "";
  var zipcode=bln ? (jQuery('#account_billingaddresses_attributes_0_zipcode').val()) : "";
  var country=bln ? (jQuery('#account_billingaddresses_attributes_0_country').val()) : "";
  jQuery('#account_shippingaddresses_attributes_0_street').val(street);
  jQuery('#account_shippingaddresses_attributes_0_city').val(city);
  jQuery('#account_shippingaddresses_attributes_0_state').val(state);
  jQuery('#account_shippingaddresses_attributes_0_zipcode').val(zipcode);
  jQuery('#account_shippingaddresses_attributes_0_country').val(country);
}

/* Show/hide a select role popup, when lead lawyer for matter is not the
 * current lawyer. Used on matter new/edit view. */
function roleInMatter(new_id, lead_id) {
  if(new_id != lead_id){
    jQuery("#role").fadeIn("slow");
    jQuery("#role_given").val("true");
  }else{
    jQuery("#role").fadeOut("slow");
    jQuery("#role_given").val("false");
  }
}

this.imagePreview= function(){
  /* CONFIG */
  var xOffset = 10;
  var yOffset = 30;
  // these 2 variable determine popup's distance from the cursor
  // you might want to adjust to get the right result
  /* END CONFIG */
  jQuery("a.preview").hover(function(e){
    this.t = this.title;
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

function validate_search_date(){    
  if (jQuery('#search_date').is(':checked')){
    start_date = jQuery("input#search_from_date").val();
    end_date = jQuery("input#search_to_date").val();
    if(start_date != "" && end_date != ""){
      if (Date.parse(start_date) > Date.parse(end_date)){
        alert("End Date should be greater than Start Date");
        return false;
      }
    }else{
      alert("Please Specify Both the dates")
      return false;
    }
  }else{
    jQuery("input#datepicker_date_start").val('');
    jQuery("input#datepicker_date_end").val('');
  }
  return true;
}

jQuery(function(){
  jQuery('.cancelbutton').click(function(){
    history.back();
    return false;
  });
})

//This function validates start date and end date for dashboards :sania wagle
function validate_date_dashboards(){
  if (jQuery('#duration').val() == '5'){
    var start_date;
    if(typeof(jQuery("input#from_date")!= 'undefined')){
      start_date = jQuery("input#from_date").val();
    }else{
      start_date = jQuery("input#created_date").val();
    }
    var end_date = jQuery("input#to_date").val();
    if(start_date != "" && end_date != ""){
      if (Date.parse(start_date) > Date.parse(end_date)){
        alert("End Date should be greater than Start Date");
        return false;
      }
    }else{
      alert("Please Specify Both the dates")
      return false;
    }
  }else{
    jQuery("input#parameters_0").val('');
    jQuery("input#parameters_1").val('');
  }
  return true;
}

function show_report(){
  document.location.href = "/rpt_contacts/current_contact";
}

function show_dashboard(){
  document.location.href = "/dashboards/all_category";
}

function show_all_dashboard(){
  document.location.href = "/dashboards/all_category";
}

function db_date_change(){
  jQuery('#duration').change(function(){
    jQuery('#date_div');
    if (jQuery(this).val() == '5'){
      jQuery("#date_checked").attr("checked", "checked");
      jQuery('#date_div').show();
    }else{
      jQuery('#date_div').hide();
    }
  });
}

function validate_checkbox(){
  var len=jQuery("input.val_check:checked").length
  if (len > 3){
    alert("You cannot select more than three Dashboards");
    return false
  }else{
    jQuery('#Save').attr("disabled",true)
    jQuery('#Save').val("Please wait...")
    jQuery('#save_dashbrd').attr("disabled",true)
    jQuery('#save_dashbrd').val("Please wait...")
    return true;
  }
}

function validate_checkbox_onclick(class_name,id){
  var len=jQuery("input.val_check:checked").length
  if (len > 3){
    alert("You cannot select more than three Dashboards");
    jQuery("#"+class_name).attr('checked',false)
  }
  if (jQuery("#"+class_name).is(':checked')){
    jQuery("#md_val_check"+id).attr('checked',true);
  }else{
    jQuery("#md_val_check"+id).removeAttr('checked');
  }
}

function check_uncheck_dashboard(id){
  if (jQuery("#md_val_check"+id).is(':checked')){
    jQuery("#op_val_check"+id).attr('checked',true);
    jQuery("#rv_val_check"+id).attr('checked',true);
    jQuery("#cs_val_check"+id).attr('checked',true);
    jQuery("#ot_val_check"+id).attr('checked',true);
    var len=jQuery("input.val_check:checked").length
    if (len > 3){
      alert("You cannot select more than three Dashboards");
      jQuery("#op_val_check"+id).attr('checked',false);
      jQuery("#rv_val_check"+id).attr('checked',false);
      jQuery("#cs_val_check"+id).attr('checked',false);
      jQuery("#ot_val_check"+id).attr('checked',false);
      jQuery("#md_val_check"+id).attr('checked',false);
    }
  }else{
    jQuery("#op_val_check"+id).attr('checked',false);
    jQuery("#rv_val_check"+id).attr('checked',false);
    jQuery("#cs_val_check"+id).attr('checked',false);
    jQuery("#ot_val_check"+id).attr('checked',false);
  }
}

jQuery(document).ready(function(){
  imagePreview();
  initToggle();  
  closeFaceBox();
});

/* This function grants/removes access to matter people from index page of matter people */
function matterPeopleAccessCheckbox(url, id, haveAccessText, notHaveAccessText){
  var val = jQuery("#access_given_to_mem_" + id).val();
  jQuery("#period_span_" + id).html("");
  loader2.appendTo("#period_span_" + id);
  jQuery.post(
    url,{
      "grant_access" : val == "false"
    },
    function(data) {
      jQuery("#period_span_" + id).html(data);
      if (val == "false") {
        jQuery("#access_link_span_" + id).text(haveAccessText);
        jQuery("#access_given_to_mem_" + id).val("true");
      } else {
        jQuery("#access_link_span_" + id).text(notHaveAccessText);
        jQuery("#access_given_to_mem_" + id).val("false");
      }
    });
}

function populateproducts( id, comp_id ){
  if (id==""){
    jQuery('#productdiv').html("");
    return false
  }
  loader.prependTo("#productdiv");
  jQuery.ajax({
    type: "GET",
    url: "/roles/"+id,
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

// id for company
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

function populateuserfields(elm){
  if (elm.checked) {
    jQuery("#userformfield").show();
  } else {
    jQuery("#userformfield").hide();
  }
}

function get_company_licence_by_product(product_id, company_id, user_id){
  if(product_id==""){
    loader.remove();
    jQuery("#div_product_licences").css('display','none');
    jQuery("#div_submit").css('display','none');
    return false
  }
  loader.prependTo("#span_product");
  jQuery.post(
    "/roles/show_licences",{
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

// id for company
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
  }else{
    jQuery("#company_shipping_address_attributes_0_street").val('');
    jQuery("#company_shipping_address_attributes_0_city").val('');
    jQuery("#company_shipping_address_attributes_0_zipcode").val('');
    jQuery("#company_shipping_address_attributes_0_country").val('');
    jQuery("#company_shipping_address_attributes_0_state").val('');
  }
}

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

function list_company_utility(id){
  type = jQuery('#hidden_utility_type').val();
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
    }
  });
}

// This function is to call the "show_company_list" function in manage_secretary controller by passing the required parameters which is used to get the required data for company dropdown in Manage Secretary Module for Admin login
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

// This function is to call the "show_employee_list" function in manage_secretary controller by passing the required parameters which is used to get the required data for employee dropdown in Manage Secretary Module for Admin login
function show_employee_list(company_id, secretary_id){
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

//This function is to call the "unassign_sec_to_emp" function in manage_secretary controller by passing the required parameters
function unassign_sec_to_emp(secretary_id, lawyer_id){
  loader.prependTo("#show_employee_list")

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

//This function is to call the "assign_sec_to_emp" function in manage_secretary controller by passing the required parameters
function assign_sec_to_emp(secretary_id){
  if (jQuery("#employee_id").val() == "") {
    alert("Please select a Lawyer first.");
    return;
  }
  jQuery.ajax({
    type: "POST",
    url: "/manage_secretary/assign_sec_to_emp",
    dataType: 'script',
    data: {
      'secretary_id' : secretary_id,
      'lawyer_id' : jQuery("#employee_id").val()
    }
  });
}

function show_product_pricing(product_id){
  if (product_id==""){
    jQuery("#div_product_pricing").css('display','none');
    jQuery("#div_submit").css('display','none');
    return false
  }
  loader.prependTo("#div_prd_price");
  jQuery.post(
    "/product_licences/product_pricing",{
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

// removed duplicate from admin application.js
function validate_dashboard_name(){
  var dashname=jQuery('#favorite_title').val();
  if (dashname == ""){
    jQuery('#nameerror').html("<div class='message_error_div'>Please specify Dashboard name</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow')
    loader.remove();
    jQuery('#nameerror').show();
    return false;
  }else{
    return true;
  }
}

// checked
function validate_name_fav(){
  var name=jQuery('#fav_name').val();
  var txturl=jQuery('#fav_url');
  txturl.val(window.location);
  if(name == ""){
    jQuery('#fav_nameerror')
    .html("<div class='message_error_div'>Please specify name for favorite</div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow')
    loader.remove();
    return false;
  }else{
    return true;
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
// checked
function validate_favourite_url(){
  loader.appendTo('#fav_loader_container');
  var name=jQuery('#name').val();
  var type=jQuery('#fav_type').val();
  var url=jQuery('#url').val();
  var regexp = /[a-z0-9]{3}.[a-z0-9]*.(com|org|net|xml|html|aspx)/i;
  var err=''
  if (name==''){
    err='Please specify Name<br>'
  }
  if (url==''){
    err+='Please specify URL'
  }
  if(type=='External'){   
    if (!regexp.test(url)){
      if(url!=''){
        err+='<br/>'
        err+='Please Enter Valid URL'
      }
    }
  }
  if (err!='') {
    jQuery('#nameerror')
    .html("<div class='message_error_div'> "+err+" </div>")
    .fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow')
    loader.remove();
    jQuery('#save').attr('disabled',false)
    jQuery('#save').val('Save')
    return false;
  }else{
    return true
  }
}

function show_msg(div_id,msg){
  jQuery('#'+div_id).html(msg);
  jQuery('#'+div_id).show();
}

function filterContact(mode,contact_type, perpage, letter){
  if(perpage == ""){
    if(contact_type =='All'){
      document.location.href = "/contacts?mode_type="+mode+"&letter="+letter;
    } else{
      document.location.href = "/contacts?mode_type="+mode+"&contact_type="+contact_type+"&letter="+letter;
    }
  }else{
    if(contact_type =='All'){
      document.location.href = "/contacts?mode_type="+mode+"&per_page="+perpage+"&letter="+letter;
    } else{
      document.location.href = "/contacts?mode_type="+mode+"&contact_type="+contact_type+"&per_page="+perpage+"&letter="+letter;
    }
  }
}

function filterCategory(category_type,folder_id){
  if(folder_id == ""){
    if(category_type =='All'){
      document.location.href = "/repositories";
    } else{
      document.location.href = "/repositories?category_type="+category_type;
    }
  }else{
    if(category_type =='All'){
      document.location.href = "/repositories?parent_id="+folder_id;
    } else{
      document.location.href = "/repositories?category_type="+category_type+"&parent_id="+folder_id;
    }
  }
}

function filterOpportunity(mode,opp_stage){
  if(opp_stage == ""){
    document.location.href = "/opportunities?mode_type="+mode
  } else{
    document.location.href = "/opportunities?mode_type="+mode+"&opp_stage="+opp_stage;
  }
}

// Stage fiter on manage campaign - Ketki 4/5/2011
function filterManageCampaign(mode,camp_stage){
  if(camp_stage == ""){
    document.location.href = "/campaigns?mode_type="+mode;
  } else{
    document.location.href = "/campaigns?mode_type="+mode+"&stage="+camp_stage;
  }
}

function matter_status(mode,matter_status){
  document.location.href = "/matters?matter_status="+matter_status+"&mode_type="+mode;
}

function account_matter_status(account_id,status,modetype){
  loader.prependTo('#update_table')
  jQuery.ajax({
    type: 'GET',
    url: "/accounts/"+ account_id +"/matters_linked_to_account",
    data: {
      'matter_status' : status ,
      'mode_type': modetype
    },
    success: function(transport){
      jQuery("#update_table").html(transport);
      loader.remove();
    }
  });
}

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
      loader.remove();
      jQuery(div_id).hide();
    },
    complete: function(){
      window.location.reload();
    }
  });
}

function clear_follow_up_date_home(id){
  var div_id = "#follow_up_date_" + id;
  if(id==""){
    return false
  }   
  loader2.prependTo('#loader1_' + id)
  jQuery.ajax({
    type: "POST",
    url: "/opportunities/clear_follow_up_date",
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(transport){
      loader.remove();
      jQuery(div_id).hide();
      window.location.reload()
    },
    complete: function(){ }
  });
}

function showlookupvalues(type){
  if(type==""){
    return false
  }
  loader.prependTo("#lookupdiv");
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

function livia_datepicker(field){     
  jQuery(function(){
    var today=today_date();
    jQuery(".date_picker").datepicker({
      showOn: 'both',
      dateFormat: 'mm/dd/yy',
      changeMonth: true,
      changeYear: true
    });
  });
}

//this date picker function provides the month and year for selection
//Created by R.Ganesh dt.29042011
function livia_datepicker_monthYear(field){
  jQuery(function() {
    var today=today_date();
    jQuery(field).datepicker({
      showOn: 'both',
      dateFormat: 'mm/dd/yy',
      changeMonth: true,
      changeYear: true,
      yearRange: (today.getFullYear()-90)+':'+(today.getFullYear()),
      maxDate: today,      
      onSelect: function(value,date){
        var newdate=new Date(value);
      }
    });
  });
}

function expenseDatePicker(timenow){
  var previousDatePicker=null;
  var previousDate=null;
  jQuery('.expense_date_picker').datepicker({
    showOn: 'both',
    dateFormat: 'mm/dd/yy',
    changeMonth: true,
    changeYear: true,
    beforeShow: function(input, inst) {
      previousDatePicker = input;
      previousDate = input.value;
    },
    onSelect: function(value,date){
      var today = new Date(timenow);
      var newdate = new Date(value);
      if(newdate > today){
        var date_confirm = confirm('Details being entered are for a future date. Click OK to proceed.');
        if(date_confirm){         
          updateMatters(value,date);
        }else{
          previousDate = new Date(previousDate);
          if(previousDate > today){
            previousDate = today;
          }
          jQuery(previousDatePicker).val((previousDate.getMonth()+1)+'/'+previousDate.getDate()+'/'+previousDate.getFullYear());
          return;
        }
      }else{
        updateMatters(value,date);
        date.value = ((newdate.getMonth()+1)+'/'+newdate.getDate()+'/'+newdate.getFullYear());
      }
    }
  });
}

function updateMatters(value,date){
  if(jQuery('#expense_entry_page').length > 0){
    var entry_id = date.id.split('_')[0];
    jQuery('.'+entry_id +'_drop_down').css('display', 'none');
    jQuery.ajax({
      beforeSend: function(){
        jQuery('body').css("cursor", "wait");
      },
      type: 'GET',
      url: '/physical/timeandexpenses/unexpired_matters',
      data: {
        type : 'expense',
        time_entry_date : value,
        expense_div_id  :entry_id
      },
      async: true,
      dataType: 'script',
      complete: function(){
        jQuery('body').css("cursor", "default");
      },
      success: function(){
        jQuery('.'+entry_id +'_drop_down').css('display', '');
      }
    });
  }
}

function livia_datepicker_new(field){
  jQuery(function() {
    var today=today_date();
    jQuery(field).datepicker({
      showOn: 'both',
      dateFormat: 'mm/dd/yy',
      changeMonth: true,
      changeYear: true,
      maxDate: today,
      onSelect: function(value,date){
        var newdate=new Date(value);
        jQuery(field).val((newdate.getMonth()+1)+'/'+newdate.getDate()+'/'+newdate.getFullYear	());
      }
    });
  });
}

function livia_matter_inception_datepicker_new(field){
  jQuery(function() {
    var today=today_date();
    jQuery(field).datepicker({
      showOn: 'both',
      dateFormat: 'mm/dd/yy',
      changeMonth: true,
      changeYear: true,     
      onSelect: function(value,date){
        if (jQuery(this).attr("start_date")) {
          jQuery("input[end_date=true]").datepicker("option","minDate" , new Date(date.selectedYear,date.selectedMonth,date.selectedDay));
        }
        
        if ((field=="#datepicker_opportunity_follow_up" || field=="#datepicker_opportunity_follow_edit") && jQuery('#datepicker_opportunity_follow_up').val()!=""){
          jQuery('.opportunity_follow_up_time').show();
        }
        var check_matter=jQuery(this).attr('matter_date')
        if (check_matter=='start_date' || check_matter=='end_date'){
          validate_start_end_date_value(check_matter);
        }
      }
    });
  });
}

function validate_start_end_date_value(input){
  var enddate = new Date(jQuery("#date_end").val());
  var startdate = new Date(jQuery("#date_start").val());
  if(enddate != "" && startdate != ""){
    if(enddate < startdate){
      alert("End Date should be greater than Start Date");
      if (input=="end_date"){
        jQuery("#date_end").val("");
      }else{
        jQuery("#date_start").val("");
      }
    }
  }
}

function sort_table(order,matter_id,dir,people_type,action,sort_by,div_id,empty,index){
  if (empty == "true"){
    return false;
  }
  jQuery.ajax({
    type: "GET",
    url: "/matter_peoples/" + action,
    dataType: 'script',
    data: {
      'order' : order,
      'matter_id' : matter_id,
      'dir' : dir,
      'people_type' : people_type,
      'sort_by' : sort_by,
      'update_div' : div_id,
      'index' : index
    },
    beforeSend: function() {
      jQuery('#loader' + index).show()
    },
    complete: function(){
      jQuery('#loader' + index).hide()
    },
    success: function(){
      loader.remove();
    }
  });
}

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

function rename_fav(fav_id){
  jQuery('#rename_dash_board_favorite').show();
  jQuery.ajax({
    type: "GET",
    url: "/dashboards/title_change",
    dataType: 'script',
    data: {
      'id' : fav_id
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

function show_fav_div(){
  jQuery('#show_dash_board_favorite').show();
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
  jQuery('#save_rep').disabled=true
  jQuery('#save_rep').val('Please wait...')
}

function show_end_time(repeat,choose_end_time_id){    
  if(repeat.value!=""){
    if(repeat.id=='zimbra_activity_repeat' ){
      jQuery('#'+choose_end_time_id).show();
      jQuery('#mandatory_zimbra').show();
      return false
    }else{
      jQuery('#'+choose_end_time_id).show();
      jQuery('#mandatory_task').show();                    
    }        
  }else{
    if(repeat.id=='zimbra_activity_repeat' ){
      jQuery('#'+choose_end_time_id).hide();
      jQuery('#mandatory_zimbra').hide();
      return false
    }else{
      jQuery('#'+choose_end_time_id).hide();
      jQuery('#mandatory_task').hide();
    }
  }
}

//function add_sticky_note(note,counter) : removed
jQuery(function(){  
  jQuery("#revenue_enhancement_toggle").click(function () {
    jQuery("#revenue_enhancement").toggle("slow");
    jQuery(".revenue_enhancement").toggle();
  });
  jQuery("#cost_savings_toggle").click(function () {
    jQuery("#cost_savings").toggle("slow");
    jQuery(".cost_savings").toggle();
  });
  jQuery("#operational_efficiency_toggle").click(function () {
    jQuery("#operational_efficiency").toggle("slow");
    jQuery(".operational_efficiency").toggle();
  });
  jQuery("#customer_satisfaction_toggle").click(function () {
    jQuery("#customer_satisfaction").toggle("slow");
    jQuery(".customer_satisfaction").toggle();
  });
  jQuery("#others_toggle").click(function () {
    jQuery("#others_dashboards").toggle("slow");
    jQuery(".others_dashboards").toggle();
  });
  jQuery("#import_contact").hide();
  jQuery("#radio_add_contact").click(function(){
    jQuery('#add_contact').show();
    jQuery('#import_contact').hide();
  });
  jQuery("#import_util_contacts").click(function(){
    window.location.href= "/excel_imports/index?module_type=contact&from=utility"
  });
  jQuery("#radio_import_contact").click(function(){
    var campaign_id = jQuery(this).attr('campaign_id');
    window.location.href= "/excel_imports/index?module_type=campaign_member&campaign_id="+campaign_id
  });
  jQuery("#import_time").click(function(){
    window.location.href= "/excel_imports/index?module_type=time"
  });
  jQuery("#import_expense").click(function(){
    window.location.href= "/excel_imports/index?module_type=expense"
  });
  jQuery("#import_matter").click(function(){
    window.location.href= "/excel_imports?module_type=matter&from=utility"
  });


});

//surekha----done for checking file format in contacts import & campaigns
function check_file_format() {
  var fileformat = jQuery('#file_format').val();
  if(fileformat=="XLS"){
    jQuery("#xls").show();
    jQuery("#csv").hide();
  }else{
    jQuery("#csv").show();
    jQuery("#xls").hide();
  }
}

function download_formats(){
  var fileformat = jQuery('#file_format').val();
  var importEntity;
  if(jQuery('#import_contacts').attr('checked')){
    importEntity = jQuery('#import_contacts').val();
  }
  if(jQuery('#import_util_contacts').attr('checked')){
    importEntity = 'contacts'
  }
  if(jQuery('#import_time').attr('checked')){
    importEntity = jQuery('#import_time').val();  
  }
  if(jQuery('#import_expense').attr('checked')){
    importEntity = jQuery('#import_expense').val();  
  }
  if(jQuery('#import_matters').attr('checked')){
    importEntity = jQuery('#import_matters').val();
  }
  jQuery('#sample_format').html("<a href='/import_data/"+importEntity+"?f="+fileformat+"'>Download File Format ("+fileformat+")</a>");
}

/* added for thickbox title when it clashes with vtip - Supriya 19-06-2010 12:05 PM */
function add_missing_header_to_thickbox(title){    
  if(jQuery('#TB_ajaxWindowTitle').is(':empty')){
    jQuery('#TB_ajaxWindowTitle').append(title);
  }
}

function formatCurrency(num) {
  num = num.toString().replace(/\$|\,/g,'');
  if(isNaN(num))
    num = "0";
  var sign = (num == (num = Math.abs(num)));
  num = Math.floor(num*100+0.50000000001);
  var cents = num%100;
  num = Math.floor(num/100).toString();
  if(cents<10)
    cents = "0" + cents;
  for (var i = 0; i < Math.floor((num.length-(1+i))/3); i++)
    num = num.substring(0,num.length-(4*i+3))+','+
    num.substring(num.length-(4*i+3));
  return (((sign)?'':'-') +  num + '.' + cents);
}

//Categories drop down in Support-Surekha
function change_catgeories(val){
  if(val=="IT Error"){
    jQuery("#response_categories").html("<option value='Access Denied'>Access Denied</option><option value='Error 404'>Error 404</option><option value='Error 500'>Error 500</option><option value='Other'>Other</option>");
  }
  if(val=="Feedback"){
    jQuery("#response_categories").html("<option value='Livian'>Livian</option><option value='Access Speed'>Access Speed</option><option value='User Interface'>User Interface</option><option value='Functions'>Functions</option><option value='Other'>Other</option>");
  }
  if(val=="Improvement"){
    jQuery("#response_categories").html("<option value='User Interface'>User Interface</option><option value='Functions'>Functions</option><option value='Other'>Other</option>");
  }
  if(val=="New Business"){
    jQuery("#response_categories").html("<option value='Extra Licenses'>Extra Licenses</option><option value='New Account'>New Account</option><option value='Other'>Other</option>");
  }
  if(val=="Other"){
    jQuery("#response_categories").html("<option value='Other'>Other</option>");
  }
  return true;
}

function generate_report(fav_id, controller, action_name, title){
  jQuery.ajax({
    type: 'GET',
    url: '/' + controller + '/' + action_name,
    data: {
      'fav_id' : fav_id,
      'load_popup' : 'true',
      'format' : 'html'
    },
    beforeSend: function() {
      jQuery('#loader').show();
    },
    complete: function(){
    },
    success: function(html){
      jQuery('#TB_ajaxWindowTitle').text(title);
      jQuery('#TB_window').width(1090);
      jQuery('#TB_ajaxContent').width(1055);
      jQuery('#TB_window').height(500);
      jQuery('#TB_ajaxContent').height(450);
      jQuery('#TB_window').css("margin-left","-535px");
      jQuery('#TB_window').css("margin-top","-250px");
      jQuery("#fragment-1").removeClass('tabs-container');
      jQuery('#TB_ajaxContent').html(html);
      jQuery("#fragment-1").removeClass('tabs-container');
    }
  });
}

function save_to_workspace(title,url,feed_url,feed_title){
  jQuery.ajax({
    type: 'GET',
    url: 'new_workspace',
    data: {
      'title' : title,
      'url' : url,
      'feed_url' : feed_url,
      'feed_title': feed_title
    },
    beforeSend: function() {
      jQuery('#loader').show()
    },
    complete: function(){
      jQuery('#loader').hide()      
      if(jQuery('#rssfeed_error').css('opacity','1')){
        jQuery('td span.workspace').hide();
        jQuery('td span.workspace').prev('a').show();      
      }    
    },
    success: function(){
      loader.remove();
      jQuery('#TB_ajaxWindowTitle').text(title)
      jQuery('#TB_window').width(1090)
      jQuery('#TB_ajaxContent').width(1055)
      jQuery('#TB_window').height(500)
      jQuery('#TB_ajaxContent').height(450)
      jQuery('#TB_window').css("margin-left","-535px")
      jQuery('#TB_window').css("margin-top","-250px")
      jQuery("#fragment-1").removeClass('tabs-container')
      jQuery('#TB_ajaxContent').html(html)
      jQuery("#fragment-1").removeClass('tabs-container')
    },
    dataType: 'script'
  });
}

function save_to_repository(title,url,feed_url,feed_title,link){  
  jQuery.ajax({
    type: 'GET',
    url: 'new_repository',
    data: {
      'title' : title,
      'url' : url,
      'feed_url' : feed_url,
      'feed_title': feed_title,
      'load_popup' : 'true',
      'format' : 'html'
    },
    beforeSend: function() {
      jQuery('#loader').show()
      jQuery(link).hide();
      jQuery(link).next('span').show();
      jQuery(".respository_links").removeAttr('onclick');
    },
    complete: function(){
      jQuery('#loader').hide()
    },
    success: function(){
      loader.remove();
    },
    dataType: 'script'
  });
}

function list_favorites(){
  jQuery.ajax({
    type: 'GET',
    url: '/company_reports/fav_reports/' ,
    data :{
      'list_fav' : true,
      'load_popup' : true
    },
    beforeSend: function() {
      jQuery('#loader').show()
    },
    complete: function(){
      jQuery('#loader').hide()
    },
    success: function(){
      loader.remove();
    },
    dataType: 'script'
  });
}

function set_active(tab){
  jQuery('#search_by').val(tab);
  if (tab=='tag'){
    jQuery('#tag').addClass("active");
    jQuery('#description').removeClass("active");
  }else{
    jQuery('#description').addClass("active");
    jQuery('#tag').removeClass("active");     
  }
}

// This method is used for matter and contact autocomplete search
function setMatterORContactSearchInputFields(contactTextFieldID,matterTextFieldID,emp_id,comp_id,hidden_contact_id,hidden_matter_id,entryID,type){
  var url_str = "/physical/timeandexpenses/time_and_expenses/time_entry_matter_search/" +emp_id +"?&company_id="+comp_id ;
  jQuery("#" + contactTextFieldID).unautocomplete();
  jQuery("#"+ matterTextFieldID).unautocomplete();
  jQuery("#" + contactTextFieldID).autocomplete(url_str, {
    width: '300',
    extraParams: {
      entry_date: function() {
        loader.prependTo("#"+entryID + "_contactSpinner");
        jQuery('body').css("cursor", "wait");
        if(jQuery("#physical_timeandexpenses_time_entry_time_entry_date") != null && jQuery("#physical_timeandexpenses_time_entry_time_entry_date").length > 0){
          return jQuery("#physical_timeandexpenses_time_entry_time_entry_date").val();
        }else if(type== 'addexpense_entry'){
          return jQuery("#" + entryID + "_expense_entry_expense_entry_date").val();
        } else if(jQuery("#datepicker_time_entry") != null && jQuery("#physical_timeandexpenses_time_entry_time_entry_date").length > 0){
          return jQuery("#datepicker_time_entry").val();
        } else if(jQuery("#"+entryID +"_expense_entry_expense_entry_date") != null && jQuery("#"+entryID +"_expense_entry_expense_entry_date").length > 0){
          return jQuery("#"+entryID +"_expense_entry_expense_entry_date").val();
        } else {
          return '';
        }
      },
      value: function(){
        return jQuery('#'+contactTextFieldID).val();
      },
      search_for: "contact"
    },
    formatResult: function(data, value) {
      jQuery('body').css("cursor", "default");
      loader.remove();
      return value.split("</span>")[1];
    }
  }).flushCache();
  jQuery("#" + contactTextFieldID).result(function(event, data, formatted) {
    var val = (data[0].split("</span>")[0]).split(">")[1];
    if(val != null && val !=''){
      jQuery("#"+hidden_contact_id).val(val);
      if(type== 'addexpense_entry'){
        get_all_matters_for_expenses(entryID)
      } else if(type == 'timeEntryIndex'){
        showMattersForSelectedContact(entryID);
      } else if(type == 'expense'){
        var idStr = entryID + '_matter_id';
        get_all_expense_matters(idStr,entryID);
      } else{
        new_time_entry_get_all_matters();
      }
    }
  });
  jQuery("#"+ matterTextFieldID).autocomplete(url_str, {
    width: '300',
    extraParams: {
      entry_date: function() {
        loader.prependTo("#" + entryID + "_matterSpinner");
        jQuery('body').css("cursor", "wait");
        if(jQuery("#physical_timeandexpenses_time_entry_time_entry_date") != null && jQuery("#physical_timeandexpenses_time_entry_time_entry_date").length > 0){
          return jQuery("#physical_timeandexpenses_time_entry_time_entry_date").val();
        }else if(jQuery("#datepicker_time_entry") != null && jQuery("#datepicker_time_entry").length > 0){
          return jQuery("#datepicker_time_entry").val();
        } else if(jQuery("#"+entryID +"_expense_entry_expense_entry_date") != null && jQuery("#"+entryID +"_expense_entry_expense_entry_date").length > 0){
          return jQuery("#"+entryID +"_expense_entry_expense_entry_date").val();
        } else {
          return '';
        }
      },
      value: function(){
        jQuery("#contact_overlay").hide();
        return jQuery("#"+ matterTextFieldID).val();
      }
    },
    formatResult: function(data, value) {
      jQuery('body').css("cursor", "default");
      loader.remove();      
      return (value.split(",")[0]).split("</span>")[1];
    }
  }).flushCache();
  jQuery("#"+ matterTextFieldID).result(function(event, data, formatted) {
    var val = (data[0].split("</span>")[0]).split(">")[1]
    if(val != null && val !=''){
      jQuery("#"+hidden_matter_id).val(val);     
      if(type== 'addexpense_entry'){
        getMatterContactForExpense(entryID)
      } else if(type == 'timeEntryIndex'){
        update_matter_contact(entryID);
      } else if(type == 'expense'){
        var idStr = entryID + '_matter_id'
        get_expense_matters_contact(idStr,entryID);
      }else{
        get_new_time_entry_matters_contact();
      }
    }  
  });
}

function show_all_selected(){
  jQuery("#show_selected_dashboards").show();
  jQuery("#manage_dashboards").show();
  jQuery("#md_arrow_up").show();
  jQuery("#md_arrow_down").hide();
}

function show_all_dashboards(){
  jQuery("#revenue_enhancement").show();
  jQuery("#cost_savings").show();
  jQuery("#operational_efficiency").show();
  jQuery("#customer_satisfaction").show();
  jQuery("#others_dashboards").show();
  jQuery("#show_all_dashboards").hide();
  jQuery("#collapse").show();
  jQuery("#rev_arrow_up").show();
  jQuery("#cs_arrow_up").show();
  jQuery("#op_arrow_up").show();
  jQuery("#cust_arrow_up").show();
  jQuery("#ot_arrow_up").show();
  jQuery("#md_arrow_up").show();
  jQuery("#rev_arrow_down").hide();
  jQuery("#cs_arrow_down").hide();
  jQuery("#op_arrow_down").hide();
  jQuery("#cust_arrow_down").hide();
  jQuery("#ot_arrow_down").hide();
  jQuery("#md_arrow_down").hide();
}

function hide_all_dashboards(){
  jQuery("#revenue_enhancement").hide();
  jQuery("#cost_savings").hide();
  jQuery("#operational_efficiency").hide();
  jQuery("#customer_satisfaction").hide();
  jQuery("#others_dashboards").hide();
  jQuery("#collapse").hide();
  jQuery("#show_all_dashboards").show();
  jQuery("#rev_arrow_up").hide();
  jQuery("#cs_arrow_up").hide();
  jQuery("#op_arrow_up").hide();
  jQuery("#cust_arrow_up").hide();
  jQuery("#ot_arrow_up").hide();
  jQuery("#md_arrow_up").hide();
  jQuery("#rev_arrow_down").show();
  jQuery("#cs_arrow_down").show();
  jQuery("#op_arrow_down").show();
  jQuery("#cust_arrow_down").show();
  jQuery("#ot_arrow_down").show();
  jQuery("#md_arrow_down").show();
}

// function redirect_to_dashboard() : removed
function create_task_thickbox(title,got_url,note_id,matter_id){
  jQuery.ajax({
    type: 'GET',
    url: got_url,
    data: {
      'width' : 930,
      'title' :title,
      'note_id' : note_id,
      'matter_id' : matter_id,
      'load_popup' : 'true'    
    },
    beforeSend: function() {
      jQuery('#loader1').show();
    },
    success: function(){
      jQuery('#loader1').hide();
    }
  });
}

function create_contact_thickbox(title){
  jQuery.ajax({
    type: 'POST',
    url: '/physical/clientservices/home/create_opportunity',
    data:{
      'title' :title,
      'val'   :'contact',
      'load_popup' :'true'
    },
    beforeSend: function(){
      jQuery('#loader1').show();
    },
    complete: function(){
      jQuery('#loader1').hide();
    },
    success: function(){
      loader.remove();
    } ,
    dataType: 'script'
  });
}

function setContactORMatter(obj,id,hidden_id,methodName){    
  var mattername = obj.innerHTML.replace('amp;','');    
  var elems = jQuery('.back_ground_overlay');
  for(i=0;i < elems.length; i++){
    elems[i].style.display='none';
  }
  var entryID =obj.id.replace(/[^0-9\\.]/g, '');
  if(jQuery('#'+hidden_id).attr("tagName") == "SELECT"){
    jQuery('#matters_div').html('');
    var tempObj = jQuery('#001_matterSearch');
    var str = '<input type="hidden" id="'+hidden_id+'" value="'+entryID +'" name="physical_timeandexpenses_time_entry[matter_id]" />'
    tempObj.append(str);
    tempObj.show();
    jQuery('#'+id).val(mattername);
  }else {
    jQuery('#'+id).val(mattername);
    jQuery('#'+hidden_id).val(entryID);
  }
  eval(methodName)(entryID);
}

function showDivListBox(id){
  var elems = jQuery('.back_ground_overlay');
  for(i=0; i < elems.length; i++){
    if(elems[i].id !=id){
      elems[i].style.display='none';
    }
  }
  var obj = jQuery('#' + id);
  if(obj.is(":visible")){
    obj.hide();
    return false;
  }
  obj.show();
  obj.focus();
}

//jQuery(function(){
//  timeEnteryListBoxHide();
//});
//
//function timeEnteryListBoxHide(){
//  jQuery('.back_ground_overlay').bind("mouseleave", function(){
//    setTimeout(function(){
//      hideMatterORContactListBox();
//    },500);
//  });
//
//  jQuery('.back_ground_overlay').focusout(function(e){
//    setInterval(function(){
//      jQuery(e.target).fadeOut('slow');
//      hideMatterORContactListBox();
//    },10000);
//
//  });
//}
function hideMatterORContactListBox(){
  var elems = jQuery('.back_ground_overlay');
  for(i=0; i < elems.length; i++){
    elems[i].style.display='none';
  }
}

function zimbra_business_contact(zimbra_contact_url){
  jQuery.ajax({
    type: 'GET',
    url: zimbra_contact_url
  })
}

function dumpProps(obj, parent){
  for (var i in obj){
    // if a parent (2nd parameter) was passed in, then use that to
    // build the message. Message includes i (the object's property name)
    // then the object's property value on a new line
    if (parent) {
      var msg = parent + "." + i + "\n" + obj[i];
    } else {
      var msg = i + "\n" + obj[i];
    }
    // Display the message. If the user clicks "OK", then continue. If they
    // click "CANCEL" then quit this level of recursion
    if (!confirm(msg)) {
      return;
    }
    // If this property (i) is an object, then recursively process the object
    if (typeof obj[i] == "object"){
      if (parent) {
        dumpProps(obj[i], parent + "." + i);
      } else {
        dumpProps(obj[i], i);
      }
    }
  }
}

function toggle_doc_comments(){
  jQuery("#comment_toggle").click(function(){
    jQuery("#comment_div").toggle();
    jQuery(".toggle_comment").toggle();
  });

  jQuery("#doc_toggle").click(function(){
    jQuery("#doc_div").toggle();
    jQuery(".toggle_doc").toggle();
  });

  jQuery("#client_doc_toggle").click(function(){
    jQuery("#client_doc_div").toggle();
    jQuery(".toggle_client_doc").toggle();
  });
}

// function dumpProps : duplicate

function sort_columnof_tasks_modal(id,dir,task_type){
  if(id==""){
    return false
  }
  jQuery.ajax({
    type: "POST",
    url: "/physical/clientservices/home/view_matter_tasks",
    dataType: 'script',
    data: {
      'column_name' : id,
      'dir':dir,
      'task_type':task_type
    },
    success: function(){}
  });
}

function add_filters(fields, mt){
  fields = fields.split(",")
  jQuery('#add_filters').hide();
  jQuery('#remove_filters').show();
  jQuery('#search_submit').show();
  var i
  var winwidth = (screen.width || document.client.width);
  var exact_location = window.location.href.toString() /* make the location as a string */
  var loc_split = exact_location.split("/") /* split the location */
  var controller = loc_split[3] /* find controller name */

  for (i=0; i<=fields.length-1;i++){
    var str = '#search_' + fields[i]
    jQuery(str).show();
    if (str =="#search_accounts--phone"||str =="#search_contacts--phone" ){
      jQuery(str).attr('maxlength',15);
    }    
    var parent_width = parseInt(jQuery(str).parent().parent().parent().width());
    if(parent_width<=75){
      jQuery(str).parent().parent().css({
        "min-width" : "71px",
        "width" : "71px"
      });
      jQuery(str).parent().css({
        "min-width" : "71px",
        "width" : "71px"
      });
    }
  }
  var maxheight = 0
  jQuery(".tablesorter").children("div").children("a").each(function(){
    var thisheight = jQuery(this).height();
    if(thisheight>maxheight){
      maxheight = thisheight
    }
  });
  var height = parseInt(maxheight+26)
  jQuery(".tablesorter").children("div").height(height);
  if (winwidth <= 1400 || controller=="opportunities") {
    jQuery(".action_column").css({
      "width":"53px",
      "position":"absolute",
      "margin-top": mt+"px"
    });
  }else{
    jQuery(".action_column").css({
      "width":"53px"
    });
  }  
}
  
function remove_filters(fields){
  fields = fields.split(",")
  jQuery('#add_filters').show();
  jQuery('#remove_filters').hide();
  jQuery('#search_submit').hide();
  for (i=0;i<=fields.length-1;i++){
    var str = '#search_' + fields[i]
    jQuery(str).hide();
    jQuery(str).parent().parent().removeAttr("style");
    jQuery(str).parent().parent().css("position", "relative");
  }
  jQuery(".tablesorter").children("div").height("auto");
  jQuery(".action_column").height("auto");
}

/* sort columns opportunities on home page - Supriya */
function sort_opportunities_columns(col, dir){
  loader.prependTo("#loader_opp")
  jQuery.ajax({
    type: "POST",
    url: "/opportunities/sort_opportunities_columns",
    dataType: 'script',
    data: {
      'col' : col,
      'dir':dir
    },
    success: function(transport){
      jQuery('#sort_column_opp').html(transport);
      loader.remove();
    }
  });
}

//Validaing the checkbox of matter task dashboard --Santosh Challa
function validate_matter_task_checkbox(){
  var len=jQuery("input.valdiation_matter_task_check:checked").length
  if (len < 1){
    jQuery(".valdiation_matter_task_check").attr('checked',true);
    return false
  }
}

function show_sub_categories(catID){
  loader.appendTo('#categories_span');
  jQuery.ajax({
    type: 'GET',
    url: '/repositories/get_sub_categories',
    data: {
      'category_id' : catID
    },
    dataType: 'script',
    success: function(){
      loader.remove();
    }
  });
}

//Belowe code is used in campaign module : contacts_campaign for deleting purpose Added by Ajay Arsud on 30th Spet 2010.
function disable_submit_button(field){
  jQuery(field).val('Please wait...');
  jQuery('#submit_action').val('Delete');
  field.disabled = true;   
}

jQuery(function(){
  jQuery(".for_ajax_req").bind('click', function(event) {    
    var tmpArr = event.target.href.split('#');    
    id=null;
    if(tmpArr !=null && tmpArr.length > 1){
      var id=tmpArr[1];
      var currentObj = jQuery('#' + id +'-1');
      if(currentObj == null || currentObj.length <= 0){
        return false;
      }
    }
    jQuery.ajax({
      beforeSend: function(){
        jQuery('body').css("cursor", "wait");
        loader.appendTo('#' + id);
      },
      url: '/physical/clientservices/livian_instruction',
      type: "GET",
      data: {
        "id": id
      },
      dataType: "script",
      complete: function(){
        jQuery('body').css("cursor", "default");
        loader.remove();
      }
    });
  });
});

// Disable all submit buttons on submit of a form
function disableAllSubmitButtons(class_name){
  jQuery('.' + class_name).attr('disabled', 'disabled');
  jQuery('.' + class_name).css('color', 'gray');  
  return true;
}

function enableAllSubmitButtons(class_name){
  // find all the submit buttons and disable them on click  
  jQuery('.' + class_name).removeAttr('disabled');
  jQuery('.' + class_name).css('color', '');
  jQuery('#save_link_account').val('Save');
  jQuery('#Login2').val('Cancel');
  jQuery('#Login4').val('Cancel');
  jQuery('#create_folder').val('Create');
  jQuery('#move_button').val('Move');
  jQuery('#save_research').val('Save');
  jQuery('#save_risk').val('Save');
  jQuery('#save_task').val('Save');
  jQuery('#save_issue').val('Save');
  jQuery('#save_fact').val('Save');
  jQuery('#rename_folder').val('Rename');
  jQuery('#time_and_expense_id').val('Save & Exit');
  jQuery('input[name=save]').val('Save');
  jQuery('input[name=assign]').val('Assign');
  jQuery('input[name=activate_account_with_primary]').val('Save');
}

function setButtonPressed(but){
  but.value = "Please wait ...";
  jQuery("#button_pressed").val(but.name);
  return true;
}

//Added by Pratik - For matters To check wheather lawyer has selected his role for matter.
function validate_user_role(e,euid,is_a_member,from_tabs,access){
  if(access !=null && Boolean(access)) return true;
  if (from_tabs){
    if (!is_a_member || (euid != jQuery('#matter_employee_user_id').val() && jQuery('#lawyer_role').val()=="")){
      alert('You do not have a role in this Matter. Please select a role if you want to have access to this Matter');
      return false
    }
  }else{
    if (euid != jQuery('#matter_employee_user_id').val() && jQuery('#lawyer_role').val()==""){
      var answer = confirm("You have not selected a role in this matter. You will not be able to access this matter once you exit. Do you want to exit this Matter?")
      if (answer){
        setButtonPressed(e);
        return true
      }else{
        return false
      }
    }
  }
  setButtonPressed(e);
  return true
}

function refreshIfHomePage(url) {  
  if (window.location.toString().indexOf(url) != -1) {
    window.location.reload();
  }
}

//Function used in RSS for workspace name validation-- surekha
function validate_document_name(){
  if(jQuery('#document_home_name').val()==''){
    alert('Please Enter Document Name');
    jQuery('#save_rep').attr('disabled','');
    jQuery('#save_rep').val('Upload');
    jQuery('#loader').hide()
    return false;
  }else{
    return true;
  }
}
  
jQuery(function(){
  jQuery(".check_onblur").bind('blur', function(e) {
    if(e.target.value ==null || e.target.value==""){
      var parentElem = e.target.parentNode;
      var childes = parentElem.childNodes;
      for(i=0;i<childes.length;i++){
        if(childes[i].type=="hidden"){
          childes[i].value="";
          idStr = childes[i].id.replace(/matter_id|contact_id/,'');
          var matterORContactObj = null;
          if(childes[i].id.search('matter_id') !=-1){
            matterORContactObj = jQuery('#'+idStr+"contact_id");
            matterORContactObj.val('');          
          }else{
            matterORContactObj = jQuery('#'+idStr+"matter_id");
            jQuery('#_matter_ctl').val("");
            matterORContactObj.val('');
          }
          if(matterORContactObj !=null && matterORContactObj.val()==''){
            jQuery('#'+idStr+'is_internal').attr('checked','checked');
          }
        }
      }
    }          
  });
});

function resetForm(div_id){
  jQuery('#'+div_id+' :input').each(function() {
    switch(this.type) {
      case 'select-one':
      case 'text':
        $(this).val('');
        break;
      case 'textarea':
        $(this).val('');
        break;
      case 'checkbox':
      case 'radio':
        this.checked = false;
    }
  });
  disable_date();
}

/* ------------------------------------ Added By Pratik A Jadhav----------------------------------
   This Function was added to toggle between expand and colapsed folder icon in folder structure */
function toggle_plus_minus(link,span){
  jQuery("a").removeClass('selected');
  jQuery(link).addClass('selected');
  var expand=/icon_expand_folder/gi;
  var collapse=/icon_collapse_folder/gi;
  var matched, newclass;
  if (link){
    var prevSpan = jQuery(link).children("span");
    var classname = jQuery(prevSpan).attr("class")
    matched = classname.match(expand) || classname.match(collapse);
    newclass = classname.match(expand) ? "icon_collapse_folder" : "icon_expand_folder";
    if(!matched == null){
      jQuery(prevSpan).removeClass(matched[0]).addClass(newclass);
    }
  }else if (span){    
    classname = jQuery(span).attr("class")
    matched = classname.match(expand) || classname.match(collapse);
    newclass = classname.match(expand) ? "icon_collapse_folder" : "icon_expand_folder";
    if(!matched == null){
      jQuery(span).removeClass(matched[0]).addClass(newclass);
    }
  }    
}

function goto_support(email){
  jQuery("#email").val("Email Id");
  jQuery("#ticket_email").attr("value",email);
}

function checkContactSelected(){
  if(jQuery('#contact_nos_all').attr('checked')){
    var checked = $("#contact_list input:checked").length > 0;
    if(checked){
      return true;
    }else{
      show_error_msg("cont_errs","Please select atleast one contact","message_error_div");
      return false;
    }
  }else{
    return true;
  }
}

jQuery(document).ready(function(){
  jQuery(".thickboxConfirm").bind("click",function(){
    if(confirm(this.rel)){
      var t = this.title || this.name || null;
      var a = this.href || this.alt;
      var g = false;
      tb_show(t,a,g);
      this.blur();
      return false;
    }else{
      return false;
    }
  });
}); 

jQuery(function(){
  jQuery('.phone').live('keypress',function(e){
    if(e.charCode != 46 && e.charCode !=0 && ((e.charCode < 48 && e.charCode != 8 && e.charCode != 43 && e.charCode != 45 && e.charCode != 40 && e.charCode != 41) || e.charCode > 57 )){
      e.preventDefault();
    }
  }) ;
});

function today_date(){
  var d=jQuery("#user_date").val();
  var t=jQuery("#user_time").val();
  // var o=jQuery("#user_of").val();
  var lat_date = new Date(d+","+t);
  return lat_date
}

function show_child_tasks(task_id){
  var test_img = /plus/;
  if(task_id != null){
    if(test_img.test(jQuery('#task_plus_img_'+task_id).attr('src'))){
      jQuery('.'+task_id).show();
      jQuery('#task_plus_img_'+task_id).attr('src','/images/icon_small_minus.png');
    }else{
      child_hide(task_id);
      jQuery('#task_plus_img_'+task_id).attr('src','/images/icon_small_plus.png');
    }
  }else{
    var parents = jQuery('.parent');
    if(test_img.test(jQuery('#colapse').attr('src'))){
      jQuery.each(parents, function(e, parent){
        var parent_id = parent.id;
        jQuery('#colapse').attr('src','/images/icon_small_minus.png');
        var child = jQuery('.'+parent_id);
        if (child != null){
          jQuery('#task_plus_img_'+parent_id).attr('src','/images/icon_small_minus.png');
          child_show(parent_id);
        }
      });
    }else{
      jQuery.each(parents, function(e, parent){
        var parent_id = parent.id;
        jQuery('#colapse').attr('src','/images/icon_small_plus.png');
        var child = jQuery('.'+parent_id);
        if (child != null){
          jQuery('#task_plus_img_'+parent_id).attr('src','/images/icon_small_plus.png');
          child_hide(parent_id);
        }
      });
    }
  }
}

function child_show(task_id){
  var child_task = jQuery('.'+task_id);
  jQuery.each(child_task, function(e,obj){
    var child_id = obj.id;
    jQuery('#'+child_id).show();
    jQuery('#task_plus_img_'+child_id).attr('src','/images/icon_small_minus.png');
    var gchild = jQuery('.'+child_id);
    if (gchild != null){
      child_show(child_id);
    }
  });
}

function child_hide(task_id){
  var child_task = jQuery('.'+task_id);
  jQuery.each(child_task, function(e,obj){
    var child_id = obj.id;
    jQuery('#'+child_id).hide();
    jQuery('#task_plus_img_'+child_id).attr('src','/images/icon_small_plus.png');
    var gchild = jQuery('.'+child_id);
    if (gchild != null){
      child_hide(child_id);
    }
  });
}

function close_otherThickbox(title, path){
  tb_remove();
  tb_show(title, path, "");
}

function check_for_share_with_client(matter_id, permn, mattercontactid, select){
  var selectvalue = jQuery(select).val();
  if(permn=="yes" && mattercontactid!=selectvalue && jQuery('#matter_client_access').is(':checked')){
    var c = confirm("Do you want the contact to be shared with this matter?")
    if(c){
      jQuery("#contact_email").val('');
      var contact_id=jQuery("#matter_contact_id").val();
      if(jQuery('#matter_client_access').is(':checked')){
        jQuery('body').css("cursor", "wait");
        jQuery.ajax({
          type: 'GET',
          url: "/matters/get_client_contact",
          data: {
            'contact_id' : contact_id,
            'matter_id'  : matter_id
          },
          success: function(transport) {
            jQuery('body').css("cursor", "default");
            if(jQuery("#contact_email").val()==""){
              tb_show('New Matter Client','/matters/new_client?contact_id='+contact_id+'&KeepThis=false&height=150&width=300','')
            }
          }
        });
      }
    }
  }
}

function toggle_checked_entries(){
  var entries = jQuery(".entries");
  for (var i=0; i<entries.length; i++) {
    if(entries[i].disabled==false){
      entries[i].checked = jQuery("#check_all:checked").val();
    }
  }
}

jQuery(function(){
  expenseEntriesAdjusments();
  timeEntriesAdjusments();
  tneExpenseEntriesAdjusments();
});

function calculate_markup_for_expense_entry(amountID,obj,entry_id){
  var final_expense_amount = parseFloat(jQuery('#'+amountID).val());
  var billing_percent = parseFloat(obj.value);
  if(isNaN(billing_percent) || billing_percent < 0 || billing_percent > 100){
    alert("Please Enter Markup between 0.01 to 100");
    obj.value=0.00;
    jQuery('#'+ entry_id.toString()+ '_final_billed_amount').html(jQuery('#'+entry_id+'_full_amount').html());
    return false;
  } else{
    final_expense_amount += (final_expense_amount * billing_percent) / 100;
    obj.value= (billing_percent.toFixed(2));
    jQuery('#'+ entry_id.toString()+ '_final_billed_amount').html(final_expense_amount.toFixed(2));
  }
}

function tneExpenseEntriesAdjusments(){
  jQuery(".tne_expense_entry").live('change',function(e){
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    if(e.target.value ==2){
      txtField.name = entry_id+'[tne_invoice_expense_entry][billing_percent]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_discount_rate_for_expense_entry('"+ entry_id + "_tne_invoice_expense_entry_expense_amount','"+ entry_id + "_show_amount',"+ entry_id +")");
      txtField.maxlength=5;
    }else if(e.target.value==3){
      txtField.name = entry_id+'[tne_invoice_expense_entry][final_expense_amount]';
      txtField.id = entry_id+'_show_amount';
      ;
      txtField.maxlength=5;
      txtField.setAttribute('onblur','check_expense_override(this '+','+ entry_id+')');
    }else if(e.target.value==1){
      var fullAmountField = jQuery('#'+entry_id +'_final_billed_amount');
      if(fullAmountField !=null && fullAmountField.length > 0){
        fullAmountField.html(parseFloat(jQuery('#'+entry_id+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2));
      }else{
      }
      txtField.value= parseFloat(jQuery('#'+entry_id+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2);
      txtField.name='show_full_amount';
      txtField.id=entry_id + '_show_amount';
      txtField.disabled='disabled';
    }else if(e.target.value==4){
      txtField.name = entry_id+'[tne_invoice_expense_entry][markup]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_markup_for_expense_entry('"+ entry_id + "_tne_invoice_expense_entry_expense_amount',this,"+ entry_id +")");
      txtField.maxlength=5;
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });
}

function expenseEntriesAdjusments(){ 
  jQuery(".expense_entry").live('change',function(e){
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    if(e.target.value ==2){
      txtField.name = entry_id+'[expense_entry][billing_percent]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_discount_rate_for_expense_entry('"+ entry_id + "_expense_entry_expense_amount','"+ entry_id + "_show_amount',"+ entry_id +")");
      txtField.maxlength=5;
    }else if(e.target.value==3){
      txtField.name = entry_id+'[expense_entry][final_expense_amount]';
      txtField.id = entry_id+'_show_amount';
      txtField.maxlength=5;
      txtField.setAttribute('onblur','check_expense_override(this '+','+ entry_id+')');
    }else if(e.target.value==1){
      var fullAmountField = jQuery('#'+entry_id +'_final_billed_amount');
      if(fullAmountField !=null && fullAmountField.length > 0){
        fullAmountField.html(parseFloat(jQuery('#'+entry_id+'_expense_entry_expense_amount').val()).toFixed(2));
      }
      txtField.value= parseFloat(jQuery('#'+entry_id+'_expense_entry_expense_amount').val()).toFixed(2);
      txtField.name='show_full_amount';
      txtField.id=entry_id + '_show_amount';
      txtField.disabled='disabled';
    }else if(e.target.value==4){
      txtField.name = entry_id+'[expense_entry][markup]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_markup_for_expense_entry('"+ entry_id + "_expense_entry_expense_amount',this,"+ entry_id +")");
      txtField.maxlength=5;
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });

  // This section for in line edit for the created expense entries
  jQuery(".expense_entry_inline_edit").live('change',function(e){ 
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var hiddenBillingAdjustment = jQuery('#hidden_billing_adjustment_expense'+entry_id);
    var hiddenFinalAmount = parseFloat(hiddenBillingAdjustment.val());
    var finalExpenseAmount = parseFloat(jQuery('#expense_final_billed_amount_'+entry_id).html().replace(/,/g,''));
    var billed_amount = parseFloat(jQuery('#expenseamount_'+entry_id).children("span").html().replace(/,/g,''));
    var fullExpenseAmount = parseFloat(jQuery('#hidden_billing_full_amount_'+entry_id).val());
    var time_entry_date= jQuery("#date_time").val();
    var view_type= jQuery("#viewType").val();
    var txtField = document.createElement('input');    
    txtField.type = 'text';
    txtField.className = "amount";
    txtField.style.textAlign='right';
    txtField.id = entry_id+'_show_amount';
    txtField.size =8;
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
    if(e.target.value ==2){
      if (e.target.getAttribute('route') == 'tne_invoice_') {
         txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'expense_entries','set_expense_entry_billing_percent',"+entry_id +")");
      }else{
         txtField.setAttribute('onblur', "updateTimeUtilities" + "(this,'expense_entries','set_expense_entry_billing_percent?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      txtField.setAttribute('maxlength',5);
      if(hiddenBillingAdjustment.attr('name')=='2' && hiddenFinalAmount==finalExpenseAmount){
        var percentage = ((fullExpenseAmount - finalExpenseAmount) * 100 ) / fullExpenseAmount;
        txtField.value=percentage.toFixed(2);
      }else{
        txtField.value="";
      }
    }else if(e.target.value==3){
      txtField.setAttribute('maxlength',5);
      if (e.target.getAttribute('route') == 'tne_invoice_') {
         txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'expense_entries','set_expense_entry_billing_amount',"+entry_id +")");
      }else{
         txtField.setAttribute('onblur', "updateTimeUtilities" + "(this,'expense_entries','set_expense_entry_billing_amount?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      if(hiddenBillingAdjustment.attr('name')=='3' && hiddenFinalAmount==finalExpenseAmount){
        txtField.value=finalExpenseAmount;
      }else{
        txtField.value='';
      }
    }else if(e.target.value==4){
      if (e.target.getAttribute('route') == 'tne_invoice_') {
         txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'expense_entries','set_expense_entry_markup',"+entry_id +")");
      }else{
         txtField.setAttribute('onblur', "updateTimeUtilities" + "(this,'expense_entries','set_expense_entry_markup?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      txtField.setAttribute('maxlength',5);
      if(hiddenBillingAdjustment.attr('name')=='4' && hiddenFinalAmount==finalExpenseAmount){
        var markup = ((finalExpenseAmount - fullExpenseAmount) * 100) / fullExpenseAmount;
        txtField.value=markup.toFixed(2);
      }else{
        txtField.value='';
      }
    }else if(e.target.value==1){           
      if(hiddenBillingAdjustment.attr('name')=='1' && hiddenFinalAmount==finalExpenseAmount){
        txtField.value = finalExpenseAmount;
      }else{
        txtField.value=billed_amount;
        if(e.target.getAttribute('route')=='tne_invoice_'){
          invoiceTimeOrExpenseFullAmount(txtField,'expense_entries','set_expense_entry_full_amount',entry_id);
        }else{
          txtField.value=billed_amount;
          timeOrExpenseFullAmount(txtField,'expense_entries','set_expense_entry_full_amount?time_entry_date='+time_entry_date+"&view_type="+view_type, entry_id);
        }
      }
      txtField.setAttribute('disabled','disabled');
    }
  });
}

function timeEntriesAdjusments(){
  jQuery(".time_entries").live('change',function(e){
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    var obj = e.target;
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    var nameStr = 'physical_timeandexpenses_time_entry';
    if(e.target.value ==2){
      txtField.name = nameStr + '[billing_percent]';
      txtField.id = "show_amount";
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'physical_timeandexpenses_time_entry_')");
      txtField.maxLength=5;
    }else if(e.target.value==3){
      txtField.name = nameStr + '[final_billed_amount]';
      txtField.id = "show_amount";
      txtField.maxLength=5;
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'physical_timeandexpenses_time_entry_')");
    }else if(e.target.value==1){
      newEntryBillAmount(this,'physical_timeandexpenses_time_entry_');
      txtField.name='show_full_amount';
      txtField.id = "show_amount";
      txtField.disabled='disabled';
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });
  jQuery(".tne_time_entries").live('change',function(e){
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    var obj = e.target;
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    var nameStr = 'tne_invoice_time_entry';
    if(e.target.value ==2){
      txtField.name = nameStr+'[billing_percent]';
      txtField.id = "show_amount";
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'tne_invoice_time_entry_')");
      txtField.maxLength=5;
    }else if(e.target.value==3){
      txtField.name = nameStr+'[final_billed_amount]';
      txtField.id = "show_amount"
      txtField.maxLength=5;
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'tne_invoice_time_entry_')");
    }else if(e.target.value==1){
      newEntryBillAmount(this,'tne_invoice_time_entry_');
      txtField.name='show_full_amount';
      txtField.id = "show_amount";
      txtField.disabled='disabled';
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });
  
  jQuery(".time_entry_inline_edit").live('change',function(e){
    var parentTR = e.target.parentNode.parentNode;    
    var entry_id = e.target.id.split('_')[0];
    var hiddenBillingAdjustment = jQuery('#hidden_billing_adjustment_'+entry_id);
    var hiddenFinalAmount = parseFloat(hiddenBillingAdjustment.val());
    var finalExpenseAmount = parseFloat(jQuery('#final_billed_amount_'+entry_id).children("span").html().replace(/,/g,''));
    var billed_amount = parseFloat(jQuery('#billed_amount_'+entry_id).children("span").html().replace(/,/g,''));
    var fullExpenseAmount = parseFloat(jQuery('#hidden_billing_full_amount_'+entry_id).val());
    var txtField = document.createElement('input');
    var time_entry_date= jQuery("#date_time").val();
    var view_type= jQuery("#viewType").val();
    txtField.type = 'text';
    txtField.className = "amount";
    txtField.style.textAlign='right';
    txtField.id = entry_id+'_show_amount';
    txtField.size =8;
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
    if(e.target.value ==2){
      if (e.target.getAttribute('route') == 'tne_invoice_'){
        txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_percent',"+  entry_id +")");
      }else{
      txtField.setAttribute('onblur',"updateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_percent?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      txtField.setAttribute('maxLength',5);
      if(hiddenBillingAdjustment.attr('name')=='2' && hiddenFinalAmount==finalExpenseAmount){
        var percentage = ((fullExpenseAmount - finalExpenseAmount) * 100 ) / fullExpenseAmount;
        txtField.value=percentage.toFixed(2);
      }else{
        txtField.value="";
      }
    }else if(e.target.value==3){
      txtField.setAttribute('maxLength',5);
      if (e.target.getAttribute('route') == 'tne_invoice_'){
        txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_amount',"+  entry_id +")");
      }else{
        txtField.setAttribute('onblur', "updateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_amount?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      if(hiddenBillingAdjustment.attr('name')=='3' && hiddenFinalAmount==finalExpenseAmount){
        txtField.value=finalExpenseAmount;
      }else{
        txtField.value='';
      }
    }else if(e.target.value==4){
       if (e.target.getAttribute('route') == 'tne_invoice_'){
        txtField.setAttribute('onblur', "invoiceUpdateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_percent',"+  entry_id +")");
      }else{
        txtField.setAttribute('onblur', "updateTimeUtilities" + "(this,'time_entries','set_time_entry_billing_percent?time_entry_date="+time_entry_date+"&view_type="+view_type+"&id="+entry_id +"')");
      }
      txtField.setAttribute('maxLength',5);
      if(hiddenBillingAdjustment.attr('name')=='4' && hiddenFinalAmount==finalExpenseAmount){
        var markup = ((finalExpenseAmount - fullExpenseAmount) * 100) / fullExpenseAmount;
        txtField.value=markup.toFixed(2);
      }else{
        txtField.value='';
      }
    }else if(e.target.value==1){
      if(hiddenBillingAdjustment.attr('name')=='1' && hiddenFinalAmount==finalExpenseAmount){
        txtField.value = finalExpenseAmount;
      }else{
        txtField.style.display='none';
        if(e.target.getAttribute('route')=='tne_invoice_'){
          invoiceTimeOrExpenseFullAmount(txtField,'time_entries','set_time_entry_full_amount',entry_id);
        }else{
          txtField.value=addCommas(billed_amount);
          timeOrExpenseFullAmount(txtField,'time_entries','set_time_entry_full_amount?time_entry_date='+time_entry_date+"&view_type="+view_type, entry_id);
        }
      }
      txtField.setAttribute('disabled','disabled');
    }
  });
}

function check_if_open_children(this_value, new_task, has_children, init_completed, matter_task_category_todo, matter_task_completed, matter_task_assoc_as, matter_task_parent_id){
  has_children = ((has_children == 'true')? true : false);
  var if_todo = jQuery('#'+matter_task_category_todo).attr('checked');
  if(if_todo){
    var completed = jQuery('#'+matter_task_completed).attr("checked");
    var has_parent = jQuery('#'+matter_task_assoc_as).attr('checked');
    var parent_id = jQuery('#'+matter_task_parent_id).val();
    init_completed = ((init_completed == "true")? true : false);
    new_task = ((new_task == "true")? true : false);
    if (has_children && completed && !init_completed){
      var child_cmplt = confirm('All the children tasks will also be completed. Do you want to continue?');
      if (child_cmplt){
        return setButtonPressed(this_value);
      }else{
        return false;
      }
    }else if(has_parent && (parent_id != "")){
      var parent_complete = jQuery('#'+parent_id+'_completed').val();
      parent_complete = ((parent_complete == 'true')? true : false);
      if(parent_complete && !completed){
        var open_parent = confirm('Adding open task to completed parent would cause the parent to open. Do you want to continue?');
        if (open_parent){
          return setButtonPressed(this_value);
        }else{
          return false;
        }
      } else{
        return setButtonPressed(this_value);
      }
    }else{
      return setButtonPressed(this_value);
    }
  }else{
    return setButtonPressed(this_value);
  }
}

function show_communications_divs(option){
  jQuery('.'+option).slideDown();
  jQuery('.rev_arrow_up_'+option).show();
  jQuery('.rev_arrow_down_'+option).hide();
}

function hide_communications_divs(option){
  jQuery('.'+option).slideUp();
  jQuery('.rev_arrow_down_'+option).show();
  jQuery('.rev_arrow_up_'+option).hide();
}

function append_loader(id){
  loader.appendTo(id);
}

function validate_filters_dates(option){
  var from_date = jQuery('#'+option+'_from_date').val();
  var to_date = jQuery('#'+option+'_to_date').val();
  if(from_date != "" && to_date != ""){
    if (Date.parse(from_date) > Date.parse(to_date)){
      alert("To Date should be greater than From Date");
      return false;
    }
  }else {
    alert("Please Specify Both the dates")
    return false;
  }    
}

function assign_service_provider(service_provider_id){
  var answer = jQuery('#accept_permissions').is(':checked');
  if(answer){
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

function checkloader(){   
  jQuery('#loader').show();
}

function check_box(){
  var v= jQuery('.recordscampmem').attr('checked');
  if (v == true){
    jQuery('.linknormal').removeAttr('disabled');
  }else{
    jQuery('.linknormal').attr('disabled', 'disabled');
  }
}

function hide_private(employee_user_id){
  var emp,select;
  emp= jQuery('#search_owner option:selected').val();
  select= jQuery('#search_owner option:selected').text();
  if ( select!='Please Select' && emp!=employee_user_id){
    jQuery('#disable_private').attr('disabled','disabled');
    jQuery('#disable_private').removeAttr('checked');
  }else{
    jQuery('#disable_private').removeAttr('disabled');
  }
}

function search_toggle(search){
  if ((jQuery("#plusminusicon").attr("src") == "/images/icon_small_plus.png") || search=='Open' ){
    jQuery("#plusminusicon").attr({
      "src":"/images/icon_small_minus.png",
      "title": "Close Search",
      "class" :"vtip"
    })
    jQuery(".toggle_busi_cont_detail").show();
    jQuery("#toggle_busi_cont_detail_div").show();
    jQuery('#display_search').val('Open');
  }else{
    jQuery("#plusminusicon").attr({
      "src":"/images/icon_small_plus.png",
      "title":"Display Search",
      "class" :"vtip"
    })
    jQuery(".toggle_busi_cont_detail").hide();
    jQuery("#toggle_busi_cont_detail_div").hide();
    jQuery('#display_search').val('Close');
  }
}
jQuery(function(){
  jQuery('#arrowSelectBox0').live('click',function(e){
    var divContainer = jQuery('#selectBoxOptions0');
    if(divContainer.css('display') == 'none'){
      divContainer.css('display','block')
      divContainer.css("visibility:",'visible');
    }else{
      divContainer.css('display','none');
      divContainer.attr("visibility:",'hidden');
    }
  });
  jQuery('.selectBoxAnOption').live('click',function(e){
    var elem = e.target;
    jQuery('#opportunity_probability').val(elem.innerHTML);
    var divContainer = jQuery('#selectBoxOptions0');
    divContainer.css('display','none');
    divContainer.attr("visibility:",'hidden');
  });
  jQuery('#opportunity_stage').live('change',function(e){
    var selectElem = e.target;
    var probTextFld = jQuery('#opportunity_probability');
    if(jQuery('#op_prob_'+selectElem.value).length > 0 ){
      probTextFld.val(jQuery('#op_prob_'+selectElem.value).html());
    }else{
      probTextFld.val("");
    }
  });
  jQuery('#opportunity_probability').live('blur',function(e){
    var divContainer = jQuery('#selectBoxOptions0');
    divContainer.css('display','none');
    divContainer.attr("visibility:",'hidden');
  });
  jQuery('#opportunity_probability').live('keypress',function(e){
    var key =null;
    if (e.charCode == undefined){
      key = e.keyCode;
    }else{
      key = e.charCode;
    }
    var str     = e.target.value.toString();
    if(key != 46 && key !=0 && (key < 48 || key > 57)){
      e.preventDefault();
    }else{
      try {
        str  =  parseFloat(str + String.fromCharCode(key));
        if(!isNaN(str) && str > 100 || str < 0){
          alert("Please insert Probability value between 0% -100%.");
          e.target.focus();
          e.preventDefault();
        }
      } catch (exception) { }
    }
  });
  var probSelectBox = jQuery('#opportunity_stage').val();
  var probTextFld = jQuery('#opportunity_probability');
  try{
    var val = parseFloat(probTextFld.val());
    if(isNaN(val) && jQuery('#op_prob_'+probSelectBox).html() !=null){
      probTextFld.val();
    }
  }catch(e){ }

  //to validate start date and end date :Rashmi.N
  jQuery('#save_bill').live('click', function() {
    jQuery('#matter_bill_errors').removeClass("message_error_div");
    //validate start date and end date for bill.
    var d1 = jQuery('#matter_billing_bill_pay_date').val();//start date
    var d2 = jQuery('#matter_billing_bill_due_date').val();//end date
    return check_date_validation(d1, d2);
  });

  //to verify start date should not be greater than end date.
  function check_date_validation(d1, d2){
    //start date should not be greater than end date
    if(new Date(d1) > new Date(d2)){      
      alert('Due date is less than Invoice date');
      jQuery('#matter_billing_bill_due_date').focus();
      return false;
    } else{
      return checkloader();
    }
  }

  //to check the file uploaded campaigns :Rashmi.N
  jQuery('#upload_but').live('click', function() {
    jQuery('#modal_document_home_errors').hide();
    jQuery('#modal_document_home_errors').removeClass("message_error_div");
  });

  jQuery('#file_first0').live('change', function() {
    check_file_size('#file_first0', 'campaign');
  });

  jQuery('#file_first1').live('change', function() {
    check_file_size('#file_first1', 'campaign');
  });

  jQuery('#file_second0').live('change', function() {
    check_file_size('#file_second0', 'campaign');
  });

  jQuery('#file_second1').live('change', function() {
    check_file_size('#file_second1', 'campaign');
  });

  jQuery('#document_home_document_attributes_data').live('change', function(e) {
    check_file_size(this, 'document');
  });

  jQuery('#document_home_data').live('change', function(e) {
    check_file_size(this, 'supercede');
  });

  jQuery('#physical_timeandexpenses_time_entry_file').live('change', function() {
    check_file_size(this, 'time_expense');
  });

  jQuery('#document_home_file').live('change', function() {
    check_file_size(this, 'matter_billing_retainer');
  });
});

//to check the file size in campaigns :Rashmi.N
function check_file_size(id, modules_name){    
  if ($.browser.msie ) {}
  else{
    if(modules_name == 'campaign') {
      //this[0].files[0].fileSize gets the size of your file.
      var file_size = jQuery(id)[0].files[0].fileSize;
    }else{
      var file_size = id.files[0].size;
    }
    var max_size = 52428800;
    if(file_size <= 1 || file_size > max_size){
      if (modules_name == 'supercede'){
        jQuery('#one_field_error_div').html('<div class = "message_error_div">Upload File size should be between is 1KB-50MB.</div>').fadeIn('slow')
        .animate({
          opacity: 1.0
        }, 8000)
        .fadeOut('slow');
        jQuery('#document_home_data').val('');
      }
       
      if(modules_name == 'campaign') {
        jQuery('#modal_document_home_errors').html('<div class = "message_error_div">Upload File size should be between is 1KB-50MB.</div>').fadeIn('slow')
        .animate({
          opacity: 1.0
        }, 8000)
        .fadeOut('slow');
        jQuery(id).val('');
      }
       
      if(modules_name == 'document'){
        jQuery('#modal_new_document_error').html('<div class = "message_error_div">Upload File size should be between is 1KB-50MB.</div>').fadeIn('slow')
        .animate({
          opacity: 1.0
        }, 8000)
        .fadeOut('slow');
        jQuery('#document_home_document_attributes_data').val('');
        jQuery('#document_home_document_attributes_name').val('');
        jQuery('#document_home_name').val('');
      }

      if(modules_name == 'time_expense'){
        jQuery('#from_matters_error_notice').html('<div class = "message_error_div">Upload File size should be between is 1KB-50MB.</div>').fadeIn('slow')
        .animate({
          opacity: 1.0
        }, 8000)
        .fadeOut('slow');
        jQuery('#physical_timeandexpenses_time_entry_file').val('');
      }

      if(modules_name == 'matter_billing_retainer'){
        jQuery('#matter_bill_errors').html('<div class = "message_error_div">Upload File size should be between is 1KB-50MB.</div>').fadeIn('slow')
        .animate({
          opacity: 1.0
        }, 8000)
        .fadeOut('slow');
        jQuery('#document_home_file').val('');
      }
    }
  }
}

function get_matters_contact_for_time_entry(){
  var contact_id = jQuery('#_time_entry_contact_id option:selected').val();
  jQuery('#physical_timeandexpenses_time_entry_contact_id').val(contact_id);
}

function reset_partial(option){
  loader.appendTo("#"+option+"_loader");  
  if(option == "outstanding"){
    option = 'outstanding_task_details';
  }else if(option == "completed"){
    option = 'completed_action_details';
  }
  jQuery.ajax({
    type: "POST",
    url: "/communications/view_within_date_range",
    dataType: 'script',
    data: {
      'option' : option
    },
    success: function(){
      loader.remove();
    }
  });
}

function checkamount(){
  var a = jQuery('#opportunity_amount').val();
  if (a < 0){
    alert('Please Enter Valid Amount');
    jQuery('#opportunity_amount').val('');
    jQuery('#opportunity_amount').focus();
  }
  if(isNaN(a)){
    alert('Please enter number');
    jQuery('#opportunity_amount').val('');
  }
  if (a != ""){
  jQuery('#opportunity_amount').focus();
  }
}

function find_more_notifications(limit){
  jQuery('#all-messages').text('Please Wait...');
  jQuery.ajax({
    type: "POST",
    url: "/wfm/notifications/more_notifications",
    dataType: 'script',
    data: {
      'limit' : limit
    },
    success: function(transport){
      jQuery('#messages-box').slideDown();
      loader.remove();
    }
  });
}

function upload_notifications(obj,id,notify_id){
  jQuery('#messages-box').slideUp();
  jQuery('#notification_'+id).css('background-color', '#F5F5F5');
  jQuery("#all-messages").text('Please Wait...');
  jQuery.ajax({
    type: "GET",
    url: "/wfm/notifications/"+id,
    dataType: 'script',
    data:{
      'limit' : jQuery('.notify').size(),
      'notify_id' : notify_id
    },
    success: function(){
      jQuery("#all-messages").text('View More');
    }
  });
}

jQuery(function(){
  jQuery('.trust_type').change(function(e){
    var lvalue = e.target.options[this.selectedIndex].getAttribute('lvalue');
    if(lvalue == 'linked to matter'){
      jQuery('#matter_div').show();
      jQuery('#account_div').hide();
    }else if(lvalue == 'linked to account'){
      jQuery('#matter_div').hide();
      jQuery('#account_div').show();
    } else{
      jQuery('#matter_div').hide();
      jQuery('#account_div').hide();
    }
  });
  
  jQuery('#tne_invoice_matter_id').live('change',function(e){
    var elems = jQuery('.new_tme_billling');
    var matterID=null;
    if(elems !=null && elems.length > 0){
      matterID = e.target.options[this.selectedIndex].value;
      var strUrl = elems.attr('href');
      if(strUrl.search(/matter_id/) !=-1){
        strUrl = strUrl.replace(/matter_id=/,'billing');
        strUrl = strUrl + "&matter_id= "  + matterID;
        elems.attr('href',strUrl)
      }
    }
    var elems1 = jQuery('.new_exp_billling');
    if(elems1 !=null && elems1.length > 0){
      var strUrl = elems1.attr('href');
      if(strUrl.search(/matter_id/) !=-1){
        strUrl = strUrl.replace(/matter_id=/,'billing');
        strUrl = strUrl + "&matter_id= "  + matterID;
        elems1.attr('href',strUrl)
      }
    }
  });   
});

function check_box_matter(){
  var matter;
  matter = jQuery('.recordscampmem').is(':checked');
  if(matter==true){
    jQuery('.linknormal').show();
  }else{
    jQuery('.linknormal').hide();
  }
}

// added by mangala
function MatterEnteryListBoxHide(){
  jQuery('.com_notes_entries1').bind("mouseleave", function(){
    setTimeout(function(){
      hideMatterORContactListBox();
    },500);
  });

  jQuery('.com_notes_entries1').focusout(function(e){
    setTimeout(function(){
      hideMatterORContactListBox();
    },500);
  });
}

function hideMatterORContactListBox(){
  var elems = jQuery('.com_notes_entries1');
  for(i=0; i < elems.length; i++){
    elems[i].style.display='none';
  }
}

function search_comm_matter(name, val, thisid, otherid, from){
  jQuery('.ac_results').remove();
  jQuery('#notes_lwayers_list').slideUp();
  var url_str = "/communications/get_matter_details";
  var matter_name = name
  jQuery("#" + thisid).unautocomplete();
  jQuery("#"+ otherid).unautocomplete();
  jQuery('#'+thisid).autocomplete(url_str,{
    width : 'auto',
    delay: 1,
    minLength:1,
    extraParams: {
      com_id : val,
      from   : from
    },
    formatResult: function(data, value){
      jQuery('body').css("cursor", "default");
      loader.remove();
      return value.split("</span>")[1];
    }
  }).flushCache();

  jQuery('#'+thisid).result(function(event, data, formatted) {
    if(from=="matters"){
      var mtrSpanId = '#_matter_ctl_'+val;
      var cntSpanId = '#_contact_ctl_'+val;
      var value =jQuery('#_matter_ctl_'+val).val();
    }else{
      var mtrSpanId = "#comm_mtr_"+val+"_span";
      var cntSpanId = "#comm_cnt_"+val+"_span";
      var value =jQuery("#comm_cnt_"+val+"_span").val();
    }
    var mtrId = jQuery('#id_matter'+val).text();
    var cntId = jQuery('#id_contact'+val).text();

    getCommMattersContacts(val,mtrSpanId,cntSpanId,mtrId,cntId,value);
  });
}

// This is for IE 8 and 7
jQuery(function(){
  jQuery(".IE_8_time_entries").change(function(e){
    var parentTR = e.target.parentNode.parentNode;
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    var obj = e.target;
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    var nameStr = 'physical_timeandexpenses_time_entry';
    if(e.target.value ==2){
      txtField.name = nameStr + '[billing_percent]';
      txtField.id = "show_amount";
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'physical_timeandexpenses_time_entry_')");
      txtField.maxLength=5;
    }else if(e.target.value==3){
      txtField.name = nameStr + '[final_billed_amount]';
      txtField.id = "show_amount";
      txtField.maxLength=5;
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'physical_timeandexpenses_time_entry_')");
    }else if(e.target.value==1){
      newEntryBillAmount(this,'physical_timeandexpenses_time_entry_');
      txtField.name='show_full_amount';
      txtField.id = "show_amount";
      txtField.disabled='disabled';
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });

  jQuery(".IE_8_expense_entry").change(function(e){
    var parentTR = e.target.parentNode.parentNode;
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    if(e.target.value ==2){
      txtField.name = entry_id+'[expense_entry][billing_percent]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_discount_rate_for_expense_entry('"+ entry_id + "_expense_entry_expense_amount','"+ entry_id + "_show_amount',"+ entry_id +")");
      txtField.maxlength=5;
    }else if(e.target.value==3){
      txtField.name = entry_id+'[expense_entry][final_expense_amount]';
      txtField.id = entry_id+'_show_amount';
      txtField.maxlength=5;
      txtField.setAttribute('onblur','check_expense_override(this '+','+ entry_id+')');
    }else if(e.target.value==1){
      var fullAmountField = jQuery('#'+entry_id +'_final_billed_amount');
      if(fullAmountField !=null && fullAmountField.length > 0){
        fullAmountField.html(parseFloat(jQuery('#'+entry_id+'_expense_entry_expense_amount').val()).toFixed(2));
      }
      txtField.value= parseFloat(jQuery('#'+entry_id+'_expense_entry_expense_amount').val()).toFixed(2);
      txtField.name='show_full_amount';
      txtField.id=entry_id + '_show_amount';
      txtField.disabled='disabled';
    }else if(e.target.value==4){
      txtField.name = entry_id+'[expense_entry][markup]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_markup_for_expense_entry('"+ entry_id + "_expense_entry_expense_amount',this,"+ entry_id +")");
      txtField.maxlength=5;
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });

  jQuery(".IE_8_tne_time_entries").change(function(e){
    var parentTR = e.target.parentNode.parentNode;
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    var obj = e.target;
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    var nameStr = 'tne_invoice_time_entry';
    if(e.target.value ==2){
      txtField.name = nameStr+'[billing_percent]';
      txtField.id = "show_amount";
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'tne_invoice_time_entry_')");
      txtField.maxLength=5;
    }else if(e.target.value==3){
      txtField.name = nameStr+'[final_billed_amount]';
      txtField.id = "show_amount"
      txtField.maxLength=5;
      txtField.setAttribute('onblur', "newEntryBillAmount(this,'tne_invoice_time_entry_')");
    }else if(e.target.value==1){
      newEntryBillAmount(this,'tne_invoice_time_entry_');
      txtField.name='show_full_amount';
      txtField.id = "show_amount";
      txtField.disabled='disabled';
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });
  jQuery(".IE_8_tne_expense_entry").change(function(e){
    var parentTR = e.target.parentNode.parentNode;
    var entry_id = e.target.id.split('_')[0];
    var txtField = document.createElement('input');
    txtField.type = 'text';
    txtField.size =8;
    txtField.className = "amount";
    txtField.style.textAlign='right';
    if(e.target.value ==2){
      txtField.name = entry_id+'[tne_invoice_expense_entry][billing_percent]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_discount_rate_for_expense_entry('"+ entry_id + "_tne_invoice_expense_entry_expense_amount','"+ entry_id + "_show_amount',"+ entry_id +")");
      txtField.maxlength=5;
    }else if(e.target.value==3){
      txtField.name = entry_id+'[tne_invoice_expense_entry][final_expense_amount]';
      txtField.id = entry_id+'_show_amount';
      ;
      txtField.maxlength=5;
      txtField.setAttribute('onblur','check_expense_override(this '+','+ entry_id+')');
    }else if(e.target.value == 1){
      var fullAmountField = jQuery('#'+entry_id +'_final_billed_amount');
      if(fullAmountField !=null && fullAmountField.length > 0){
        fullAmountField.html(parseFloat(jQuery('#'+entry_id+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2));
      }
      txtField.value= parseFloat(jQuery('#'+entry_id+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2);
      txtField.name='show_full_amount';
      txtField.id=entry_id + '_show_amount';
      txtField.disabled='disabled';
    }else if(e.target.value==4){
      txtField.name = entry_id+'[tne_invoice_expense_entry][markup]';
      txtField.id = entry_id+'_show_amount';
      txtField.setAttribute('onblur', "calculate_markup_for_expense_entry('"+ entry_id + "_tne_invoice_expense_entry_expense_amount',this,"+ entry_id +")");
      txtField.maxlength=5;
    }
    parentTR.cells[1].innerHTML="";
    parentTR.cells[1].appendChild(txtField);
  });
});


jQuery("#popup_sort").live("click", (function(event){
  event.preventDefault();
  jQuery.ajax({
    type: "GET",
    url: this.href,
    success: function(transport){
      jQuery('#ajax_sort').html(transport);
    }
  });
}));

/// added fro autocomplete serach matter and contact in communication
function SearchAutocomplete(){
jQuery(".all_matter_input").autocomplete(
    "/communications/get_matter_details", {
      width: 'auto',
      extraParams:{
        from: "matters"
      },
      formatResult: function(data, value) {
        return value.split("</span>")[1];
      }
    });
  jQuery('.all_matter_input').result(function(event, data, formatted) {
    var arr = this.id.split('_');
    var index= arr[2];
    var cntSpanId = 'contact_cnt_'+index;
    var mtrId = formatted.split('>')[1].split('<')[0];
    var value = this.value
    getCommMattersContacts(index,this.id,cntSpanId,value,mtrId,'');
  });

  jQuery(".all_contact_input").autocomplete(
    "/communications/get_matter_details", {
      width: 'auto',
      extraParams:{
        from: "contacts"
      },
      formatResult: function(data, value) {
        return value.split("</span>")[1];
      }
    });
  jQuery('.all_contact_input').result(function(event, data, formatted) {
    var arr = this.id.split('_');
    var index= arr[2];
    var mtrSpanId = 'matter_cnt_'+index;
    var cntId = formatted.split('>')[1].split('<')[0];
    var value = this.value
    getCommMattersContacts(index,mtrSpanId,this.id,value,'',cntId);
  });
}

function disable_rightclick_for_time(){
  jQuery('.hasTimeEntry').bind('contextmenu', function(e){
    return false;
  });
}

function megaHoverOver(){
  jQuery(this).find(".sub").stop().fadeTo('fast', 1).show();
  //Calculate width of all ul's
  var rowWidth = 0;
  (function(jQuery) {
    jQuery.fn.calcSubWidth = function() {
      //Calculate row
      jQuery(this).find("ul").each(function() {
        rowWidth += $(this).width();
      });
    };
  })(jQuery);
  if ( jQuery(this).find(".row").length > 0 ) { //If row exists...
    var biggestRow = 0;
    //Calculate each row
    jQuery(this).find(".row").each(function() {
      jQuery(this).calcSubWidth();
      //Find biggest row
      if(rowWidth > biggestRow) {
        biggestRow = rowWidth;
      }
    });
    //Set width
    jQuery(this).find(".sub").css({
      //    'width' :biggestRow
      });
    jQuery(this).find(".row:last").css({
      'margin':'0'
    });
  } else { //If row does not exist...
    jQuery(this).calcSubWidth();
    //Set Width
    jQuery(this).find(".sub").css({
      'width' : rowWidth
    });
  }
}

function megaHoverOut(){
  jQuery(this).find(".sub").stop().fadeTo('fast', 0, function() {
    jQuery(this).hide();
  });
}

// Feature 10280: Timer,Ajax request sent to replace "timer-container" div with partial layout/_timer.html.erb - Kirti
function fetchTimer(){
  jQuery.ajax({
    type: "GET",
    url: "/utilities/fetch_timer",
    dataType: 'text',
    data: {
      'time_now' : (new Date()).toString()
    },
    success: function(transport){
      jQuery("#timer-container").html(transport);
      }
    });
}

  // Feature 10280: Timer, Fetch time from timer and convert into seconds -Kirti
  function getBaseSeconds(timerVal) {
    timerArr = timerVal.split("&nbsp;:&nbsp;");
    hrs = parseInt(timerArr[0]);
    mins = parseInt(timerArr[1]);
    secs = parseInt(timerArr[2]);
    if(hrs!=0); mins = mins + hrs*60
    if(mins!=0); secs = secs + mins * 60
    return secs
  }

  // Feature 10280: Timer, Reset timer -Kirti
  function resetTimer() {
    jQuery('#timer').countdown('destroy').html("00 : 00 : 00");
    jQuery('#start').show();
    jQuery("#pause, #stop, #reset").hide();
    portal_timer.state = "stopped";
    jQuery.get("/utilities/set_timer", {start_time: '',state: portal_timer.state, base_seconds: 0});
  }

// Feature 10280: Timer, Show Warning when user click for logout and timer is running -Kirti
  function timer_warning() {
    if (portal_timer.state != "stopped") {
      return confirm("Are you sure to logout? You have a timer running right now. If you logout, your timer will be lost.");
    }
    return true;
  }