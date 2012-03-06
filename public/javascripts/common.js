/*This javascript file should be used only for the functions which needs to be accessible in various logins(as this file is included in all layouts).*/

// function created for deleting records when independent delete method is called.
function confirm_for_delete_module_record( module_name, path , optional_confirm){
  confirm_msg ="Deleting this "+module_name+" will permanently delete all the associated documents. Please confirm if you want to continue?";
  if(typeof(optional_confirm)!="undefined")
    confirm_msg = "Deleting this "+module_name+".This will permanently delete Contact,Opportunity and all the associated documents. Please confirm if you want to continue?";
  var response = confirm(confirm_msg);
  if(response){
    var confirm_response = confirm("The deleted data cannot be retrieved. Please confirm if you want to proceed with deletion?");
    if(confirm_response){
      window.location.href = path
    }
    return false;
  }
  return false;
}

// function created for deleting documents when delete method from CRUD is called.
function confirm_for_delete_document(a, companyid, page, matterid, authenticity_token, view){
  var response = confirm("You will not be able to retrieve this document once it is deleted. You may want to save it in your personal drive or add it to the Portal Repository or Workspace. Do you want to Continue?");
  if(response){
    var confirm_response = confirm("Are you sure you want to delete this document?");
    if(confirm_response){
      var f = document.createElement('form');
      f.style.display = 'none';
      a.parentNode.appendChild(f);
      f.method = 'POST';
      f.action = a.href;
      var m = document.createElement('input');
      m.setAttribute('type', 'hidden');
      m.setAttribute('name', '_method');
      m.setAttribute('value', 'delete');
      f.appendChild(m);
      if(view=="admin"){
        var c = document.createElement('input');
        c.setAttribute('type', 'hidden');
        c.setAttribute('name', 'company_id');
        c.setAttribute('value', companyid);
        f.appendChild(c);
        var p = document.createElement('input');
        p.setAttribute('type', 'hidden');
        p.setAttribute('name', 'page');
        p.setAttribute('value', page);
        f.appendChild(p);
        var t = document.createElement('input');
        t.setAttribute('type', 'hidden');
        t.setAttribute('name', 'm');
        t.setAttribute('value', matterid);
        f.appendChild(t);
      }
      var s = document.createElement('input');
      s.setAttribute('type', 'hidden');
      s.setAttribute('name', 'authenticity_token');
      s.setAttribute('value', authenticity_token);
      f.appendChild(s);
      f.submit();
    }
    return false;
  }
  return false;
}

// function created for deleting records when delete method from CRUD is called.
function confirm_for_module_record_delete(link, record_name, module_name, authenticity_token,msg){
  if(module_name=="Opportunity")
    var response = confirm("Deleting this "+ msg +" will permanently delete all the associated documents. Please confirm if you want to continue?");
  else
    var response  = confirm("Deleting this "+module_name+" will permanently delete all the associated documents. Please confirm if you want to continue?");
  if(response){
    var confirm_response = confirm("The deleted data cannot be retrieved. Please confirm if you want to proceed with deletion?");
    if(confirm_response){
      var f = document.createElement('form');
      f.style.display = 'none';
      link.parentNode.appendChild(f);
      f.method = 'POST';
      f.action = link.href;
      var m = document.createElement('input');
      m.setAttribute('type', 'hidden');
      m.setAttribute('name', '_method');
      m.setAttribute('value', 'delete');
      f.appendChild(m);
      if(module_name=="Campaign"){
        var a = document.createElement('input');
        a.setAttribute('type', 'hidden');
        a.setAttribute('name', 'delete');
        a.setAttribute('value', true);
        f.appendChild(a);
      }
      var s = document.createElement('input');
      s.setAttribute('type', 'hidden');
      s.setAttribute('name', 'authenticity_token');
      s.setAttribute('value', authenticity_token);
      f.appendChild(s);
      f.submit();
    }
    return false;
  }
  return false;
}

