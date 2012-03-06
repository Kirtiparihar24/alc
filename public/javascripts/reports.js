jQuery.noConflict();

function get_matters_contact(){
  var matter_id = jQuery('#report_matter_id').val();
  var contact_id = jQuery('#report_contact_id').val();
  if (matter_id == "" || contact_id == ""){ 
    jQuery.ajax({
      type: 'GET',
      url: '/rpt_time_and_expenses/get_new_matters_contact',
      data: {
        'matter_id' : matter_id,
        'contact_id' : contact_id
      },
      dataType: 'script'
    });
  }
}

function get_all_matters(){
  var contact_id = jQuery('#report_contact_id').val();
  var matter_id = jQuery('#report_matter_id').val();
  jQuery('#matter_head')[ (contact_id != '')  ? 'show' : 'hide' ]()
  jQuery('#matter_content')[ (contact_id != '') ? 'show' : 'hide' ]()
  jQuery.ajax({
    type: 'GET',
    url: '/rpt_time_and_expenses/get_all_new_matters',
    data: {
      'contact_id' : contact_id,
      'matter_id' : matter_id
    },
    dataType: 'script'
  });
}

function date_change(){
  if (jQuery("#report_duration").val() == '5' || jQuery("#report_duration").val() == 'range'){
    jQuery("#date_selected").attr("checked", "checked");
    jQuery('#date_div').show();
  }else{
    jQuery("#date_selected").attr("checked", "");
    jQuery('#date_div').hide();
  }
}

// First Verify - Not Used
function matter_date_change(){
  if (jQuery("#report_duration").val() == 'range'){
    jQuery("#date_selected").attr("checked", "checked");
    jQuery('#date_div').show();
  }else{
    jQuery("#date_selected").attr("checked", "");
    jQuery('#date_div').hide();
  }
}

function get_contact(){
  jQuery('#report_selected').change(function(){
    jQuery('#contact_name')[ (jQuery(this).val() == 'contact')  ? 'show' : 'hide' ]()
    jQuery('#contacts_content')[ (jQuery(this).val() == 'contact') ? 'show' : 'hide' ]()
    jQuery('#matter_head')[ (jQuery(this).val() == 'matter')  ? 'show' : 'hide' ]()
    jQuery('#matter_content')[ (jQuery(this).val() == 'matter') ? 'show' : 'hide' ]()

    if(jQuery(this).val() == 'contact'){
      jQuery.ajax({
        type: 'GET',
        url: '/rpt_time_and_expenses/get_contacts',
        dataType: 'script'
      });
    }
    if(jQuery(this).val() == 'matter'){
      jQuery.ajax({
        type: 'GET',
        url: '/rpt_time_and_expenses/get_matters',
        dataType: 'script'
      });
    }
  });
}

// function show_date_div() : removed : duplicate
function validate_report_date(){
  if (jQuery('#date_selected').attr('checked')){
    start_date = jQuery("input#date_start").val();
    end_date = jQuery("input#date_end").val();
    if(start_date != "" && end_date != ""){
      if(Date.parse(start_date) > Date.parse(end_date)){
        alert("End Date should be greater than Start Date");
        jQuery("#report-info").hide();
        jQuery("#report-content").hide();
        return false;
      }
    }else{
      alert("Please Specify Both the dates")
      jQuery("#report-info").hide();
      jQuery("#report-content").hide();
      return false;
    }
  }else{
    jQuery("input#date_start").val('');
    jQuery("input#date_end").val('');    
  }
  checkloader();
  jQuery("#report-info").show();
  jQuery("#report-content").show();
  return true;  
}

function validate_report_name(){    
  var rptname=jQuery('#report_favourite_report_name').val();
  if (rptname == ""){
    jQuery('#nameerror').html("<div class='message_error_div'>Please specify Report name</div>").fadeIn('slow')
    .animate({
      opacity: 1.0
    }, 8000)
    .fadeOut('slow')
    loader.remove();
    return false;
    jQuery('#nameerror').show();
    return false;
  }else{
    return true;
  }
}

jQuery(function(){
  jQuery('#report_duration').bind('change',function(){
    if (jQuery("#report_duration").val() == 'range'){
      jQuery("#date_selected").attr("checked", "checked");
      jQuery('#date_div').show();
    }else{
      jQuery("#date_selected").attr("checked", "");
      jQuery('#date_div').hide();
    }
  });

//  jQuery('.cancelbutton').click(function(){
//    history.back();
//    return false;
//  });
});