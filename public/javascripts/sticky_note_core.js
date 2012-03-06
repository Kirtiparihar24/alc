/* 
 name : core.js
 version : 0.1
 date : 03-08-2010
 Author : Sanil Naik
 References : railscast complex form part 1,2,3,http://www.quirksmode.org/js/cookies.html
    overview: On login it checks for current user's sticky note. If its nil it builds the one blank in the UI.
              See app/controller/application_controller
              Action- load_sticky_notes
              For sticky textarea onchange event is used to assign onblur events this removes
              the problem of blank create and reduces unnecessary ajax calls
              See public/javascripts/sticky_notes/core.js
              function - setBlurActions()
              All ajax requests are restful.
              See sticky_notes_controller
 */
/// PLEASE READ THE COMMENTS BEFORE MANIPULATING THE CODE. SiLlY MiStAkEs MIGHT BREAK THE FUNCTIONALITY :-E

var xhr;
jQuery(document).ready(function(){
  if(typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
      return this.replace(/^\s+|\s+$/g, '');
    }
  }
  stickyInit();
  jQuery("#sticky").draggable({
    containment: "document",
    scroll: false
  });

  if (jQuery('.sticky_text_old').length > 0){
    jQuery('#add_note').click();
  }

  jQuery('.thickbox').click(function(){
    setFlagForStickyNote(false);
  });
  // This will hide the sticky note while click on areas other than sticky note.------
  jQuery('body').click(function(){
    setFlagForStickyNote(false);
  });
  stop_propogation();
});

function stop_propogation(){    
  jQuery('#sticky, #sticky_notes_header_link,#sticky_notes_icon_link').click(function(event){
    event.stopPropagation();
  });
}

// This function creates a sticky Note.
// First validate the textarea if its not empty.
// If valid the make it readonly and makes a ajax call.
// see create.js.erb for ajax response updates
function createStickyNote(text_ar, count){
  if((jQuery(text_ar).val()=="" && jQuery(text_ar).hasClass("sticky_text_new"))){
    jQuery(text_ar).closest('td').prev('.time_stamp').hide();
  } else {
    jQuery(text_ar).attr("readonly","readonly");
    jQuery(text_ar).removeAttr("onBlur");
    txtVal=jQuery(text_ar).val();
    jQuery(text_ar).removeClass('sticky_text_new').addClass('sticky_text_old');
    jQuery("#note_count").html(jQuery('.sticky_text_old').length).show();
    jQuery("#td_action_"+count).html("<img src='/images/loading.gif' />").show();
    // makes a restful ajax request to save the sticky note
    jQuery.post('/sticky_notes',{
      "[sticky_note]description" : txtVal,
      tmp_note_id : count
    },function(data){
      vtip();
    },"script");
  }
}

// This Function updates the Sticky note. see - update.js.erb for ajax response updates
// It stores the ajax request to a variable.
// we can abort previous ajax request if the changes is on same record using xhr variable ie. xhr.abort();
function updateStickyNote(text_ar, note_id){
  var txtVal = jQuery(text_ar).val();
  jQuery(text_ar).removeAttr("onBlur");
  if(txtVal!=""){
    if(xhr && xhr.request_id==note_id) {
      // It calls ajax abort function if the update is on same textarea
      xhr.abort();
    }
    xhr = jQuery.post('/sticky_notes/'+note_id, {
      _method:'PUT',
      "[sticky_note]description" : txtVal
    } , function(data){},"script");
    xhr.request_id=note_id;
  }

}


// This function first deletes the sticky note from the DOM and then
// fires the restful ajax request to the controller to delete it from database
function deleteStickyNote(note_id){
  //---5times note building if all notes are deleted
  createNewByClick();
  jQuery.post('/sticky_notes/'+note_id, {
    _method:'DELETE'
  } , function(data){
    if(data == 'deleted'){
      jQuery("#sticky_table_"+note_id).remove(); //Dom element Removal
      jQuery("#styling_div_"+note_id).remove(); //Dom element Removal
      if (jQuery('.sticky_text_old').length>0){
        jQuery("#note_count").html(jQuery('.sticky_text_old').length); //updates the note count if the count is not zero
      }else {
        jQuery("#note_count").html('').hide();// if all notes are deleted it removes the updates the note count and hide the count icon
      }
    }else{
      alert(data);
      window.location.href ="/logout";
    }
  });
}

