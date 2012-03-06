function enable_disable_time_percent( radio, text, disable_text ){
  if (!jQuery(radio).is(':checked')){
    jQuery('#'+text).attr('disabled',false);
    jQuery('#'+disable_text).val('');
    jQuery('#'+disable_text).attr('disabled',true);
  }
}

function disable_all( expense_entry, obj ){
  if(obj.value == null || obj.value==""){
    jQuery('#'+expense_entry).attr('checked',false);
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled',true);
    jQuery('#'+expense_entry+'_adjustment_table').hide();
    jQuery('#'+expense_entry+'_full_amount').html('0.00');
    jQuery('#'+expense_entry+'_show_amount').html('0.00');
    jQuery('#'+expense_entry+'_final_amount').html('0.00');
  }else{
    try{
      if(isNaN(parseFloat(obj.value))){
        alert(obj.value + " is not valid amount");
        obj.value="";
      }else{
        obj.value=parseFloat(obj.value).toFixed(2);
        var tempFullAmount = jQuery('#billed_amount_'+expense_entry).length > 0 ? parseFloat(jQuery('#billed_amount_'+expense_entry)) : 0.00;
        if(jQuery('#'+expense_entry).attr('checked')==true && obj.value != tempFullAmount){
          jQuery('#billed_amount_'+expense_entry).html(obj.value);
          jQuery('#'+expense_entry + '_final_amount').html(obj.value);
          jQuery('#'+expense_entry+'_full_amount').html(parseFloat(obj.value).toFixed(2));
          var billingMethodType = jQuery('#'+expense_entry+'_expense_entry_billing_method_type').val();
          var adjustment = parseFloat(jQuery('#'+expense_entry + '_show_amount').val());
          var amt = parseFloat(obj.value);
          if(!isNaN(adjustment)){
            if(billingMethodType =='2'){
              if(!isNaN(amt)){
                amt -= (amt * adjustment) / 100;
              }
            }else if(billingMethodType =='4'){
              if(!isNaN(amt)){
                amt += (amt * adjustment) / 100;
              }
            }else if(billingMethodType =='1'){
              jQuery('#'+expense_entry + '_show_amount').val(obj.value);
            }else if(billingMethodType =='3'){
              amt = adjustment;
            }
            jQuery('#'+expense_entry + '_final_billed_amount').html(amt.toFixed(2));
          }else{
            if(billingMethodType =='1'){
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

function disable_amount_and_percent( percent_text, amt_text, expense_amt, final_billed_amount ){
  jQuery('#'+percent_text).val('');
  jQuery('#'+amt_text).val('');
  jQuery('#'+percent_text).attr('disabled',true);
  jQuery('#'+amt_text).attr('disabled',true);
  jQuery('#'+amt_text).attr('disabled',true);
  if (jQuery('#'+final_billed_amount) != null){
    jQuery('#'+final_billed_amount).html(jQuery('#'+expense_amt).val());
  }
}

function enable_disable_billing( expense_entry, obj ){
  if (!jQuery('#'+expense_entry).is(':checked')){
    jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled',true);
    jQuery('#'+expense_entry+'_full_amount').val('0.00');
    jQuery('#'+expense_entry+'_adjustment_table').hide();
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').val('');
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').val('');
    jQuery('#'+expense_entry+'_expense_entry_billing_percent').attr('disabled',true);
    jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').attr('disabled',true);
    jQuery('#'+expense_entry+'_final_billed_amount').val('0.00');
    jQuery('#billed_amount_'+expense_entry).val('0.00');
  }else{
    if(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val() !=""){
      jQuery('#'+expense_entry+'_adjustment_table').show();
      jQuery('#'+expense_entry+'_expense_entry_billing_method_type').attr('disabled',false);
      jQuery('#'+expense_entry+'_final_billed_amount').html(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
      jQuery('#'+expense_entry+'_full_amount').html(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
      jQuery('#billed_amount_'+expense_entry).html(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2));
      jQuery('#'+expense_entry+'_expense_entry_final_expense_amount').attr('disabled',true);
      jQuery('#'+expense_entry+'_show_amount').val(parseFloat(jQuery('#'+expense_entry+'_expense_entry_expense_amount').val()).toFixed(2))
    }else{
      obj.checked=false;
    }
  }
}

function calculate_discount_rate_for_expense_entry( expense_amount, expense_percent, expense_entry_id ){
  try {
    var bill_amount = parseFloat(jQuery('#'+expense_amount).val());
    var billing_percent = parseFloat(jQuery('#'+expense_percent).val());
    if(isNaN(billing_percent) || billing_percent < 0 || billing_percent > 100){
      alert("Please Enter Discount between 0.01 to 100");
      jQuery('#'+expense_percent).val('0.00');
      jQuery('#'+ expense_entry_id.toString()+ '_final_billed_amount').html(jQuery('#billed_amount_'+expense_entry_id).html());
      return false;
    }else{
      jQuery('#'+expense_percent).val(billing_percent.toFixed(2));
      bill_amount -= (bill_amount * billing_percent) / 100;
      jQuery('#'+ expense_entry_id.toString()+ '_final_billed_amount').html(bill_amount.toFixed(2));
    }
  }catch (exception){
    alert("Please Enter Discount between 0.01 to 100");
  }
}

function set_expense_billing_amount( billing_amount, expense_amount, final_expense_amount ){
  var val = parseFloat(jQuery('#'+billing_amount).val());
  if (isNaN(val)||val < 0 || typeof(val) != 'number'){
    alert("Please Enter valid Amount");
    var entery_id= billing_amount.split('_');
    if(entery_id.length > 0){
      entery_id=entery_id[0];
      jQuery('#'+billing_amount).val('');
      jQuery('#'+final_expense_amount).html(jQuery('#billed_amount_'+entery_id).html());
    }
  }else{
    jQuery('#'+final_expense_amount).html(val.toFixed(2));
    jQuery('#'+billing_amount).val(val.toFixed(2));
  }
}

function expence_entry_validation(){
  var flag = 0;
  for ( var i=1;i<=6;i++){
    if(jQuery('#'+i+'_expense_entry_description').val()!="" || jQuery('#'+i+'_expense_entry_expense_amount').val() != ""){
      flag = 1;
      if (jQuery('#'+i+'_expense_entry_description').val()==""){
        alert("Description should not be blank");
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        return false;
      }
      if (jQuery('#'+i+'_expense_entry_expense_amount').val()==""){
        alert("Amount should not be blank");
        jQuery("input[name=save_and_add_expense]").val("Save & Exit");
        return false;
      }
    }
  }
  if(flag == 0){
    alert("Please enter atleast one expense entry");
    jQuery("input[name=save_and_add_expense]").val("Save & Exit");
    return false;
  }
  disableAllSubmitButtons('time_and_expense');
  return true;
}

function check_add_expense_amt( obj, expense_entry ){
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
      disable_all(expense_entry, obj);
    }
  }
}

function check_add_expense_entry_override( obj, expense_entry ){
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
    set_expense_billing_amount(expense_entry+'_expense_entry_final_expense_amount', expense_entry+'_expense_entry_expense_amount', expense_entry+'_final_billed_amount');
  }
}

function check_expense_override( obj, expense_entry ){
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