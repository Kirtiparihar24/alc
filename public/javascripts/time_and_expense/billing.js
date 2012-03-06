//This Js is used for Billing Module
//Surekha 

var loader = jQuery("<center><img src='/images/loading.gif' /></center>");
var loader2 = jQuery("<img src='/images/loading.gif' />");
var spinner = jQuery("<center><img src='/images/spinner.gif' /></center>");

jQuery.noConflict();
jQuery(function(){
  jQuery("#datepicker_time_entry").datepicker({
    showOn: 'both',
    dateFormat: 'mm/dd/yy',
    changeMonth: true,
    changeYear: true,
    setDate: today_date().toDateString(),
    onSelect: function(value,date){
      var today = today_date();
      var newdate = new Date(value);
      var time_entry_date
      if( newdate > today ){
        var date_confirm = confirm('Details being entered are for a future date. Click OK to proceed.');
        if(date_confirm){
          time_entry_date = jQuery('#datepicker_time_entry').val();
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
  });
});

function display_data(){
    var param_data = jQuery("#tne_invoice").serialize();
    param_data= param_data.replace('_method=put','_method=post')
    jQuery.ajax({
        type: 'post',
        url: '/tne_invoices/display_data',
        data: param_data,
        dataType: 'script',
        beforeSend: function(){
            loader.prependTo('#display_loader');
            jQuery('body').css("cursor", "wait");
        },
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
        },
        success: function(transport)
        {
            show_errors('second');
            changePTaxnSTaxName();

            if(jQuery('#apply_primary_tax').length==0){}else{
                if(jQuery('#apply_primary_tax').is(':checked')){
                    jQuery('#primary_tax_tr').removeAttr('style');
                }else{
                    jQuery('#primary_tax_tr').css('display','none');
                }
            }

            if(jQuery("#apply_secondary_tax").length==0){}else{
                if(jQuery('#apply_secondary_tax').is(':checked')){
                    jQuery('#secondary_tax_tr').removeAttr('style');
                }else{
                    jQuery('#secondary_tax_tr').css('display','none');
                }
            }
            if(jQuery('#apply_final_discount').is(':checked')){
                jQuery('#discount_tr').removeAttr('style');
            }else{
                jQuery('#discount_tr').css('display','none');
                check_amount();
                
            }
        }
    });
}

jQuery(function(){
    jQuery('#show_prev').live('click', function(e){;
    });
});

jQuery(function(){
    jQuery('#show_next').live('click', function(e){
        displayInvoiceNo('tne_invoice_invoice_no');
        changePTaxnSTaxName();
        classname='message_error_div';
        msg='';
        if(jQuery('#tne_invoice_view').val()=='presales' && jQuery('#tne_invoice_contact_id').val()=="")
            {
                msg="Please select the contact from contacts list<br/>"
            }
        else if(jQuery('#tne_invoice_matter_id').val()=="")
            {
                msg="Please select a matter from matters list<br/>"
            }
        if(jQuery('#tne_invoice_invoice_no').val()=="")
            {
                msg+="Invoice No cannot be blank. <br/>"
            }
        else {
           msg+= checkInvoiceNo();
        }
        if(msg)
        {
            jQuery('#errorCont')
            .html("<div class="+classname+">"+msg+"</div>")
            .fadeIn('slow')
            .animate({
                opacity: 1.0
            }, 8000)
            .fadeOut('slow')
           // jQuery("#bill_details").show();
           // jQuery("#time_and_expense_details").show();
    
        }
    
        else
        {
            //jQuery("#bill_details").show();
            //jQuery("#time_and_expense_details").show();
            //jQuery('#calculation_detail').show();
            jQuery('.no_record').hide();

            if(jQuery('#apply_primary_tax').length==0){}else{
                if(jQuery('#apply_primary_tax').is(':checked')){
                jQuery('#primary_tax_tr').removeAttr('style');
                }else{
                jQuery('#primary_tax_tr').css('display','none');}
            }            

            if(jQuery('#apply_secondary_tax').length==0){}else{
                if(jQuery('#apply_secondary_tax').is(':checked')){
                jQuery('#secondary_tax_tr').removeAttr('style');
                }else{
                jQuery('#secondary_tax_tr').css('display','none');}
            }            

           displayDiscount();
            check_amount();            

           if (jQuery("#tne_invoice_matter_id").val() != "" ) {
               display_data();
           }
        

        }

    });
});

function time_entry_refresh(){
   // jQuery("#time_and_expense_details").show();
   // jQuery('#calculation_detail').show();

    if(jQuery("#apply_primary_tax").length==0){}else{
        if(jQuery('#apply_primary_tax').is(':checked')){
        jQuery('#primary_tax_tr').removeAttr('style');
        }else{
        jQuery('#primary_tax_tr').css('display','none');}
    }   

    if(jQuery("#apply_secondary_tax").length==0){}else{
        if(jQuery('#apply_secondary_tax').is(':checked')){
            jQuery('#secondary_tax_tr').removeAttr('style');
        }else{
            jQuery('#secondary_tax_tr').css('display','none');}
    }

    displayDiscount();

    check_amount();
    display_data();
}

function delete_expense_entry(id)
{    

    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {
        jQuery.ajax(
       {
        type: 'delete',
        url: '/tne_invoice_expense_entries/' + id,
            dataType: "script",
        success: function(transform){
            time_entry_refresh();
        },
        complete: function(){
               show_error_msg("errorCont",'Expense Entry Deleted Successfully',"message_sucess_div");
            }
        });
       

    }
    else
    {
        return;
    }
   

}

function delete_time_entry(id)
{

    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {
        jQuery.ajax(
       {
        type: 'delete',
        url: '/tne_invoice_time_entries/' + id,
            dataType: "script",
        success: function(transform){
            time_entry_refresh();
        },
        complete: function(){
               show_error_msg("errorCont",'Time Entry Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }


}


function delete_all_time_entry(matter_id_val,contact_id_val,activity_type_val,invoice_id_val,consolidate_by_val)
{

    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {loader.prependTo('#display_loader');
        jQuery.ajax(
        {
            type: 'GET',
            url: '/tne_invoice_time_entries/delete_all_time_entries',
            data: {
            contact_id : contact_id_val,
            matter_id: matter_id_val,
            activity_type: activity_type_val,
            invoice_id: invoice_id_val,
            consolidate_by: consolidate_by_val
        },
            dataType: "script",
            success: function(transform){
                time_entry_refresh();
                loader.remove();
            },
            complete: function(){
               show_error_msg("errorCont",'Time Entries Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }


}


function delete_all_expense_entry(matter_id_val,contact_id_val,activity_type_val,invoice_id_val,consolidate_by_val)
{    
    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {loader.prependTo('#display_loader');
        jQuery.ajax(
        {
            type: 'GET',
            url: '/tne_invoice_expense_entries/delete_all_expense_entries',
            data: {
            contact_id : contact_id_val,
            matter_id: matter_id_val,
            expense_type: activity_type_val,
            invoice_id: invoice_id_val,
            consolidate_by: consolidate_by_val
        },
            dataType: "script",
            success: function(transform){
                loader.remove();
                time_entry_refresh();
            },
            complete: function(){
               show_error_msg("errorCont",'Expense Entries Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }


}

function showMattersForSelectedContact(id){
    var matter_id = jQuery('#'+id.toString() + '_matter_id').val();
    var contact_id = jQuery('#'+id.toString() + '_contact_id').val();
    //    tempObj = jQuery('#' + id.toString() + '_matter_id');
    //    if(tempObj !=null && tempObj.length > 0){
    //        tempObj.remove();
    //    }
    //jQuery('#' + id.toString() + '_matterSearch').hide();
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
function get_all_matters(id,time_entry_id, expense_entries)
{
    var tmp = id.split('_');
    var contact_id = tmp[1];

    var matter_id = jQuery( '#'+time_entry_id.toString() + '_matter_id' ).val();
    var expense_entries_array = "[";
    //  remove unnecessary ',' for o length
    for ( var i=0, len=expense_entries.length; i<len; ++i ){
        expense_entries_array = expense_entries_array + expense_entries[i] + ",";
    }
    expense_entries_array = expense_entries_array + "]";
  
  
    if (contact_id == "" && matter_id == "")
    {
        jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', true);
        set_is_billable(time_entry_id, expense_entries);
    }
    else
    {
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

function update_matter_contact(id){
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
function updateContactORMatter(obj,ID,type,expense_entries,methodName){
    idStr = ID+"_"+type+"_id";
    if(type=="matter"){
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
            str = '<input type="hidden" value="" id="'+idStr+'" name="'+ID+'"[matter_id]" />';
            searchDiv.append(str);
            searchDiv.show();
        }
    } 
    entryID =obj.id.replace(/[^0-9\\.]/g, '');

    //var selcted_id = jQuery('#'+ID+'_'+type+'_id').val();
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

function get_matters_contact(id,time_entry_id, expense_entries,mat_id)
{  

    var tmp = id.split('_');
    var matter_id = tmp[1];
    if(mat_id !=null && mat_id !=""){
        matter_id = mat_id
    }
    var contact_id = jQuery('#'+time_entry_id.toString() + '_contact_id').val();
    
 
    var expense_entries_array = "[";
    //  remove unnecessary ',' for o length
    for ( var i=0, len=expense_entries.length; i<len; ++i ){
        expense_entries_array = expense_entries_array + expense_entries[i] + ",";
    }
    expense_entries_array = expense_entries_array + "]";
  
    if (contact_id == "" && matter_id == "")
    {
        jQuery('#'+time_entry_id.toString() + '_is_internal').attr('checked', true);
        set_is_billable(time_entry_id, expense_entries);
    }
    else
    {
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

function get_all_expense_matters(id,expense_entry_id,cont_id)
{  
    var contact_id = jQuery('#'+id).val();
    var matter_id = jQuery('#'+ expense_entry_id.toString() + '_expense_matter_id'  ).val();
    if( cont_id !=null && cont_id !=""){
        contact_id = cont_id
    }
    if (contact_id == "" && matter_id == "")
    {
        jQuery('#'+ expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',true);
        set_is_billable_for_expense_entry(expense_entry_id);
    }
    else
    {
        jQuery('#'+expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',false);
        jQuery('#'+expense_entry_id + '_is_internal_for_expense_entry').attr("onClick", "set_is_billable_for_expense_entry('"+expense_entry_id+"');");
        set_is_billable_for_expense_entry(expense_entry_id);
    }
    tempObj = jQuery('#'+expense_entry_id.toString() + '_matter_id');
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

function get_expense_matters_contact(id,expense_entry_id,mat_id)
{
    var matter_id = jQuery('#'+id).val();
    if(mat_id !=null && mat_id !=""){
        matter_id = mat_id
    }
    var contact_id = jQuery('#'+expense_entry_id.toString() + '_expense_contact_id').val();

    if (contact_id == "" && matter_id == "")
    {
        jQuery('#'+expense_entry_id.toString() + '_is_internal_for_expense_entry').attr('checked',true);
        set_is_billable_for_expense_entry(expense_entry_id);
    }
    else
    {
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
//
}

function set_is_billable(id, expense_entries)
{  
    if (jQuery('#'+id+'_is_internal').attr('checked'))
    {
        jQuery('#'+id+'_matters_div').html('');
        jQuery('#'+id+'_matterSearch').show();
        jQuery('#'+id+'_matter_ctl').attr("title","search");
        jQuery('#'+id+'_matter_ctl').val("");
        jQuery('#'+id+'_contact_span').html('');
        jQuery('#'+id+'_contactSearch').show();
        jQuery('#'+id+'_contact_ctl').val("");
        jQuery('#'+id+'_contact_ctl').attr("title","search");
        var billing_method_type= 1;
        var billing_type = 2;
        var is_internal = true;
        jQuery('#'+id+'_is_billable').attr("checked", false);
        jQuery('#'+id+'_is_billable').attr("disabled", true);
        jQuery('#billing_options_for_entry_'+id).hide();
        jQuery('#'+id+'_matter_id').val('');
        jQuery('#'+id+'_contact_id').val('');
        if(expense_entries != "0")
        {
            for ( var i=0, len=expense_entries.length; i<len; ++i ){
                jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("checked", false);
                jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("disabled", true);
                jQuery('#expense_entry_billing_options_'+expense_entries[i].toString()).hide();
                //jQuery('#expense_final_billed_amount_'+expense_entries[i].toString()).html('0.0');
                jQuery('#expense_final_billed_amount_'+expense_entries[i].toString()).hide();
            }
        }
        jQuery('#'+id + '_is_internal').attr("onClick", "show_alert_for_matter_and_contact('"+id+"_is_internal');");
    }
    else
    {   
        if(expense_entries != "0")
        {
            for ( var i=0, len=expense_entries.length; i<len; ++i ){
                jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("checked", true);
                jQuery('#'+expense_entries[i].toString()+'_expense_is_billable').attr("disabled", false);
                if(jQuery('#'+id+'_is_billable').attr("checked"))
                {
                    jQuery('#expense_entry_billing_options_'+expense_entries[i].toString()).show();
                }
                jQuery('#expense_final_billed_amount_'+expense_entries[i].toString()).show();
            }
        }
        var is_internal = false;
        if(jQuery('#'+id+'_is_billable').attr("checked"))
        {
            var billing_type = 1;
            jQuery('#billing_options_for_entry_'+id).show();
        }
        else
        {
            var billing_type = 2;
            jQuery('#'+id+'_is_billable').attr("disabled", false);
            jQuery('#billing_options_for_entry_'+id).hide();
        }
    }
    var billing_method_type=jQuery('#'+id+'_saved_entry_billing_method_type option:selected' ).val();
    jQuery.ajax({
        type: 'post',
        url: '/physical/timeandexpenses/time_entries/set_is_billable',
        data: {
            billing_type : billing_type,
            is_internal: is_internal,
            billing_method_type : billing_method_type,
            id: id
        },
        dataType : 'script'

    });
}

function set_is_billable_for_expense_entry(id)
{
    var accounted_type_expense_entry= '#'+ id+'_is_internal_for_expense_entry';
    if (jQuery(accounted_type_expense_entry).attr('checked'))
    {
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
    }
    else
    {
        var is_internal = false;
        if(jQuery('#'+id+'_expense_is_billable').attr('checked'))
        {
            var billing_type = 1;
            jQuery('#expense_entry_billing_options_'+id).show();
        }
        else
        {
            var billing_type = 2;
            jQuery('#'+id+'_expense_is_billable').attr("disabled",false);
            jQuery('#expense_entry_billing_options_'+id).hide();
        }
    }

    jQuery.ajax({
        type: 'post',
        url: '/tne_invoice_expense_entries/set_expense_is_billable',
        data: {
            billing_type : billing_type,
            is_internal: is_internal,
            id: id
        } ,
        dataType : 'script'
     
    });

}

function set_expense_is_billable(billing_type,expense_entry)
{
    var is_internal;
    if(jQuery('#'+billing_type).attr('checked'))
    {
        var billing_type = 1;
        is_internal = false;
        jQuery('#expense_entry_billing_options_'+expense_entry).show();

    }
    else
    {
        var billing_type = 2;
        is_internal = true;
        jQuery('#expense_entry_billing_options_'+expense_entry).hide();
    }


    jQuery.ajax({
        type: 'post',
        url: '/tne_invoice_expense_entries/set_expense_is_billable',
        data: {
            billing_type : billing_type,
            is_internal: is_internal,
            id: expense_entry
        } ,
        dataType : 'script'

    });
}


function show_alert_for_matter_and_contact(id)
{
    jQuery('#'+id).attr('checked',true);
    alert('Select matter/contact or check internal.');
    return;
}

function initeditexpense_type(expensetypes){
    jQuery.noConflict();
    jQuery(function() {
        jQuery('.editexpense_type').editable('/tne_invoice_expense_entries/set_expense_entry_expense_type',{
            cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
            submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
            indicator : '<img src="/images/livia_portal/indicator.gif" />',
            style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
            data : expensetypes,
            type : 'select',
            width : '150px',
            tooltip   : 'Click to edit.'
     
        });
    });
}


function initedit_timentry_activity(){
    jQuery.noConflict();
    jQuery(function() {
        jQuery('.edit_timeentry_activity').editable('/tne_invoice_time_entries/set_time_entry_activity_type',{
            cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
            submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
            indicator : '<img src="/images/livia_portal/indicator.gif" />',
            style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
            data : activitytypes,
            type : 'select',
            width : '150px',
            //callback : function(content){update_entries_divs_in_callback(jQuery(this).attr("id"));},
            tooltip   : 'Click to edit.'
        });
    });
}


function init_edit_time_entry_status(){
    jQuery.noConflict();
    jQuery(function() {
        jQuery('.edit_time_entry_status').editable('/tne_invoice_time_entries/set_time_entry_status',{
            cancel : '<img src="/images/livia_portal/icon_cancel.gif"  class="vtip" title="Cancel"/>',
            submit : '<img src="/images/livia_portal/icon_tick.gif"  class="vtip" title="Ok"/>',
            indicator : '<img src="/images/livia_portal/indicator.gif" />',
            style : 'position:absolute;z-index:99999;border:1px solid #EEEEBB;background:#FFFFCC;padding:5px;',
            data : status,
            type : 'select',
            width : '150px',
            //callback : function(content){update_entries_divs_in_callback(jQuery(this).attr("id"));},
            tooltip   : 'Click to edit.'
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
            tooltip   : 'Click to edit.'
        });
    });

}


function change_time_entry_status(id, url)
{
    var status = jQuery('#time_entry_'+id.toString() + '_status').val();
    jQuery.ajax({
        type: 'post',
        url: '/physical/timeandexpenses/time_and_expenses/set_time_entry_status',
        data: {
            id : id ,
            value : status
        } ,
        dataType: 'script',
        complete: function(){
            window.location = url;
        }
    });
}


function change_expense_entry_status(id, url)
{
    var status = jQuery('#expense_entry_'+id.toString() + '_status').val();
    jQuery.ajax({
        type: 'post',
        url: '/tne_invoice_expense_entries/set_expense_entry_status',
        data: {
            id : id ,
            value : status
        } ,
        dataType: 'script',
        complete: function(){
            window.location = url;
        }
    });
}

function toggle_checked_entries()
{
    var entries = jQuery(".entries");
    for (var i=0; i<entries.length; i++) {
        if(entries[i].disabled==false)
        {
            entries[i].checked = jQuery("#check_all:checked").val();
        }
    }
}

function invoiceUpdateTimeUtilities(obj,type,methodName,timeOrExpenseId,bill_entry_id)
{
    try {
        if(isNaN(text_val) == true)
        {
            alert("Please enter numeric value");
            obj.value="";
            return;
        }
        var text_val = parseFloat(obj.value.replace(/,/g,''));
        if(isNaN(text_val) == true){
            alert("Please enter numeric value");
             obj.value="";
            return;
        }
        if((text_val < 0 || text_val > 100) && (methodName.search(/percent/) !=-1)){
            alert("Please Enter Discount between 0.01 to 100");
            obj.value="";
        }else if(text_val < 0 && (methodName.search(/percent/) ==-1)){
            alert("Please enter numeric value");
            obj.value="";
        } else if((text_val < 0 || text_val > 1000)&& (methodName.match(/markup/))){
            alert("Please Enter Markup between 0.01 to 1000");
            obj.value="";
        }
        else{
            jQuery.ajax({
                beforeSend: function(){
                    loader.prependTo(obj.parentNode);
                    obj.style.display='none';
                    jQuery('body').css("cursor", "wait");
                },
                type: 'POST',
                url: '/tne_invoice_'+type+'/'+timeOrExpenseId+'/'+methodName,
                data: {
                    value : text_val,
                    bill_entry_id : bill_entry_id
                },
                async: true,
                dataType: 'script',
                complete: function(){
                    jQuery('body').css("cursor", "default");
                    loader.remove();
                    obj.style.display='block';
                }
            });
        }

    } catch (exception) {
        alert("Please enter numeric value");
    }
}//end up

function invoiceTimeOrExpenseFullAmount(obj,type,methodName,timeOrExpenseId){
   
    var fullAmount;
    var finalAmount;
    if(type =='time_entries'){
        fullAmount = jQuery('#billed_amount_'+timeOrExpenseId).children('span').html();
        finalAmount = jQuery('#final_billed_amount_'+timeOrExpenseId).children('span').html();
        try {
            fullAmount = parseFloat(removeCommas(fullAmount));
            finalAmount = parseFloat(removeCommas(finalAmount));
            if(finalAmount == fullAmount){
                return;
            }
        } catch (exception) {
            return;
        }

    } else {
        fullAmount = jQuery('#expenseamount_'+timeOrExpenseId).children('span').html();
        finalAmount = jQuery('#expense_final_billed_amount_'+timeOrExpenseId).html();
        try {
            fullAmount = parseFloat(removeCommas(fullAmount));
            finalAmount = parseFloat(removeCommas(finalAmount));
            if(finalAmount == fullAmount){
                return;
            }
        } catch (exception) {
            alert(exception);
            return;
        }
    }
    elems = jQuery('.input_class');
    for(i =0;i < elems.length;i++){
        elems[i].disabled=true;
    }
    jQuery.ajax({
        beforeSend: function(){
            loader.prependTo(obj.parentNode);
            jQuery('body').css("cursor", "wait");
        },
        type: 'POST',
        url: '/tne_invoice_'+ type + '/'+timeOrExpenseId + '/' + methodName,
        async: true,
        dataType: 'script',
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
        }
    });
}//end of timeOrExpenseFullAmount()

function check_calculations(){
    var invoice_amt =   jQuery('#tne_invoice_invoice_amt');
    var discount    =   jQuery("#tne_invoice_discount");
    var primary_tax_rate    =   jQuery('#tne_invoice_primary_tax_rate');
    var primary_tax_name    =   jQuery('#tne_invoice_primary_tax_name');
    var primary_tax_value   =   jQuery('#primary_tax_value');
    var secondary_tax_rate  =   jQuery('#tne_invoice_secondary_tax_rate');
    var secondary_tax_name    =   jQuery('#tne_invoice_secondary_tax_name');
    var secondary_tax_value =   jQuery('#secondary_tax_value');
    var final_invoice_amount    =   jQuery('#tne_invoice_final_invoice_amt');
    var apply_primary_tax   =   jQuery('#apply_primary_tax');    
    var apply_final_discount    =   jQuery('#apply_final_discount');
    var primary_tax = 0 ;
    if(jQuery('#apply_secondary_tax').length==0){
        checkcalulated_tax_with_only_primary();
    }else{
        var apply_secondary_tax   =   jQuery('#apply_secondary_tax');
        var secondary_tax_rule   =   jQuery('#tne_invoice_secondary_tax_rule');
        calculate_primary_secondary_tax();
        
    }
     invoice_amt.val(addCommas(invoice_amt.val().replace(/\,/g,'')));
   if(invoice_amt.val()==""){
        invoice_amt.val('0');
   }

    if(apply_final_discount.is(':checked'))
    {
        if(discount.val()==""){
            discount_total    =   parseFloat(invoice_amt.val().replace(/\,/g,'')) -  0 ;
        }else{
            discount_total    =   parseFloat(invoice_amt.val().replace(/\,/g,'')) -  parseFloat(discount.val().replace(/\,/g,'')) ;
        }
    }
    else
    {
        discount_total    =   parseFloat(invoice_amt.val().replace(/\,/g,'')) -  0;
        jQuery("#tne_invoice_discount").val(0.00);
    }
   
    if(apply_primary_tax.is(':checked'))
    {
        if(primary_tax_rate.val()==""){
            primary_tax_rate.val(0);
        }
        primary_tax    =   parseFloat(((parseFloat(discount_total)  *   parseFloat(primary_tax_rate.val())) / 100 ));
        primary_tax_value = floatToTwoDecimalPlaces(primary_tax);
}
    else
    {
        primary_tax_value    =   0;
        primary_tax_rate.val(0);

    }
        
    if(jQuery('#apply_secondary_tax').length==0){}else{
    if(apply_secondary_tax.is(':checked'))
    {
        if(secondary_tax_rate.val()==""){
            secondary_tax_rate.val(0);
        }
        if(secondary_tax_rule.val()==0){
            secondary_tax    =   parseFloat(((parseFloat(invoice_amt.val())  *   parseFloat(secondary_tax_rate.val())) / 100 ));
            secondary_tax_value = floatToTwoDecimalPlaces(secondary_tax);
        }else{
            total   =   parseFloat(discount_total)  +  parseFloat(primary_tax_value);
            secondary_tax   =   parseFloat(((parseFloat(total) *   parseFloat(secondary_tax_rate.val())) /100 ));
            secondary_tax_value = floatToTwoDecimalPlaces(secondary_tax);
        }
    }else{
        secondary_tax_value = 0;
        secondary_tax_rate.val(0);
     }
    }
    if(discount.val()==""){
        jQuery("#tne_invoice_discount").val(0);
    }
   
    //Code to display Primary tax and seconadry tax  to display the actual names defined in settings or at a bill level.
    if(primary_tax_name.val()==""){
        jQuery('#p_tax').html('Primary Tax ' + ' ' +"("+primary_tax_rate.val()+" %)");
    }else{
        jQuery('#p_tax').html(primary_tax_name.val() + ' ' + "(" +primary_tax_rate.val()+ " %)");
    }
    if(jQuery('#apply_secondary_tax').length==0){}else{
    if(secondary_tax_name.val()==""){
        jQuery('#s_tax').html('Secondary Tax' + ' ' + "(" + secondary_tax_rate.val() + " %)");
    }else{
        jQuery('#s_tax').html(secondary_tax_name.val() + ' ' + "(" +secondary_tax_rate.val() + " %)");
    }
    }
    
    if(jQuery("#apply_primary_tax").attr("checked")){
        if(primary_tax_name.val()==""){
            jQuery('#header_p_tax').html('Primary Tax ' +'<br/>' +"("+primary_tax_rate.val()+" %)");
        }else{
            jQuery('#header_p_tax').html(primary_tax_name.val()+'<br/>'+"("+primary_tax_rate.val()+" %)");
        }
    }else{
        jQuery('#header_p_tax').html('Primary Tax '+'<br/>'+"("+primary_tax_rate.val()+" %)");
    }
    if(jQuery('#apply_secondary_tax').length==0){}else{
    if(jQuery("#apply_secondary_tax").attr("checked")){
        if(secondary_tax_name.val()==""){
            jQuery('#header_s_tax').html('Secondary Tax'+'<br/>'  +"("+secondary_tax_rate.val()+" %)");
        }else{
            jQuery('#header_s_tax').html(secondary_tax_name.val() +'<br/>'  +"("+secondary_tax_rate.val()+" %)");
        }
    }else{
        jQuery('#header_s_tax').html('Secondary Tax '+'<br/>' +"("+secondary_tax_rate.val()+" %)");
    }
    }
   
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

function show_entries(div_id)
{
    if(div_id == 'client'){
        jQuery("#searched_invoices_"+div_id).show();
        jQuery("#searched_invoices_matter").hide();
    }else{
        jQuery("#searched_invoices_"+div_id).show();
        jQuery("#searched_invoices_client").hide();
    }
}

// To add commas and convert into float values
  function addCommas(num) 
{
    var number = parseFloat(num).toFixed(2)+'';
    rgx = /(\d+)(\d{3}[\d,]*\.\d{2})/;
    while (rgx.test(number)) {
        number = number.replace(rgx, '$1' + ',' + '$2');
    }
    return number;
}

function removeCommas(num) {
    var number =  parseFloat(num).toFixed(2)+'';
    if (number!=""){
       number=num.replace(/\,/g,'');
    }
    return number;
}



function get_tne_act_rate(activity_type_id,form_id,emp_id)
{
    activity_rate_id = ".new_invoice_time_entry";
    var activity_rate = jQuery(activity_rate_id).find("#activity_rate");        
    var employee_id = emp_id;
    jQuery.ajax({
        type: 'GET',
        url: '/physical/timeandexpenses/get_billing_activity_rate',
        data: {
            activity_type_id : activity_type_id,
            employee_id: employee_id
        },
        async: true,
        dataType: 'script',
        beforeSend: function(){
            loader.prependTo('#loader_container');
            jQuery('body').css("cursor", "wait");
        },
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
        },
        success: function(transport)
        {            
            activity_rate.val(transport);
        }
    });   
}

function add_new_time_entry(dbrow,mattet_id_val,invoice_id,contact_id_val){
    var activity_type_id = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_activity_type").val();
    var activity_duration = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_duration").val();
    var activity_rate = removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_rate").val());    
    var activity_desc = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_description").val();    
    var activity_primary_tax = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_primary_tax").is(':checked');
    var activity_secondary_tax = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_secondary_tax").is(':checked');
    
    if( activity_duration==""){
        alert("Please enter duration");
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_duration").focus();
        return false;
    }

    if(activity_duration!=""){
        if(isNaN(activity_duration) || eval(activity_duration)<=0) {
            alert("Please enter duration between 0.01 to 24.00")
            jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_duration").focus();
            return false;
        }

    }

    if( activity_rate=="" || eval(activity_rate)<=0 || isNaN(activity_rate)){
        alert("Rate should be between 0.01 and 9999.99");
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_rate").focus();
        return false;
    }

    if(eval(activity_rate)>0){
           frate = parseFloat(activity_rate);
            if ((activity_rate.indexOf('.') != -1) && ((activity_rate.length - activity_rate.indexOf('.') -1) > 2))
            {
                frate = frate.toFixed(2);
                
            }
            
            if (frate > 9999.99 || frate < 0.01)
            {
                alert("Rate should be between 0.01 and 9999.99");
                jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_rate").focus();
                return false;
            }     
            

    }

    if(activity_desc==""){
        alert("Please enter description");
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrow+"_description").focus();
        return false;
    }

    // alert(activity_type_id+"-"+activity_duration+"-"+activity_rate+"-"+activity_desc+"-"+activity_primary_tax+"-"+activity_secondary_tax+""+mattet_id_val);

    jQuery.ajax({
        type: 'GET',
        url: '/tne_invoice_time_entries/add_new_time_entry',
        data: {
            activity_type : activity_type_id,
            description: activity_desc,
            actual_duration: activity_duration,
            matter_id: mattet_id_val,
            primary_tax: activity_primary_tax,
            secondary_tax: activity_secondary_tax,
            actual_rate: activity_rate,
            time_invoice_id:invoice_id,
            contact_id : contact_id_val
        },
        async: true,
        dataType: 'script',
        beforeSend: function(){
            loader.prependTo('#loader_container');
            jQuery('body').css("cursor", "wait");
        },
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
            show_error_msg("errorCont",'Time Entry Saved Successfully',"message_sucess_div");
        }

         
    });
}

function add_new_expense_entry(dbrows,mattet_id_val,invoice_id_val,contact_id_val,consolidated_by,regenerate){
    var activity_type_id = jQuery(".expense_act_type").val();
    var activity_desc = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_description").val();
    var activity_primary_tax = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_primary_tax").is(':checked');
    var activity_secondary_tax = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_secondary_tax").is(':checked');
    var activity_amount = jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_amount").val();

    if( activity_desc==""){
        alert("Please enter description");
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_description").focus();
        return false;
    }

    if(activity_amount=="" || isNaN(removeCommas(activity_amount))){
        alert("Please enter amount");
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_amount").focus();
        return false;
    }

    if(activity_amount!=""){
        if(eval(removeCommas(activity_amount))<=0) {
            alert("Amount must be > 0");
            jQuery("#tne_invoice_tne_invoice_details_attributes_"+dbrows+"_amount").focus();
            return false;
        }

    }

    jQuery.ajax({
        type: 'GET',
        url: '/tne_invoice_expense_entries/add_new_expense_entry',
        data: {
            activity_type : activity_type_id,
            description: activity_desc,
            matter_id: mattet_id_val,
            primary_tax: activity_primary_tax,
            secondary_tax: activity_secondary_tax,
            activity_amount: removeCommas(activity_amount),
            expense_invoice_id: invoice_id_val,
            contact_id : contact_id_val,
            consolidated_by : consolidated_by,
            regenerate : regenerate
        },
        async: true,
        dataType: 'script',
        beforeSend: function(){
            loader.prependTo('#loader_container');
            jQuery('body').css("cursor", "wait");
        },
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
            show_error_msg("errorCont",'Expense Entry Saved Successfully',"message_sucess_div");
             display_data();
        }                  

    });
}

function check_detailed_tax(checkbox)
{
    var view =jQuery('#tne_invoice_view_by option:selected').val();
    if (view=='Detailed')
    {
        if(checkbox.checked)
        {
        jQuery(checkbox).next().next().val(true);
        }
        else{
           jQuery(checkbox).next().next().val(false);
        }
    }
}
function check_amount_for_delete()
{
    var recs = jQuery(".tne_invoice_amount");
    var total=0;
    for (var i=0; i<recs.length; i++) {
      var amount_id = jQuery('#' + recs[i].id);
      var amount = amount_id.val().replace(/\,/g,'');
      if(amount<0 || isNaN(amount)){
          jQuery('#' + recs[i].id).val("0.00");
          alert("Please Enter Valid Amount");
          return false;
      }
      amount_id.next().val(parseFloat(amount));
      total += parseFloat(amount);
      jQuery('#' + recs[i].id).val(addCommas(amount));
    }
    jQuery('#tne_invoice_invoice_amt').val(addCommas(total));
    check_calculations();
}

function check_amount()
{ 
    var recs = jQuery(".tne_invoice_amount");
    var total=0;
    for (var i=0; i<recs.length; i++) {
      var amount_id = jQuery('#' + recs[i].id);
      var amount = amount_id.val().replace(/\,/g,'');
      amount_id.next().val(parseFloat(amount));
      total += parseFloat(amount);
      jQuery('#' + recs[i].id).val(addCommas(amount));
    }
    jQuery('#tne_invoice_invoice_amt').val(addCommas(total));
    check_calculations();
}

function delete_table_row(tbrow,add_button){  
   jQuery(tbrow).parent().parent().parent().remove();
    jQuery(add_button).show();
    check_amount();


}


 function changePTaxnSTaxName(){
      if (jQuery('#tne_invoice_primary_tax_name').val()=='Primary Tax Name')
      {
        jQuery('#tne_invoice_primary_tax_name').val('')
      }
      if (jQuery('#tne_invoice_secondary_tax_name').val()=='Secondary Tax Name')
      {
        jQuery('#tne_invoice_secondary_tax_name').val('')
      }
    }

function check_amount_new()
{
    var recs = jQuery(".tne_invoice_amount");
    var total=0;
    for (var i=0; i<recs.length; i++) {
      var amount_id = jQuery('#' + recs[i].id);
      var amount = amount_id.val().replace(/\,/g,'');
      amount_id.next().val(parseFloat(amount));
      total += parseFloat(amount);
      jQuery('#' + recs[i].id).val(addCommas(amount));
    }
    jQuery('#tne_invoice_invoice_amt').val(addCommas(total));
    check_calculations();
}

function change_rate_text_fields(id,counter,duration,final_bill_amount,to_do,activity_type,detail_entry)
{
    consolidated_duration = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_duration").val()));
    consolidated_amt = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()));
    jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val(parseFloat(Math.abs(consolidated_amt-parseInt(final_bill_amount))))
    if(to_do =="delete_donot_appear")
    {
        duration_after_delete = Math.abs(consolidated_duration-duration)
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_duration").val(addCommas(duration_after_delete))
        rate = (parseInt(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val())/parseInt(duration_after_delete))
        jQuery("#time_"+id).remove();
        if((rate.toString()=='NaN') || (rate.toString()=='Infinity') || rate ==0)
        {
            jQuery('#excluded_time').append("<input id='delete_time_detail_entries_ids_' type='hidden' name='delete_time_detail_entries_ids[]' value="+detail_entry+">")
            jQuery('#excluded_time').append("<input id='delete_time_entries_ids_' type='hidden' name='delete_time_entries_ids[]' value="+counter+">")
            jQuery('#outer_'+activity_type).remove();
        }
        else
        {
           jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_rate").val(addCommas(rate))
        }
    }
    else
     {
         rate = (parseInt(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val())/parseInt(consolidated_duration));
         //if(rate != 0)
          jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_rate").val(addCommas(rate));
     }

    check_amount_new();


}

function change_expence_text_fields(id,counter,final_expense_amount,to_do,activity_type,detail_entry)
{
    consolidated_amt = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()));
    jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val(parseFloat(Math.abs(consolidated_amt-parseInt(final_expense_amount))))

    if(to_do =="delete_donot_appear")
    {
        jQuery("#expense_"+id).remove();
        if(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()=="0")
          {
           jQuery('#excluded_time').append("<input id='delete_expense_detail_entries_ids_' type='hidden' name='delete_expense_detail_entries_ids[]' value="+detail_entry+">")
           jQuery('#excluded_time').append("<input id='delete_expense_entries_ids_' type='hidden' name='delete_expense_entries_ids[]' value="+counter+">")
            jQuery('#outer_'+activity_type).remove();
          }
    }
    check_amount_new();
}

function time_entry_refresh_delete(id,to_do,counter,final_bill_amount,rate,duration,activity_type,detail_entry){
    jQuery("#bill_details").show();
    jQuery("#time_and_expense_details").show();
    jQuery('#calculation_detail').show();

    if(jQuery('#apply_primary_tax').is(':checked'))
        jQuery('#primary_tax_tr').removeAttr('style');
    else
        jQuery('#primary_tax_tr').css('display','none');

    if(jQuery('#apply_secondary_tax').is(':checked'))
        jQuery('#secondary_tax_tr').removeAttr('style');
    else
        jQuery('#secondary_tax_tr').css('display','none');

   displayDiscount();
    check_calculations();
    jQuery('#'+id+'_saved_entry_billing_method_type').attr('selectedIndex', 1);
    jQuery.ajax({
        type: 'post',
        url: '/physical/timeandexpenses/time_entries/set_is_billable',
        data: {
            billing_type : true,
            is_internal: false,
            billing_method_type : 2,
            id: id
        },
        dataType : 'script',
        success: function(transform){
            if (to_do =="delete_appear")
            {
                jQuery('#'+id+'_show_amount').show();
                jQuery('#'+id+'_show_amount').val(addCommas(100));
                jQuery('#final_billed_amount_'+id).children().text(addCommas(0));                
            }
            change_rate_text_fields(id,counter,duration,final_bill_amount,to_do,activity_type,detail_entry)
            

          }

    });

}


function remove_time_entry(id,to_do,final_bill_amount,rate,duration,counter,activity_type,detail_entry)
{
    var c=confirm("The entry will be removed from the current invoice and will reflect as an approved entry in Time and Expenses module. Are you sure you want to proceed with the same?");
    if(c==true)
    {loader.prependTo('#display_loader');
        consolidated_duration = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_duration").val()));
        consolidated_amt = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()));
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_duration").val(addCommas(Math.abs(consolidated_duration-duration)))
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val(parseFloat(Math.abs(consolidated_amt-parseInt(final_bill_amount))))
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_rate").val(addCommas((parseInt(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val())/parseInt(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_duration").val()))))
        jQuery("#time_"+id).remove();
        if(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_rate").val()=='NaN' || parseInt(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_rate").val())==0)
        {
         jQuery('#outer_'+activity_type).remove();
         jQuery('#excluded_time').append("<input id='delete_time_entries_ids_' type='hidden' name='delete_time_entries_ids[]' value="+counter+">")
         jQuery('#excluded_time').append("<input id='delete_time_detail_entries_ids_' type='hidden' name='delete_time_detail_entries_ids[]' value="+detail_entry+">")
        }
        check_amount();
        tb_remove();
        jQuery('#excluded_time').append("<input id='excluded_time_entries_ids_' type='hidden' name='excluded_time_entries_ids[]' value="+id+">")
        

     loader.remove();
    }
    else
    {
        return
    }

}

function delete_time_entry_basic(id)
{
    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {
        tb_remove();
        loader.prependTo('#display_loader');
        jQuery.ajax(
       {
        type: 'delete',
        url: '/tne_invoice_time_entries/' + id,
        dataType: "script",
        success: function(transform){
            time_entry_refresh();
        },
        complete: function(){
             loader.remove();
               show_error_msg("errorCont",'Time Entry Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }
}

function delete_time_entry(id,to_do,counter,final_bill_amount,rate,duration,activity_type,detail_entry)
{
    if(to_do =='delete_appear'){
        var r=confirm("The entry will reflect in the current invoice with 100% discount applied to it. Are you sure you want to proceed with the same?");
    }
    else{
       var r=confirm("The entry will be removed from the current invoice and will reflect as an approved but non billable entry in Time and Expenses module. Are you sure you want to proceed with the same?");
    }

    if (r==true)
    {
        tb_remove();
        loader.prependTo('#display_loader');
        jQuery.ajax(
        {
            type: 'delete',
            url: '/tne_invoice_time_entries/' + id,
            data: {
                to_do : to_do
            },
            dataType: "script",
            success: function(){
                time_entry_refresh_delete(id,to_do,counter,final_bill_amount,rate,duration,activity_type,detail_entry);
            },
            complete: function(){
                loader.remove();
                show_error_msg("errorCont",'Time Entry Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }


}


function delete_all_time_entry(matter_id_val,contact_id_val,activity_type_val,invoice_id_val,consolidate_by_val)
{

    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {loader.prependTo('#display_loader');
        jQuery.ajax(
        {
            type: 'GET',
            url: '/tne_invoice_time_entries/delete_all_time_entries',
            data: {
            contact_id : contact_id_val,
            matter_id: matter_id_val,
            activity_type: activity_type_val,
            invoice_id: invoice_id_val,
            consolidate_by: consolidate_by_val
        },
            dataType: "script",
            success: function(){
                time_entry_refresh();
            },
            complete: function(){
                jQuery('body').css("cursor", "default");
                loader.remove();
            }
        });
    }
}

function remove_expense_entry(id,final_expense_amount,counter,activity_type,detail_entry)
{
    var c=confirm("The entry will be removed from the current invoice and will reflect as an approved entry in Time and Expenses module. Are you sure you want to proceed with the same?");
    if(c==true)
    {loader.prependTo('#display_loader');
        consolidated_amt = parseInt(removeCommas(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()));
        jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val(parseFloat(Math.abs(consolidated_amt-parseInt(final_expense_amount))))
        jQuery("#expense_"+id).remove();
        if(jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()=='NaN' || jQuery("#tne_invoice_tne_invoice_details_attributes_"+counter+"_amount").val()==0)
            {
            jQuery('#outer_'+activity_type).remove();
            jQuery('#excluded_expense').append("<input id='delete_expense_entries_ids_' type='hidden' name='delete_expense_entries_ids[]' value="+counter+">")
            jQuery('#excluded_expense').append("<input id='delete_expense_detail_entries_ids_' type='hidden' name='delete_expense_detail_entries_ids[]' value="+detail_entry+">")
            }
        check_amount();
        tb_remove();
        jQuery('#excluded_expense').append("<input id='excluded_expense_entries_ids_' type='hidden' name='excluded_expense_entries_ids[]' value="+id+">")
        loader.remove();
    }
    else
    {
        return
    }
}


function delete_expense_entry_basic(id)
 {
    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {loader.prependTo('#display_loader');
        jQuery.ajax(
       {
        type: 'delete',
        url: '/tne_invoice_expense_entries/' + id,
            dataType: "script",
        success: function(transform){
            time_entry_refresh();
        },
        complete: function(){
              loader.remove();
               show_error_msg("errorCont",'Expense Entry Deleted Successfully',"message_sucess_div");
            }
        });


    }
    else
    {
        return;
    }


}


function expense_entry_refresh_delete(id,to_do,counter,final_expense_amount,activity_type,detail_entry){
    jQuery("#bill_details").show();
    jQuery("#time_and_expense_details").show();
    jQuery('#calculation_detail').show();

    if(jQuery('#apply_primary_tax').is(':checked'))
        jQuery('#primary_tax_tr').removeAttr('style');
    else
        jQuery('#primary_tax_tr').css('display','none');

    if(jQuery('#apply_secondary_tax').is(':checked'))
        jQuery('#secondary_tax_tr').removeAttr('style');
    else
        jQuery('#secondary_tax_tr').css('display','none');

    displayDiscount();

    check_calculations();
    jQuery('#'+id+'_expense_entry_billing_method_type').attr('selectedIndex', 1);
    jQuery.ajax({
        type: 'post',
        url: '/tne_invoice_expense_entries/'+id+'/set_expense_entry_billing_percent',
        data: {
            value : 100,
            id: id
        },
        dataType : 'script',
        success: function(transform){
            if (to_do =="delete_appear")
             {
                jQuery('#'+id+'_show_amount_expense').show();
                jQuery('#'+id+'_show_amount_expense').val(addCommas(100));
                jQuery('#expense_final_billed_amount_'+id).children().text(addCommas(0));
             }
            change_expence_text_fields(id,counter,final_expense_amount,to_do,activity_type,detail_entry)
            

          }

    });
}

function delete_expense_entry(id,to_do,counter,final_expense_amount,activity_type,detail_entry)
{
     if(to_do =='delete_appear'){
        var r=confirm("The entry will reflect in the current invoice with 100% discount applied to it. Are you sure you want to proceed with the same?");
    }
    else{
       var r=confirm("The entry will be removed from the current invoice and will reflect as an approved but non billable entry in Time and Expenses module). Are you sure you want to proceed with the same?");
    }
    
    if (r==true)
    {loader.prependTo('#display_loader');
        tb_remove();
        jQuery.ajax(
       {
        type: 'delete',
        url: '/tne_invoice_expense_entries/' + id,
        data: {to_do : to_do},
            dataType: "script",
        success: function(transform){
            expense_entry_refresh_delete(id,to_do,counter,final_expense_amount,activity_type,detail_entry);
        },
        complete: function(){
              loader.remove();
               show_error_msg("errorCont",'Expense Entry Deleted Successfully',"message_sucess_div");
            }
        });


    }
    else
    {
        return;
    }


}

function delete_all_expense_entry(matter_id_val,contact_id_val,activity_type_val,invoice_id_val,consolidate_by_val)
{
    var r=confirm("Are you sure you want to delete this record?");
    if (r==true)
    {loader.prependTo('#display_loader');
        jQuery.ajax(
        {
            type: 'GET',
            url: '/tne_invoice_expense_entries/delete_all_expense_entries',
            data: {
            contact_id : contact_id_val,
            matter_id: matter_id_val,
            expense_type: activity_type_val,
            invoice_id: invoice_id_val,
            consolidate_by: consolidate_by_val
        },
            dataType: "script",
            success: function(transform){
                time_entry_refresh();
            },
            complete: function(){
                loader.remove();
               show_error_msg("errorCont",'Expense Entries Deleted Successfully',"message_sucess_div");
            }
        });

    }
    else
    {
        return;
    }


}

function preview_bill_details()
{
    var param_data = jQuery("#tne_invoice").serialize();
    param_data= param_data.replace('_method=put','_method=post')
    jQuery.ajax({
        type: 'get',
        url: '/tne_invoices/preview_bill',
        data: param_data,
        dataType: 'script',
        beforeSend: function(){
            loader.prependTo('#display_loader');
            jQuery('body').css("cursor", "wait");
        },
        complete: function(){
            jQuery('body').css("cursor", "default");
            loader.remove();
        },
        success: function(transport)
        {
            h=window.open('about:blank','middleBody-div','fullscreen=yes,status=yes,location=yes, left=0,top=0,directories=no,scrollbars=yes')
            h.document.write("<html> <head> </head> <body>"+transport+" </body> </html>");
            h.document.close();
            return false;
        }
    });
}


    function checkInvoiceNo()
    {
        var invoice_no = jQuery('#tne_invoice_invoice_no').val();
        var invoice_id = jQuery('#tne_invoice_id').val();
        var html =jQuery.ajax({
            type: "get",
            url: "/tne_invoices/check_invoice_no",
            data: {
                invoice_no : invoice_no,
                invoice_id : invoice_id
            },
            dataType: "text",
            async:false,
            beforeSend: function(){
                loader.prependTo("#display_loader");
                jQuery('body').css("cursor", "wait");
            },
            complete: function(){
                jQuery('body').css("cursor", "default");
                loader.remove();
            }
     });     
   return html.responseText;
}


function checkcalulated_tax_with_only_primary(){
    var ptaxary = 0;
    var view = jQuery("#tne_invoice_view_by").val();
    var p_entryid;
    var ttotal=0,etotal=0,grand_total = 0,tmp=0;
    if(jQuery("#apply_primary_tax").attr("checked")){
        var ptaxrate = parseFloat(jQuery("#tne_invoice_primary_tax_rate").val());
        jQuery(".p_tax_time:checked").each(function(){
            p_entryid = jQuery(this).next().attr("id").split("_")[4];
            tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"time");
            jQuery(this).next().val(tmp);
            ttotal += tmp;
        });
        jQuery(".p_tax_expense:checked").each(function(){
            p_entryid = jQuery(this).next().attr("id").split("_")[4];
            tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"expense");
            jQuery(this).next().val(tmp);
            etotal += tmp;
        });
        grand_total = ttotal + etotal;

        if(view=="Summary"){
            ptaxary += grand_total;
        }else{
            ptaxary = calculateChangesPrimaryTax(".time_entry_p_tax_time", "time", ptaxrate);
            ptaxary += calculateChangesPrimaryTax(".time_entry_p_tax_expense", "expense", ptaxrate);
        }
    }
    jQuery("#primary_tax_value").val(addCommas(ptaxary));
    var amt = 0;
    jQuery(".tne_invoice_amount").each(function(){
        if(!this.value==""){
            amt += parseFloat(this.value.replace(/\,/g,''));
        }
    });
    amt = floatToTwoDecimalPlaces(amt);
    var total = (parseFloat(amt)+parseFloat(ptaxary));
    
    if(jQuery("#apply_final_discount").attr("checked")){
        var disc = jQuery("#tne_invoice_discount").val().replace(/\,/g,'');
        if(disc == ""){
            disc= 0;
        }
        total = parseFloat(total) - parseFloat(disc);
        jQuery("#tne_invoice_discount").val(addCommas(disc));
    }
    total = addCommas(parseFloat(total));
    jQuery("#tne_invoice_final_invoice_amt").val(total);
}


function calculate_primary_tax(){
    var p_entryid;
    var view = jQuery("#tne_invoice_view_by").val();
    var ttotal=0,etotal=0,grand_total = 0,tmp=0;
    if(jQuery("#apply_primary_tax").attr("checked")){
        var ptaxrate = parseFloat(jQuery("#tne_invoice_primary_tax_rate").val());
        var ptaxary = 0;
        jQuery(".p_tax_time:checked").each(function(){
            p_entryid = jQuery(this).next().attr("id").split("_")[4];
            tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"time");
            jQuery(this).next().val(tmp);
            ttotal += tmp;
        });
        jQuery(".p_tax_expense:checked").each(function(){
            p_entryid = jQuery(this).next().attr("id").split("_")[4];
            tmp = CalculateSummaryPrimaryTax(p_entryid,ptaxrate,"expense");
            jQuery(this).next().val(tmp);
            etotal += tmp;
        });
        grand_total = ttotal + etotal;
        grand_total = floatToTwoDecimalPlaces(grand_total);

        if(view=="Summary"){
            ptaxary += grand_total;
        }else{
            ptaxary = calculateChangesPrimaryTax(".time_entry_p_tax_time", "time", ptaxrate);
            ptaxary += calculateChangesPrimaryTax(".time_entry_p_tax_expense", "expense", ptaxrate);
        }
        jQuery("#primary_tax_value").val(addCommas(ptaxary));
    }
    var chkd = 0
    if(jQuery('#apply_final_discount').attr("checked")){
        chkd = parseFloat(jQuery("#tne_invoice_discount").val().replace(/\,/g,''));
    }
    jQuery("#tne_invoice_discount").val(addCommas(chkd));
    var v = parseFloat(jQuery("#tne_invoice_invoice_amt").val().replace(/\,/g,'')) + parseFloat(jQuery("#primary_tax_value").val().replace(/\,/g,''));
    jQuery("#tne_invoice_final_invoice_amt").val(addCommas(parseFloat(v - chkd)));
    return false;
}


jQuery('#display_data').live('click', function(e){
        if(confirm_bill_changes())
        {

        displayInvoiceNo('tne_invoice_invoice_no');
        changePTaxnSTaxName();
        classname='message_error_div';
        msg='';
        if(jQuery('#tne_invoice_view').val()=='presales' && jQuery('#tne_invoice_contact_id').val()=="")
            {
                msg="Please select the contact from contacts list<br/>"
            }
        else if(jQuery('#tne_invoice_matter_id').val()=="")
            {
                msg="Please select a matter from matters list<br/>"
            }
        if(jQuery('#tne_invoice_invoice_no').val()=="")
            {
                msg+="Invoice No cannot be blank.<br/>"
            }
        else {
           msg+= checkInvoiceNo();
        }
        if(msg)
        {
            jQuery('#errorCont')
            .html("<div class="+classname+">"+msg+"</div>")
            .fadeIn('slow')
            .animate({
                opacity: 1.0
            }, 8000)
            .fadeOut('slow')
          jQuery('.tne_invoices').attr('disabled','true');
          jQuery('.tne_invoices').css('color','grey');
        }

        else
        {

            if(jQuery('#apply_primary_tax').length==0){}else{
                if(jQuery('#apply_primary_tax').is(':checked')){
                jQuery('#primary_tax_tr').removeAttr('style');
                }else{
                jQuery('#primary_tax_tr').css('display','none');}
            }

            if(jQuery('#apply_secondary_tax').length==0){}else{
                if(jQuery('#apply_secondary_tax').is(':checked')){
                jQuery('#secondary_tax_tr').removeAttr('style');
                }else{
                jQuery('#secondary_tax_tr').css('display','none');}
            }
            displayDiscount();
            check_amount();
//            check_calculations();

           if (jQuery("#tne_invoice_matter_id").val() != "" ) {
               display_data();
           }


        }
        }
});

function displayDiscount()
{
      if(jQuery('#apply_final_discount').is(':checked')){
        jQuery('#discount_tr').removeAttr('style');
      }else{
        jQuery('#discount_tr').css('display','none');
      }
}

function displayPrimarySecondaryName(){
    var primary_tax_rate    =   jQuery('#tne_invoice_primary_tax_rate');
    var primary_tax_name    =   jQuery('#tne_invoice_primary_tax_name');
    var secondary_tax_rate  =   jQuery('#tne_invoice_secondary_tax_rate');
    var secondary_tax_name    =   jQuery('#tne_invoice_secondary_tax_name');
    if(primary_tax_name.val()==""){
        jQuery('#p_tax').html('Primary Tax ' +"("+primary_tax_rate.val()+" %)");
    }else{
        jQuery('#p_tax').html(primary_tax_name.val() + ' ' +"("+primary_tax_rate.val()+" %)");
    }
    if(jQuery('#apply_secondary_tax').length==0){}else{
        if(secondary_tax_name.val()==""){
            jQuery('#s_tax').html('Secondary Tax ' +"("+secondary_tax_rate.val()+" %)");
        }else{
            jQuery('#s_tax').html(secondary_tax_name.val()+ ' ' +"("+secondary_tax_rate.val()+" %)");
        }
    }
    if(jQuery("#apply_primary_tax").attr("checked")){
        if(primary_tax_name.val()==""){
            jQuery('#header_p_tax').html('Primary Tax ' +'<br/>' +"("+primary_tax_rate.val()+"%)");
        }else{
            jQuery('#header_p_tax').html(primary_tax_name.val()  +'<br/>'+"("+primary_tax_rate.val()+"%)");
        }
         jQuery('#apply_primary_tax_checked').val('true');
         jQuery('#primary_tax_tr').removeAttr('style');
    }else{

        jQuery('#apply_primary_tax_checked').val('false');
        jQuery('#primary_tax_tr').css('display','none');
        jQuery('#header_p_tax').html('Primary Tax ' +'<br/>'+"("+primary_tax_rate.val()+"%)");
        jQuery('#p_tax').html('Primary Tax ' +"("+primary_tax_rate.val()+" %)");
    }
    checkPrimaryTax();
    checkcalulated_tax_with_only_primary();
    if(jQuery('#apply_secondary_tax').length==0){}else{
        if(jQuery("#apply_secondary_tax").attr("checked")){
            if(secondary_tax_name.val()==""){
                jQuery('#header_s_tax').html('Secondary Tax' +'<br/>'  +"("+secondary_tax_rate.val()+"%)");
            }else{
                jQuery('#header_s_tax').html(secondary_tax_name.val() +'<br/>' +"("+secondary_tax_rate.val()+"%)");
            }
            jQuery('#apply_secondary_tax_checked').val('true');
            jQuery('#secondary_tax_tr').removeAttr('style');
        }else{
            jQuery('#secondary_tax_tr').css('display','none');
            jQuery('#apply_secondary_tax_checked').val('false');
            jQuery('#header_s_tax').html('Secondary Tax '+'<br/>' +"("+secondary_tax_rate.val()+"%)");
            jQuery('#s_tax').html('Secondary Tax' +"("+secondary_tax_rate.val()+" %)");
        }
    }
    checkSecondaryTax();
}

function checkSecondaryTax(){
    var view = jQuery("#tne_invoice_view_by").val();
  var secondary_checkboxes = jQuery(".s_tax");
  secondary_checkboxes.each(function(){
    var s_id = jQuery(this).next().attr("id").split("_")[4];
    if(jQuery("#apply_secondary_tax").attr("checked")){
      if(this.checked){
        if(view=="Summary"){
          jQuery(".time_entry_s_tax").each(function(i,e){
            if(jQuery(e).parent().hasClass("tne_s_tax_"+s_id)){
              jQuery(e).attr("checked", true);
              jQuery(e).attr("disabled", true);
              jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
              jQuery(e).next().next().val(true);
            }
          });
        }else{
          jQuery(".time_entry_s_tax").each(function(i,e){
            if(jQuery(e).parent().hasClass("tne_s_tax_"+s_id)){
              jQuery(e).removeAttr("disabled");}
          });
        }
      }else{
        if(view=="Summary"){
          jQuery(this).removeAttr("disabled");
          jQuery(".time_entry_s_tax").each(function(i,e){
            jQuery(e).removeAttr("checked");
            jQuery(e).removeAttr("disabled");
            jQuery(e).attr("disabled", true);
            jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
            jQuery(e).next().next().val(false);
          });
        }else{
          jQuery(this).removeAttr("disabled");
          jQuery(".time_entry_s_tax").each(function(i,e){
            jQuery(e).removeAttr("disabled");
          });
        }
      }
    }else{
      jQuery(this).removeAttr("checked");
      jQuery(this).attr("disabled", true);
      jQuery(".time_entry_s_tax").each(function(i,e){
        jQuery(e).removeAttr("checked", false);
        jQuery(e).attr("disabled", true);
        jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
        jQuery(e).next().next().val(false);
      });
    }
  });
}

function confirm_bill_changes(){
time_entry_rows=eval(jQuery('#time_entry_rows').val());
expene_entry_rows=eval(jQuery('#expene_entry_rows').val());
inv_details=jQuery('#tne_invoice_view_by').val();

var tax_related = "";

if ( jQuery("#apply_primary_tax").attr("checked") || jQuery("#apply_secondary_tax").attr("checked") ) {
    tax_related = " tax related";
}

  if((time_entry_rows+expene_entry_rows) > 0) {
      
      var conf_message="";
      if(inv_details=="Detailed") {
        conf_message="The" + tax_related + " fields will get reset to default value.";
      } else {
        conf_message="The" + tax_related + " fields will get reset to default value and summary details will be deleted.";
      }


       var bill_changes = confirm(conf_message);
        if(bill_changes){
          return true;
        }
        else
        {
          return false;
        }
  }
    return true;
 }

 function saveExpense(db_rows,invoice_id,consolidated_by,regenerate){
    var matter_id = jQuery('#tne_invoice_matter_id').val();
    var contact_id= jQuery('#tne_invoice_contact_id').val();
    jQuery("input#matter_id").val(matter_id);
    jQuery("input#contact_id").val(contact_id);
     add_new_expense_entry(db_rows,matter_id,invoice_id,contact_id,consolidated_by,regenerate);
  }


function calculateChangesPrimaryTax(tax_entry_group, entry_type, ptax) {
    var total = 0;
    jQuery(tax_entry_group + ":checked").each(function(i,e){
        jQuery(e).removeAttr("disabled");
        var chek = jQuery(e);
        var amt;
        var field = jQuery(e).parent().next();
        if (jQuery('#apply_secondary_tax').length > 0) {
            field = field.next();
        }
        if(entry_type == "expense"){
            amt = parseFloat(field.children().children().html().replace(/\,/g,''))
        }else{
            amt = parseFloat(field.children().children().children().html().replace(/\,/g,''));
        }
        var tax = floatToTwoDecimalPlaces(parseFloat((parseFloat(amt*ptax)/100)));
        jQuery(e).next().val(tax);

        if(chek.attr("checked")){
            total += tax;
        }
    });
    return total;
}

function calculateChangesSecondaryTax(tax_entry_group,entry_type,stax,secondary_tax_rule,ptax) {
    var stax_total = 0;
    jQuery(tax_entry_group + ":checked").each(function(i,e){     
        var chek = jQuery(e);
        var amt = 0;
        if(entry_type == "expense"){
            amt = parseFloat(jQuery(e).parent().next().children().children().html().replace(/\,/g,''));
        }else{
            amt = parseFloat(jQuery(e).parent().next().children().children().children().html().replace(/\,/g,''));
        }
        var s_tax;
        if(secondary_tax_rule==0){
            s_tax = floatToTwoDecimalPlaces(parseFloat(((amt * stax)/100)));
        }else{
            var p_tax_amount= chek.parent().prev().children().first();
            if(p_tax_amount.attr("checked") && p_tax_amount.hasClass(entry_type)){
                amt = parseFloat(amt) +  floatToTwoDecimalPlaces(parseFloat(((amt*ptax)/100)));
            }
            s_tax = floatToTwoDecimalPlaces(parseFloat(((amt * stax)/100)));
        }
        jQuery(e).next().val(s_tax);
        if(chek.attr("checked")){
            stax_total += s_tax;
        }        
    });
    
    return stax_total;
}


function CalculateSummarySecondaryTax(s_entryid,staxrate,entry_type,secondary_tax_rule){
    var total= 0;
    var hiddenfield = entry_type+"_hidden_amount_"+s_entryid;
    var tne_amount = parseFloat(jQuery("#"+hiddenfield).val());
    if(secondary_tax_rule==0){
        total = floatToTwoDecimalPlaces(parseFloat(((tne_amount * staxrate)/100)));
    }else{
        var tne_amount_ptax = tne_amount
        if(jQuery("#"+entry_type+"_header_ptax_hidden_"+s_entryid).prev().attr("checked")){
            tne_amount_ptax = tne_amount + parseFloat(jQuery("#"+entry_type+"_header_ptax_hidden_"+s_entryid).val());
        }
        total = floatToTwoDecimalPlaces(parseFloat(((tne_amount_ptax * staxrate)/100)));
    }
    return total;
}

function CalculateSummaryPrimaryTax(entryid, taxrate, entry_type) {
    var total = 0;
    var hiddenfield = entry_type + "_hidden_amount_" + entryid;
    var tne_amount = parseFloat(jQuery("#"+hiddenfield).val());
    total = floatToTwoDecimalPlaces(parseFloat(((tne_amount * taxrate) / 100)));
    return total;
}

function checkPrimaryTax(){
    var view = jQuery("#tne_invoice_view_by").val();
  var primary_checkboxes = jQuery(".p_tax");
  primary_checkboxes.each(function(){
    var p_id = jQuery(this).next().attr("id").split("_")[4];
    if(jQuery("#apply_primary_tax").attr("checked")){
      if(this.checked){
        if(view=="Summary"){
          jQuery(".time_entry_p_tax").each(function(i,e){
            if(jQuery(e).parent().hasClass("tne_p_tax_"+p_id)){
              jQuery(e).attr("checked", true);
              jQuery(e).attr("disabled", true);
              jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
              jQuery(e).next().next().val(true);
            }
          });
        }else{
          jQuery(".time_entry_p_tax").each(function(i,e){
            if(jQuery(e).parent().hasClass("tne_p_tax_"+p_id)){
              jQuery(e).removeAttr("disabled");}
          });
        }
      }else{
        if(view=="Summary"){
          jQuery(this).removeAttr("disabled");
          jQuery(".time_entry_p_tax").each(function(i,e){
            jQuery(e).removeAttr("checked");
            jQuery(e).removeAttr("disabled");
            jQuery(e).attr("disabled", true);
            jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
            jQuery(e).next().next().val(false);
          });
        }else{
          jQuery(this).removeAttr("disabled");
          jQuery(".time_entry_p_tax").each(function(i,e){
            jQuery(e).removeAttr("disabled");
          });
        }
      }
    }else{
      jQuery(this).removeAttr("checked");
      jQuery(this).attr("disabled", true);
      jQuery(".time_entry_p_tax").each(function(i,e){
        jQuery(e).removeAttr("checked", false);
        jQuery(e).attr("disabled", true);
        jQuery(e).next().next().attr("name", jQuery(e).attr("name"));
        jQuery(e).next().next().val(false);
      });
    }
  });
}

function floatToTwoDecimalPlaces(number){
 var num = number.toString().split(".")[0];
 var dec =  number.toString().split(".")[1];
    if(dec == undefined){
    number=  parseFloat(num +".00");
    return number;
    }
   var decimals = dec.split("");
    if (decimals.length < 3){
    return number;
    }
    if (parseInt(decimals[2]) >= 5){
      dec = (parseInt(decimals[0] + decimals[1])) +1 ;
      if (dec == 100){
        num = parseInt(num) + 1;
        dec = "00"
      }
    }else{
      dec = decimals[0] + decimals[1];
    }
   number =parseFloat(num.toString() + "." + dec.toString());
   return number;
}


function displayMatterNo(matter_id){
  if (matter_id != ""){
    jQuery.ajax({
      type: 'get',
      url: '/tne_invoices/get_matter_no',
      data: {
        matter_id : matter_id
      },
      dataType: "text",
      beforeSend: function(){
        loader.prependTo('#display_loader');
        jQuery('body').css("cursor", "wait");
      },
      complete: function(){
        jQuery('body').css("cursor", "default");
        loader.remove();
      },
      success: function(transport)
      {
        jQuery("#label_matter_no").show();
        jQuery("#bill_matter_name_id").html(transport);
      }
    });
  }else{
    jQuery("#label_matter_no").hide();
    jQuery("#bill_matter_name_id").html('');
  }
}

function checkDiscount(){
  var discount_val, amt_val, discount;
  discount = jQuery("#tne_invoice_discount");
  discount_val = discount.val();

  if(isNaN(discount_val) == true){
    alert("Please enter numeric value");
    discount.val('0.00');
    return;
  }
  amt_val = jQuery("#tne_invoice_invoice_amt").val();
  amt_val = parseFloat(amt_val.replace(",", ""));
  
  discount_val = parseFloat(discount_val.replace(",", ""));

  if (discount_val > amt_val) {
    alert("Discount value can not be more than the total amount.");
    discount.val('0.00');
  } else if (discount_val < 0) {
    alert("Discount value can not be negative.");
    discount.val('0.00');
  }

  check_calculations();
}