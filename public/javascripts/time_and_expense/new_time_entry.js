jQuery.noConflict();
jQuery(document).ready(function() {
  jQuery("#datepicker_time_entry").datepicker({
    showOn: 'both',
    dateFormat: 'mm/dd/yy',
    changeMonth: true,
    changeYear: true,
    onSelect: function(value,date){
      var today = today_date();
      var newdate = new Date(value);
      if( newdate > today ){
        var date_confirm = confirm('Details being entered are for a future date. Click OK to proceed.');
        if(date_confirm){
          var time_entry_date = jQuery('#datepicker_time_entry').val();
          return;
        }else{
          jQuery('#datepicker_time_entry').val((today.getMonth()+1)+'/'+today.getDate()+'/'+today.getFullYear());
          return;
        }
      }else{
        var time_entry_date = jQuery('#datepicker_time_entry').val();
      }
      jQuery('#physical_timeandexpenses_time_entry_time_entry_date').val(time_entry_date);
      var selectedDate = null;
      var time_entry_employee_user_id = jQuery('#physical_timeandexpenses_time_entry_employee_user_id').val();
      if(jQuery('#matter_list_box_hidden').length > 0){
        selectedDate = new Date(time_entry_date);
        var elems = jQuery('.matters_is_by_date');
        for(i=0; i < elems.length; i++){
          var matterDate = new Date(elems[i].getAttribute('date_str'));
          if(selectedDate < matterDate){
            elems[i].style.display = 'none';
          }
        }
        jQuery('#_matter_ctl').val("");
        jQuery('#_matter_ctl').attr("title",'search');
        jQuery('#physical_timeandexpenses_time_entry_matter_id').val("");
        jQuery('#_contact_ctl').val("");
        jQuery('#_contact_ctl').attr("title",'search');
        jQuery('#_contact_ctl').val("");
        jQuery('#physical_timeandexpenses_time_entry_contact_id').val("");
        var previousSelectedEntryDate = new Date(jQuery('#previous_entry_date').val());
        if(selectedDate > previousSelectedEntryDate)
          jQuery('.drop_down').css('display', 'none');
        jQuery.ajax({
          beforeSend: function(){
            jQuery('body').css("cursor", "wait");
          },
          type: 'GET',
          url: '/physical/timeandexpenses/unexpired_matters',
          data: {
            time_entry_date : time_entry_date,
            time_entry_employee_user_id : time_entry_employee_user_id
          },
          async: true,
          dataType: 'script',
          complete: function(){
            jQuery('body').css("cursor", "default");
          },
          success: function(){
            jQuery('.drop_down').css('display', '');
          }
        });
      }
      jQuery('#previous_entry_date').val(jQuery('#datepicker_time_entry').val());
    }
  });
});

function get_activity_rate(){ 
  var activity_type_id = jQuery('#physical_timeandexpenses_time_entry_activity_type').val();
  var employee_id = jQuery('#physical_timeandexpenses_time_entry_employee_user_id').val();
  jQuery.ajax({
    type: 'GET',
    url: '/physical/timeandexpenses/get_activity_rate',
    data: {
      activity_type_id : activity_type_id,
      employee_id: employee_id
    },
    async: true,
    dataType: 'script'
  });
  calculate_bill_amount();
}

//function get_tne_invoice_activity_rate() - Removed.

