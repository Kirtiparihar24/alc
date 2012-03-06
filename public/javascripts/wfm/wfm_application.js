var loader = jQuery("<center><img src='/images/loading.gif' /></center>");
var task_i = 1;
// copy note test to task test on new task page

jQuery(document).ready(function(){
  jQuery('body').click(function(){
    jQuery('.actions').hide('slow');
    jQuery('#lawyer_list_div').slideUp();
    jQuery('#messages-box').slideUp();
  });
  stop_propogating();
  jQuery('#hoverIntent span').hoverIntent({
    sensitivity: 7, // number = sensitivity threshold (must be 1 or higher)
    interval: 350,   // number = milliseconds of polling interval
    over: showNav,  // function = onMouseOver callback (required)
    timeout: 100,   // number = milliseconds delay before onMouseOut function call
    out: hideNav    // function = onMouseOut callback (required)
  });
});

function stop_propogating(){
  jQuery('.actions, .action_pad, #lawyer_list_div, #drop, .search_div, #search_button, #message-count, #all-messages, #ui-datepicker-div').click(function(event) {
    event.stopImmediatePropagation();
  });
}

function update_task_text(field,index){
  if(field.checked){
    document.getElementById("tasks_"+index+"_name").value = jQuery(".note_text").val();
  } else{
    document.getElementById("tasks_"+index+"_name").value="";
  }
}

function update_work_type_select(category_type,task_index,note_id){
  loader.appendTo("#"+task_index+"_loader_img");
  jQuery(".sub_text_"+task_index).hide();
  jQuery("#tasks_"+task_index+"_assigned_to_user_id")[0].options.length=1;
  jQuery("#tasks_"+task_index+"_work_subtype_id")[0].options.length=1;
  var el = jQuery("#tasks_"+task_index+"_work_subtype_complexity_id");
  if(el.length > 1){
    el[0].options.length=1;
  }
  jQuery("#tasks_"+task_index+"_complexity_stt_tat").hide();
  jQuery("#task_"+task_index+"_user_select").show();
  if(category_type === 'BackofficeTask'){
    jQuery('#cluster_users_'+task_index).html('BO Agents');
    jQuery('#common_pool_agent_div_'+task_index).hide();
    jQuery('input.cluster_users_radio_'+task_index).attr('checked', true);
    jQuery('#backoffice_'+task_index).show();
  }else{
    jQuery('#cluster_users_'+task_index).html('Cluster Users');
    jQuery('#common_pool_agent_div_'+task_index).show();
    jQuery('#task_'+task_index+'_user_select_option').show();
    jQuery("input[name='task_"+task_index+"_radio_2']").filter("[value='ClusterUsers']").attr("checked","checked");
    jQuery('#task_'+task_index+'_CommonPoolAgentRadio').show();
    jQuery('#backoffice_'+task_index).hide();
  }
  jQuery('#task_'+task_index+'_complexity').hide();
  var lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
  jQuery.ajax({
    type: "POST",
    url: "/wfm/user_tasks/get_work_types",
    dataType: 'script',
    data: {
      'category_type' : category_type,
      'task_index'    : task_index,
      'note_id'       : note_id,
      'lawyer_id'     : lawyer_id
    },
    success: function(transport) {
      loader.remove();
    }
  });
}

function update_work_subtype_select(work_type_id,task_index,note_id){
  var user_category_type = ""
  var task_type = ""
  if(task_index == ''){
     var el = jQuery("#task_work_subtype_complexity_id");
     if(el.length > 1){
        el[0].options.length=1;
     }
  }else{
     jQuery('.sub_text_'+task_index).hide();
     jQuery("#tasks_"+task_index+"_assigned_to_user_id")[0].options.length=1;
     var el1 = jQuery("#tasks_"+task_index+"_work_subtype_complexity_id");
     if(el1.length > 1){
       el1[0].options.length=1;
     }
    jQuery("#tasks_"+task_index+"_complexity_stt_tat").hide();
  }
  if (work_type_id == ""){
      if(task_index == ''){
          jQuery("#task_work_subtype_id")[0].options.length=1;
      }else{
          jQuery("#tasks_"+task_index+"_work_subtype_id")[0].options.length=1;
      }
  }else{
    loader.appendTo("#"+task_index+"_loader_img");
    var lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
    task_type = jQuery("input[name='task_"+task_index+"_radio_1']:checked").val();
    user_category_type = jQuery("input[name='task_"+task_index+"_radio_2']:checked").val();
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_work_subtypes",
      dataType: 'script',
      data: {
        'work_type_id' : work_type_id,
        "task_index"   : task_index,
        'note_id'      : note_id,
        'lawyer_id'    : lawyer_id,
        'user_category_type' : user_category_type,
        'task_type' : task_type
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
  reassign_task_block();
}

function update_complexity_select(work_subtype_id,task_index){
  var user_category_type = jQuery("input[name='task_"+task_index+"_radio_2']:checked").val();
  jQuery("#tasks_"+task_index+"_assigned_to_user_id").attr('length', '1');
  jQuery("#tasks_"+task_index+"_complexity_stt_tat").hide();
  jQuery(".sub_text_"+task_index).hide();
  if (work_subtype_id == ""){
    jQuery('.subText').hide();
    jQuery("#tasks_"+task_index+"_work_subtype_complexity_id").attr('length', '1');
    jQuery("#task_work_subtype_complexity_id").attr('length', '1');
  } else{
    loader.appendTo("#"+task_index+"_loader_img");
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_complexities",
      dataType: 'script',
      data: {
        'work_subtype_id' : work_subtype_id,
        "task_index" : task_index,
        "user_category_type" : user_category_type
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
  reassign_task_block();
}

function update_user_select(task_index,employee_user_id,user_category_type,back_office){
  var task_type = jQuery("input[name='task_"+task_index+"_radio_1']:checked").val();
  if(employee_user_id==""){
    employee_user_id = jQuery('#note_assigned_by_employee_user_id').val();
  }
  if(user_category_type === undefined ){
    user_category_type = jQuery("input[name='task_"+task_index+"_radio_2']:checked").val();
  }

  if (user_category_type == "CommonPool"){
    jQuery("#tasks_"+task_index+"_assigned_to_user_id").attr('length', '1');
    jQuery("#task_"+task_index+"_user_select").hide();
  } else{
    var work_subtype_id = jQuery("#tasks_"+task_index+"_work_subtype_id").val();
    var complexity_id = jQuery("#tasks_"+task_index+"_work_subtype_complexity_id").val();
    jQuery("#task_"+task_index+"_user_select").show();
    if((task_type == "BackofficeTask" && back_office == 'true' && complexity_id == "") || work_subtype_id == ""){
      jQuery("#tasks_"+task_index+"_assigned_to_user_id").attr('length', '1');
    } else{
      loader.appendTo("#"+task_index+"_loader_img");
      jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/get_users",
        dataType: 'script',
        data: {
          'user_category_type' : user_category_type,
          "task_index" : task_index,
          "work_subtype_id" : work_subtype_id,
          "employee_user_id" : employee_user_id,
          "task_type" : task_type,
          "complexity_id" : complexity_id
        },
        success: function(transport) {
          loader.remove();
        }
      });
    }
  }
}

function display_stt_tat_update_user_select(id,index){
  jQuery(".sub_text_"+index).hide();
  var user_type = jQuery("input[name='task_"+index+"_radio_2']:checked").val();
  var work_subtype_id = jQuery("#tasks_"+index+"_work_subtype_id").val();
  jQuery("#complexity_"+id+"_stt_tat_"+index).show();
  if (user_type == "ClusterUsers" && id != ""){
    loader.appendTo("#"+index+"_loader_img");
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_users",
      dataType: 'script',
      data: {
        'user_category_type' :user_type,
        "task_index" : index,
        "work_subtype_id" : work_subtype_id,
        "task_type" : "BackOffice",
        "complexity_id" : id,
        "from_complexity_select" : true
      },
      success: function(transport) {
        loader.remove();
      }
    });
  } else if(id == ""){
    jQuery("#tasks_"+index+"_complexity_stt_tat").hide();
    jQuery("#tasks_"+index+"_assigned_to_user_id").attr('length', '1');
  } else{
    jQuery(".sub_text_"+index).hide();
    jQuery("#tasks_"+index+"_complexity_stt_tat_"+id).show();
    jQuery("#tasks_"+index+"_assigned_to_user_id").attr('length', '1');
  }
}

