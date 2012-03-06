function enable_disable_time_percent( radio, text, disable_text ){
  if (!jQuery(radio).is(':checked')){
    jQuery('#'+text).attr('disabled',false);
    jQuery('#'+disable_text).val('');
    jQuery('#'+disable_text).attr('disabled',true);
  }
}

function disable_all( expense_entry, obj ){
  if(obj.value == null || obj.value == ""){
    jQuery('#'+expense_entry+'_is_billable').attr('checked',false);
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled',true);
    jQuery('#'+expense_entry+'_final_billed_amount').html('0.00');
    jQuery('#'+expense_entry+'_full_amount').html('0.00');
    jQuery('#'+expense_entry + '_show_amount').val('0.00');
  }else{
    try{
      if(isNaN(parseFloat(obj.value))){
        alert(obj.value + " is not valid amount");
        obj.value = "";
      }else{
        obj.value = parseFloat(obj.value).toFixed(2);
        var tempFullAmount = jQuery('#'+expense_entry+'_full_amount').length > 0 ? parseFloat(jQuery('#'+expense_entry+'_full_amount').html()) : 0.00;
        if(jQuery('#'+expense_entry+'_is_billable').attr('checked') == true && obj.value != tempFullAmount){
          jQuery('#'+expense_entry+'_full_amount').html(parseFloat(obj.value).toFixed(2));
          var amt = 0.00;
          var billingMethodType = jQuery('#'+expense_entry+'_expense_entry_billing_method_type').val();
          var adjustment = parseFloat(jQuery('#'+expense_entry + '_show_amount').val());
          amt = parseFloat(obj.value);
          if(!isNaN(adjustment)){
            if(billingMethodType =='2'){
              if(!isNaN(amt)){
                amt -= (amt * adjustment) / 100;
              }
            }else if(billingMethodType == '4'){
              if(!isNaN(amt)){
                amt += (amt * adjustment) / 100;
              }
            }else if(billingMethodType == '1'){
              jQuery('#'+expense_entry + '_show_amount').val(obj.value);
            }else if(billingMethodType == '3'){
              amt = adjustment;
            }
            jQuery('#'+expense_entry + '_final_billed_amount').html(amt.toFixed(2));
          }else{
            if(billingMethodType == '1'){
              jQuery('#'+expense_entry + '_show_amount').val(parseFloat(obj.value));
            }
            jQuery('#'+expense_entry + '_final_billed_amount').html(parseFloat(obj.value));
          }
        }
      }
    }catch(e){
      alert(obj.value + " is not valid amount");
    }
  }
}

function enable_disable_billing(expense_entry, obj){
  if (!jQuery('#'+expense_entry+'_accounted_for_type').is(':checked')){
    jQuery('#'+expense_entry+'_is_billable').attr('disabled',false);
  }else{
    jQuery('#'+expense_entry+'_accounted_for_type').attr('checked',true);
    jQuery('#'+expense_entry+'_accounted_for_type').attr("onClick", "alert_for_matter_and_contact('"+expense_entry+"_accounted_for_type');");
    jQuery('#'+expense_entry+'_expense_matter_id').val('');
    jQuery('#'+expense_entry+'_expense_contact_id').val('');
    jQuery('#'+expense_entry+'_is_billable').attr('disabled',true);
    disable_all(expense_entry,obj);
    jQuery('#' + expense_entry + "_matters_div").html('');
    var matterSearchDiv = jQuery('#' + expense_entry + "_matterSearch");
    matterSearchDiv.show();
    contactTextField = jQuery('#' + expense_entry + "_contact_ctl");
    matterTextField = jQuery('#' + expense_entry + "_matter_ctl");
    matterTextField.val('');
    contactTextField.val('');
    matterTextField.attr("title","search");
    contactTextField.attr("title","search");
    hiddenContactId = jQuery('#' + expense_entry + "_expense_contact_id");
    if(hiddenContactId =! null && hiddenContactId.length > 0){
      hiddenContactid.val('');
    }
    matterSearchDiv.append('<input type="hidden" title="search" value="" id="'+ expense_entry + '"_expense_matter_id" name="'+expense_entry +'"[expense_entry][matter_id]">');
  }
}