function confirm_for_delete_client_document(a, companyid, page, matterid, authenticity_token, view){
  var response = confirm("This document is uploaded by client and deleting will also delete the same from client side. You will not be able to retrieve this document once it is deleted. Do you want to Continue?");
  if(response){
    var confirm_response = confirm("Are you sure you want to delete this document?");
    if(confirm_response){
      var f = document.createElement('form');
      f.style.display = 'none';
      a.parentNode.appendChild(f);
      f.method = 'POST';
      f.action = a.href;
      var m = document.createElement('input');
      m.setAttribute('type', 'hidden');
      m.setAttribute('name', '_method');
      m.setAttribute('value', 'delete');
      f.appendChild(m);
      if(view=="admin"){
        var c = document.createElement('input');
        c.setAttribute('type', 'hidden');
        c.setAttribute('name', 'company_id');
        c.setAttribute('value', companyid);
        f.appendChild(c);
        var p = document.createElement('input');
        p.setAttribute('type', 'hidden');
        p.setAttribute('name', 'page');
        p.setAttribute('value', page);
        f.appendChild(p);
        var t = document.createElement('input');
        t.setAttribute('type', 'hidden');
        t.setAttribute('name', 'm');
        t.setAttribute('value', matterid);
        f.appendChild(t);
      }
      var s = document.createElement('input');
      s.setAttribute('type', 'hidden');
      s.setAttribute('name', 'authenticity_token');
      s.setAttribute('value', authenticity_token);
      f.appendChild(s);
      f.submit();
    }
    return false;
  }
  return false;
}

function check_uncheck_all(parentid, checkboxes){
  var parent_checkbox = $("#"+parentid)
  var sub_checkboxes = $("."+checkboxes)
  parent_checkbox.click(function(){
    var checked_status = this.checked;
    sub_checkboxes.each(function(){
      this.checked = checked_status;
    });
  });
  sub_checkboxes.click(function(){
    var checked_status = 0;
    sub_checkboxes.each(function(){
      if(this.checked){
        checked_status += 1;
      }else{
        parent_checkbox.removeAttr("checked");
      }
    });
    if(sub_checkboxes.length == checked_status){
      parent_checkbox.attr("checked", checked_status);
    }
  });
}

jQuery(function(){
  jQuery('#employee_is_firm_manager').change(function(e){
    if(e.target.checked){
      jQuery('.firm_manager_plge').show();
    }else{
      jQuery('.firm_manager_plge').hide();
      jQuery('#employee_can_access_matters').attr('checked',false);
      jQuery('#employee_can_access_t_and_e').attr('checked',false);
    }
  });
});

function addCommas(num){
  var number = parseFloat(num).toFixed(2)+'',
  rgx = /(\d+)(\d{3}[\d,]*\.\d{2})/;
  while (rgx.test(number)) {
    number = number.replace(rgx, '$1' + ',' + '$2');
  }
  return number;
}

function doc_manager_get_children(selected_node, folder_id){
  jQuery('#perpage_loader').show();
  var node
  if(folder_id==''){
    node = selected_node
  }else{
    if(selected_node.match(/recycle_bin/)){
      selected = "recycle_bin";
    }else{
      node = selected_node.split("_");
      selected = node[0]
    }
    node = selected+"_"+folder_id
  }
  jQuery.ajax({
    type: 'GET',
    url: '/document_managers/documents_list',
    data : {
      'selected_node': node
    },
    success: function(transport){
      jQuery('#resultant-content').html(transport);
    }
  });
}

function document_manager(selected_node,url){
  jQuery('#perpage_loader').show();
  var path_url = url
  var data_1 = {
    'selected_node': selected_node
  }
  jQuery.get(
    path_url ,data_1    ,
    function (data) {
      jQuery('#resultant-content').html(data);
      enable_search();
      jQuery('#perpage_loader').hide();
    });
}

