jQuery.noConflict();
jQuery(function() {

  jQuery("#datepicker_time_entry").datepicker({
    showOn: 'both',
    dateFormat: 'mm/dd/yy',
    changeMonth: true,
    changeYear: true,
    onSelect: function(value,date){
      var today = today_date();
      var newdate = new Date(value);
      var time_entry_date
      var from = jQuery('#from').val();
      if(from != 'matters'){
        if( newdate > today ){
          var date_confirm = confirm('Details being entered are for a future date. Click OK to proceed.');
          if(date_confirm){
            var time_entry_date = jQuery('#datepicker_time_entry').val();
            document.location = '/physical/timeandexpenses/time_and_expenses/new?time_entry_date='+time_entry_date;
          }else{
            jQuery('#datepicker_time_entry').val((today.getMonth()+1)+'/'+today.getDate()+'/'+today.getFullYear());
          }
        }else{
          time_entry_date = jQuery('#datepicker_time_entry').val();
          document.location = '/physical/timeandexpenses/time_and_expenses/new?time_entry_date='+time_entry_date;
        }
        jQuery('#physical_timeandexpenses_time_entry_time_entry_date').val(time_entry_date);
      }
    }
  });

  jQuery('.edit_timeentry_actual_duration').editable('/physical/timeandexpenses/time_entries/set_time_entry_actual_duration?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    width : '30px',
    maxlength :6,
    is_duration: true,
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_starttime').editable('/physical/timeandexpenses/time_entries/set_time_entry_formatted_start_time?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"  />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    inputclassname : 'starttime',
    width : '75px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_endtime').editable('/physical/timeandexpenses/time_entries/set_time_entry_formatted_end_time?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    inputclassname : 'endtime',
    width : '75px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_description').editable('/physical/timeandexpenses/time_entries/set_time_entry_description',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    truncate_no : 150,
    txtValidation : true,
    type : 'textarea',
    height : '45px',
    width : '200px',
    tooltip   : 'Click to edit'
  });

  jQuery('.edit_timeentry_bill_rate').editable('/physical/timeandexpenses/time_entries/set_time_entry_actual_bill_rate?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    maxlength : 7,
    istimeEntryRate : true,
    width : '50px',
    is_int : true,
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_billing_percent').editable('/physical/timeandexpenses/time_entries/set_time_entry_billing_percent?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    is_discount : true,
    amount_field_id_name : 'calculated_amount_',
    width : '50px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_overrideamount').editable('/physical/timeandexpenses/time_entries/set_time_entry_billing_amount?time_entry_date='+jQuery("#date_time").val()+'&view_type='+jQuery("#viewType").val()+'&start_date='+jQuery("#start_date").val()+'&end_date='+jQuery("#end_date").val(),{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    maxlength : 12,
    is_amount : true,
    amount_field_id_name : 'calculated_amount_',
    width : '50px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.editexpensedescription').editable('/physical/timeandexpenses/expense_entries/set_expense_entry_description',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    truncate_no : 150,
    txtValidation : true,
    type : 'textarea',
    height : '45px',
    width : '200px',
    tooltip   : 'Click to edit'
  });

  jQuery('.editexpenseamount').editable('/physical/timeandexpenses/expense_entries/set_expense_entry_expense_amount',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    maxlength : 12,
    width : '50px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.editexpensebillingpercent').editable('/physical/timeandexpenses/expense_entries/set_expense_entry_billing_percent1',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    is_discount : true,
    amount_field_id_name : 'actual_expense_amount_',
    width : '50px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.editexpensebillingamt').editable('/physical/timeandexpenses/expense_entries/set_expense_entry_billing_amount',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    is_amount : true,
    maxlength : 12,
    amount_field_id_name : 'actual_expense_amount_',
    width : '50px',
    ajaxoptions: {
      dataType: 'script'
    }
  });
});

