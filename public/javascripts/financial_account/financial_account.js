jQuery(function(){
    jQuery('.trust_number').live('keypress',function(e){
        var key =null;
        if (e.charCode == undefined){
            key = e.keyCode;
        }else{
            key = e.charCode;
        }

        var str     = e.target.value.toString();
        var match = /\./.test(str);
        var maxLength = e.target.getAttribute('maxlength');
        if(key != 46 && key !=0 && (key < 48 || key > 57)){
            e.preventDefault();
        }else{
            try{
                var inputAmount = parseFloat(e.target.value);
                if(isNaN(inputAmount)){
                    e.target.value='';
                }else{

            }
            }catch(exception){
                alert(exception);
                e.target.value='';
            }
        }
    }) ;
    livia_datepicker(null);
    showHideAdvanceButton();
});

jQuery(function(){
    jQuery('.financial_account_type').change(function(e){
        var lvalue = e.target.options[this.selectedIndex].getAttribute('lvalue');
        if(lvalue == 'linked to matter'){
            jQuery('#matter_search_div').show();
            jQuery('#financial_account_matter_sphinx_search').show();
            jQuery('#financial_account_account_sphinx_search').val("");
            jQuery('#financial_account_account_id').val("");
            jQuery('#matter_search_div').html("")
            jQuery('#account_search_div').hide();
        }else if(lvalue == 'linked to account'){
            jQuery('#matter_search_div').hide();
            jQuery('#financial_account_matter_id').val("");
            jQuery('#account_search_div').show();
        } else{
            jQuery('#matter_search_div').hide();
            jQuery('#account_search_div').hide();
            jQuery('#financial_account_account_id').val('');
            jQuery('#financial_account_matter_id').val('');
        }
    });
    jQuery("#financial_account_matter_sphinx_search").autocomplete(
        "/financial_accounts/search", {
            width: 'auto',
            extraParams :{
                searchable_type : 'Matter'
            },
            formatResult: function(data, value) {
                return value.split("</span>")[1];
            }
        }).flushCache();

    jQuery("#financial_account_matter_sphinx_search").result(function(event, data, formatted) {
        var idName = event.target.className.split(' ')[0];
        var matterID = data.toString().split('"display: none;">')[1];
        var matterID = matterID.toString().split('</span>')[0];
        jQuery('#'+idName +'_matter_id').val(matterID);
        var resultSpanElem = jQuery('#'+matterID);
        if(resultSpanElem.attr('account_id') !=null){
            jQuery('#'+idName +'_account_id').val(resultSpanElem.attr('account_id'));
            jQuery("#financial_account_account_sphinx_search").val(resultSpanElem.attr('account_name'))
        }
        jQuery('#account_search_div').show();
        if(jQuery('#invoice').attr('checked')){
            invoicesNums(matterID);
        }
    });

    jQuery("#financial_account_account_sphinx_search").change(function(e){        
       if (jQuery("#financial_account_account_sphinx_search").val() == ''){           
           jQuery("#financial_transaction_account_id").val('');
           e.preventDefault();
       }
    });

    jQuery("#financial_account_matter_sphinx_search").change(function(e){
       if (jQuery("#financial_account_matter_sphinx_search").val() == ''){
           jQuery("#financial_transaction_matter_id").val('');
           e.preventDefault();
       }
    });

    jQuery("#financial_account_account_sphinx_search").change(function(e){
       if (jQuery("#financial_account_account_sphinx_search").val() == ''){
           jQuery("#financial_account_account_id").val('');
           e.preventDefault();
       }
    });

    jQuery("#financial_account_matter_sphinx_search").change(function(e){
       if (jQuery("#financial_account_matter_sphinx_search").val() == ''){
           jQuery("#financial_account_matter_id").val('');
           e.preventDefault();
       }
    });

     
    jQuery("#financial_account_account_sphinx_search").autocomplete(
        "/financial_accounts/search", {
            width: 'auto',
            extraParams :{
                searchable_type : 'Account'
            },
            formatResult: function(data, value) {
                return value.split("</span>")[1];
            }
        }).flushCache();
    jQuery("#financial_account_account_sphinx_search").result(function(event, data, formatted) {
        var accountID = data.toString().split('"display: none;">')[1];
        var accountID = accountID.toString().split('</span>')[0];
        var idName = event.target.className.split(' ')[0];
        jQuery('#'+idName +'_account_id').val(accountID);
        if(jQuery('#financial_account_financial_account_type_id').length > 0 && jQuery('#financial_account_financial_account_type_id option:selected').text() == 'linked to account'){
            jQuery('#financial_account_matter_sphinx_search').val('');
            jQuery('#financial_account_matter_id').val('');
            jQuery('#matter_search_div').hide();
            return;
        }
        jQuery.ajax({
            beforeSend: function(){
                jQuery('body').css("cursor", "wait");
            },
            type: "GET",
            url: "/financial_accounts/matters",
            dataType: 'script',
            data: {
                'account_id' : accountID
            },
            complete: function(){
                jQuery('body').css("cursor", "default");
            },
            success: function()
            {
                jQuery('#matter_search_div').show();
                    jQuery('#'+idName +'_matter_id').val(jQuery('#matter_id option:first-child').val());
                loader.remove();
            }
        });

    });

    jQuery('#matter_id').live('change',function(e){
        jQuery('#financial_transaction_matter_id').val(jQuery('#matter_id option:selected').val());
        jQuery('#financial_account_matter_id').val(jQuery('#matter_id option:selected').val());
        e.preventDefault();
    });


    jQuery('.select_invoice').live('change',function(e){
        matterID = jQuery('#financial_transaction_matter_id').val();
        if(e.target.id =='financial_transaction_approval_status_id'){
            if(e.target.options[this.selectedIndex].text == 'Not Needed'){
                jQuery('#approved_by').hide();
                jQuery("#approved_by_list").html("");
            }else{
                if(matterID == ""){
                    e.target.selectedIndex=0;
                }else{
                    jQuery.ajax({
                        type: "GET",
                        url: "/financial_transactions/invoice_or_contacts/" + matterID,
                        dataType: 'script',
                        success: function(transport)
                        {
                            jQuery("#approved_by_list").html(transport);
                            jQuery('#approved_by').show();
                        }

                    });
                }
            }
        }else if(e.target.id == 'invoice'){
            if(!e.target.checked){
                jQuery("#invoice_no_list_box").html('');
                jQuery('.invoice_no').hide();
                jQuery('#amount_to_paid_span').hide();
//                jQuery('#financial_transaction_amount').attr('readonly','');
                return;
            }
            if(jQuery('#financial_transaction_matter_id').val()==''){
                alert('Please select Matter');
                e.target.checked = false;
                jQuery("#invoice_no_list_box").html('');
                jQuery('.invoice_no').hide();
                jQuery('#amount_to_paid_span').hide();
                return;
            }else{
                if(matterID == ""){
                    alert('please select matter');
                    return;
                }
                invoicesNums(matterID);
            }
        }
    });
    jQuery('#financial_account_invoice_no').live('change',function(e){
        jQuery('#invoice_billed_amount').html(e.target.options[this.selectedIndex].getAttribute('billed_amt'));
        jQuery('#invoice_paid_amount').html(e.target.options[this.selectedIndex].getAttribute('paid_amt'));
        payingElem = jQuery('#amount_to_paid');
        payingElem.html(e.target.options[this.selectedIndex].getAttribute('balance'));
        jQuery('#amount_to_paid_span').show();
//        payingElem.attr('readonly',true);
    });
    jQuery('#financial_account_debited_no').live('change',function(e){
       jQuery('#remaining_amount').html(e.target.options[this.selectedIndex].getAttribute('available_amount'));
    });
});

function invoicesNums(matterID){
    jQuery.ajax({
        type: "GET",
        url: "/financial_transactions/invoice_or_contacts/" + matterID,
        dataType: 'script',
        data:{
            'type' : 'invoice'
        },
        success: function(transport)
        {
            if(transport.length <= 0){
                alert('There is no  Invoices for selected matter');
                jQuery("#invoice_no_list_box").html('');
                jQuery('.invoice_no').hide();
                e.target.checked = false;
            }else{
                selectListArr = transport.split('bre');
                jQuery("#invoice_no_list_box").html(selectListArr[0]);
                jQuery('#invoice_billed_amount').html(selectListArr[1]);
                jQuery('#invoice_paid_amount').html(selectListArr[2]);
                amountElem = jQuery('#amount_to_paid');
                amountElem.html(selectListArr[3]);
                jQuery('#amount_to_paid_span').show();
                jQuery('.invoice_no').show();
            }
        }

    });
}

function showHideAdvanceButton(){
    jQuery('.advance_filter').live('click',function(e){
        jQuery('.display_none').hide();
        jQuery('#advanced_filter').html('');
    })
}