function validate_email_doc_form(button){
  var msg = "";
  var value = jQuery.trim(jQuery("#email_to").val());
  var result = value.split(",");
  for(var i = 0; i < result.length; i++){
    if(!validateEmail(jQuery.trim(result[i]))){
      msg = "Invalid Email ID(s)<br/>";
    }
  }
  if((jQuery.trim(jQuery("#email_to").val())=="")){
    msg = "Email can't be blank<br/>";
  }
  //
  if (jQuery.trim(jQuery("#email_subject").val())==""){
    msg += "Document Name can't be blank<br/>";
  }
  if (jQuery.trim(jQuery("#email_description").val())==""){
    msg += "Description can't be blank<br/>";
  }

  if (msg!="" ){
    show_error_msg('error_explanation',msg,'message_error_div');
    return false;
  }
  disableAllSubmitButtons(button);
  jQuery('.sp-loader').show();
  return true;
}

function validateEmail(field){
  var regex = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
  if(!regex.test(field)){
    return false;
  }
  return true;
}

//Functions added for the Feature No 10006
function createNewonClick(){
  jQuery("#_contact_ctl").hide();
  jQuery("#create_new_span").hide();
  jQuery("#required").hide();
  jQuery("#_contact_ctl").val('');
  jQuery("#check_exising").val('false');
  jQuery("#TB_ajaxContent").height('500px');
  jQuery("#create_new_div").show();
  jQuery("#create_from_existing_div").hide();
  jQuery("#create_new_span").html("Create New");
  jQuery("#select_exist_td").html(jQuery("<a class='link_blue' href='#' onclick='return selectExisitingonClick()'>Select from Existing</a>"));
  return false;
}
function selectExisitingonClick(){
  jQuery("#_contact_ctl").show();
  jQuery("#create_new_span").show();
  jQuery("#required").show();
  jQuery("#create_new_div").hide();
  jQuery("#check_exising").val('true');
  jQuery("#create_from_existing_div").show();
  jQuery("#select_exist_td").html("Select from Existing <span class='alert_message'>*</span>");
  jQuery("#create_new_span").html(jQuery("<a class='link_blue' href='#' onclick='return createNewonClick()'>Create New</a>"));
  jQuery("#TB_ajaxContent").height('125px');
  return false;
}

function add_matter_people_form_loading(){
  jQuery("#TB_ajaxContent").height('125px');
  jQuery('#added_to_contact').click(function() {
    jQuery('#hidden_added_to_contact').val(jQuery('#added_to_contact').attr('checked'));
  });
  jQuery("#_contact_ctl").val("Search Existing");
  jQuery('#_contact_ctl').click(function() {
    if(jQuery("#_contact_ctl").val()=='Search Existing')
      jQuery("#_contact_ctl").val('');
  });
  jQuery('#_contact_ctl').blur(function() {
    if(jQuery("#_contact_ctl").val()=='')
      jQuery("#_contact_ctl").val('Search Existing');
  });
}

function check_contact() {
  if(jQuery("#_contact_ctl").val()=='Search Existing'){
    errors = "<ul>" + "<li>" + "Please enter valid contact" + "</li>" + "</ul>"
    show_error_msg('matter_people_errors',errors,'message_error_div');
    jQuery('#loader').hide();
    disableWithPleaseWait('add_matter_people_button', false, 'Save');
    return false;
  }else if((jQuery("#_contactid").val()=="")&&(jQuery(".existing_check").val()=="true")){
    errors = "<ul>" + "<li>" + "Contact doesn't exist" + "</li>" + "</ul>"
    show_error_msg('matter_people_errors',errors,'message_error_div');
    jQuery('#loader').hide();
    disableWithPleaseWait('add_matter_people_button', false, 'Save');
    return false;
  }else{
    return checkloader();
  }
}

//Functions added for the Feature No 10006 end here
function enable_secondary(){
  if(jQuery('#tne_invoice_setting_secondary_tax_enable').is(':checked')){
    jQuery('.ste').show();
  }else{
    jQuery('.ste').hide();
  }
}