function timeOrExpenseFullAmount(obj, type, methodName, timeOrExpenseId){
  var fullAmount;
  var finalAmount;
  if(type =='time_entries'){
    fullAmount = jQuery('#billed_amount_'+timeOrExpenseId).children('span').html().replace(/,/g,'');
    finalAmount = jQuery('#final_billed_amount_'+timeOrExpenseId).children('span').html().replace(/,/g,'');
    try{
      fullAmount = parseFloat(fullAmount);
      finalAmount = parseFloat(finalAmount);
      if(finalAmount == fullAmount){
        return;
      }
    }catch (exception){
      return;
    }
  }else{
    fullAmount = jQuery('#expenseamount_'+timeOrExpenseId).children('span').html().replace(/,/g,'');
    finalAmount = jQuery('#expense_final_billed_amount_'+timeOrExpenseId).html().replace(/,/g,'');
    try{
      fullAmount = parseFloat(fullAmount);
      finalAmount = parseFloat(finalAmount);
      if(finalAmount == fullAmount){
        return;
      }
    }catch(exception){
      return;
    }
  }
  var elems = jQuery('.input_class');
  for(var i = 0; i < elems.length; i++){
    elems[i].disabled=true;
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo(obj.parentNode);
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/'+type+'/'+methodName,
    data: {
      id : timeOrExpenseId
    },
    async: true,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
      jQuery.getScript("/javascripts/time_and_expense/new_time_entry.js");
      obj.style.display='';
    }
  });
}

function updateTimeUtilities(obj,type,methodName,timeOrExpenseId){
  try{
    var text_val = parseFloat(obj.value.replace(/,/g,''));
    if(isNaN(text_val) == true){
      alert("Please enter numeric value");
      return;
    }
    if((text_val < 0 || text_val > 100) && (methodName.match(/percent/))){
      alert("Please Enter Discount between 0.01 to 100");
      obj.value="";
    }else if((text_val < 0 || text_val > 1000) && (methodName.match(/markup/))){
      alert("Please Enter Markup between 0.01 to 1000");
      obj.value = "";
    }else{
      jQuery.ajax({
        beforeSend: function(){
          loader.prependTo(obj.parentNode);
          obj.style.display = 'none';
          jQuery('body').css("cursor", "wait");
        },
        type: 'GET',
        url: '/physical/timeandexpenses/'+type+'/'+methodName,
        data: {
          id : timeOrExpenseId,
          value : text_val
        },
        async: true,
        dataType: 'script',
        complete: function(){
          jQuery('body').css("cursor", "default");
          loader.remove();
          obj.style.display = 'block';
          jQuery.getScript("/javascripts/time_and_expense/new_time_entry.js");
        }
      });
    }
  }catch(exception){
    alert("Please enter numeric value");
  }
}

function timeExpenseEditable(obj){
  var elems = jQuery('.input_class');
  for(var i = 0;i < elems.length; i++){
    elems[i].disabled=true;
  }
  if(obj){
    jQuery('#'+obj).removeAttr("disabled");
  }
}

function set_activity_rate(activity_rate){
  jQuery('#physical_timeandexpenses_time_entry_actual_activity_rate').val(activity_rate);
}

function calculatedDuration(setting_type){
  if(setting_type == true){
    var daysDifference = Math.floor(difference/1000/60/60/24);
    if(!daysDifference <= 0){
      difference -= daysDifference*1000*60*60*24;
    }
    hoursDifference = Math.floor(difference/1000/60/60);
    if(!hoursDifference <= 0){
      difference -= hoursDifference*1000*60*60;
    }
    var minutesDifference = Math.floor(difference/1000/60);
    difference -= minutesDifference*1000*60;
    return actual_duration  = hoursDifference + parseFloat((minutesDifference/60).toFixed(2));
  }
  else{
    var minutesDifference = Math.floor(difference/1000/60);
    var actual_duration  = hoursDifference + parseFloat((minutesDifference/60));
    var hours = minutesDifference/60;
    var minutes= minutesDifference%60;
    if(minutes!=0)
    {
      var minutes_mod = minutes%60;
      if(minutes_mod!=0)
      {
        var minutes_of_minute = minutes_mod/6;
        var minutes_of_minute_mod = minutes_mod%6;
        if(minutes_of_minute_mod!=0)
        {
          var hoursInt = parseInt(hours);
          var minutes_of_minuteInt = parseInt(minutes_of_minute);
          minutes_of_minuteInt = minutes_of_minuteInt + 1;
          var fin = hoursInt.toString() +"."+ minutes_of_minuteInt.toString();
          return actual_duration = (fin =='') ? '' : fin
        }
        else
        {
          return actual_duration = (actual_duration=="") ? "" : actual_duration
        }
      }
    }
    else
    {
      return actual_duration = (actual_duration=="")? "" : actual_duration
    }
  }
}


