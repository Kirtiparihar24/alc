// This Js is used for Billing Module
// Surekha, Beena

jQuery(function(){
  jQuery('.edit_timeentry_total_duration').editable('/tne_invoice_time_entries/set_time_entry_total_duration',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
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
  
  jQuery('.edit_timeentry_actual_duration').editable('/tne_invoice_time_entries/set_time_entry_actual_duration',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
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

  jQuery('.edit_timeentry_starttime').editable('/tne_invoice_time_entries/set_time_entry_formatted_start_time',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    inputclassname : 'starttime',
    width : '75px',
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_endtime').editable('/tne_invoice_time_entries/set_time_entry_formatted_end_time',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
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

  jQuery('.edit_timeentry_description').editable('/tne_invoice_time_entries/set_time_entry_description',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
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

  jQuery('.edit_timeentry_bill_rate').editable('/tne_invoice_time_entries/set_time_entry_actual_bill_rate',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
    indicator : '<img src="/images/livia_portal/indicator.gif" />',
    style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
    tooltip   : 'Click to edit',
    maxlength : 12,
    width : '50px',
    is_int : true,
    ajaxoptions: {
      dataType: 'script'
    }
  });

  jQuery('.edit_timeentry_billing_percent').editable('/tne_invoice_time_entries/set_time_entry_billing_percent',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
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

  jQuery('.edit_timeentry_overrideamount').editable('tne_invoice_time_entries/set_time_entry_billing_amount',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"   class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
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

  jQuery('.editexpensedescription').editable('/tne_invoice_expense_entries/set_expense_entry_description',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"  />',
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

  jQuery('.editexpenseamount').editable('/tne_invoice_expense_entries/set_expense_entry_expense_amount',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"  />',
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

  jQuery('.editexpensebillingpercent').editable('/tne_invoice_expense_entries/set_expense_entry_billing_percent',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
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

  jQuery('.editexpensebillingamt').editable('/tne_invoice_expense_entries/set_expense_entry_billing_amount',{
    cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel" />',
    submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok" />',
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