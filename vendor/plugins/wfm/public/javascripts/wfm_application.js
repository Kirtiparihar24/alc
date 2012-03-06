var loader = jQuery("<center><img src='/images/loading.gif' /></center>");
var task_i = 1;
// copy note test to task test on new task page

jQuery(document).ready(function()
{
    jQuery('body').click(function()
    {
        jQuery('.actions').hide('slow');
        jQuery('#lawyer_list_div').slideUp();
    });
    jQuery('#task_due_at').click(function()
    {
      //  jQuery(".due_date").datepicker({ minDate: new Date(2011, 1 - 1, 1) });
    });
    stop_propogating();

   });

function stop_propogating()
{
    jQuery('.actions, .action_pad, #lawyer_list_div, #drop').click(function(event)
    {
        event.stopPropagation();
    });
}

function update_task_text(field,index){
    if(field.checked){
        document.getElementById("tasks_"+index+"_name").value=$("#note_text").val();
    }
    else{
        document.getElementById("tasks_"+index+"_name").value="";
    }
}

function update_work_type_select(category_type,task_index){
    loader.appendTo("#"+task_index+"_loader_img");
    //document.getElementById("tasks_"+task_index+"_work_subtype_id").options.length = 0;
    var el = document.getElementById("tasks_"+task_index+"_work_subtype_id");
    if(el != null){
        el.options.length = 0;
    };
    var el1 = document.getElementById("tasks_"+task_index+"_work_subtype_complexity_id");
    if(el1 != null){
        el1.options.length = 0;
    };
    
    jQuery('#task_'+task_index+'_complexity').hide();
    jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/get_work_types",
        dataType: 'script',
        data: {
            'category_type' : category_type,
            'task_index' : task_index
        },
        success: function(transport)
        {
            loader.remove();
        }

    });
}