function timeDifference(setting_type){
  var object_id =''
  if(jQuery("#physical_timeandexpenses_time_entry_start_time").val() == undefined){
    object_id= 'tne_invoice_time_entry'
  }
  else{
    object_id = 'physical_timeandexpenses_time_entry'
  }
  var start_val = jQuery("#"+object_id+"_start_time").val();
  var end_val = jQuery("#"+object_id+"_end_time").val();
  var hoursDifference=0.0;
  if(start_val == "00:00 PM" || end_val == "00:00 PM"){
    return;
  }
  var time_start = (new Date (today_date().toDateString() + ' ' + start_val));
  var time_end = (new Date (today_date().toDateString() + ' ' + end_val));
  var difference = time_end.getTime() - time_start.getTime();
  var actual_duration
  if(isNaN(difference)){
    actual_duration = ""
  }else{
    if(difference <= 0 ){
      alert('The end time should be greater than start time');
      jQuery("#"+object_id+"_actual_duration").val("");
      return;
    }
    if(setting_type == true){
      var daysDifference = Math.floor(difference/1000/60/60/24);
      if(!daysDifference <= 0){
        difference -= daysDifference*1000*60*60*24;
      }
      hoursDifference = Math.floor(difference/1000/60/60);
      if(!hoursDifference <= 0){
        difference -= hoursDifference*1000*60*60;
      }
      var minutesDifference = Math.floor(difference/1000/60);
      difference -= minutesDifference*1000*60;
      actual_duration  = hoursDifference + parseFloat((minutesDifference/60).toFixed(2));
    }
    else{
      var minutesDifference = Math.floor(difference/1000/60);
      var actual_duration  = hoursDifference + parseFloat((minutesDifference/60));
      var hours = minutesDifference/60;
      var minutes= minutesDifference%60;
      if(minutes!=0)
      {
        var minutes_mod = minutes%60;
        if(minutes_mod!=0)
        {
          var minutes_of_minute = minutes_mod/6;
          var minutes_of_minute_mod = minutes_mod%6;
          if(minutes > 54 )
          {
            var hoursInt = parseInt(hours);
            actual_duration = hoursInt + 1;
            actual_duration=parseFloat(actual_duration).toFixed(1);
          }
          if(minutes_of_minute_mod!=0 && minutes < 54)
          {
            var hoursInt = parseInt(hours);
            var minutes_of_minuteInt = parseInt(minutes_of_minute);
            minutes_of_minuteInt = minutes_of_minuteInt + 1;
            var fin = hoursInt.toString() +"."+ minutes_of_minuteInt.toString();
            var actual_duration = (fin =='') ? '' : fin
          }
          else
          {
            var actual_duration = (actual_duration=="") ? "" : actual_duration
          }
        }
      }
      else
      {
        var actual_duration = (actual_duration=="")? "" : actual_duration
      }
    }
  }
  jQuery("#"+object_id+"_actual_duration").val(actual_duration);
  jQuery("#hidden_duration").val(hoursDifference + '.' + minutesDifference);
  var bill_rate = jQuery("#"+object_id+"_actual_activity_rate").val().replace(/\,/g,'');
  actual_duration = (actual_duration=="" ? 0 : actual_duration)
  if(jQuery("#"+object_id+"_is_billable").is(':checked')){
    jQuery('#final_billed_amount').html((actual_duration * bill_rate).toFixed(2));
  }
  jQuery('#bill_amount').html((actual_duration * bill_rate).toFixed(2));
}