function enable_primary(){
  if(jQuery('#tne_invoice_setting_primary_tax_enable').is(':checked')){
    jQuery('.pte').show();
    enable_secondary();
  }else{
    jQuery('.pte').hide();
    jQuery('.ste').hide();
    jQuery('#tne_invoice_setting_secondary_tax_enable').attr("checked",false);
  }
}

// Replaces "&amp;" in a given string with "&" and returns the result.
function fixAmpersand(str){
  str = str.replace(/&amp;/g, "&");
  return str;
}

function matterToePopup(){
  alert("Terms of Engagement is not attached...!");
}

// validation for non-numberic, negative number, round-off and handling NaN exception-Feature #10272
function convertTOFloat(id){
  var value = jQuery(id).val();
  new_value= parseFloat(value).toFixed(2);
  jQuery(id).val(new_value);
  if (value < 0) {
    jQuery(id).val('0.00');
    alert("Please enter positive value");
    return;}
  if(isNaN(value) == true){
    jQuery(id).val('0.00');
    alert("Please enter numeric value");
  }
}

// validation for tax rate should not be grator than 100 -Feature #10272
function check_tax_rate(text, rate){
  if (text.value=="") {
    text.value = "0.00";
    alert("Rate cannot be blank");
  }if(parseFloat(text.value) > 100){
    text.value = rate;
    alert("Please enter valid rate");
  }
}

function set_flag(matter_view){
  if (matter_view==true){
    flag=true;
  }else if(matter_view==false){
    flag=false;
  }
}

/* Added by Kalpit patel 24/10/2011
 * plupload--Feature 8375
 * Variables used.
 * path : for redirecting to method
 * return_path : for redirdirecting it to landing page
 * authenticity_token : for authenticity it is passed in params
 * params : params to be send to a particular method
 * description : Intialize empty string  on change for a tectbox of description value will be intialize
 * tag_array : Intialize empty string  on change for a tectbox of tag value will be intialize
 * categories : Intailze a dropdown default value
 * extendedparams : It used to add extra params
 * workspaceparams : Intialze params that need to be sent when plupload is called from workspace
 * toeparams : Intialze params that need to be sent when plupload is called from Terms Of Engagement(matters)
 * repositoryparams : Intialze params that need to be sent when plupload is called from Repository
 * commonparams : Intialze params that need to be sent when plupload is called from common place like (contacts,accounts,opportunity...)
 * matterdocparams : Intialze params that need to be sent when plupload is called from matter document
 */