// this function initalizes time stamp td to open when focus on textarea.sets the keypress event to
// setfocus function and also apply textareaexpander to textarea
function stickyInit(){
  jQuery(".sticky_text_new").focus(function(){
    jQuery(this).closest('td').prev('.time_stamp').show()
  });
  jQuery(".sticky_text").keypress(function(event){
    return setFocus(this, event)
  });
  jQuery("textarea[class*=expand]").TextAreaExpander();
}

// This function traverses the focus from up to down.
// If the focus is on the last row and user presses enter it creates a new empty row
// This function also handles the on keypress newline(/n) problem
// Be Careful while modifying this function. Silly mistake might break the functionality . Have a code backup first
function setFocus(txt_area, event){
  keyCode = event.keyCode || event.which;
  if(keyCode == 13){
    if( jQuery(txt_area).val().trim()!=''){
      var next_table = jQuery(txt_area).closest('table').next().next();
      text_child = next_table.children().children().children().children('textarea.sticky_text');
      if (text_child.length == 0){
        // generates new row if its on the new line
        jQuery('#add_note').click();
        next_table = jQuery(txt_area).closest('table').next().next();
        text_child = next_table.children().children().children().children('textarea.sticky_text');
        jQuery(text_child).focus();
      } else  {
        jQuery(text_child).focus();
      }
      return false;
    } else {
      return false;
    }
  }
}

function initNewTextArea(){
  var len = jQuery('.sticky_text').length;
  var obj = jQuery('.sticky_text')[len-1];
  jQuery(obj).attr({
    'id' : 'text_area_'+len,
    'onChange' : 'setBlurActions(true,'+len+', this)'
  });
  jQuery(obj).closest('td').prev('.time_stamp').attr('id','time_stamp_'+len);
  jQuery(obj).closest('td').next('.td_action').attr('id','td_action_'+len);
  var styling_div = jQuery(".styling_div")[len-1];
  var sticky_table = jQuery(".sticky_table")[len-1];
  jQuery(styling_div).attr("id","styling_div_"+len);
  jQuery(sticky_table).attr("id","sticky_table_"+len);
  stickyInit();
}

// sets the blur action based on bln variable
// if its a new record set it to createStickyNote else updateStickyNote
function setBlurActions(bln,note_id, text_area){
  if(jQuery(text_area).val().trim()!=""){
    if(bln){
      jQuery(text_area).attr("onBlur","createStickyNote(this,"+note_id+")")
    } else {
      jQuery(text_area).attr("onBlur","updateStickyNote(this,"+note_id+")")
    }
  }
}

// Cookies are created to maintain the state of sticky note div whether its is opened or closed.
function setFlagForStickyNote(bln) {
  jQuery('.sticky_text_new').blur();
  bln ? jQuery('#sticky_div').slideDown('slow') : jQuery('#sticky_div').slideUp('slow');
}

// If the all the sticky notes are deleted . This function is used to create 5 new empty rows dynamically
function createNewByClick(){
  if(jQuery('.sticky_text').length==0){
    jQuery('#sticky_div').slideUp('slow');
    for(var i = 0 ; i <= 4; i++){
      jQuery('#add_note').click();
    }
  }
}

// Reference http://www.quirksmode.org/js/cookies.html
// Added by Sanil 10 Aug
// Helps manipulating the cookie
var Cookies = {
  init: function () {
    var allCookies = document.cookie.split('; ');
    for (var i=0;i<allCookies.length;i++) {
      var cookiePair = allCookies[i].split('=');
      this[cookiePair[0]] = cookiePair[1];
    }
  },
  create: function (name,value,days) {
    if (days) {
      var date = new Date();
      date.setTime(date.getTime()+(days*24*60*60*1000));
      var expires = "; expires="+date.toGMTString();
    } else {var expires = "";}
    document.cookie = name+"="+value+expires+"; path=/";
    this[name] = value;
  },
  erase: function (name) {
    this.create(name,'',-1);
    this[name] = undefined;
  }
};