function resetDuration( obj,isOneHundreth ){
  var val = jQuery("#hidden_duration").val();
  try{
    var obj_val = parseFloat(obj.value);
    if(isNaN(obj_val) || obj_val < 0 || obj_val > 24){
      alert("Please enter duration between 0.01 to 24.00");
      return;
    } else if(obj_val > val){
      obj.value = isOneHundreth ? obj_val.toFixed(2) : obj_val.toFixed(1);
      var from_time_or_invoice = obj.id.split('actual_duration')[0];

      newEntryBillAmount(obj,from_time_or_invoice);
    }
  }catch(exception){
    alert(exception.toString());
  }
}

//function calculateTimeEnteryAmount(){} - Removed.

function get_time_difference( time_diff ){
  jQuery("#notice").html('');
  jQuery.ajax({
    type: 'GET',
    url: '/physical/timeandexpenses/get_time_difference',
    data: jQuery("#new_physical_timeandexpenses_time_entry").serialize(),
    async: true,
    dataType: 'script'
  });
}

function set_time_difference( time_diff ){
  jQuery('#physical_timeandexpenses_time_entry_actual_duration').val(time_diff);
}

function set_time_values_to_blank(){
  jQuery('#physical_timeandexpenses_time_entry_start_time').val('');
  jQuery('#physical_timeandexpenses_time_entry_end_time').val('');
  jQuery('#physical_timeandexpenses_time_entry_actual_duration').val('');
}

//function time_difference_error( error ) - Removed.

function calculate_billing_percent( obj ){
  try{
    var val = parseFloat(obj.value);
    var bill_amount = parseFloat(jQuery('#bill_amount').html().replace(',',''));
    if(isNaN(val) || val < 0 || val > 100){
      alert("Please Enter Discount between 0.01 to 100");
      jQuery('#'+obj.id).select();
      return false;
    }else{
      if(isNaN(bill_amount) || bill_amount != null && bill_amount > 0){
        bill_amount -= ((parseFloat(bill_amount) * val)) / 100;
        jQuery('#final_billed_amount').html(bill_amount.toFixed(2));
        obj.value = val.toFixed(2);
      }
    }
  }catch(exception){
    alert("Please Enter Discount between 0.01 to 100");
    return false;
  }
}