jQuery(function(){
  jQuery("#upload_multi").live('click', function(event){
    event.preventDefault();
    var stop = false;
    var path = jQuery("#upload_multi").attr('path')
    var return_path = jQuery("#upload_multi").attr('return_path')
    var authenticity_token=jQuery("#upload_multi").attr('authenticity_token')
    var params = {}
    var description = ""
    var tag_array = ""
    var categories = jQuery('#categories_combo').val()
    var extendedparams = {}
    var title = "File(s) Upload";
    var custom_title = jQuery("#upload_multi").attr('custom_title');
    if (custom_title != undefined)
        {
        title = title + " for " + custom_title;
        }

    jQuery('#categories_combo').change(function() {
      categories = jQuery('#categories_combo').val()
    });
    jQuery('#tag_array').change(function() {
      tag_array = jQuery('#tag_array').val()
    });
    jQuery('#description').change(function() {
      description = jQuery('#description').val()
    });
    var workspaceparams = {
      'parent_folder_id' : jQuery("#upload_multi").attr('parentid'),
      'current_user_id' : jQuery("#upload_multi").attr('current_user_id'),
      'employee_user_id': jQuery("#upload_multi").attr('employeeuserid'),
      'company_id' : jQuery("#upload_multi").attr('company_id'),
      'document_home[tag_array]':'',
      'description': '',
      'authenticity_token' : authenticity_token
    }
    var toeparams = {
      'matter_id' : jQuery("#upload_multi").attr('matter_id'),
      'current_user_id' : jQuery("#upload_multi").attr('current_user_id'),
      'employee_user_id': jQuery("#upload_multi").attr('employeeuserid'),
      'company_id' : jQuery("#upload_multi").attr('company_id'),
      'authenticity_token' : authenticity_token,
      'document_home[document_attributes][tag_array]' : '',
      'document_home[tag_array]':'',
      'description': ''
    }
    var repositoryparams = {
      'parent_folder_id' : jQuery("#upload_multi").attr('parentid'),
      'current_user_id' : jQuery("#upload_multi").attr('current_user_id'),
      'employee_user_id': jQuery("#upload_multi").attr('employeeuserid'),
      'company_id' : jQuery("#upload_multi").attr('company_id'),
      'authenticity_token' :authenticity_token,
      'category_id' : jQuery('#categories_combo').val()
    }
    var commonparams={
      'current_user_id' : jQuery("#upload_multi").attr('current_user_id'),
      'employee_user_id': jQuery("#upload_multi").attr('employeeuserid'),
      'owner_user_id=': jQuery("#upload_multi").attr('owner_user_id'),
      'company_id' : jQuery("#upload_multi").attr('company_id'),
      'document_home[mapable_id]' : jQuery("#upload_multi").attr('mappable_id'),
      'from' : jQuery("#upload_multi").attr('from'),
      'time_entry_date' : jQuery("#upload_multi").attr('time_entry_date'),
      'document_home[tag_array]':'',
      'description': ''
    }
    set_parameters();
    var client_access = 0
    var enforce_version_change = 0
    var access_right = jQuery('#access_control_matter_view').val();
    if (jQuery('#access_control_private').attr('checked')== true){
      access_right =jQuery('#access_control_private').val();
    }else if(jQuery('#access_control_selective').attr('checked')== true){
      access_right =jQuery('#access_control_selective').val();
    }else if(jQuery('#access_control_matter_view').attr('checked')== true){
            access_right =jQuery('#access_control_matter_view').val();
    }else if(jQuery('#access_control_public').attr('checked')== true){
            access_right =jQuery('#access_control_public').val();
    }
        function set_parameters(){
            if (jQuery('#document_home_client_access').attr('checked')){
                client_access = 1;
            }
            if (jQuery('#enforce_version_change').attr('checked')){
                enforce_version_change = 1;
            }

            var matter_people_ids= [];
            jQuery('#selective :input[type=checkbox]').each(function(){
                if(jQuery(this).attr('checked')){
                    matter_people_ids.push(this.value);
                }
            });
            var mpi = matter_people_ids.toString();
            extendedparams={
                'document_home[document_attributes][doc_type_id]' : jQuery('#document_home_document_attributes_doc_type_id').val(),
                'document_home[document_attributes][privilege]' : jQuery('#document_home_document_attributes_privilege').val(),
                "document_home[document_attributes][description]" : jQuery('#document_home_document_attributes_description').val(),
                "document_home[document_attributes][author]" : jQuery('#document_home_document_attributes_author').val(),
                "document_home[document_attributes][doc_source_id]" : jQuery('#document_home_document_attributes_doc_source_id').val(),
                "document_home[document_attributes][bookmark]" : jQuery('#bookmark').attr('checked'),
                "document_home[client_access]" : client_access,
                "document_home[enforce_version_change]" : enforce_version_change,
                'access_control': access_right,
                'document_home[repo_update]' : jQuery('#document_home_repo_update').val(),
                'document_home[owner_user_id]' : jQuery('#document_home_owner_user_id').val(),
                'document_home[tag_array]' : jQuery('#document_home_tag_array').val(),
                'document_home[matter_people_ids][]' : mpi,
                "document_home[matter_task_ids][]":jQuery("#upload_multi").attr('document_home_matter_task_ids'),
                "document_home[matter_fact_ids][]":jQuery("#upload_multi").attr('document_home_matter_fact_ids'),
                "document_home[matter_risk_ids][]":jQuery("#upload_multi").attr('document_home_matter_risk_ids'),
                "document_home[matter_research_ids][]":jQuery("#upload_multi").attr('document_home_matter_research_ids'),
                "document_home[matter_issue_ids][]":jQuery("#upload_multi").attr('document_home_matter_issue_ids')
            }
         }
     
         if (jQuery('#document_home_client_access').attr('checked')){
            client_access = 1;
        }
        var matterdocparams={
            "document_home[folder_id]": jQuery("#upload_multi").attr('parentid'),
            'current_user_id' : jQuery("#upload_multi").attr('current_user_id'),
            'employee_user_id': jQuery("#upload_multi").attr('employeeuserid'),
            'company_id' : jQuery("#upload_multi").attr('company_id'),
            'matter_id' : jQuery("#upload_multi").attr('matter_id'),
            'access_control': access_right
        }
        if (event.target.id=='matter' || event.target.id=='matter_tabs')
        {
            params = matterdocparams
            default_radio_select();
        }
        else if (event.target.id=='common')
        {
            params = commonparams
        }
        else if (event.target.id=='workspace')
        {
            params = workspaceparams
        }
        else if (event.target.id=='repository')
        {
            params = repositoryparams
        }
        else if (event.target.id=='toe')
        {
            params = toeparams
        }
        // var authtoken = $("input[name=authenticity_token]").val();
        tb_show(title, "#TB_inline?height=425&width=950&inlineId=mass_upload", "");
        var original_tb_remove = tb_remove;
        tb_remove = function () { // This function overides the tb_remove method of thickbox and disables the esc button for mass upload thickbox
            if(keycode == 27){ // close
                return false;
            }
            original_tb_remove();
            return false;
        }
        jQuery('#TB_closeWindowButton').click(function(){
           window.location.href = return_path ;
        });
        jQuery('#TB_overlay').unbind('click');
        jQuery('#document_home_document_attributes_doc_type_id').change(function() {
            set_parameters();
        });
        jQuery('#document_home_document_attributes_privilege').change(function() {
            set_parameters();
        });
        jQuery('#document_home_document_attributes_description').change(function() {
            set_parameters();
        });
        jQuery('#document_home_document_attributes_author').change(function() {
            set_parameters();
        });
        jQuery('#document_home_document_attributes_doc_source_id').change(function() {
            set_parameters();
        });
        jQuery('#bookmark').change(function() {
            set_parameters();
        });
        jQuery('#document_home_repo_update').change(function() {
            set_parameters();
        });
        jQuery('#document_home_owner_user_id').change(function() {
            set_parameters();
        });
        jQuery('#document_home_tag_array').change(function() {
            set_parameters();
        });
        jQuery('#enforce_version_change').change(function() {
            set_parameters();
        });
        jQuery('#access_control_matter_view, #access_control_selective, #access_control_private, #access_control_public').change(function() {
            access_right = jQuery(this).val();
            set_parameters();

        });
        jQuery('#document_home_client_access').change(function() {
            set_parameters();
        });
        jQuery('#selective :input[type=checkbox]').each(function(){
            jQuery(this).change(function() {
                alert(console.log(this));
            set_parameters();
            });
        });
        jQuery('#uploader').plupload('resetQueue')
        var myupload = jQuery("#uploader").plupload({
            runtimes : 'html5,flash,silverlight,gears,browserplus',
            url : path+ stop,
            max_file_size : '50mb',
            multipart : true,
            urlstream_upload: true,
            return_path : return_path,
            prevent_duplicates : true,
            multipart_params : params,
            flash_swf_url : '/javascripts/plupload/js/plupload.flash.swf',
            silverlight_xap_url : '/javascripts/plupload/js/plupload.silverlight.xap',
            init: {
                BeforeUpload: function(up,file){
                    if (event.target.id=='matter' || event.target.id=='matter_tabs'){
                        jQuery.extend(up.settings.multipart_params,extendedparams );
                    }
                    else if (event.target.id=='toe'){
                        jQuery.extend(up.settings.multipart_params,{
                            'document_home[tag_array]' : tag_array,
                            'description': description
                        });
                    }
                    else if(event.target.id=='repository'){
                        jQuery.extend(up.settings.multipart_params,{
                            'category_id' : categories,
                            'tag_array' : tag_array,
                            'description': description
                        });
                    }
                    else {
                        jQuery.extend(up.settings.multipart_params,{
                            'document_home[tag_array]' : tag_array,
                            'description': description
                        });
                    }
                },

                FileUploaded: function(up, file, info) {
                    eval(info["response"]);
                },
                UploadComplete: function(up, files, info) {
                    if (event.target.id=='common' || event.target.id=='toe' || event.target.id=='matter_tabs'){
                        window.location.href = return_path ;
                    }else if(event.target.id=='workspace'){
                        tb_remove();
                        jQuery('#uploader').html('');
                        jQuery('.mandatory').html('');
                        jQuery.ajax({
                            url : return_path,
                            type : 'GET',
                            success : function(transport){
                                jQuery('#resultant-content').html(transport);
                                show_error_msg('altnotice', files.length + ' File(s) uploaded successfully' ,'message_sucess_div');
                            }
                        });
                    }
                    else{
                        window.location.href = return_path + files.length;
                    }
                }
            },
            rename : true
        });
      });
 });