function showMattersForSelectedContact(id){
  var matter_id = jQuery('#'+id.toString() + '_matter_id').val();
  var contact_id = jQuery('#'+id.toString() + '_contact_id').val();
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#" + id + "_matterSpinner");
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_all_matters',
    data: {
      contact_id : contact_id ,
      matter_id : matter_id,
      time_entry_id : id
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function get_all_matters( id, time_entry_id, expense_entries ){
  var tmp = id.split('_');
  var contact_id = tmp[1];
  var matter_id = jQuery( '#'+time_entry_id.toString() + '_matter_id' ).val();
  var expense_entries_array = "[";
  for ( var i=0, len=expense_entries.length; i<len; ++i ){
    expense_entries_array = expense_entries_array + expense_entries[i] + ",";
  }
  expense_entries_array = expense_entries_array + "]";

  if (contact_id == "" && matter_id == ""){
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', true);
    set_is_billable(time_entry_id, expense_entries);
  }else{
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', false);
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr("onClick", "set_is_billable("+time_entry_id+","+ expense_entries_array+");");
    set_is_billable(time_entry_id, expense_entries);
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_all_matters',
    data: {
      contact_id : contact_id ,
      matter_id : matter_id,
      time_entry_id : time_entry_id,
      isBillableSet : 'yes'
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function update_matter_contact( id ){
  var matter_id = jQuery('#'+id.toString() + '_matter_id').val();
  var contact_id = jQuery('#'+id.toString() + '_contact_id').val();
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#" + id + "_contactSpinner");
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_matters_contact',
    data: {
      matter_id : matter_id,
      contact_id :contact_id,
      time_entry_id : id
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function updateContactORMatter( obj, ID, type, expense_entries, methodName ){
  var idStr = ID+"_"+type+"_id";
  var divTag, searchDiv;
  if(type == "matter"){
    divTag = jQuery('#'+ID+'_matters_div');
    searchDiv = jQuery('#'+ID+'_matterSearch');
  }else{
    divTag = jQuery('#'+ID+'_contact_span');
    searchDiv = jQuery('#'+ID+'_contactSearch');
  }
  if(divTag.html() !=""){
    divTag.html("");
    if(type !='contact'){
      idStr = ID+"_"+type+"_id"
      var str = '<input type="hidden" value="" id="'+idStr+'" name="'+ID+'"[matter_id]" />';
      searchDiv.append(str);
      searchDiv.show();
    }
  }
  var entryID =obj.id.replace(/[^0-9\\.]/g, '');
  var cnt = obj.id.split("_");
  jQuery('#'+ID+'_'+type+'_id').val(cnt[1]);
  jQuery('#'+ID+'_'+type+'_ctl').val(obj.innerHTML.replace(/&amp;/g, "&"));
  hideMatterORContactListBox();
  if(expense_entries ==null){
    eval(methodName)(obj.id,ID,entryID);
  }else{
    eval(methodName)(obj.id,ID, expense_entries,entryID);
  }
}

function get_matters_contact( id, time_entry_id, expense_entries, mat_id ){
  var tmp = id.split('_');
  var matter_id = tmp[1];
  if(mat_id != null && mat_id != ""){
    matter_id = mat_id
  }
  var contact_id = jQuery('#'+time_entry_id.toString() + '_contact_id').val();
  var expense_entries_array = "[";
  for ( var i=0, len=expense_entries.length; i<len; ++i ){
    expense_entries_array = expense_entries_array + expense_entries[i] + ",";
  }
  expense_entries_array = expense_entries_array + "]";
  if (contact_id == "" && matter_id == ""){
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', true);
    set_is_billable(time_entry_id, expense_entries);
  }else{
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', false);
    jQuery('#'+time_entry_id.toString() + '_is_internal').attr("onClick", "set_is_billable("+time_entry_id+","+expense_entries_array+");");
    jQuery('#'+time_entry_id.toString()+'_is_billable').attr("checked", true);
    jQuery('#'+time_entry_id.toString()+'_is_billable').attr("disabled", false);
    set_is_billable(time_entry_id, expense_entries);
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_matters_contact',
    data: {
      matter_id : matter_id,
      contact_id :contact_id,
      time_entry_id : time_entry_id,
      isBillableSet : 'yes'
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function get_all_expense_matters( id, expense_entry_id, cont_id ){
  var contact_id = jQuery('#'+id).val();
  var matter_id = jQuery('#'+ expense_entry_id.toString() + '_expense_matter_id'  ).val();
  if( cont_id !=null && cont_id !=""){
    contact_id = cont_id
  }
  if (contact_id == "" && matter_id == ""){
    jQuery('#'+ expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',true);
    set_is_billable_for_expense_entry(expense_entry_id);
  }else{
    jQuery('#'+expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',false);
    jQuery('#'+expense_entry_id + '_is_internal_for_expense_entry').attr("onClick", "set_is_billable_for_expense_entry('"+expense_entry_id+"');");
    set_is_billable_for_expense_entry(expense_entry_id);
  }
  var tempObj = jQuery('#'+expense_entry_id.toString() + '_matter_id');
  if(tempObj !=null && tempObj.length > 0 ){
    tempObj.remove();
  }//end if
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#" + expense_entry_id.toString() + '_contactSpinner');
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_all_expense_matters',
    data: {
      contact_id : contact_id ,
      matter_id : matter_id,
      expense_entry_id : expense_entry_id
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function get_expense_matters_contact( id, expense_entry_id, mat_id ){
  var matter_id = jQuery('#'+id).val();
  if(mat_id != null && mat_id != ""){
    matter_id = mat_id
  }
  var contact_id = jQuery('#'+expense_entry_id.toString() + '_expense_contact_id').val();
  if (contact_id == "" && matter_id == ""){
    jQuery('#'+expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',true);
    set_is_billable_for_expense_entry(expense_entry_id);
  }else{
    jQuery('#'+expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',false);
    jQuery('#'+expense_entry_id + '_is_internal_for_expense_entry').attr("onClick", "set_is_billable_for_expense_entry('"+expense_entry_id+"');");
    set_is_billable_for_expense_entry(expense_entry_id);
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#" + expense_entry_id + '_contactSpinner');
      jQuery('body').css("cursor", "wait");
    },
    type: 'get',
    url: '/physical/timeandexpenses/time_and_expenses/get_expense_matters_contact',
    data: {
      matter_id : matter_id,
      contact_id :contact_id,
      expense_entry_id : expense_entry_id
    } ,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function set_is_billable( id, expense_entries ){
  var time_entry_date = jQuery("#date_time").val();
  var view_type= jQuery("#viewType").val();  
  if (jQuery('#'+id+'_is_internal').attr('checked')){
    jQuery('#'+id+'_matters_div').html('');
    jQuery('#'+id+'_matterSearch').show();
    jQuery('#'+id+'_matter_ctl').attr("title","search");
    jQuery('#'+id+'_matter_ctl').val("");
    jQuery('#'+id+'_contact_span').html('');
    jQuery('#'+id+'_contactSearch').show();
    jQuery('#'+id+'_contact_ctl').val("");
    jQuery('#'+id+'_contact_ctl').attr("title","search");
    var billing_method_type = 1;
    var billing_type = 2;
    var is_internal = true;
    jQuery('#'+id+'_is_billable').attr("checked", false);
    jQuery('#'+id+'_is_billable').attr("disabled", true);
    jQuery('#billing_options_for_entry_'+id).hide();
    jQuery('#'+id+'_matter_id').val('');
    jQuery('#'+id+'_contact_id').val('');
    if(expense_entries != "0"){
      for ( var i = 0, len = expense_entries.length; i < len; ++i ){
        jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("checked", false);
        jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("disabled", true);
        jQuery('#expense_entry_billing_options_'+expense_entries[i].toString()).hide();
        jQuery('#expense_final_billed_amount_'+expense_entries[i].toString()).hide();
      }
    }
    jQuery('#'+id + '_is_internal').attr("onClick", "show_alert_for_matter_and_contact('"+id+"_is_internal');");
  }else{
    if(expense_entries != "0"){
      for ( var i = 0, len = expense_entries.length; i < len; ++i ){
        jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("checked", true);
        jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("disabled", false);
        if(jQuery('#'+id+'_is_billable').attr("checked")){
          jQuery('#expense_entry_billing_options_'+expense_entries[i].toString()).show();
        }
        jQuery('#expense_final_billed_amount_'+expense_entries[i].toString()).show();
      }
    }
    var is_internal = false;   
    if(jQuery('#'+id+'_is_billable:checked').val() == 1){
      jQuery('#'+id+'_saved_entry_billing_method_type').attr('selectedIndex', 0);
      jQuery('#'+id+'_show_amount').attr("disabled",true);
      var billing_type = 1;     
      jQuery('#billing_options_for_entry_'+id).show();
    }else{        
      var billing_type = 2;     
      jQuery('#'+id+'_is_billable').attr("disabled", false);
      jQuery('#billing_options_for_entry_'+id).hide();
    }
  }
  var billing_method_type = jQuery('#'+id+'_saved_entry_billing_method_type option:selected' ).val();
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/time_entries/set_is_billable?view_type='+view_type+'&time_entry_date='+time_entry_date,
    data: {
      billing_type : billing_type,
      is_internal: is_internal,
      billing_method_type : billing_method_type,
      id: id
    },
    dataType : 'script'
  });
}

function set_is_billable_for_expense_entry( id ){
  var accounted_type_expense_entry = '#'+ id+'_is_internal_for_expense_entry';
  var time_entry_date = jQuery("#date_time").val();
  var view_type= jQuery("#viewType").val();  
  if (jQuery(accounted_type_expense_entry).attr('checked')){
    var billing_type = 2;
    var is_internal = true;
    jQuery('#'+id+'_expense_is_billable').attr("checked",false);
    jQuery('#'+id+'_expense_is_billable').attr("disabled","disabled");
    jQuery('#expense_entry_billing_options_'+id).hide();
    jQuery('#'+id+'_expense_matter_id').val('');
    jQuery('#'+id+'_expense_contact_id').val('');
    jQuery('#'+id+'_matter_ctl').val('');
    jQuery('#'+id+'_contact_ctl').val('');
    jQuery('#'+id + '_is_internal_for_expense_entry').attr("onClick", "show_alert_for_matter_and_contact('"+id+"_is_internal_for_expense_entry');");
  }else{
    var is_internal = false;
    if(jQuery('#'+id+'_expense_is_billable:checked').val() == 1){
      var billing_type = 1;      
      jQuery('#expense_entry_billing_options_'+id).show();
      jQuery('#'+id+'_expense_entry_billing_method_type').attr('selectedIndex', 0);
      jQuery('#'+id+'_show_amount').val(jQuery('#expenseamount_'+id).children('span').html());
      jQuery('#expense_final_billed_amount_'+id).html(jQuery('#expenseamount_'+id).children('span').html().replace(/,/g,''))      
      jQuery('#'+id+'_show_amount').attr("disabled",true);
    }else{
      var billing_type = 2;      
      jQuery('#'+id+'_expense_is_billable').attr("disabled",false);
      jQuery('#expense_entry_billing_options_'+id).hide();
    }
  }
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/expense_entries/set_expense_is_billable?view_type='+view_type+'&time_entry_date='+time_entry_date,
    data: {
      billing_type : billing_type,
      is_internal: is_internal,
      id: id
    } ,
    dataType : 'script'
  });
}

function set_expense_is_billable(billing_type, expense_entry){
  var is_internal = false;
  var time_entry_date = jQuery("#date_time").val();
  var view_type= jQuery("#viewType").val();  
  if(jQuery('#'+billing_type+':checked').val() == 1){
    var billing_type = 1;
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('selectedIndex', 0);
    jQuery('#'+expense_entry+'_show_amount').val(jQuery('#expenseamount_'+expense_entry).children('span').html().replace(/,/g,''));
    jQuery('#expense_final_billed_amount_'+expense_entry).children('span').html(jQuery('#expenseamount_'+expense_entry).children('span').html().replace(/,/g,''))
    jQuery('#'+expense_entry+'_show_amount').attr("disabled",true);
    jQuery('#expense_entry_billing_options_'+expense_entry).show();
  }else{
    var billing_type = 2;   
    jQuery('#expense_entry_billing_options_'+expense_entry).hide();
  }
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/expense_entries/set_expense_is_billable?view_type='+view_type+'&time_entry_date='+time_entry_date,
    data: {
      billing_type : billing_type,
      is_internal: is_internal,
      id: expense_entry
    } ,
    dataType : 'script'
  });
}

function show_alert_for_matter_and_contact( id ){
  jQuery('#'+id).attr('checked',true);
  alert('Select matter/contact or check internal.');
  return;
}

function initeditexpense_type( expensetypes ){
  jQuery.noConflict();
  jQuery(function() {
    jQuery('.editexpense_type').editable('/physical/timeandexpenses/expense_entries/set_expense_entry_expense_type',{
      cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
      submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
      indicator : '<img src="/images/livia_portal/indicator.gif" />',
      style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
      data : expensetypes,
      type : 'select',
      width : '150px',
      tooltip   : 'Click to edit'
    });
  });
}

function initedit_timentry_activity(){
  jQuery.noConflict();
  jQuery(function() {
    jQuery('.edit_timeentry_activity').editable('/physical/timeandexpenses/time_entries/set_time_entry_activity_type',{
      cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
      submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
      indicator : '<img src="/images/livia_portal/indicator.gif" />',
      style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
      data : activitytypes,
      type : 'select',
      width : '150px',
      tooltip   : 'Click to edit'
    });
  });
}

function init_edit_time_entry_status(){
  jQuery.noConflict();
  jQuery(function() {
    jQuery('.edit_time_entry_status').editable('/physical/timeandexpenses/time_entries/set_time_entry_status',{
      cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
      submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
      indicator : '<img src="/images/livia_portal/indicator.gif" />',
      style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
      data : status,
      type : 'select',
      width : '150px',
      tooltip   : 'Click to edit'
    });
  });
}

function init_edit_expense_entry_status(){
  jQuery.noConflict();
  jQuery(function() {
    jQuery('.edit_expense_entry_status').editable('set_expense_entry_status',{
      cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
      submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
      indicator : '<img src="/images/livia_portal/indicator.gif" />',
      style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
      data : status,
      type : 'select',
      width : '150px',
      tooltip   : 'Click to edit'
    });
  });
}

function change_time_entry_status( id, url ){
  var status = jQuery('#time_entry_'+id.toString() + '_status').val();
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/time_and_expenses/set_time_entry_status',
    data: {
      id : id ,
      value : status
    } ,
    dataType: 'text/html',
    success: function(html){
      jQuery("#time_"+id).html(html);
    },
    error: function(){
      window.location = url;
    }
  });
}

function change_time_entry_status_in_all_te( id, url ){
  var status = jQuery('#time_entry_'+id.toString() + '_status').val();
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/time_and_expenses/set_time_entry_status',
    data: {
      id : id ,
      value : status,
      from: "new"
    } ,
    dataType: 'text/html',
    success: function(html){
      window.location = url;
    },
    error: function(){
      window.location = url;
    }
  });
}

function change_expense_entry_status(id, url){
  var status = jQuery('#expense_entry_'+id.toString() + '_status').val();
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/expense_entries/set_expense_entry_status',
    data: {
      id : id ,
      value : status
    } ,
    dataType: 'text/html',
    success: function(html){
      jQuery("#expense_"+id).remove();
       window.location = url;
    },
    error: function(){
      window.location = url;
    }
  });
}

function change_expense_entry_status_in_all_te( id, url ){
  var status = jQuery('#expense_entry_'+id.toString() + '_status').val();
  jQuery.ajax({
    type: 'post',
    url: '/physical/timeandexpenses/expense_entries/set_expense_entry_status',
    data: {
      id : id ,
      value : status,
      from: "new"
    } ,
    dataType: 'text/html',
    success: function(html){
      window.location = url;
    },
    error: function(){
      window.location = url;
    }
  });
}