function update_work_subtype_select(work_type_id,task_index){
    if (work_type_id == ""){
        document.getElementById("tasks_"+task_index+"_work_subtype_id").options.length = 0;
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_work_subtypes",
            dataType: 'script',
            data: {
                'work_type_id' : work_type_id,
                "task_index" : task_index
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}



function update_complexity_select(work_subtype_id,task_index){
    if (work_subtype_id == ""){
        document.getElementById("task_"+task_index+"work_subtypes").value="";
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_complexities",
            dataType: 'script',
            data: {
                'work_subtype_id' : work_subtype_id,
                "task_index" : task_index
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}


function update_user_select(user_category_type,task_index,employee_user_id){
    if (user_category_type == "CommonPool"){
        document.getElementById("tasks_"+task_index+"_assigned_to_user_id").options.length = 0;
        jQuery("#task_"+task_index+"_user_select").hide();
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery("#task_"+task_index+"_user_select").show();
        work_subtype_id = jQuery("#tasks_"+task_index+"_work_subtype_id").val();
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_users",
            dataType: 'script',
            data: {
                'user_category_type' : user_category_type,
                "task_index" : task_index,
                "work_subtype_id" : work_subtype_id,
                "employee_user_id" : employee_user_id
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}

function display_stt_tat(id,index){
    if (id == ""){

    }
    else{
        $("#complexity_"+id+"_stt_tat_"+index).show();
    }
}


function add_task_form(note_id){
    loader.appendTo("#add_more_div");
    var task_index = task_i
    task_i = task_i + 1
    jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/add_new_task_form",
        dataType: 'script',
        data: {
            "task_index" : task_index,
            "note_id"    : note_id
        },
        success: function(transport)
        {
            loader.remove();
        }

    });
}

function update_user_select_div(field){
    if(field.checked){
        jQuery("#update_user_div").show();
    }else{
        jQuery("#update_user_div").hide();
    }

}

function update_stt_tat_fields(){
    if (jQuery("#special_handling").is(':checked'))
    {
        jQuery("#task_stt").removeAttr("disabled");
        jQuery("#task_tat").removeAttr("disabled");
    }

    else
    {
        jQuery("#task_stt").attr("disabled",true)
        jQuery("#task_tat").attr("disabled",true)
    }
}

function update_work_type_select_edit(category_type,task_index){
    loader.appendTo("#"+task_index+"_loader_img");
    var el2 = document.getElementById("task_work_subtype_id");
    if(el2 != null){
        el2.options.length = 0;
    };
    var el3 = document.getElementById("task_work_subtype_complexity_id");
    if(el3 != null){
        el3.options.length = 0;
    };

    jQuery('#task_'+task_index+'_complexity').hide();
    jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/get_work_types",
        dataType: 'script',
        data: {
            'category_type' : category_type,
            'task_index' : task_index,
            'from_action' : 'edit'
        },
        success: function(transport)
        {
            loader.remove();
        }

    });
}


function update_work_subtype_select_edit(work_type_id,task_index){
    if (work_type_id == ""){
        document.getElementById("task_work_subtype_id").options.length = 0;
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_work_subtypes",
            dataType: 'script',
            data: {
                'work_type_id' : work_type_id,
                "task_index" : task_index,
                'from_action' : 'edit'
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}


function update_complexity_select_edit(work_subtype_id,task_index){
    if (work_subtype_id == ""){
    // document.getElementById("task_"+task_index+"work_subtypes").value="";
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_complexities",
            dataType: 'script',
            data: {
                'work_subtype_id' : work_subtype_id,
                "task_index" : task_index,
                'from_action' : 'edit'
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}


function update_user_select_edit(user_category_type,task_index,employee_user_id){
    if (user_category_type == "CommonPool"){
        //document.getElementById("task_assigned_to_user_id").options.length = 0;
        jQuery('#task_0_user_select').hide();
        jQuery('#task_assigned_to_user_id').val("");
    }
    else{
        loader.appendTo("#"+task_index+"_loader_img");
        jQuery('#task_0_user_select').show();
        work_subtype_id = jQuery("#task_work_subtype_id").val();
        jQuery.ajax({
            type: "POST",
            url: "/wfm/user_tasks/get_users",
            dataType: 'script',
            data: {
                'user_category_type' : user_category_type,
                "task_index" : task_index,
                'from_action' : 'edit',
                "work_subtype_id" : work_subtype_id,
                "employee_user_id" : employee_user_id
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}


function show_flash_notice()
{
    if (jQuery('#notice').show())
    {
        jQuery('#notice').fadeOut(4000);
    }
}

function update_matter_contact_select(user_id){
    if (user_id == ""){
        alert("Please select lawyer");
    }
    else{
        loader.appendTo("#modal_new_task_errors");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/notes/get_matters_contacts",
            dataType: 'script',
            data: {
                'user_id' : user_id
            },
            success: function(transport)
            {
                loader.remove();
            }

        });
    }
}
function show_spinner(){
    jQuery('#loader1').show();
}

function show_error_msg(div,msg,classname)
{
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

// remote_form_for gives issues in passing the submit button param. hence this function was written to explicitly send the 'commit' param of the submit button in a remote_form_for :sania wagle 15mar'11
function send_params()
{
    jQuery('#complete').val('complete');
}


function toggle_lawyes_list(i){
    jQuery(".lawyer_list").each(function() {
        var id = jQuery(this).attr('id');
        if (id == 'verify_lawyer_div_'+i){
            jQuery(this).slideToggle('slow');
        }else{
            jQuery(this).hide('slow');
        }
    });
}

function select_lawyer(lawyer)
{
    jQuery('#id_search').val(lawyer);
    jQuery('#lawyer_list_div').slideUp('slow');
    jQuery('#id_search').trigger('keyup');
}

function check_assigned_by_user_id(id,task_index)
{
    if (jQuery('#tasks_'+task_index+'_assigned_to_user_id').val()!="")
    {
        jQuery('#tasks_'+task_index+'_assigned_by_user_id').val(id);
    }

}

function update_priorities(cluster_id){
    if (cluster_id == ""){
        alert("Please select lawyer");
    }
    else{
        loader.prependTo("#lawyers_livians_list");
        jQuery.ajax({
            type: "POST",
            url: "/wfm/manage_clusters/manage_priorities",
            dataType: 'script',
            data: {
                'cluster_id' : cluster_id
            },
            success: function(transport)
            {

                loader.remove();
            }

        });

    }

}

function getUserSkills(id) {
    try {

        loader.appendTo("#skills_spinner");
        jQuery.get("/wfm/user_work_subtypes/getUserSkills",
        {
            'user_id' : id
        },
        function (data) {
            jQuery("#skills_spinner").html("");
        //jQuery("#skills_assign").html(data);
        });
    } catch(e) {
        alert(e.message);
    }
}

function show_cluster_list(user_id,user_type){
    if (user_id == "") {
        alert("Please select a Lawyer first.");
        return;
    }
    loader.prependTo("#service_provider_cluster_list")
    jQuery.ajax({
        type: "POST",
        url: "show_cluster_list",
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


function assign_sec_to_cluster(cluster_id){
    var secretary_id= jQuery("#service_providers_id").val();
    var from_date= jQuery("#from_date").val();
    var to_date= jQuery("#to_date").val();
    if (secretary_id == "") {
        alert("Please select a Livian first.");
        return false;
    }
    loader.prependTo("#service_provider_cluster_list");
    jQuery.ajax({
        type: "POST",
        url: "assign_sec_to_cluster",
        dataType: 'script',
        data: {
            'secretary_id' : secretary_id,
            'cluster_id'   : cluster_id,
            'from_date'    : from_date,
            'to_date'      : to_date
        //'lawyer_id' : jQuery("#employee_id").val()
        },
        success: function(){
            loader.remove();
        }
    });
}

function toggle_work_subtypes_span(id){
    jQuery('#work_type_'+id+'_work_subtypes').toggle();
    jQuery('#'+id+'_worktype_plus').toggle();
    jQuery('#'+id+'_worktype_minus').toggle();
}

function toggle_check_uncheck(option)
{
    if (option == 'complete')
    {
        jQuery('#chk_reassign_task').attr('checked','');
        jQuery('#update_user_div').hide();
    }
    else if (option == 'reassign')
    {
        jQuery('#chk_complete_task').attr('checked','');
        jQuery('#complete_task_div').hide();
    }

    if(jQuery('#chk_reassign_task').attr('checked') ||jQuery('#chk_complete_task').attr('checked'))
        jQuery('#comments_div').show();
    else
        jQuery('#comments_div').hide();

}

function disableAllSubmitButtons(class_name){
    jQuery('.' + class_name).children('input').attr('disabled', 'disabled');
    jQuery('.' + class_name).css('color', 'gray');
    jQuery('.' + class_name).css('cursor', 'wait');
    return true;
}

function enableAllSubmitButtons(class_name){
    jQuery('.' + class_name).children('input').attr('disabled', '');
    jQuery('.' + class_name).css('color', '');
    jQuery('.' + class_name).css('cursor', 'pointer');
    return true;
}

function display_temp_assignment_fields(checked){
    if(checked){
        jQuery('#temp_assignment_fields').show();
    }else{
        jQuery('#temp_assignment_fields').hide();
        jQuery('#from_date').val("");
        jQuery('#to_date').val("");
    }
}

function check_stt_tat()
{
    if(jQuery('#special_handling').attr('checked'))
    {
        stt = jQuery('#task_stt').val();
        tat = jQuery('#task_tat').val();
            
        if( parseInt(stt) >  parseInt(tat))
        {
            alert('STT cannot be greater than TAT');
            enableAllSubmitButtons('buttons_to_disable');
            return false;
        }
    }

    return true;
}

function validate_from_to_date(cluster_id)
{

    if (jQuery('#temp_assign').attr('checked'))
    {
        var from_date = jQuery("#from_date").val();
        var to_date = jQuery("#to_date").val();
        if(from_date != "" && to_date != "")
        {
            if (Date.parse(from_date) > Date.parse(to_date))
            {
                alert("End Date should be greater than Start Date");
                return false;
            }
            else
            {
                assign_sec_to_cluster(cluster_id);
            }
        }
        else
        {
            alert("Please Specify Both the dates")
            return false;
        }

    }
    else
    {
        jQuery("#from_date").val('');
        jQuery("#to_date").val('');
        assign_sec_to_cluster(cluster_id);
    }
    return true;
}

function check_if_checkboxes_are_checked(div_id)
{
  if (jQuery("#"+ div_id + " input:checkbox:checked").length == 0)
  {
    alert('Please select a livian to unassign');
    return false;
  }
  return true;
}

function update_contact_select(matter_id){
    if(matter_id != ""){
        loader.appendTo("#modal_new_task_errors");
        jQuery.ajax({
        type: "POST",
        url: "notes/get_contact_of_matter",
        dataType: 'script',
        data: {
            'matter_id' : matter_id
        },
        success: function(){
            loader.remove();
        }
     });
    }
}

function update_matter_select(contact_id){
    if(contact_id != ""){
        loader.appendTo("#modal_new_task_errors");
        jQuery.ajax({
        type: "POST",
        url: "notes/get_matter_of_contact",
        dataType: 'script',
        data: {
            'contact_id' : contact_id
        },
        success: function(){
            loader.remove();
        }
     });
    }
}


  