// Added by Kirti Parihar to fix Bug #11305
// Validation for duration field: restrict alphabets and restrict key press after decimal depands on duration setting condition.
// Condition: If duration setting is 1/10th then duration textbox accept 1 digit after precision else 2 digit after precision.
// Parameters: myfield is textbox object, e is event fired, isOne100th returens true if duration setting is 1/100th else return false.
function durationInputValidation(myfield, e,isOne100th) {
    if (!e) var e = window.event;
    if (e.keyCode) code = e.keyCode;
    else if (e.which) code = e.which;
    var character = String.fromCharCode(code);
    x = myfield.value;
    arr = jQuery(myfield).val().split(".");
    limit = isOne100th ? 1 : 0 ;
    if (character.match(/[0-9\.]/g) || (code=8)) {
        // ignore if press delete key, backspace key, left arrow key and right arrow key.
        if ((code!=8 && code!=37 && code!=39 && code!=46 && arr.length > 1 && arr[1].length > limit)) {
            myfield.value=x;
            return false;
        }
        else {
            return true;
        }
    } else {
        return false;
    }  
}

jQuery(function(){
    jQuery('#use_financial_account').live('change',function(e){
        elems = jQuery('.display_false');
        if(e.target.checked){
            elems.show();
        }else{
            elems.hide();
        }//end if
    });
});

