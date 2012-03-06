/* for communication contact select box*/
/* Below funication will returns matter specific contacts */
function get_matters_contact_select_box(index,comID){
  loader.appendTo('#loading')
  var matter_id, contact_id
  if (index == '' || index == 'undefined'){
    matter_id = jQuery('#com_notes_entries_matter_id').val();
    contact_id = jQuery('#com_notes_entries_contact_id').val();
  }else{
    matter_id = jQuery('#com_notes_entries_'+ index + '_matter_id').val();
    contact_id = jQuery('#com_notes_entries_'+ index + '_contact_id').val();
  }
  jQuery.ajax({
    type: 'GET',
    url: '/application/get_matters_contact',
    data: {
      'matter_id' : matter_id,
      'contact_id' : contact_id,
      'comID': comID,
      'formINDEX' : index
    },
    dataType: 'script',
    success: function(){
      loader.remove();
    }
  });
}

/* for communication contact select box*/
/* Below funication will get employee all matters/contact specific employee matters and updates contact */
function get_all_matters_select_box(index, comID){
  loader.appendTo('#loading')
  var matter_id, contact_id
  if (index == '' || index == 'undefined'){
    matter_id = jQuery('#com_notes_entries_matter_id').val();
    contact_id = jQuery('#com_notes_entries_contact_id').val();
  } else{
    matter_id = jQuery('#com_notes_entries_'+ index + '_matter_id').val();
    contact_id = jQuery('#com_notes_entries_'+ index + '_contact_id').val();
  }
  jQuery.ajax({
    type: 'GET',
    url: '/application/get_new_matters',
    data: {
      'matter_id' : matter_id,
      'contact_id' : contact_id,
      'comID': comID,
      'formINDEX' : index
    },
    dataType: 'script',
    success: function(){
      loader.remove();
    }
  });
}

function getMattersContacts(index, mtrSpanId, cntSpanId, mtrId, cntId){
  loader.appendTo('#loading');
  jQuery.ajax({
    type: 'GET',
    url: '/application/get_matters_contacts',
    data: {
      'matter_id' : mtrId,
      'contact_id' : cntId,
      'formINDEX' : index ,
      'mtr_span_id' : mtrSpanId,
      'cnt_span_id' : cntSpanId
    },
    dataType: 'script',
    success: function(){
      loader.remove();
    }
  });
}


/// for autocomplete search in communication
function getCommMattersContacts(index,mtrSpanId,cntSpanId,value,mtrId,cntId){
 var img_drop ="";
  loader.appendTo('#loading');
    if (mtrId ==""){
    jQuery('#matter_cnt_'+index).val();
    jQuery("#contact_cnt_"+index).val(value);
  }
  else{
       if(cntId==""){
        img_drop ="drop";
       }
      jQuery('#matter_cnt_'+index).val(value);
  }
    jQuery.ajax({
    type: 'GET',
    url: '/communications/search_matters_contacts',
    data: {'matter_id' : mtrId, 'contact_id' : cntId,'formINDEX' : index ,'mtr_span_id' : mtrSpanId,'cnt_span_id' : cntSpanId,'img_drop' :img_drop,'value' :value},
    dataType: 'script',
        complete: function(data){
        jQuery(".all_matter_input").unautocomplete();
        jQuery(".all_contact_input").unautocomplete();
        SearchAutocomplete();
            loader.remove();
        }
   });
   
 
}
