/* for matters view*/
function showHideLitigation(show) {
    if (show) {
        jQuery('#litigation').show();
        jQuery("#matter_type").html('');
        jQuery('#matter_type_liti').show();
        jQuery('#matter_type_nonliti').hide();        
    } else {
        jQuery('#litigation').hide();
        jQuery("#matter_type").html('');
        jQuery('#matter_type_liti').hide();
        jQuery('#matter_type_nonliti').show();
    }
}

function updatename(fName,elementid){
    fullName = fName;
    shortName = fullName.match(/[^\/\\]+$/);
    document.getElementById(elementid).value = shortName
}

function openDocPop() {
    window.open(
        "/documents/new",
        "docs",
        "height=400,width=700,status=no,menubar=no,location=no,toolbar=no,scrollbars=yes"
        );
}
  
/*start - scripts for the contact views*/
/*call at the time of contact edit view load*/
function contact_edit_init(){
    jQuery('#account_id').attr("disabled", true);
}


jQuery(function() {
    // unobtrusive javascripts
    // Contact --Index -- by Sanil
    jQuery(".selContact").click(function() {
        getContactsAll(this.value)
    });
    // Contact --new
    jQuery("#account_selector").click(function() {
        account_combo_toggle(this.value)
        return false
    });
    jQuery("#contact_do_not_call").click(function() {
        //jQuery(".warningSpan").attr("onclick","showalert()");
        });
});


/*for contact controller*/
function account_combo_toggle() {
    var content = jQuery("#account_selector").text();
    if(content == "Create New") {
        var value_sel = "Select Existing"
        jQuery("#account_selector").text(value_sel);
        jQuery("#account_id").attr('disabled',true)
        jQuery("#account_id").hide();
        jQuery("#account_name").val();
        jQuery("#account_name").attr('disabled',false)
        jQuery("#account_name").show();
    }else {
        var value_create = "Create New"
        jQuery("#account_selector").text(value_create);
        jQuery("#account_name").attr('disabled',true)
        jQuery("#account_name").hide();
        jQuery("#account_id").attr('disabled',false)
        jQuery("#account_id").show();
    }
}

function contact_combo_toggle() {
    var content = jQuery("#contact_selector").text();
    if(content == "Create New") {
        jQuery('#contact_lead_type_1').attr('disabled', false);
        var value_sel = "Select Existing"
        jQuery("#contact_selector").text(value_sel);
        jQuery("#contact_name").attr('disabled',false)
        jQuery(".disundis").attr("disabled", false);
        jQuery("#contact_name").show();
        jQuery("#contact_id").attr('disabled', true);

    }else {
        var value_create = "Create New"
        jQuery("#contact_selector").text(value_create);
        jQuery('#contact_lead_type_1').attr('disabled', true);
        jQuery(".disundis").attr("disabled", "disabled");
        jQuery("#contact_name").hide();
        jQuery("#contact_id").attr('disabled', false);
    }
}

/*In contact for change_status*/
function validate_field(field_id,msg){  
    var field_value=jQuery.trim('#'+field_id).val();
    field_value = jQuery.trim(field_value)
    if (field_value==""){
        jQuery('#nameerror').children('div').html(msg);
        jQuery('#nameerror').show();
        return false
    }
    else{
        return true
    }
}

/*In contact for _create_opportunity*/
function validate_name(){
    var oppname=jQuery('#opportunity_name').val();
    if (oppname==""){
        jQuery('#nameerror').html("<div class='errorCont'>Please enter Opportunity Name</div>");
        return false;
    }
    else{
        return true;
    }
}

/*In contact for _create_opportunity*/
function clear_account_id(){
    var contactname=jQuery('#_contact_ctl').val();
    alert(contactname);
    if (contactname==""){
        alert('yesss');
        jQuery('_contactid').val=null;
      
    }
    return true
}
/*end - scripts for the contact views*/


/*start - scripts for the campaign views*/

function switch_create_campaign(selector){
    if (selector=='new')
    {
        jQuery('#existing_campaign').hide();
        //jQuery('#campaign_id').disabled=true;
        jQuery('#campaign_name').val="";
        jQuery('#method').val='post'
        jQuery('#campFORM' + ' :input').each(function()
        {
            if(this.type=='text' || this.type=='textarea' && this.type!='hidden'){
                jQuery(this).val('');
            }
        });       
    }
    else
    {
        jQuery('#existing_campaign').show();
        jQuery('#campaign_id').disabled=false;
    }
}