function reset_expense_details(id){
    jQuery('#'+id+'_matter_ctl').val("");
    jQuery('#'+id+'_expense_matter_id').val("");
    jQuery('#'+id+'_contact_ctl').val("");
    jQuery('#'+id+'_expense_contact_id').val("");
    jQuery('#'+id+'_is_internal').attr('checked', true);
}

function enable_disable_billing_types(expense_entry){
  if (!(jQuery('#'+expense_entry+'_is_billable').is(':checked'))){
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled', true);
    jQuery('#'+expense_entry+'_full_amount').val('0.00');
    jQuery('#'+expense_entry+'_adjustment_table').hide();
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').val('');
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').val('');
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').attr('disabled', true);
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').attr('disabled', true);
    jQuery('#'+expense_entry+'_final_billed_amount').html('0.0');
    jQuery('#'+expense_entry+'_full_amount').val('0.0');
  }else{
    if(check_expense_amount_bill(expense_entry) == false){
      assign_default_full_amount(expense_entry);
    }else{
      alert("Please enter valid expense amount.");
    }
  }
}

function enable_disable_tne_billing_types(expense_entry){
  if (!(jQuery('#'+expense_entry+'_is_billable').is(':checked'))){
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled',true);
    jQuery('#'+expense_entry+'_full_amount').val('0.00');
    jQuery('#'+expense_entry+'_adjustment_table').hide();
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').val('');
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').val('');
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').attr('disabled',true);
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').attr('disabled',true);
    jQuery('#'+expense_entry+'_final_billed_amount').html('0.0');
    jQuery('#'+expense_entry+'_full_amount').val('0.0');
  }else{
    if(check_expense_tne_amount_bill(expense_entry) == false){
      assign_default_tne_full_amount(expense_entry);
    }else{
      alert("Please enter valid expense amount.");
    }
  }
}

function check_expense_amount_bill(expense_entry_id){
  return isNaN(parseFloat(jQuery('#'+expense_entry_id+'_expense_entry_expense_amount').val()));
}

function check_expense_tne_amount_bill(expense_entry_id){
  return isNaN(parseFloat(jQuery('#'+expense_entry_id+'_tne_invoice_expense_entry_expense_amount').val()));
}

function disable_amount_and_percent(percent_text, amt_text, expense_amt, final_billed_amount){
  jQuery('#'+percent_text).val('');
  jQuery('#'+amt_text).val('');
  jQuery('#'+percent_text).attr('disabled',true);
  jQuery('#'+amt_text).attr('disabled',true);
  if (jQuery('#'+final_billed_amount) != null){
    jQuery('#'+final_billed_amount).html(jQuery('#'+expense_amt).val());
  }
}

// This is repeated twice this, earlier code done by Manohar
function calculate_discount_rate_for_expense_entry(expense_amount, expense_percent, expense_entry){
  var final_expense_amount = parseFloat(jQuery('#'+expense_amount).val());
  var billing_percent = parseFloat(jQuery('#'+expense_percent).val());
  if(isNaN(billing_percent) || billing_percent < 0 || billing_percent > 100){
    alert("Please Enter Discount between 0.01 to 100");
    jQuery('#'+expense_percent).val('');
    jQuery('#'+ expense_entry.toString()+ '_final_billed_amount').html(jQuery('#'+expense_entry+'_full_amount').html());
    return false;
  }else{
    final_expense_amount -= (final_expense_amount * billing_percent) / 100;
    jQuery('#'+expense_percent).val(billing_percent.toFixed(2));
    jQuery('#'+ expense_entry.toString()+ '_final_billed_amount').html(final_expense_amount.toFixed(2));
  }
}

function set_expense_billing_amount(billing_amount, expense_amount, final_expense_amount){   
  try {
    var val = parseFloat(jQuery('#'+billing_amount).val());
    if (isNaN(val)|| val < 0 || typeof(val) != 'number'){
      alert("Please Enter valid Amount");
      var entery_id= billing_amount.split('_');
      if(entery_id.length > 0){
        entery_id = entery_id[0];
        jQuery('#'+billing_amount).val('');
        jQuery('#'+final_expense_amount).html(jQuery('#'+entery_id+'_full_amount').html());
      }
    }else{
      jQuery('#'+final_expense_amount).html(val.toFixed(2));
      jQuery('#'+billing_amount).val(val.toFixed(2))
    }
  }catch (exception){
    alert("Please Enter valid Amount");
  }
}