function activate_user_employee(company_id, id, path){
  jQuery.ajax({
    type: "GET",
    url: "/"+path,
    dataType: 'script',
    data: {
      'company_id' : company_id,
      'id' : id
    }
  });
}

//
function assign_release_moduleaccess(subproduct_id, path){
  if (subproduct_id == "") {
    return;
  }
  loader.prependTo("#spiner")
  jQuery.ajax({
    type: "POST",
    url: path,
    dataType: 'script',
    data: {
      "subproduct_id" : subproduct_id
    },
    success: function(){
      loader.remove();
    }
  });
}

function redirect_to_path_for_company( company_id, action ){
  jQuery.ajax({
    type: "GET",
    url: "/"+action,
    dataType: 'script',
    data: {
      'company_id' : company_id
    }
  });
}

function fetch_data_based_for_company( company_id, divid, path ){
  if( company_id == "" ){
    return false
  }
  loader.prependTo("#"+divid)
  jQuery.ajax({
    type: "POST",
    url: "/"+path,
    dataType: 'script',
    data: {
      'company_id' : company_id
    },
    success: function(){
      loader.remove();
    }
  });
}

// Combined function unassignsubproduct() and reassignsubproduct()
function unassign_reassign_subproduct(pl_id, sub_id, user_id, company_id, div_id, path){
  if (pl_id==""){
    return false
  }
  loader.prependTo("#subproductdiv")
  jQuery.ajax({
    type: "POST",
    url: path,
    dataType: 'script',
    data: {
      'pl_id' : pl_id,
      'sub_id' : sub_id,
      'company_id' : company_id,
      'user_id' : user_id
    },
    success: function(){
      loader.remove();
      jQuery("#"+div_id+"_subproduct").toggle();
    }
  });
}