function display_stt_tat_update_user_select_edit(id,index){
  jQuery("#complexity_"+id+"_stt_tat_"+index).show();
  if (jQuery('#chk_reassign_task').is(':checked')){
    var user_type = jQuery("input[name='user_type']:checked").val();
    var work_subtype_id = jQuery("#task_work_subtype_id").val();
    if (user_type == "ClusterUsers"){
      loader.appendTo("#"+index+"_loader_img");
      jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/get_users",
        dataType: 'script',
        data: {
          'user_category_type' :user_type,
          "task_index" : index,
          "work_subtype_id" : work_subtype_id,
          "task_type" : "BackOffice",
          "complexity_id" : id,
          "from_complexity_select" : true,
          "from_action" : "edit"
        },
        success: function(transport) {
          loader.remove();
        }
      });
    }
  }
}

function add_task_form(note_id,from_edit){
  lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
  from_edit = (typeof from_edit == 'undefined') ? 'false' : from_edit;
  loader.appendTo("#add_more_div");
  var task_index = task_i
  task_i = task_i + 1
  jQuery.ajax({
    type: "POST",
    url: "/wfm/user_tasks/add_new_task_form",
    dataType: 'script',
    data: {
      "task_index" : task_index,
      "note_id"    : note_id,
      "lawyer_id"  : lawyer_id,
      "from_edit" : from_edit
    },
    success: function(transport) {
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
  if (jQuery("#special_handling").is(':checked')) {
    jQuery("#task_stt").removeAttr("disabled");
    jQuery("#task_tat").removeAttr("disabled");
  } else {
    jQuery("#task_stt").attr("disabled",true)
    jQuery("#task_tat").attr("disabled",true)
  }
}

function update_work_type_select_edit(category_type,task_index,note_id,generate_task){
  jQuery("#task_work_subtype_id")[0].options.length=1;
  jQuery('#task_assigned_to_user_id')[0].options.length=1;
  var el = jQuery("#task_work_subtype_complexity_id");
  if(el.length > 1){
    el[0].options.length=1;
  }
  generate_task = (typeof generate_task == 'undefined') ? false : generate_task;
  reassign_task_block();
  if(category_type=='BackofficeTask'){
    jQuery('#cluster_users').html('BO Agents');
    jQuery('#common_pool_agent_div').hide();
    jQuery('#backoffice_'+task_index).show();
    jQuery('#backoffice_0').show();
    jQuery("input[name='user_type']").attr('checked',false);
    jQuery('#bo_agent_radio').attr('checked', 'checked');
  } else{
    jQuery('#common_pool_agent_div').show();
    jQuery('#cluster_users').html('Cluster Users');
    jQuery('#reassign_task_checkbox_div').show();
    jQuery('#reassign_div').show('slow');
    jQuery('#backoffice_'+task_index).hide()
    jQuery('#backoffice_0').hide()
    jQuery('#cluster_users_radio').attr('checked', true);
  }
  if(generate_task == true){
    generate_a_task();
  }
  loader.appendTo("#"+task_index+"_loader_img");
  jQuery('#task_'+task_index+'_complexity').hide();
  jQuery.ajax({
    type: "POST",
    url: "/wfm/user_tasks/get_work_types",
    dataType: 'script',
    data: {
      'category_type' : category_type,
      'task_index' : task_index,
      'from_action' : 'edit',
      'note_id' : note_id,
      'generate_task' : generate_task
    },
    success: function(transport) {
      loader.remove();
    }
  });
}

function update_work_subtype_select_edit(work_type_id,task_index,note_id,from_complete_note){
  var task_type = "";
  if(jQuery('#back_office_task').is(':checked')){
    task_type = "Back Office";
  }
  if(from_complete_note != null){
    var from_complete_note = 'from_complete_note'
  } else{
    var from_complete_note = ''
  }
  if (work_type_id == ""){
    jQuery("#task_work_subtype_id").attr('length','1');
  } else{
    loader.appendTo("#"+task_index+"_loader_img");
    var reassign = jQuery('#chk_reassign_task').attr("checked");
    var user_category_type = jQuery("input[name='user_type']:checked").val();
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_work_subtypes",
      dataType: 'script',
      data: {
        'work_type_id' : work_type_id,
        "task_index" : task_index,
        'from_action' : 'edit',
        'note_id' : note_id,
        'reassign' : reassign,
        'user_category_type' : user_category_type,
        'from_complete_note' : from_complete_note,
        'task_type' : task_type
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}


function update_complexity_select_edit(work_subtype_id,task_index,note_id){
  var task_type = "";
  if(jQuery('#back_office_task').is(':checked')){
    task_type = "Back Office";
  }
  if (work_subtype_id == ""){
    jQuery("#task_"+task_index+"_work_subtypes").attr('length','1');
  } else{
    var reassign = jQuery('#chk_reassign_task').attr("checked");
    var user_category_type = jQuery("input[name='user_type']:checked").val();
    var category_type = jQuery("input[name='task_0_radio_1']:checked").val();
    loader.appendTo("#"+task_index+"_loader_img");
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_complexities",
      dataType: 'script',
      data: {
        'work_subtype_id' : work_subtype_id,
        "task_index" : task_index,
        'from_action' : 'edit',
        'reassign' : reassign,
        'user_category_type' : user_category_type,
        'category_type' : category_type,
        'note_id' : note_id,
        'task_type' : task_type
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}

function update_user_select_edit(user_category_type,task_index,employee_user_id,back_office_user){
  var task_type = ""
  var work_complexity = jQuery("#task_work_subtype_complexity_id").val();
  var work_type = jQuery("#task_work_subtype_id").val();
  var work_category = jQuery("input[name='task__radio_1']:checked").val();
  if(work_category == "BackofficeTask" && back_office_user == "true" && work_complexity == ""){
    jQuery('input[name=user_type]').attr('checked', false);
    alert("Please Select Work-Subtype Complexity !");
    return false;
  } else if(work_type == ""){
    jQuery('input[name=user_type]').attr('checked', false);
    alert("Please Select Work-Subtype!");
    return false;
  } else{
    if (user_category_type == "CommonPool"){
      jQuery('#task_0_user_select').hide();
      jQuery('#task_assigned_to_user_id').val("");
    } else{
      if(jQuery('#back_office_task').is(':checked')){
        task_type = "BackOfficeTask";
      }else{
        task_type = "LivianTask";
      }
      loader.appendTo("#"+task_index+"_loader_img");
      jQuery('#task_0_user_select').show();
      var work_subtype_id = jQuery("#task_work_subtype_id").val();
      var complexity_id = jQuery("#task_work_subtype_complexity_id").val();
      jQuery.ajax({
        type: "POST",
        url: "/wfm/user_tasks/get_users",
        dataType: 'script',
        data: {
          'user_category_type' : user_category_type,
          "task_index" : task_index,
          'from_action' : 'edit',
          "work_subtype_id" : work_subtype_id,
          "employee_user_id" : employee_user_id,
          "task_type" : task_type,
          "complexity_id" : complexity_id
        },
        success: function(transport) {
          loader.remove();
        }
      });
    }
  }
}

function show_flash_notice(){
  if (jQuery('#notice').show()) {
    jQuery('#notice').fadeOut(4000);
  }
}

function update_assign_note_user_select(users_type,note_id){
  jQuery('#users_select').show();
  var lawyer_id = ''
  if(note_id === ''){
    lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
  }
  loader.appendTo("#_loader_img");
  jQuery.ajax({
    type: "POST",
    url: "/wfm/notes/update_assign_note_user_select",
    dataType: 'script',
    data: {
      'users_type' : users_type,
      'note_id' : note_id,
      'lawyer_id' : lawyer_id
    },
    success: function() {
      loader.remove();
      if(jQuery('#common_pool_radio').is(":checked") == true){
        jQuery('#users_select').hide();
        jQuery('#assigned_to_user_id').val('');
      }
    }
  });
}

function generate_a_task(){
  loader.appendTo("#0_loader_img");
  var users_type;
  jQuery('#comment_div').hide();
  if(jQuery('#back_office_task').is(':checked')==true){
    jQuery('#cluster_users_div').hide();
    jQuery('#common_pool_agent_div').hide();
    jQuery('#back_office_agent_div').show();
    users_type = "back_office_user";
  }else if(jQuery('#livian_task').is(':checked')==true){
    jQuery('#cluster_users_div').show();
    jQuery('#common_pool_agent_div').show();
    jQuery('#back_office_agent_div').hide();
    users_type = "cluster_users";
  }
  update_assign_note_user_select(users_type,'');
}

function update_lawyers_select(lawfirm_id,lawfirm_val){
 jQuery('#search_lawfirm').val(lawfirm_val);
  jQuery.ajax({
      type: "POST",
      url: "/wfm/notes/get_lawfirm_and_lawyers",
      dataType: 'script',
      data: {
        'company_id' : lawfirm_id,
      },
      success: function(transport) {
       jQuery('#search_lawyer').val('');
       search_lwayers_list();
       jQuery("#note_matter_id")[0].options.length=1;
       jQuery("#note_contact_id")[0].options.length=1;
       loader.remove();
      }
    });

}

function update_matter_contact_select(user_id,lawyer_val){

  jQuery('#search_lawyer').val(lawyer_val);
  var task_forms = jQuery(".task_forms").length
  work_obj=jQuery("#task_0_work_types").children()[0].options[0];
  jQuery("#tasks_0_work_subtype_id").attr('length','1');
  jQuery("#tasks_0_assigned_to_user_id").attr('length','1');
  jQuery("#tasks_0_work_subtype_complexity_id").attr('length','1');
  jQuery("#tasks_0_complexity_stt_tat").hide();
  jQuery(work_obj).attr('selected','selected');

  for(var i=1; i<= task_forms; i++){
    jQuery("#task_"+i+"_form").remove();
  }
  var back_office_task;
  if (user_id == ""){
    document.getElementById("note_matter_id").options.length = 1;
    alert("Please select lawyer");
  } else{
    loader.appendTo("#loader1");
    jQuery('#note_lawyer').val(jQuery('#'+user_id).text());
    jQuery('#note_assigned_by_employee_user_id').val(user_id);
    jQuery('.quick_result').slideUp();
    jQuery('.assign_to').show();
    if(jQuery('#generate_task').is(":checked") == true){
      generate_a_task();
      if(jQuery('#back_office_task').is(":checked") == true){
        back_office_task = 'back_office_task';
      }
    }
    jQuery.ajax({
      type: "POST",
      url: "/wfm/notes/get_matters_contacts_and_users",
      dataType: 'script',
      data: {
        'user_id' : user_id,
        'back_office_task' : back_office_task
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}

function show_spinner(){
  jQuery('#loader1').show();
}

function show_error_msg(div,msg,classname){
  loader.remove();
  jQuery('#'+div)
  .html("<div class="+classname+">"+msg+"</div>")
  .fadeIn('slow')
  .animate({
    opacity: 1.0
  }, 8000)
  .fadeOut('slow');
}

function show_error_full_msg(div,msg,classname){
  show_error_msg(div,msg,classname);
  jQuery('html, body').animate({
    scrollTop: 0
  }, 0);
  jQuery('#TB_ajaxContent').animate({
    scrollTop: 0
  }, 0);
}

// remote_form_for gives issues in passing the submit button param. hence this function was written to explicitly send the 'commit' param of the submit button in a remote_form_for :sania wagle 15mar'11
function send_params(){
  loader.appendTo('#modal_new_task_errors');
  jQuery('#complete').val('complete');
}

function toggle_lawyes_list(ids){
  jQuery("#verify_lawyer_div_"+ids).html("<center><img src='/images/loading.gif' /></center>");
  
  jQuery(".lawyer_list").each(function() {
    var id = jQuery(this).attr('id');
    if (id == 'verify_lawyer_div_'+ids){
      jQuery(this).show();
    }else{
      jQuery(this).hide();
    }
  });
  jQuery(".sct_left").scrollTo(jQuery("#lawyer_"+ids), 800 );
}

function select_lawyer(lawyer){
  jQuery('#id_search').val(lawyer);
  jQuery('#lawyer_list_div').slideUp('slow');
  jQuery('#id_search').trigger('keyup');
}

function check_assigned_by_user_id(id,task_index){
  if (jQuery('#tasks_'+task_index+'_assigned_to_user_id').val()!=""){
    jQuery('#tasks_'+task_index+'_assigned_by_user_id').val(id);
  }
}

function update_priorities(cluster_id){
  if (cluster_id == ""){
    alert("Please select lawyer");
  } else{
    loader.prependTo("#lawyers_livians_list");
    jQuery.ajax({
      type: "POST",
      url: "/wfm/manage_clusters/manage_priorities",
      dataType: 'script',
      data: {
        'cluster_id' : cluster_id
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}

function getUserSkills(id) {
  try {
    loader.appendTo("#skills_spinner");
    jQuery.get("/wfm/user_work_subtypes/getUserSkills", {
      'user_id' : id
    },
    function (data) {
      jQuery("#skills_spinner").html("");
    });
  }catch(e) {
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
    },
    success: function(){
      loader.remove();
    }
  });
}

function toggle_work_subtypes_span(id){
  jQuery('#work_type_'+id+'_work_subtypes').toggle('slow');
  jQuery('#'+id+'_worktype_plus').toggle();
  jQuery('#'+id+'_worktype_minus').toggle();
}

function toggle_check_uncheck(option){
  jQuery('#reassign_to_bo_queue').hide();
  if (option.value == 'complete')
  {
    jQuery('#chk_reassign_task').attr('checked', false);
    jQuery('#chk_escalate_task').attr('checked', false);
    jQuery('input[name=user_type]').attr('checked', false);
    jQuery('#task_assigned_to_user_id').attr('length','1');
    jQuery('#update_user_div').hide();
  }else if (option.value == 'reassign'){
    jQuery('#chk_complete_task').attr('checked',false);
    jQuery('#chk_escalate_task').attr('checked',false);
    jQuery('#complete_task_div').hide();
    update_user_select_div(option);
    if (jQuery('#chk_reassign_task').attr('checked')==false) {
      jQuery('input[name=user_type]').attr('checked', false);
      jQuery('#task_assigned_to_user_id').attr('length','1');
    }
  } else if(option.value == 'escalate') {
    if(jQuery('#chk_escalate_task').attr('checked')){
      jQuery('#chk_complete_task').attr('checked', false);
      jQuery('#chk_reassign_task').attr('checked',true);
      jQuery('#common_queue_radio').attr('checked',true);
      jQuery('#update_user_div').hide();
      jQuery('#complete_task_div').hide();
      jQuery('#reassign_to_bo_queue').show();
    } else{
      jQuery('#chk_reassign_task').attr('checked', false);
      jQuery('#comments_div').hide();
      jQuery('#reassign_to_bo_queue').hide();
    }
  }
  if(jQuery('#chk_reassign_task').attr('checked') || jQuery('#chk_complete_task').attr('checked') || jQuery('#chk_escalate_task').attr('checked')){
    jQuery('#comments_div').show();
  } else {
    jQuery('#comments_div').hide();
  }
}

function toggle_assign_complete(option){
  var lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
  if(lawyer_id == ""){
    jQuery('#generate_task').attr('checked',false);
    jQuery('#assign').attr('checked',false);
    jQuery('#complete').attr('checked',false);
    alert("Please select lawyer !");
  } else{
    if (option == 'complete') {
      jQuery('#generate_task').attr('checked',false);
      jQuery('.gen_task').hide();
      jQuery('#assign').attr('checked',false);
      jQuery('#assign_div').hide();
      jQuery('#complete_note').show();
      if (!jQuery('#complete').is(':checked')) {
        jQuery('#complete_note').hide();
      }
    }else if (option == 'assign'){
      jQuery('#generate_task').attr('checked',false);
      jQuery('.gen_task').hide();
      jQuery('#complete').attr('checked',false);
      jQuery('#complete_note').hide();
      jQuery('#assign_div').show();
      if (!jQuery('#assign').is(':checked')){
        jQuery('#assign_div').hide();
      }
    }else if(option == 'generate_task'){
      jQuery('#complete').attr('checked',false);
      jQuery('#complete_note').hide();
      jQuery('#assign').attr('checked',false);
      jQuery('#assign_div').hide();
      jQuery('.gen_task').show();
      if (!jQuery('#generate_task').is(':checked')){
        jQuery('.gen_task').hide();
      }
    }
  }
}

function disableAllSubmitButtons(class_name){
  jQuery('.' + class_name).children('input').attr('disabled', 'disabled');
  jQuery('.' + class_name).children('span').find("#button_pressed").html("Please Wait...");
  jQuery('.' + class_name).css('color', 'gray');
  jQuery('.' + class_name).css('cursor', 'wait');
  return true;
}

function enableAllSubmitButtons(class_name,value){
  jQuery('.' + class_name).children('input').attr('disabled', false);
  jQuery('.' + class_name).children('span').find("#button_pressed").html(value);
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

function check_stt_tat(){
  if(jQuery('#special_handling').attr('checked')) {
    var stt = jQuery('#task_stt').val();
    var tat = jQuery('#task_tat').val();
    if( parseInt(stt) >  parseInt(tat)) {
      alert('STT cannot be greater than TAT');
      enableAllSubmitButtons('buttons_to_disable');
      return false;
    }
  }
  return true;
}

function validate_from_to_date(cluster_id,option){
  if(option == 'assign_sec_to_cluster') {
    if (jQuery('#temp_assign').attr('checked')) {
      var from_date = jQuery("#from_date").val();
      var to_date = jQuery("#to_date").val();
      if(from_date != "" && to_date != "") {
        if (Date.parse(from_date) > Date.parse(to_date)) {
          alert("End Date should be greater than Start Date");
          return false;
        } else {
          assign_sec_to_cluster(cluster_id);
        }
      } else {
        alert("Please Specify Both the dates");
        return false;
      }
    } else {
      jQuery("#from_date").val('');
      jQuery("#to_date").val('');
      assign_sec_to_cluster(cluster_id);
    }
  } else if(option == 'update_temp_assignment') {
    var cluster_user_from_date = jQuery("#cluster_user_from_date").val();
    var cluster_user_to_date = jQuery("#cluster_user_to_date").val();
    if(cluster_user_from_date != "" && cluster_user_to_date != "") {
      if (Date.parse(cluster_user_from_date) > Date.parse(cluster_user_to_date)) {
        alert("End Date should be greater than Start Date");
        return false;
      } else {
        return true;
      }
    } else {
      alert("Please Specify Both the dates");
      return false;
    }
  }
  return true;
}

function check_if_checkboxes_are_checked(div_id){
  if (jQuery("#"+ div_id + " input:checkbox:checked").length == 0) {
    alert('Please select a livian to unassign');
    return false;
  }
  return true;
}

function update_contact_select(matter_id){
  loader.appendTo("#loader1");
  var lawyer_user_id = "";
  if(matter_id === ""){
    lawyer_user_id = jQuery('#note_assigned_by_employee_user_id').val();
  }
  if(matter_id != "" || lawyer_user_id != ""){
    jQuery.ajax({
      type: "POST",
      url: "/wfm/notes/get_contact_of_matter",
      dataType: 'script',
      data: {
        'matter_id' : matter_id,
        'lawyer_user_id' : lawyer_user_id
      },
      success: function(){
        loader.remove();
      }
    });
  } else{
    document.getElementById("note_contact_id").options.length = 1;
  }
}

function update_matter_select(contact_id){
  loader.appendTo("#loader1");
  var lawyer_user_id = "";
  if(contact_id === ""){
    lawyer_user_id = jQuery('#note_assigned_by_employee_user_id').val();
  }
  if(contact_id != "" || lawyer_user_id != ""){
    jQuery.ajax({
      type: "POST",
      url: "/wfm/notes/get_matter_of_contact",
      dataType: 'script',
      data: {
        'contact_id' : contact_id,
        'lawyer_user_id' : lawyer_user_id
      },
      success: function(){
        loader.remove();
      }
    });
  }
}

function update_lawyer_filter_select(company_id, model_name){
  loader.appendTo("#loader");
  jQuery.ajax({
    type: "POST",
    url: "notes/get_assigend_lawyers_of_company",
    dataType: 'script',
    data: {
      'company_id' : company_id,
      'model_name' : model_name
    },
    success: function(){
      loader.remove();
    }
  });
}

function reassign_multiple_tasks(){
  var checked_task_ids = [];
  jQuery("input[name='task_id']:checked").each(function(i,el) {
    checked_task_ids.push(jQuery(el).val());
  });
  if(checked_task_ids.length === 0){
    alert("Please select a task first");
  }else{
    tb_show('Reassign Tasks','/wfm/user_tasks/reassign_multiple_task_form?task_ids='+checked_task_ids+'&height=350&width=700','');
  }
}

function update_user_select_multiple_task_reasign(user_category_type,task_ids){
  if (user_category_type == "CommonPool"){
    document.getElementById("task_assigned_to_user_id").options.length = 0;

    jQuery('#task_0_user_select').hide();
  } else{
    loader.appendTo("#loader_img");
    jQuery('#task_0_user_select').show();
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_users_for_multiple_task_reassign",
      dataType: 'script',
      data: {
        'user_category_type' : user_category_type,
        "task_ids" : task_ids
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}

function get_cluster_livians(cluster_id) {
  try {
    loader.appendTo("#skills_spinner");
    jQuery.get("/wfm/user_work_subtypes", {
      'cluster_id' : cluster_id
    },
    function (data) {
      jQuery("#skills_spinner").html("");
    });
  } catch(e) {
    alert(e.message);
  }
}

function assign_multiple_notes(){
  var checked_note_ids = [];
  jQuery("input[name='task_id']:checked").each(function(i,el) {
    checked_note_ids.push(jQuery(el).val());
  });
  if(checked_note_ids.length === 0){
    alert("Please select notes");
  }else{
    tb_show('Assign Notes','/wfm/notes/assign_multiple_notes_form?note_ids='+checked_note_ids+'&height=350&width=700','');
  }
}

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

function get_clusters_livians_and_skills_for_selected_lawyer(lawfirm_user_id) {
  try {
    if(lawfirm_user_id == "" || lawfirm_user_id == null){
      alert('Please select a lawyer');
      return false;
    }
    loader.appendTo("#skills_spinner");
    jQuery.get("/wfm/user_work_subtypes/get_clusters_livians_and_skills_for_selected_lawyer", {
      'lawfirm_user_id' : lawfirm_user_id
    },
    function (data) {
      jQuery("#skills_spinner").html("");
    });
  } catch(e) {
    alert(e.message);
  }
}

function validate_selection(option){
  loader.appendTo('#skills_spinner')
  if(jQuery('#'+option+' option:selected').length == 0) {
    alert("Please select "+option);
    loader.remove();
    return false;
  }
  return true;
}

function listbox_moveacross(sourceID, destID) {
  var src = document.getElementById(sourceID);
  var dest = document.getElementById(destID);

  for(var count=0; count < src.options.length; count++) {
    if(src.options[count].selected == true) {
      var option = src.options[count];

      var newOption = document.createElement("option");
      newOption.value = option.value;
      newOption.text = option.text;
      newOption.selected = true;
      try {
        dest.add(newOption, null); //Standard
        src.remove(count, null);
      }catch(error) {
        dest.add(newOption); // IE only
        src.remove(count);
      }
      count--;
    }
  }
}

function update_skills(action){
  if(jQuery('#livians option:selected').length == 0){
    alert("Please select livian(s)");
    return false;
  }
  if((jQuery('#livian_skills option:selected').length == 0) && (action == 'unassign')){
    alert("Please select skill(s) to unassign");
    return false;
  }

  if((jQuery('#unassigned_skills option:selected').length == 0) && (action == 'assign')){
    alert("Please select skill(s) to assign");
    return false;
  }

  var livians = [];
  var unassigned_skills = [];
  var livian_skills = [];
  jQuery('#livians :selected').each(function(i, selected) {
    livians[i] = jQuery(selected).val();
  });
  jQuery('#unassigned_skills :selected').each(function(i, selected){
    unassigned_skills[i] = jQuery(selected).val();
  });
  jQuery('#livian_skills :selected').each(function(i, selected){
    livian_skills[i] = jQuery(selected).val();
  });
  try {
    loader.appendTo("#skills_spinner");
    jQuery.get("/wfm/user_work_subtypes/update_livian_skills",
    {
      'livians[]' : livians,
      'unassigned_skills[]' : unassigned_skills,
      'livian_skills[]' : livian_skills,
      'assign_or_unassign' : action
    },
    function (data) {
      jQuery("#skills_spinner").html("");
    });
  } catch(e) {
    alert(e.message);
  }
}

function check_due_at(id,checked){
  if(checked == true){
    jQuery('#scheduled_task_'+id).hide();
    jQuery('#start_at_'+id).hide();
    jQuery('#due_at_'+id).hide();
    jQuery('#tasks_'+id+'_start_at').val('');
    jQuery('#tasks_'+id+'_due_at').val('');
    jQuery('#chk_scheduled_task_'+id).attr('checked', false);
  } else{
    jQuery('#due_at_'+id).hide();
    jQuery('#tasks_'+id+'_start_at').val('');
  }
}

function check_scheduled_task(id,checked){
  if(checked == true){
    jQuery('#scheduled_task_'+id).show();
    jQuery('#chk_due_on_task_'+id).attr('checked', false);
    jQuery('#start_at_'+id).show();
    jQuery('#due_at_'+id).show();
  } else{
    jQuery('#scheduled_task_'+id).hide();
    jQuery('#due_at_'+id).hide();
    jQuery('#tasks_'+id+'_due_at').val('');
    jQuery('#tasks_'+id+'_start_at').val('');
  }
}

function validate_start_and_due_at_date(option){
  var check = true;
  jQuery('input:checkbox:checked.scheduled').map(function(){
    var sch_id = this.id;
    var sch_index = sch_id.replace(/[^\d.,]+/,'');
    var start_time = jQuery('#task_start_time_'+sch_index).val();
    var due_time =jQuery('#task_due_time_'+sch_index).val();
    if(option == 'from_edit'){
      var start_date = jQuery("#task_start_at").val();
      var due_at_date = jQuery("#task_due_at").val();
      var end_date = jQuery("#task_end_at").val();
    } else{
      var start_date = jQuery("#tasks_"+sch_index+"_start_at").val();
      var due_at_date = jQuery("#tasks_"+sch_index+"_due_at").val();
      var end_date = jQuery("#tasks_"+sch_index+"_end_at").val();
    }
    if (due_at_date != "") {
      if((Date.parse(start_date) > Date.parse(due_at_date))){
        alert("Due date and time should be greater than Start Date and time");
        check = false;
      } else if(Date.parse(start_date) == Date.parse(due_at_date) && start_time != "" && due_time != "" ){
        var dtStart = new Date(start_date+" "+start_time);
        var dtDue = new Date(due_at_date+" "+due_time);

        var difference_in_milliseconds = dtDue - dtStart;
        if (difference_in_milliseconds <= 0) {
          alert("Due date and time should be greater than Start Date and time");
          check = false;
        }
      }
    }
    if (end_date != "") {
      if((Date.parse(start_date) > Date.parse(end_date))){
        alert("End date should be greater than or equal to Start Date ");
        check = false;
      }
    }
  });
  return check;
}

function set_skill_level(checked,skill_id,user_id,old_level){
  if(checked == true){
    if (!jQuery('.level_'+skill_id+'_user_'+user_id).length){
      jQuery('.level_'+skill_id+'_user_'+user_id)[old_level].selectedIndex = 1;
    }
    jQuery('.level_'+skill_id+'_user_'+user_id).attr('disabled',false);
    if(jQuery('.level_'+skill_id+'_user_'+user_id).val()==""){
      if(old_level[old_level.length-1] == '-'){
        jQuery('.level_'+skill_id+'_user_'+user_id).attr('selectedIndex', 1);
      } else{
        jQuery('.level_'+skill_id+'_user_'+user_id).val(old_level);
      }
    }
  }else{
    jQuery('.level_'+skill_id+'_user_'+user_id).val('');
    jQuery('.level_'+skill_id+'_user_'+user_id).attr('disabled','disabled');
  }
}

function toggleCheckboxes(class_name,checked){
  jQuery("."+class_name).each(function(i,el){
    el.checked = checked;
    var user_id = class_name.match(/[\d.,]+/);
    var skill_id = el.value.split('-')[1];
    var old_level = jQuery('#'+user_id+'_'+skill_id).html();
    if(user_id != "" && skill_id != "" && old_level){
      set_skill_level(checked,skill_id,user_id,old_level);
    }
  });
}

function check_user_select(option){
  var alert_array = []
  var user= jQuery("#task_assigned_to_user_id").val();
  if(jQuery("#chk_reassign_task").attr('checked')==true){
    if(jQuery("#common_queue_radio_0").attr('checked')==false && user == ""){
      alert("Please select users !");
      return false;
    }
  }
  jQuery('.task_forms').each(function(i){
    cluster_users_radio = jQuery('.cluster_users_radio_'+i).is(':checked');
    common_pool_radio = jQuery('.common_pool_radio_'+i).is(':checked');
    users_select = jQuery('.users_select_'+i).val();
    if(cluster_users_radio == true || common_pool_radio == true){
      if(users_select == ""){
        alert_array.push(i+1);
      }
    }
  });
  if(alert_array.length >= 1){
    alert("Please select users !");
    return false;
  }
  return validate_start_and_due_at_date(option);
}

function add_time_with_date(date){
  var d = date.id
  var v = jQuery('#'+d).val();
  var t = jQuery('#'+d.split('time')[0]+'at').val();
  jQuery('#'+d.split('time')[0]+'at').val(t.split(' ')[0]+' '+v);
}

function reset_date(date){
  var t = jQuery(date).parent('div').find('input.time_picker')[0].id
  var d = jQuery(date).parent('div').find('input.datePicker')[0].id;
  jQuery('#'+t).val('00:00:AM');
  jQuery('#'+t).attr('disabled', true);
  jQuery('#'+d).val('');
}

function update_date_with_time(obj){
  var v = jQuery(obj).val();
  var t = jQuery('#'+obj.id.split('at')[0]+'time').val();
  jQuery('#'+obj.id.split('at')[0]+'time').attr('disabled', false);
  jQuery('#'+obj.id).val(v+' '+t);
}

function get_users_from_edit(work_subtype_id,employee_user_id){
  var reassign = jQuery('#chk_reassign_task').attr("checked");
  var user_category_type = jQuery("input[name='user_type']:checked").val();
  var task_type = jQuery("input[name='task_0_radio_1']:checked").val();
  var condition = (reassign === true && user_category_type != undefined &&  user_category_type != 'CommonPool');
  if(condition){
    loader.appendTo("#0_loader_img");
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/get_users",
      dataType: 'script',
      data: {
        'user_category_type' : user_category_type,
        "task_index" : '0',
        'from_action' : 'edit',
        "work_subtype_id" : work_subtype_id,
        "task_type" : task_type,
        "employee_user_id" : employee_user_id
      },
      success: function(transport) {
        loader.remove();
      }
    });
  }
}
function showNav(){
  jQuery(this).children('.task_details').fadeIn();
}

function hideNav(){
  jQuery(this).children('.task_details').fadeOut('fast');
}

function comment_share_with_client(comment_id, checked){
  loader.appendTo("#loader1");
  jQuery.ajax({
    type: "PUT",
    url: "/wfm/comments/"+comment_id,
    dataType: 'script',
    data: {
      'id' : comment_id,
      'share_with_client': checked
    },
    success: function(transport) { }
  });
  
}

function toggle_time_fields(index,type,from_edit){
  from_edit = (typeof from_edit == 'undefined') ? 'no' : from_edit;
  if(from_edit=='yes'){
    var date_picker_id = '#task_'+type+'_at';
  } else{
    var date_picker_id = '#tasks_'+index+'_'+type+'_at';
  }
  var time_picker_id = '#task_'+type+'_time_'+index;
  if(jQuery(date_picker_id).val() == ""){
    alert("Please select date");
    jQuery(time_picker_id).val('');
  }
}

function reset_fields(id){
  jQuery("#"+id).parent().find("input[type='text']").val('');
}

function document_share_with_client(document_id,checked){
  loader.appendTo("#loader_doc");
  jQuery.ajax({
    type: "PUT",
    url: "/wfm/document_homes/"+document_id,
    dataType: 'script',
    data: {
      'id' : document_id,
      'share_with_client': checked
    },
    success: function(transport) { }
  });
}

function actions_on_generate_task(checked){
  jQuery('#assign').attr('checked',false);
  jQuery('#complete').attr('checked',false);
  jQuery('.assign_to').hide();
  jQuery('#comment_div').hide();
  if(checked==true){
    jQuery('.gen_task').show();
  } else{
    jQuery('.gen_task').hide();
  }
}

function search_lawfirm_and_lawyers(){
  var url_str = "/wfm/notes/get_lawfirm_and_lawyers";
  jQuery('#search_lawfirm').autocomplete(url_str,{
    width : '152',
    extraParams:{
        from: "lawfirm"
      },
    formatResult: function(data, value){
      return value.split("</span>")[1];
    }
  });
 jQuery('#search_lawfirm').result(function(event,data){
    loader.appendTo('#loader1');
    var company_id = (data[0].split("</span>")[0]).split(">")[1];
    jQuery.ajax({
      type: "POST",
      url: url_str,
      dataType: 'script',
      data: {
        'company_id': company_id
      },
      success: function(transport) {
          jQuery('#search_lawyer').val('');
          search_lwayers_list();
          jQuery("#note_matter_id")[0].options.length=1;
          jQuery("#note_contact_id")[0].options.length=1;
          loader.remove();
      }
    });
  });
}

function search_lwayers_list(){
 jQuery("#search_lawyer").unautocomplete();
 var lawyer_list=[];
 jQuery('#notes_lwayers_list').children('li').each(function(index) {
    lawyer_list.push(jQuery(this).text());
 });
 jQuery("#search_lawyer").autocomplete(lawyer_list, {});
 jQuery('#search_lawyer').result(function(event,data){
 var lawyer_id='';
  jQuery('#notes_lwayers_list').children('li').each(function(index) {
      var lawyer_name = jQuery(this).text();
       if(data== lawyer_name){
        lawyer_id = this.id;
       }
  });
update_matter_contact_select(lawyer_id,data );
});
}


function reset_partial(option){
  loader.appendTo("#"+option+"_loader");
  var id = '';
  if(option == "outstanding"){
    id = 'fragment-2';
  }else if(option == "completed"){
    id = 'fragment-3';
  }
  jQuery.ajax({
    type: "POST",
    url: "/physical/clientservices/home/livian_instuction",
    dataType: 'script',
    data: {
      'id' : id
    },
    success: function(){
      loader.remove();
    }
  });
}

function check_for_parent_task(is_parent_task,id){
  if(is_parent_task=='true'){
    jQuery('#comments_div').hide();
    loader.appendTo('#loader_img');
    jQuery.ajax({
      type: "POST",
      url: "/wfm/user_tasks/check_for_parent_task",
      dataType: 'script',
      data:{
        'id' : id
      },
      success: function() {
        loader.remove();
      }
    });
  }
}

function update_work_type_select_for_note(category_type){
  loader.appendTo("#_loader_img");
  jQuery('#task_work_subtype_id').attr('length', '1');
  jQuery('#task_work_subtype_complexity_id').attr('length', '1');
  jQuery('.subText').hide();
  var lawyer_id = jQuery('#note_assigned_by_employee_user_id').val();
  jQuery.ajax({
    type: "POST",
    url: "/wfm/user_tasks/get_work_types",
    dataType: 'script',
    data: {
      'category_type' : category_type,
      'lawyer_id'     : lawyer_id
    },
    success: function(transport){
      loader.remove();
    }

  });
}

function check_validation_on_note(option,back_office_user) {
  var complete = jQuery("#complete").is(':checked');
  var assign = jQuery("#assign").is(':checked');
  var task_generate = jQuery("#generate_task").is(':checked');
  var description = jQuery(".note_text").val();
  
  if(description == ""){
    alert("Note can't be left blank !");
    return false;
  } else if(complete == true || option == "complete_form"){
    if(work_type_select_check(option,back_office_user) == false){
      return false;
    }
  } else if(assign == true || option == "assign_form"){
    var user = jQuery("#note_assigned_to_user_id").val();
    if(user == ""){
      alert("Pleace Select User !");
      return false;
    }
  }else if((task_generate == true && option == 'generate_task') || (option == 'new_task') ){
    
    if(check_work_type_validations(back_office_user) == false || check_user_select(option) == false){
      return false;
    }
  }else if(option == 'from_edit'){
    if(check_work_type_validations(back_office_user,option) == false || check_user_select(option) == false || check_user_select('generate_task') == false){
      return false;
    }
  }
}

function check_work_type_validations(back_office,from_edit){
  var work_type_error = []
  var work_subtype_error = []
  var complexity_error = []
  if(from_edit){
    work_type = jQuery('#work_type_id option:selected').val();
    work_subtype= jQuery('#task_work_subtype_id option:selected').val();
    complexity = jQuery("#back_office_task").is(':checked');
    complexity_value = jQuery('#task_work_subtype_complexity_id').val();
    if(work_type == ""){
      work_type_error.push(0);
    }else if(work_subtype ==""){
      work_subtype_error.push(0);
    }else if(complexity && complexity_value == "" && back_office == "true"){
      complexity_error.push(0);
    }
  }
  jQuery('.task_forms').each(function(i){
    work_type = jQuery('#task_'+i+'_work_types').children('select').val();
    work_subtype= jQuery('#tasks_'+i+'_work_subtype_id').val();
    complexity = jQuery("input[name='task_"+i+"_radio_1']:checked").val();
    complexity_value = jQuery('#tasks_'+i+'_work_subtype_complexity_id').val();
    if(work_type == ""){
      work_type_error.push(i+1);
    }else if(work_subtype ==''){
      work_subtype_error.push(i+1);
    }else if(complexity == "BackofficeTask" && complexity_value == '' && back_office == "true"){
      complexity_error.push(i+1);
    }
  });
  if(work_type_error.length >= 1){
    alert("Please select Work Type !");
    return false;
  } else if(work_subtype_error.length >= 1){
    alert("Please select Work Type Skills !");
    return false;
  }
  if(complexity_error.length >= 1){
    alert("Please select Complexity !");
    return false;
  }
}

function display_wday_end_date_options(val,index,pre_val){    
  if (val==='WEE'){
    jQuery('#repeat_at_'+index).show();
  } else{
    jQuery('#repeat_at_'+index).hide();
  }
  if (val== "" || val == pre_val){
    if(val == pre_val && pre_val != ""){
      jQuery('#end_at_'+index).show();
    }else{
      jQuery('#end_at_'+index).hide();
    }
    jQuery('#tasks_'+index+'_status').attr('disabled',false);
    if(index == 0){
      jQuery('#chk_complete_task').attr('disabled',false);
    }
  } else{
    jQuery('#tasks_'+index+'_status').attr('checked',false);
    jQuery('#tasks_'+index+'_status').attr('disabled',true);
    jQuery('#end_at_'+index).show();
    if(index == 0){
      jQuery('#chk_complete_task').attr('checked',false);
      jQuery('#chk_complete_task').attr('disabled',true);
      if(!jQuery('#chk_reassign_task').attr('checked')){
        jQuery('#comments_div').hide();
      }
    }
  }
}

function reassign_task_block(){
  if(jQuery('#chk_reassign_task').is(':checked') || jQuery('#chk_complete_task').is(':checked')){
    jQuery('#chk_reassign_task').attr('checked', false);
    jQuery('#chk_complete_task').attr('checked', false);
    jQuery('#update_user_div').hide();
    jQuery('#comments_div').hide();
    jQuery('input[name=user_type]').attr('checked', false);
    jQuery('#task_assigned_to_user_id')[0].options.length=1;
  }
}

function work_type_select_check(obj,back_office_user){
  var work_complexity = jQuery("#task_work_subtype_complexity_id").val();
  var work_type = jQuery('#task__work_types').children('select').val();
  var work_subtype = jQuery("#task_work_subtype_id").val();
  var work_category = jQuery("input[name='task__radio_1']:checked").val();

  if(work_type == ""){
    jQuery('input[name=user_type]').attr('checked', false);
    obj.checked = false;
    alert("Please Select Work Type !");
    return false;
  }else if(work_subtype ==""){
    jQuery('input[name=user_type]').attr('checked', false);
    obj.checked = false;
    alert("Please Select Work Sub Type !");
    return false;
  }else if(work_category == "BackofficeTask" && back_office_user == "true" && work_complexity == ""){
    jQuery('input[name=user_type]').attr('checked', false);
    obj.checked = false;
    alert("Please Select Work-Subtype Complexity !");
    return false;
  }else {
    toggle_check_uncheck(obj);
    return true;
  }
}

function toggle_subtasks_div(index,checked){
  if(index == '0'){
    if(checked){
      jQuery('.sub_task_forms').map(function(){
        jQuery(this).remove();
      });
      jQuery('#add_more_button').hide();
    } else{
      jQuery('#add_more_button').show();
    }
  }
}

function display_stt_tat(id){
  jQuery(".sub_text_").hide();
  jQuery("#tasks__complexity_stt_tat_"+id).show();
}

function update_priority(obj){
  loader.appendTo("#_loader_img");
  var prority = jQuery(obj).val();
  jQuery.ajax({
    type: "POST",
    url: "/manage_cluster/update_priority",
    dataType: 'script',
    data: {
      'priority_types' : prority
    },
    success: function(transport) {
      loader.remove();
    }

  });
}

function validateExcelFormat(){
  var filename=jQuery(".import_file").val();
  if (filename==""){
    alert("Please input a filename");
    return false;
  } else {
    arr = filename.split(".");
    exten = arr[arr.length -1].toUpperCase()
    if (!(exten =="XLS" ||exten =="ODS")) {
      alert("Please input excel file only");
      return false;
    }
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
    success: function(transport) {
      jQuery('#messages-box').slideDown();
      loader.remove();
    }
  });
}

function upload_notifications(obj,id,read,notify){
  if(notify == ''){
    jQuery(obj).text('Please Wait...');
  } else{
    jQuery(obj).html(loader);
  }    
  jQuery.ajax({
    type: "GET",
    url: "/wfm/notifications/"+id,
    dataType: 'script',
    data : {
      'read_all':true
    },
    success: function(){
      jQuery('#messages-box').slideUp();
    }
  });
}

function update_datepicker_min_date(index){
  if(index != ''){
    timezone=jQuery("#tasks_"+index+"_time_zone option:selected").text();
    zone= timezone.split('T')[1].split(')')[0].split(':');
    date_time_zone = getDate(zone.join('.'));
    jQuery("#tasks_"+index+"_start_at").datepicker( "option", "minDate", date_time_zone );
    jQuery("#tasks_"+index+"_due_at").datepicker( "option", "minDate", date_time_zone );
    jQuery("#tasks_"+index+"_end_at").datepicker( "option", "minDate", date_time_zone );
  }else{
    timezone=jQuery("#task_time_zone option:selected").text();
    zone= timezone.split('T')[1].split(')')[0].split(':');
    date_time_zone = getDate(zone.join('.'));
    jQuery("#task_start_at").datepicker( "option", "minDate", date_time_zone );
    jQuery("#task_due_at").datepicker( "option", "minDate", date_time_zone );
    jQuery("#task_end_at").datepicker( "option", "minDate", date_time_zone );
  }
  jQuery("#ui-datepicker-div").hide();
}

function getDate(offset){
  var now = new Date();
  var hour = 60*60*1000;
  var min = 60*1000;
  return new Date(now.getTime() + (now.getTimezoneOffset() * min) + (offset * hour));
}

function check_complete_status(obj){
  if(obj.value == "Completed"){
    jQuery('#from_to_date_div').show();
    jQuery('#due_date_div').hide();
  }else{
    jQuery('#due_date_div').show();
    jQuery('#from_to_date_div').hide();
  }
}

function validate_filters_dates(option){
  var from_date = jQuery('#search_from_date').val();
  var to_date = jQuery('#search_to_date').val();
  var status = jQuery('#search_status').val();
  if(status == "Completed"){
    if(from_date != "" && to_date != ""){
      if (Date.parse(from_date) > Date.parse(to_date)){
        alert("To Date should be greater than From Date");
        return false;
      }
    }else {
      alert("Please Specify Both the dates")
      return false;
    }
  }else{
    return true;
  }
}

function check_for_livian(note_id,current_user){
   if(jQuery('#lock_'+note_id).attr('checked')){
     var checked = 1;
     var message = "Note will be locked Are You Sure";
     var value = false;
   }
   else{
      var checked = 0;
      var message = "Note will be Unlocked Are You Sure";
       var value = true;
   }
          if(confirm(message)){
               jQuery.ajax({
                    type: "POST",
                    url: "/wfm/notes/allow_lock",
                    dataType: 'script',
                    data: {
                        'note_id': note_id,
                        'current_user_id':current_user,
                        'checked': checked
                    },
                    success: function(transport)
                    {
                    }
              });
          }
          else{
            jQuery('#lock_'+note_id).attr('checked', value);
          }
}