function expenseMatterContactDropDown(obj, ID, type, methodName){
  var val = obj.id.split('_')[1];
  var idStr = ID+"_expense_"+type+"_id";
  if(type == "matter"){
    var divTag = jQuery('#'+ID+'_matters_div');
    var searchDiv = jQuery('#'+ID+'_matterSearch');
  }else{
    divTag = jQuery('#'+ID+'_contact_span');
    searchDiv = jQuery('#'+ID+'_contactSearch');
  }
  if(divTag.html() != ""){
    divTag.html("");
    if(type != 'contact'){
      idStr = ID+"_expense_"+type+"_id";
      var str = '<input type="hidden" value="" id="'+idStr+'" name="'+ID+'"[expense_entry][matter_id]" />';
      searchDiv.append(str);
      searchDiv.show();
    }
  }
  var entryID = obj.id.replace(/[^0-9\\.]/g, '');
  var cnt = obj.id.split("_");
  jQuery('#'+ID+'_expense_'+type+'_id').val(cnt[1]);
  jQuery('#'+ID+'_'+type+'_ctl').val(obj.innerHTML.replace(/&amp;/g, "&"));

  hideMatterORContactListBox();
  eval(methodName)(ID);
}

function get_all_matters_for_expenses(id){
  var contact_id = jQuery('#'+id+'_expense_contact_id').val();
  var matter_id = jQuery('#'+id+'_expense_matter_id option:selected').val();
  var entry_date = jQuery('#'+id+'_expense_entry_expense_entry_date').val();
  
  if (matter_id == "" && contact_id == ""){
    jQuery('#'+id+'_accounted_for_type').attr('checked', true);
    enable_disable_billing(id);
  }else{
    jQuery('#'+id+'_accounted_for_type').attr("onClick", "enable_disable_billing("+id+");");
    jQuery('#'+id+'_accounted_for_type').attr('checked', false);
    enable_disable_billing(id);
  }
  var tempObj = jQuery('#'+ id +'_expense_matter_id');
  if(tempObj != null && tempObj.length > 0){
    tempObj.remove();
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/get_all_new_matters_for_expenses',
    data: {
      'contact_id' : contact_id,
      'matter_id' : matter_id,
      'id' : id,
      'expense_entry_date' : entry_date
    },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function get_matters_contact_for_expenses(id){
  var contact_id = jQuery('#'+id+'_expense_contact_id option:selected').val();
  var matter_id = jQuery('#'+id+'_expense_matter_id option:selected').val();
  if (matter_id == "" && contact_id == ""){
    jQuery('#'+id+'_accounted_for_type').attr('checked',true);
    enable_disable_billing(id);
  }else{
    jQuery('#'+id+'_accounted_for_type').attr("onClick", "enable_disable_billing("+id+");");
    jQuery('#'+id+'_accounted_for_type').attr('checked',false);
    enable_disable_billing(id);
  }
  return
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/get_new_matters_contact_for_expenses',
    data: {
      'contact_id' : contact_id,
      'matter_id' : matter_id,
      'id' : id
    },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function toggle_tne_matter_people(id){
  if (jQuery('#'+id+'_nonuser').attr('checked')){
    jQuery('#'+id+'_tne_invoice_expense_entry_employee_user_id').attr('disabled', true);
    jQuery('#'+id+'_tne_invoice_expense_entry_matter_people_id').attr('disabled', false);
    getMatterContactForExpense(id);
  }else{
    jQuery('#'+id+'_tne_invoice_expense_entry_matter_people_id').find('option').remove().end().append('<option value="" selected="">Select</option>');
    jQuery('#'+id+'_tne_invoice_expense_entry_matter_people_id').attr('selectedIndex', 0);
    jQuery('#'+id+'_tne_invoice_expense_entry_employee_user_id').attr('disabled', false);
    jQuery('#'+id+'_tne_invoice_expense_entry_matter_people_id').attr('disabled', true);
  }
}

function toggle_matter_people(id){
  if (jQuery('#'+id+'_nonuser').attr('checked')){
    jQuery('#'+id+'_expense_entry_employee_user_id').attr('disabled', true);
    jQuery('#'+id+'_expense_entry_matter_people_id').attr('disabled', false);
    getMatterContactForExpense(id);
  }else{
    jQuery('#'+id+'_expense_entry_matter_people_id').find('option').remove().end().append('<option value="" selected="">Select</option>');
    jQuery('#'+id+'_expense_entry_matter_people_id').attr('selectedIndex', 0);
    jQuery('#'+id+'_expense_entry_employee_user_id').attr('disabled', false);
    jQuery('#'+id+'_expense_entry_matter_people_id').attr('disabled', true);
  }
}

function getMatterContactForExpense(id){
  var contact_id = jQuery('#'+id+'_expense_contact_id').val();
  var matter_id = jQuery('#'+id+'_expense_matter_id').val();
  employee_id = jQuery('#'+id+ '_expense_entry_employee_user_id').val();
  if (matter_id == "" && contact_id == ""){
    jQuery('#'+id+'_accounted_for_type').attr('checked', true);
    enable_disable_billing(id);
  }else{
    jQuery('#'+id+'_accounted_for_type').attr("onClick", "enable_disable_billing("+id+");");
    jQuery('#'+id+'_accounted_for_type').attr('checked', false);
    enable_disable_billing(id);
  }
  jQuery.ajax({
    beforeSend: function(){
      loader.prependTo("#spinner_div");
      jQuery('body').css("cursor", "wait");
    },
    type: 'GET',
    url: '/physical/timeandexpenses/get_new_matters_contact_for_expenses',
    data: {
      'contact_id' : contact_id,
      'matter_id' : matter_id,
      'id' : id,
      'employee_id' : employee_id
    },
    dataType: 'script',
    complete: function(){
      jQuery('body').css("cursor", "default");
      loader.remove();
    }
  });
}

function alert_for_matter_and_contact(id){
  var tmpar = id.split('_');
  if (jQuery('#'+id).attr('checked')){
    jQuery('#'+tmpar[0]+'_matter_ctl').val('');
    jQuery('#'+tmpar[0]+'_contact_ctl').val('');
    jQuery('#'+tmpar[0]+'_expenses_matter_id').val('');
    jQuery('#'+tmpar[0]+'_expenses_contact_id').val('');
    jQuery('#'+tmpar[0]+'_is_billable').attr('checked', false);
    jQuery('#'+tmpar[0]+'_is_billable').attr('disabled', true);
    jQuery('#'+tmpar[0]+'_expense_entry_matter_people_id').find('option').remove().end().append('<option value="" selected="">Select</option>');
    jQuery('#'+tmpar[0]+'_expense_entry_matter_people_id').attr('selectedIndex', 0);
    enable_disable_billing_types(tmpar[0]);
  }else {
    jQuery('#'+id).attr('checked',true);
    alert('Select matter/contact or check internal.');
  }
  return;
}

function assign_default_tne_full_amount(expense_entry){
  jQuery('#'+expense_entry+'_tne_invoice_expense_entry_billing_method_type').attr('disabled', false);
  jQuery('#'+expense_entry+'_tne_invoice_expense_entry_billing_method_type').attr('checked', true);
  jQuery('#'+expense_entry+'_adjustment_table').show();
  jQuery('#'+expense_entry+'_full_amount').html(parseFloat(jQuery('#'+expense_entry+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_final_billed_amount').html(parseFloat(jQuery('#'+expense_entry+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_show_amount').val(parseFloat(jQuery('#'+expense_entry+'_tne_invoice_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_tne_invoice_expense_entry_billing_percent').attr('disabled', true);
  jQuery('#'+expense_entry+'_tne_invoice_expense_entry_final_expense_amount').attr('disabled', true);
}

function assign_default_full_amount(expense_entry){
  jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled', false);
  jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('checked', true);
  jQuery('#'+expense_entry+'_adjustment_table').show();
  jQuery('#'+expense_entry+'_full_amount').html(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_final_billed_amount').html(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_show_amount').val(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
  jQuery('#'+expense_entry+'_expense_entry_billing_percent').attr('disabled', true);
  jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').attr('disabled', true);
}

function expence_entry_validation(){
  var flag = 0;
  for (var i = 1; i <= 3; i++){
    if(jQuery('#'+i+'_expense_entry_description').val()!="" || jQuery('#'+i+'_expense_entry_expense_amount').val() != "" || jQuery('#'+i+'_nonuser').is(':checked')){
      flag = 1;
      if (jQuery('#'+i+'_nonuser').is(':checked') && jQuery('#'+i+'_expense_matter_id').val() == ""){
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        alert("Please Select Matter");
        return false;
      }
      if (jQuery('#'+i+'_nonuser').is(':checked') && (jQuery('#'+i+'_expense_entry_matter_people_id').val() == "" || jQuery('#'+i+'_expense_entry_matter_people_id').val() == null)){
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        alert("Please Select Matter People");
        return false;
      }
      if (jQuery('#'+i+'_expense_entry_description').val() == ""){
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        alert("Description should not be blank");
        return false;
      }
      if (jQuery('#'+i+'_expense_entry_expense_amount').val() == ""){
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        alert("Amount should not be blank");
        return false;
      }
    }
  }
  if(flag == 0){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("Please enter atleast one expense entry");
    return false;
  }else{
    disableAllSubmitButtons('time_and_expense');
    return true;
  }
}

function tne_expence_entry_validation(){    
  var flag = 0;
  if (jQuery('#0_nonuser').is(':checked') && jQuery('#0_tne_invoice_expense_matter_id').val() == ""){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("Please Select Matter");
    return false;
  }

  if (jQuery('#0_nonuser').is(':checked') && (jQuery('#0_tne_invoice_expense_entry_matter_people_id').val() == "" || jQuery('#0_tne_invoice_expense_entry_matter_people_id').val() == null)){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("Please Select Matter People");
    return false;
  }

  if (jQuery('#0_tne_invoice_expense_entry_description').val() == ""){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("Description should not be blank");
    return false;
  }
  if (jQuery('#0_tne_invoice_expense_entry_expense_amount').val() == ""){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("Amount should not be blank");
    return false;
  }

  if (!jQuery('#0_is_billable').is(':checked') ){
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    alert("is Billable Should be Checked");
    return false;
  }

  disableAllSubmitButtons('time_and_expense');
  return true;        
}

//function popup_expence_entry_validation() - Removed.

function check_expense_amount(obj, expense_entry){
  var expense = obj.value;
  if (expense){
    var fexpense = parseFloat(expense);
    if ((expense.indexOf('.') != -1) && ((expense.length - expense.indexOf('.') -1) > 2)){
      fexpense.toFixed(2);
      jQuery('#'+obj.id).select();
    }
    if (fexpense > 99999999.99 || fexpense < 0.01){
      alert("Please Enter Valid Expense Amount");
      jQuery('#'+obj.id).select();
    }else{
      disable_all(expense_entry,obj);
    }
  }
}

function noenter(evt){   
  var evt = (evt) ? evt : ((event) ? event : null);
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
  if ((evt.keyCode == 13) && (node.type == "text")){
    return false;
  }
}

function check_expense_override(obj, expense_entry){
  var exp_override = obj.value;
  var fexp_override = parseFloat(exp_override);
  if ((exp_override.indexOf('.') != -1) && ((exp_override.length - exp_override.indexOf('.') -1) > 2)){
    fexp_override.toFixed(2);
    jQuery('#'+obj.id).select();
  }
  if (fexp_override > 99999999.99 || fexp_override < 0.01){
    alert("Please Enter Valid Override Amount");
    jQuery('#'+obj.id).select();
  }else{
    set_expense_billing_amount(obj.id, expense_entry+'_expense_entry_expense_amount', expense_entry+'_final_billed_amount');
  }
}