// Combined function assignSubproducts_to_secretary() and unassignSubproducts_from_secretary()
function assign_unassign_subproducts_to_secretary(user_id, company_id, clas, alrt, path){
  var subproducts = "";
  var elems = jQuery("."+clas);
  var isNoneChecked = true;
  for (var i = 0; i < elems.length; i++ ) {
    if (elems[i].checked) {
      subproducts += elems[i].value + ",";
      isNoneChecked = false;
    }
  }
  if (isNoneChecked) {
    alert("Please Select Any Module to "+alrt+".");
    return;
  }
  loader.prependTo("#accessdetail");
  jQuery.ajax({
    type: "POST",
    url: path,
    dataType: 'script',
    data: {
      "subproducts" : subproducts,
      "user_id" : user_id,
      "company_id" : company_id
    }
  });
}

// Combined function adddependent(), deletedependent(), addsubproduct() and deletesubproduct()
function add_delete_items(item_id, select_id, other_item_id, path, type){
  var selectedproducts = [];
  jQuery('#'+select_id+' :selected').each(function(i, selected){
    selectedproducts = selectedproducts +','+ jQuery(selected).val();
  });
  jQuery.ajax({
    type: type,
    url: path,
    dataType: 'script',
    data: {
      'selectedproducts' : selectedproducts,
      'product_id' : item_id
    },
    success: function() {
      jQuery.each(selectedproducts,function(index, value){
        return !jQuery('#'+select_id+' option:selected').appendTo('#'+other_item_id);
      });
    }
  });
}

// Combined function showclients(), show_company_rate_card(), showusers() and update_company_header()
function show_data_for_record(id, div_id, type, path){
  if(id == ""){
    return false
  }
  loader.prependTo("#"+div_id)
  jQuery.ajax({
    type: type,
    url: path,
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

// function enable_payment()
function display_div(div){
  jQuery(div).show();
}

// Shifted from both application.js as duplicated
function checkinput(){
  var returnlic;
  var returnprod;
  var returnvalue;
  returnlic = checkinputlicence();
  returnprod = checkinputprod();
  returnvalue = (returnlic && returnprod)
  return returnvalue
}

function checklicenceinput(){
  var returnprod = document.getElementById('role_assign_licence_id')
  if(returnprod==null){
    return false;
  }
  return true;
}

function checkinputlicence(){
  var returnvalue;
  var arr = jQuery('.liccombo').serializeArray()
  jQuery.each(arr,function( i, n ){
    if (n.value==''){
      returnvalue= false;
    }else{
      returnvalue=true;
      return false;
    }
  });
  return returnvalue
}

function checkinputprod(){
  var returnvalue;
  var arr = jQuery('.prodcombo').serializeArray();
  jQuery.each(arr,function(i,n){
    if (n.value==''){
      returnvalue= false;
    }else{
      returnvalue=true;
      return false;
    }
  });
  return returnvalue
}

function set_matter_people_end_date(elem){
  if (elem.checked){
    jQuery('#matter_people_end_date').val('');
  }else{
    var a = today_date();
    var m = a.getMonth()+1;
    m = m < 10 ? '0'+m : m;
    var d = a.getDate();
    d = d < 10 ? '0'+d : d;
    var y = a.getFullYear();
    jQuery('#matter_people_end_date').val(m + '/' + d + '/' + y);
  }
}

function financial_account_company(id){
   loader.prependTo("#spinner_div")
    jQuery.ajax({
        type: "GET",
        url: "/financial_accounts?company_id="+id,
        dataType: 'script',
        success: function(){
            loader.remove();
        }
    });
}//end trust_account_company()