function switch_upload(file, link){
    
    if (file)
    {
        jQuery('#file_label').show();
        jQuery('#file_attr').show();
        jQuery('#link_label').hide();
        jQuery('#link_attr').hide();

    }
    if(link)
    {
        jQuery('#link_label').show();
        jQuery('#link_attr').show();
        jQuery('#file_label').hide();
        jQuery('#file_attr').hide();
    }
}

function getCampaigns(type,camp_status) {
    //var selContact = jQuery("input[name='selContact']:checked").val();
    document.location.href = "/campaigns?mode_type="+type+"&camp_status="+camp_status;
}
function getManagedCampaigns(type,camp_status) {
    //var selContact = jQuery("input[name='selContact']:checked").val();
    document.location.href = "/campaigns/manage_campaigns?mode_type="+type;
}

function validateFile(){
    var filename=document.getElementById("import_file").value;
    if (filename=="")
    {
        alert("Please input a filename");
        return false;
    }
    else
    {
        arr = filename.split(".");
        exten = arr[arr.length -1].toUpperCase()
        if (!(exten =="CSV"))
        {
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
        if(recs[i] == this)

        {
            recs[i].checked = true
        }
        else
        {
            recs[i].checked = false
        }
    }
}
function validateImportFile(){
    var filename=document.getElementById("import_file").value;
    var fileformat=document.getElementById("file_format").value
    
    if (filename=="")
    {
        alert("Please select a file to import");
        return false;
    }
    else
    {
        arr = filename.split(".");
        exten = arr[arr.length -1].toUpperCase()
        if(fileformat=="CSV")
        {
            if (!(exten =="CSV" || exten =="VCF"))
            {
                alert("Please specify valid filename");
                return false;
            }
        }
        if(fileformat=="XLS")
        {
            if (!(exten =="XLS" ||exten =="XLSX" ||exten =="ODS"))
            {
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
    notes_div = jQuery('#notes');
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
    //var selContact = jQuery("input[name='selContact']:checked").val();
    document.location.href = "/opportunities?mode_type="+type+"&opp_status="+opp_status+"&opp_stage="+opp_stage;
}

function initCampaignsOpportunityToggle1() {
    jQuery("#prospectsdiv").hide();
    jQuery("#prospectsToggle").click(function(){
        jQuery("#prospectsdiv").toggle();
        jQuery(".toggle_prospects").toggle();
    });
    jQuery("#proposaldiv").hide();
    jQuery("#proposalToggle").click(function(){
        jQuery("#proposaldiv").toggle();
        jQuery(".toggle_proposal").toggle();
    });
    jQuery("#negotiationdiv").hide();
    jQuery("#negotiationToggle").click(function(){
        jQuery("#negotiationdiv").toggle();
        jQuery(".toggle_negotiation").toggle();
    });
    jQuery("#finalreviewdiv").hide();
    jQuery("#finalreviewToggle").click(function(){
        jQuery("#finalreviewdiv").toggle();
        jQuery(".toggle_finalreview").toggle();
    });
    jQuery("#closedwondiv").hide();
    jQuery("#closedwonToggle").click(function(){
        jQuery("#closedwondiv").toggle();
        jQuery(".toggle_closedwon").toggle();
    });
    jQuery("#closedlostdiv").hide();
    jQuery("#closedlostToggle").click(function(){
        jQuery("#closedlostdiv").toggle();
        jQuery(".toggle_closedlost").toggle();
    });
    jQuery("#inprogressdiv").hide();
    jQuery("#inprogressToggle").click(function(){
        jQuery("#inprogressdiv").toggle();
        jQuery(".toggle_inprogress").toggle();
    });
    jQuery("#planneddiv").hide();
    jQuery("#plannedToggle").click(function(){
        jQuery("#planneddiv").toggle();
        jQuery(".toggle_planned").toggle();
    });
    jQuery("#completeddiv").hide();
    jQuery("#completedToggle").click(function(){
        jQuery("#completeddiv").toggle();
        jQuery(".toggle_completed").toggle();
    });
    jQuery("#aborteddiv").hide();
    jQuery("#abortedToggle").click(function(){
        jQuery("#aborteddiv").toggle();
        jQuery(".toggle_aborted").toggle();
    });
    jQuery("#searchlistToggle").hide();
}

function matterAddComment(comment_user_id,comment_commentable_id,comment_commentable_type,comment_title){

    var user_id = comment_user_id;
    var commentable_id = comment_commentable_id;
    var commentable_type = comment_commentable_type;
    var priv = false;
    var title = comment_title;
    var comment = jQuery("#matter_comment").val();

    jQuery.post("/comments/add_new_comment",
    {
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

//surekha adding matter comment in CGC module
function cgcMatterAddComment(comment_company_id,comment_user_id,comment_commentable_id,comment_commentable_type,comment_title){
    var company_id = comment_company_id;
    var user_id = comment_user_id;
    var commentable_id = comment_commentable_id;
    var commentable_type = comment_commentable_type;
    var priv = false;
    var title = comment_title;
    var comment = jQuery("#matter_comment").val();

    jQuery.post("/comments/add_new_comment",
    {
        "company_id" : company_id,
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
function startEndTimeFormat(id) {
    //    isFlag = isFlag != null && isFlag !="" ? isFlag : false;
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
/* Matter Task start and end time picker settings. */
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

/* Set matter task appointees autocomplete */
function matter_task_attendees_autocomplete(cid, attendees_email){
    jQuery(document).ready(function(){
        var url = "/contacts/attendees_autocomplete";
        var comma = ",";
        jQuery("#"+attendees_email).autocomplete(url, {
            multiple : true,
            multipleSeparator : comma,
            cacheLength : 1, // NO CACHE!
            /*formatItem : function(out) {
        var tmp = (out+"").split("/");        
        return tmp[0];
      },
      formatResult : function(out) {
        var tmp = (out+"").split("/");        
        //alert(ids);
        return tmp[0];
      },*/
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
    if(selective)
        jQuery("#selective").show();
    else
        jQuery("#selective").hide();
    if(check_box)
        jQuery("#check_box").show();
    else
        jQuery("#check_box").hide();


}

function hideaccessdetails() {
    jQuery("#selective").hide();
}

function validateNotes() {
    var task_type = jQuery("#task_tasktype option:selected").text();
    var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
    err='';
    if (task_type == "-- Select --") {
        err+="Please select task type";
    }
    if (assigned_to == "-- Select --") {
        err+="<br>Please select assigned to"
    }

    if (err!="")
    {
        jQuery("#notes_errors").html("<div class='errorCont'>"+err+"</div>");
        return false;
    }
    else {
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
    var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
    err='';
    if (task_type == "-- Select --") {
        err+="Please select task type";
    }
    //    if (assigned_to == "-- Select --") {
    //        err+="<br>Please select assigned to"
    //    }

    if (err!="")
    {
        jQuery("#notes_errors").html("<div class='errorCont'>"+err+"</div>");
        return false;
    }
    else {
        tb_remove();
    }
}

function validateTasks() {
    var task_type = jQuery("#task_tasktype option:selected").text();
    var assigned_to = jQuery("#task_assigned_to_user_id option:selected").text();
    err='';
    if (task_type == "-- Select --") {
        err+="Please select task type";
    }
    //    if (assigned_to == "-- Select --") {
    //        err+="<br>Please select assigned to"
    //    }

    if (err!="")
    {
        jQuery("#task_errors").html("<div class='errorCont'>"+err+"</div>");
        return false;
    }
    else {
        tb_remove();
    }
}
 
function maximize_grid(max_img_id,min_img_id){
    $(secretaries_details_img_minus).style.display='none';
    $(max_img_id).style.display='none';
    $(min_img_id).style.display='block';
}

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


function myPasswordSubmit() {
    f = document.getElementById("pf");
    var cpass = jQuery("#current_password").val();
    var npass = jQuery("#password").val();
    var npass2 = jQuery("#password_confirmation").val();
    jQuery("#password_errors").hide();
    loader.appendTo("#loader_spinner");
    jQuery.post("/users/change_password",
    {
        "current_password" : cpass,
        "user[password]" : npass,
        "user[password_confirmation]" : npass2
    },
    function(out) {
        jQuery("#loader_spinner").html("");
        if (out != "") {
            jQuery("#password_errors").html(out);
            jQuery("#password_errors").show();
        } else {
            closeFaceBox();
            window.location = "/logout?change_password=true";
        }
    });
    return false;
}

function submitMe(f) {
    tb_remove();
    f.submit();
    return false;
}

/* Submit the password reset form using jQuery-AJAX, handle and display error
     * messages. */
function submitPasswordReset(id) {
    var npass = jQuery("#reset_password").val();
    var npass2 = jQuery("#reset_password_confirmation").val();
    jQuery.post("/users/reset_password/" + id, {
        "user[password]" : npass,
        "user[password_confirmation]" : npass2
    },
    function(out) {
        
        if (out != "") {
            //alert(out);
            loader.remove();
            jQuery("#reset_password_errors").html(out);
            //jQuery("#reset_password_errors").show();
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


/* Submit the tpin reset form using jQuery-AJAX, handle and display error
     * messages. */
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
        jQuery("#datepicker").datepicker(
        {
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

function appointments_grid_init(){
    var spanID = "";
    jQuery.noConflict();
    jQuery(function(jQuery) {
        //run the currently selected effect
        function runEffect(){
            
            //get effect type from
            var selectedEffect = "blind";
			
            //most effect types need no options passed by default
            var options = {};
            //check if it's scale, transfer, or size - they need options explicitly set
            if(selectedEffect == 'scale'){
                options = {
                    percent: 0
                };
            }
            else if(selectedEffect == 'size'){
                options = {
                    to: {
                        width: 200,
                        height: 60
                    }
                };
            }
            //alert(jQuery(this).attr("id"));
            //var jQueryParser = "#"+spanID+"tec"
            var jQueryParser = "#appointment_"+spanID
            
            //run the effect
            jQuery(jQueryParser).toggle(selectedEffect,options,500);
        };

        //set effect from select menu value
        jQuery("span").click(function() {
            spanID = jQuery(this).attr("id");
            ;
            runEffect();
            return false;
        });
    });
}



function status_change(selected,action,current_value,opportunity, matter)
{
    lead_div = jQuery('#lead');
    prospect_div = jQuery('#prospect');
    notes_div = jQuery('#notes');

    selectedtxt = jQuery('#contact_contact_stage_id option:selected').text();
    if (selectedtxt=='Lead')
    {
        if(matter > 0 || opportunity > 0 )
        {
            alert("It has a related Opportunity or a Matter");
        }
        jQuery('#contact_lead_status').val("11");
        jQuery('#contact_lead_status').attr('disabled',false)
        lead_div.show();
        jQuery('#contact_prospect_status').attr('disabled','disabled')
        prospect_div.hide();
    }
    else{
        lead_div.hide();
        prospect_div.show();
        jQuery('#contact_lead_status').attr('disabled','disabled')
        jQuery('#contact_prospect_status').val("7");
        jQuery('#contact_prospect_status').attr('disabled',false)
    }
    if (selected==current_value){
        notes_div.hide();
    }
    else
    {
        notes_div.show();
    }

    /*
 * This is used for to know whick list box is selected, according to the create a hidden field
 * in the form so that in controll we can descrimate the which is selected
 **/
    jQuery('#selected_list_box').val(selectedtxt);
}

function application_layout_init(){
    jQuery.noConflict();
    jQuery(document).ready(function(){
        initAutoComplete();
        initCampaignsOpportunityToggle();
        initLiviaHint();
        initLiviaFaceBox();
        closeFaceBox();
        rolloverToolTip();

        //initToggle();
        
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

function campaign_layout_init(){
    jQuery.noConflict();
    jQuery(document).ready(function(){
        initLiviaFaceBox();
        initAutoComplete();
        initCampaignsOpportunityToggle();
        initLiviaHint();
        initToggle();
        jQuery("#apptHeader").click(function() {
            jQuery("#appointments").toggle();
            jQuery(".toggle_appt").toggle();
        });
    });
}

function selected_tab(idx){

    jQuery(function() {
        $tabs = jQuery('#child-tabs').tabs({
            cache: true
        });
        $tabs.tabs('select', idx );
    });
}

function matters_layout_init(){
    jQuery.noConflict();
    jQuery(document).ready(function(){
        //initLiviaFaceBox();
        //initAutoComplete();
        initLiviaMatterToggle();
        //initLiviaHint();
        //initToggle();
        jQuery("#apptToggle").click(function() {
            jQuery("#apptContent").toggle();
            jQuery(".toggle_appt").toggle();
        });
    });
}

function intiToggleIt(){
    jQuery("#sumamrygridToggle").click(function(){
        jQuery("#saved_entries_div").toggle();
        jQuery(".toggle_saved_entries").toggle();
    });
}

function timeandexpenses_layout_init(){
    
    jQuery.noConflict();
    jQuery(document).ready(function(){
        intiToggleIt();
        jQuery("#viewHeader").click(function() {
            jQuery("#viewHeaderArea").toggle();
            jQuery(".toggle_view").toggle();
        });
    });    
}

function matter_client_init(){
    jQuery(document).ready(
        function(){
            initLiviaFaceBox();
            initLiviaMatterToggle();
        });
}


function payment_mode_change(selected_value)
{
    jQuery.ajax({
        type: "get",
        url: "/payments/payment_mode_of_selected_id",
        dataType: 'script',
        data: {
            'selected_value' : selected_value
        }
    });
}


//jQuery(function()
//{    jQuery('#compliance_type_id').change(function()
//    {
//        selectedval=jQuery('#compliance_type_id option:selected').val();
//        jQuery.ajax({
//            url: '/compliances/getlookupdata',
//            type: "GET",
//            data: {
//                "id" : selectedval
//            },
//            dataType: "script"
//        });
//			 
//   });

/* fill in the email id of the compliance department owner */ 
//   jQuery('#compliance_compliance_department_id').change(function(){
//   selectedval = jQuery('#compliance_compliance_department_id :selected').val();
//   jQuery.ajax({
//      url: '/compliance_departments/get_owner_email',
//      type: "GET",
//      data: {
//        "id":selectedval
//      },
//      dataType: "script"
//   });     
//  })
//})



jQuery(function()
{
    jQuery('#report_type').change(function()
    {
        selectedval=jQuery('#report_type option:selected').val();
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
/*function update_sub_product(product_id, subproducts)
{
    var chkprd = document.getElementById("chk_" + product_id);
    var sub_prd = product_id + "_product_sub_module";
    var div_subprd = document.getElementById(sub_prd);
    var prd_qty = document.getElementById("product_licence_qty_" + product_id);
    var txtcost = document.getElementById("txtcost_" + product_id);
    var txtrate = document.getElementById("txtrate_" + product_id);
    var totalamt = document.getElementById("txttotalcost");
    var total = 0;
    var total1 = 0;
    if (subproducts!='')
    {
        var sb = subproducts.split(',');        
        for(i=0;i<sb.length;i++)
        {
            var chkdep = document.getElementById("chk_" + sb[i]);
            var depend_mod = document.getElementById(sb[i] + "_product_sub_module");
            var depend_qty = document.getElementById("product_licence_qty_" + sb[i]);
            var txtsubcost = document.getElementById("txtcost_" + sb[i]);
            var txtsubrate = document.getElementById("txtrate_" + sb[i]);
            if (chkprd.checked==true)
            {
                chkdep.checked = true;                
                depend_mod.style.display = 'block';
                depend_qty.value = prd_qty.value;
                txtsubrate.value = (depend_qty.value*txtsubcost.value);
                total = total + parseInt(txtsubrate.value);
            }
            else
            {
                chkdep.checked = false;
                depend_mod.style.display = 'none';
                depend_qty.value = '';
                txtsubrate.value = '';
            }
     
        }
    }
  
    if (chkprd.checked==true)
    {
            div_subprd.style.display = 'block';
            txtrate.value = (prd_qty.value*txtcost.value);
            total1 = parseInt(txtrate.value);
    }
    else
    {
        div_subprd.style.display = 'none';
        prd_qty.value = '';
        txtrate.value = '';
    }    
    totalamt.value = (total+total1);
}*/



/* ======================================== NOTE 19 April 2010 Monday ========================================== 
Some functions for datepickers are now removed from this file.
And livia_datepicker() is added to application.js on 15th April 2010.
And the list is 
1. function campaign_datepicker()
2. function campaign_datepicker() === this function was duplicate copy of previous
3. function campaign_opportunity_datepicker()
4. function edit_opportunity_datepicker()
5. function matter_client_datepicker() --- Added the code again
6. function new_opportunity_datepicker()
7. function new_company_datepicker()
8. function matter_people_start_end_datepicker()
9. function budget_period_from_to_datepicker() 
10.function matter_task_complete_by_datepicker()
11.function matter_task_dates_datepicker()
12.function matter_issue_target_resolution_datepicker()
13.function matter_billing_bill_pay_datepicker()
14.function matter_retainer_datepicker()
======================================= Supriya */

/*For Clients Login it needs the Calender Date:19-04-2010 Author: Madhu*/

function matter_client_datepicker(){
    jQuery.noConflict();
    jQuery(document).ready(function() {
        jQuery("#datepicker").datepicker({
            showOn: 'focus',
            closeAtTop: true,
            buttonImage: '/images/cgc_images/calendar_n.gif',
            buttonImageOnly: true,
            showOtherMonths: true,
            dateFormat: 'yy-mm-dd',
            onSelect: function(value){             
                update_taskdiv(value)
            //jQuery('datepicker_opportunity_new').value =(newdate.getMonth()+1)+'/'+newdate.getDate()+'/'+newdate.getFullYear();

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


jQuery('#open-items-filter').change(function(){
    selected_val = jQuery('#open-items-filter :selected').val();
    alert(selected_val);
    alert(document.location.href);

})

function getCategoryWorktypes(catId)
{
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
    //loader.prependTo("#show_employee_list")
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