function enable_disable_time_entry_billing( obj ){
  if(jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').is(':checked')){
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('disabled', true);
    jQuery('#physical_timeandexpenses_time_entry_contact_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_matter_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr("onClick", "alert_for_matter_and_contact('physical_timeandexpenses_time_entry_accounted_for_type');");
    jQuery('#show_amount').val('');
    jQuery('#show_amount').attr('disabled', false);
    resetMatterContactFields();
  }
  if (!jQuery('#physical_timeandexpenses_time_entry_is_billable').is(':checked')){
    jQuery('#physical_timeandexpenses_time_entry_billing_method_type').attr('disabled', true);
    jQuery('#show_amount').val('');
    jQuery('#show_amount').attr('disabled', true);
    jQuery('#final_billed_amount').html('0.00');
  }else{
    jQuery('#physical_timeandexpenses_time_entry_billing_method_type').attr('disabled', false);
    newEntryBillAmount(obj,'physical_timeandexpenses_time_entry_');
  }
}

function enable_disable_tne_invoice_time_entry_billing( obj ){
  if(jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').is(':checked')){
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('disabled', true);
    jQuery('#physical_timeandexpenses_time_entry_contact_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_matter_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr("onClick", "alert_for_matter_and_contact('physical_timeandexpenses_time_entry_accounted_for_type');");
    jQuery('#show_amount').val('');
    jQuery('#show_amount').attr('disabled', false);
    resetMatterContactFields();
  }
  if (!jQuery('#tne_invoice_time_entry_is_billable').is(':checked')){
    jQuery('#tne_invoice_time_entry_billing_method_type').attr('disabled', true);
    jQuery('#show_amount').val('');
    jQuery('#show_amount').attr('disabled', true);
    jQuery('#final_billed_amount').html('0.00');
  }else{
    jQuery('#tne_invoice_time_entry_billing_method_type').attr('disabled', false);
    newEntryBillAmount(obj,'tne_invoice_time_entry_');
  }
}

function new_time_entry_get_all_matters( entryID ){
  jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('disabled', true);
  employee_id = jQuery('#physical_timeandexpenses_time_entry_employee_user_id').val();
  activity_type_id = jQuery('#physical_timeandexpenses_time_entry_activity_type').val();
  var matterObj = jQuery('#physical_timeandexpenses_time_entry_matter_id');
  var contactObj = jQuery('#physical_timeandexpenses_time_entry_contact_id');
  var matter_id = matterObj.val();
  var contact_id = contactObj.val();
  var entry_date = jQuery('#datepicker_time_entry').val();
  //  var entry_date = jQuery('#physical_timeandexpenses_time_entry_time_entry_date').val();
  if (contact_id == "" && matter_id == ""){
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', true);
    enable_disable_time_entry_billing();
  }else{
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr("onClick", "enable_disable_time_entry_billing();");
    enable_disable_time_entry_billing();
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/get_all_new_matters',
    data: {
      'contact_id' : contact_id,
      'matter_id' : matter_id,
      'time_entry_date' : entry_date,
      'employee_id' : employee_id,
      'activity_type_id' : activity_type_id
    },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function get_new_time_entry_matters_contact( replace_id ){ 
  replace_id = replace_id != null ? replace_id : "";
  var tempObj;
  employee_id = jQuery('#physical_timeandexpenses_time_entry_employee_user_id').val();
  activity_type_id = jQuery('#physical_timeandexpenses_time_entry_activity_type').val();
  jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('disabled', true);
  var matterObj = jQuery('#physical_timeandexpenses_time_entry_matter_id');
  var contactObj =  jQuery('#physical_timeandexpenses_time_entry_contact_id');
  var entry_date = jQuery('#datepicker_time_entry').val();
  var matter_id = matterObj.val();
  var contact_id =contactObj.val();
  if(matterObj.attr("selectedIndex") == 0 && replace_id == ""){
    tempObj = jQuery(matterObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    tempObj.children(':nth-child(2)').append('<input type="hidden" id="physical_timeandexpenses_time_entry_matter_id" name="physical_timeandexpenses_time_entry[matter_id]" />');
    jQuery(matterObj).parent().html('');
    matterObj.val('');
    jQuery('#_matter_ctl').val('');
    return;
  } 
  if(replace_id != "" && (matter_id == null || matter_id == "")){
    matter_id = replace_id;
    tempObj = jQuery(matterObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    jQuery(matterObj).parent().html('');
  }
  if (matter_id == "" && contact_id == ""){
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', true);
    enable_disable_time_entry_billing();
  }else{
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr("onClick" , "enable_disable_time_entry_billing();");
    enable_disable_time_entry_billing();
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/get_new_matters_contact',
    data: {
      'matter_id' : matter_id,
      'contact_id' : contact_id,
      'replace_id' : replace_id,
      'time_entry_date': entry_date,
      'employee_user_id' : employee_id,
      'activity_type_id' : activity_type_id

    },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function set_matters_contact( replace_id ){
  replace_id = replace_id != null ? replace_id : "";
  var tempObj;
  var matterObj = jQuery('#physical_timeandexpenses_time_entry_matter_id');
  var contactObj =  jQuery('#physical_timeandexpenses_time_entry_contact_id');
  var entry_date = jQuery('#datepicker_time_entry').val();
  var matter_id = matterObj.val();
  var contact_id =contactObj.val();
  if(matterObj.attr("selectedIndex") == 0 && replace_id == ""){
    tempObj = jQuery(matterObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    tempObj.children(':nth-child(2)').append('<input type="hidden" id="physical_timeandexpenses_time_entry_matter_id" name="physical_timeandexpenses_time_entry[matter_id]" />');
    jQuery(matterObj).parent().html('');
    matterObj.val('');
    jQuery('#_matter_ctl').val('');
    return;
  }
  if(replace_id != "" && (matter_id == null || matter_id == "")){
    matter_id = replace_id;
    tempObj = jQuery(matterObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    jQuery(matterObj).parent().html('');
  }
  if (matter_id == "" && contact_id == ""){
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', true);
    enable_disable_time_entry_billing();
  }else{
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_accounted_for_type').attr("onClick" , "enable_disable_time_entry_billing();");
    enable_disable_time_entry_billing();
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/set_matters_contact',
    data: {
      'matter_id' : matter_id,
      'contact_id' : contact_id,
      'replace_id' : replace_id,
  },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function resetMatterContactFields(){
  var tempObj;
  var matterObj = jQuery('#physical_timeandexpenses_time_entry_matter_id');
  var contactObj = jQuery('#physical_timeandexpenses_time_entry_contact_id');
  var matter_id = matterObj.val();
  var contact_id = contactObj.val();
  if(matterObj.attr("tagName") == "SELECT"){
    tempObj = jQuery(matterObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    tempObj.children(':nth-child(2)').append('<input type="hidden" id="physical_timeandexpenses_time_entry_contact_id" name="physical_timeandexpenses_time_entry[contact_id]" />');
    jQuery(matterObj).parent().html('');
    matterObj.val('');
    contactObj.val('');
    jQuery('#_contact_ctl').val('');
    jQuery('#_matter_ctl').val('');
  }
  if(contactObj){
    tempObj = jQuery(contactObj).parent().parent();
    tempObj.children(':nth-child(2)').show();
    matterObj.val('');
    contactObj.val('');
    jQuery('#_contact_ctl').val('');
    jQuery('#_matter_ctl').val('');
  }
}

function set_override_amount( obj ){
  var regexp = /^[-+]?[0-9]+(\.[0-9]+)?$/
  var val;
  try {
    if (isNaN(obj)){
      val = parseFloat(obj.value);
    }else{
      val = parseFloat(obj);
    }
    if (val < 0.00){
      alert("Please Enter Valid Amount");
      obj.value = "";
      return false;
    }
    if(!regexp.test(val)){
      alert("Please Enter Valid Amount");
      obj.value = "";
      return false;
    }
  }catch (exception){
    alert("Please Enter Valid Amount");
    obj.value="";
    return false;
  }
  jQuery('#final_billed_amount').html(val.toFixed(2));
  if (isNaN(obj)){
    obj.value = val.toFixed(2);
  }else{
    obj = val.toFixed(2);
  }
}

function newEntryBillAmount( obj, idName ){
  if(obj != null){
    var caption = obj.id.split('_');
    caption = caption[caption.length - 1];
    var val = parseFloat(obj.value);
    var amount = 0.0;
    if(isNaN(val)){
      obj.value = '';
      alert('Please Enter Proper ' + caption);
      return false;
    }else if(obj != null){
      try{
        var duration = parseFloat(jQuery('#' + idName+'actual_duration').val());
        duration = Math.abs(duration);
        duration = duration.toFixed(2);        
        var rate = parseFloat(jQuery('#' + idName+'actual_activity_rate').val().replace(/\,/g,''));
        var isBillable = jQuery('#'+idName + 'is_billable').attr('checked');
        if(rate > 0 && duration > 0 ){
          amount = (rate * duration).toFixed(2);
          jQuery('#bill_amount').html(addCommas(amount));
          jQuery('#' + idName+'actual_activity_rate').val(addCommas(rate));
        }
        if(isBillable){
          var billingType = jQuery('#'+idName+'billing_method_type').val();
          var finalAmount = amount;          
          var showamount = jQuery('#show_amount').val();
          if(billingType == '2' && showamount > 100){
            alert("Please Enter Discount between 0.01 to 100");
            jQuery('#show_amount').focus();
            return false;
          }
          var showAdjustment
          if(showamount != ""){
            showAdjustment = parseFloat(jQuery('#show_amount').val());
          }else{
            showAdjustment = 0
          }
          if(!isNaN(showAdjustment)){
            if(billingType > 0){
              switch(billingType.toString()){
                case '2':
                  if(showAdjustment != 0){
                    finalAmount -= (amount * showAdjustment) / 100;
                  }
                  break;
                case '3':
                  finalAmount = showAdjustment;
                  break;
              }
            }                  
            if(billingType == '1'){
              jQuery('#show_amount').val(addCommas(parseFloat(finalAmount)));
            }else{
              jQuery('#show_amount').val(addCommas(parseFloat(showAdjustment)));
            }
            jQuery('#final_billed_amount').html(addCommas(parseFloat(finalAmount)));
          }
        }
      }catch(exception){
        alert(exception.stack);
      }
    }
  }
}

function calculate_bill_amount( obj ){
  if(obj != null && obj.length > 0){
    var val = parseFloat(obj.value);
    if(obj != null && isNaN(val) || val == ""){
      alert('Please Enter Proper Duration');
      obj.value = "";
      return false;
    }else if(obj != null){
      val = Math.abs(val);
      val = val < 10 ? '0' + val.toFixed(2) : val.toFixed(2) ;
      obj.value = Math.abs(val);
    }
  }    
  jQuery.ajax({
    beforeSend: function(){
      jQuery('body').css("cursor", "wait");
    },
    type: 'POST',
    url: '/physical/timeandexpenses/calculate_billing_amount_per_duration',
    data: jQuery("#new_physical_timeandexpenses_time_entry").serialize(),
    async: true,
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
    }
  });
}

function save_and_add_expense(){
  jQuery.ajax({
    type: 'POST',
    url: '/physical/timeandexpenses/save_and_add_expense',
    data: jQuery("#new_physical_timeandexpenses_time_entry").serialize(),
    async: true,
    dataType: 'script'
  });
}

function alert_for_matter_and_contact( id ){
  if (jQuery('#'+id).attr('checked')){
    jQuery('#_matter_ctl').val('');
    jQuery('#_contact_ctl').val('');
    jQuery('#physical_timeandexpenses_time_entry_matter_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_contact_id').val('');
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('checked', false);
    jQuery('#physical_timeandexpenses_time_entry_is_billable').attr('disabled', true);
    enable_disable_time_entry_billing();
  }else {
    jQuery('#'+id).attr('checked', true);
    alert('Select matter/contact or check internal.');
  }
  return;
}

function check_duration( obj ){
  if (isNaN(obj.value)){
    alert('Please enter only number');
    obj.value = ''
    obj.focus();
    return;
  }
  var duration = obj.value;
  var fduration = parseFloat(duration)
  if ((duration.indexOf('.') != -1) && ((duration.length - duration.indexOf('.') -1) > 2)){
    fduration = fduration.toFixed(2);
    jQuery('#'+obj.id).val(fduration.toString());
  }
  if(fduration > 24.00 || fduration == 0.00){
    alert("Please enter duration between 0.01 to 24.00");
    jQuery('#'+obj.id).select();
  }else{       
    calculate_bill_amount(obj);
  }
}

function check_rate(obj){
  if (isNaN(parseFloat(obj.value.replace(/,/g,'')))){
    alert('Please enter valid rate');
    obj.value='';
    obj.focus();
    return;
  }
  var rate = obj.value.replace(/,/g,'');
  var frate = parseFloat(rate);
  if ((rate.indexOf('.') != -1) && ((rate.length - rate.indexOf('.') -1) > 2)){
    frate = addCommas(parseFloat(frate));
    jQuery('#'+obj.id).val(frate);
  }
  if (frate > 9999.99 || frate < 0.01){
    alert("Rate should be between 0.01 and 9999.99");
    jQuery('#'+obj.id).select();
    obj.value = '';
  }else{
    jQuery('#'+obj.id).val(addCommas(rate));
    var from_time_or_invoice = obj.id.split('actual_activity_rate')[0];
    newEntryBillAmount(obj, from_time_or_invoice);
  }     
}

function check_time_override(){
  var override = jQuery('#physical_timeandexpenses_time_entry_final_billed_amount').val();
  var foverride = parseFloat(override);
  if ((override.indexOf('.') != -1) && ((override.length - override.indexOf('.') -1) > 2)){
    foverride.toFixed(2);
  }else{
    if (foverride > 99999999.99 || foverride < 0.01 || isNaN(override)){
      alert("Please Enter Valid Rate");
      jQuery('#physical_timeandexpenses_time_entry_final_billed_amount').select();
    }else{
      set_override_amount(override);
    }
  }
}

function update_matter_contact_select(empObj, date ){
  user_id = empObj.value;
  matter_id = empObj.options[empObj.selectedIndex].getAttribute('matter_id');
  if(matter_id !=null && matter_id == jQuery('#physical_timeandexpenses_time_entry_matter_id').val()){
    return ;
  }
  jQuery("#matters_div").hide();
  jQuery("#001_matterSearch").show();
  if (user_id == ""){
    alert("Please select lawyer");
  }else{
    reset_matter_contact("_matter_ctl","_contact_ctl",empObj,000,date);
  }
}

function reset_matter_contact( matterTextFieldID, contactTextFieldID, empObj, expense_id, date ){
  user_id = empObj.value;
  matter_id = empObj.options[empObj.selectedIndex].getAttribute('matter_id');
  if(matter_id !=null && matter_id == jQuery('#'+expense_id +'_expense_matter_id').val()){
    return ;
  }
  jQuery("#"+contactTextFieldID).val('');
  jQuery("#"+matterTextFieldID).val('');
  jQuery.ajax({
    type: "GET",
    url: "/physical/timeandexpenses/get_lawyers_matters_contacts",
    dataType: 'script',
    data: {
      'user_id' : user_id,
      'expense_id' : expense_id,
      'date' : jQuery("#"+date).val()
    }
  });
}

function toggle_employee( id ){
  matter_id = jQuery('#physical_timeandexpenses_time_entry_matter_id').val();
  if(jQuery('#'+id).attr('checked')){
    jQuery("#lawyer_employee").hide();
    jQuery("#matter_peoples").show();
    if(matter_id ==null || matter_id.toString().length <= 0){
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr("disabled", true);
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr('checked', false);
      return;
    }
    get_new_time_entry_matters_contact();
    jQuery("#physical_timeandexpenses_time_entry_is_internal").attr("disabled", true);
    jQuery("#physical_timeandexpenses_time_entry_is_internal").attr('checked', false);
  }else{
    jQuery("#lawyer_employee").show();
    jQuery("#matter_peoples").hide();
    if(jQuery('#physical_timeandexpenses_time_entry_matter_id').val() != ""){
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr("disabled", true);
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr('checked', false);
    }else{
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr("disabled", false);
      jQuery("#physical_timeandexpenses_time_entry_is_internal").attr('checked', true);
    }
    if(matter_id !=null && matter_id.toString().length > 0){
      get_new_time_entry_matters_contact();
    }
  }
}

function is_internal(){
  if(jQuery('#physical_timeandexpenses_time_entry_is_internal').is(':checked')){
    jQuery('#nonuser').removeAttr("checked");
    jQuery('#matter_peoples').hide();
    jQuery('#matter_peoples').html("");
  }
}