var loader = jQuery("<center><img src='/images/loading.gif' /></center>");

jQuery(document).ready(function(){
  MatterCalendarTooltipAP();
  if(jQuery(".icon_tultip").length != 0){
    jQuery(".icon_tultip").click(function(e){
      jQuery('.tooltip').fadeOut(100);
      var div = jQuery(this).next();
      var div_width = jQuery(this).children('b').width();
      div.css({
        "left": div_width +"px",
        "top" : "10px",
        "position": "absolute",
        "z-index" : "999999"
      });
      div.fadeIn(300);
      e.stopPropagation();
    });
  }

  jQuery('.tooltip').bind("mouseleave", function(){
    setTimeout(function(){
      jQuery('.tooltip').fadeOut(100);
    },500);
  });

  jQuery('.body_container').click(function(){
    jQuery('.tooltip').fadeOut(100);
  });
});

function matter_focus_out(){
  var matter_ids = jQuery('#mattersselect select').val();
  jQuery("#loading_imagediv").show();
  jQuery.ajax({
    type: 'GET',
    url: '/calendars/search_matter_people',
    data:{
      'matters[]' : matter_ids,
      'mode_type' : 'matter'
    },
    success: function(){
      jQuery("#loading_imagediv").hide();
      jQuery("#peopletoggle").attr({
        "src": "/images/icon_small_minus.png",
        "alt": "Icon_small_minus"
      });
    }
  });
}

function people_matter_focus_out(){
  var people_ids = jQuery('#peopleselect select').val();
  jQuery("#loading_imagediv").show();
  jQuery.ajax({
    type: 'GET',
    url: '/calendars/search_matter_people',
    data:{
      'people[]' : people_ids,
      'mode_type' : 'people'
    },
    success: function(){
      jQuery("#loading_imagediv").hide();
      jQuery("#mattertoggle").attr({
        "src": "/images/icon_small_minus.png",
        "alt": "Icon_small_minus"
      });
    }
  });
}

//function show_date_range(id) - Removed
function MatterCalendarTooltipAP(){
  if(jQuery(".icon_caltool").length != 0){
    jQuery(".icon_caltool").hover(function(){
      var div = jQuery(this).next();
      var div_width = jQuery(this).children('b').width();
      var div_height = div.height();
      div.css({
        "margin-left": div_width +"px",
        "margin-top": "-" + div_height/2 + "px",
        "position": "absolute",
        "z-index" : "999999"
      });
      div.fadeIn(300);
      jQuery(this).parent('div').css({
        "border-color": "#2C2B2B",
        "z-index" : "9999"
      });
    },
    function(){
      jQuery('.tooltip').fadeOut(100);
      jQuery(this).parent('div').css({
        "border-color": "#029051",
        "z-index" : ""
      });
    })
  }
}

// function mark_as_completed_thickbox_path(id, matter, mattertask) - Removed.
// function AppointmentBox() - Removed.
function change_styling(input, dy, mnth){
  var basewidth = jQuery('.styling').width();
  if(jQuery(input).text() == "More"){
    jQuery(".morelink").text("More");
    jQuery(input).text("Close");
    jQuery(".showdiv").hide();
    jQuery('.styling').css({
      "border":"1px solid #404755",
      "background-color":"trasparent",
      "width": basewidth,
      "height": "auto",
      "position":"none",
      "margin-left":"0",
      "padding":"1px",
      "margin-top":"3px",
      "z-index": ""
    });
    jQuery('#styling'+dy+mnth+' .showdiv').show();
    jQuery('#styling'+dy+mnth).css({
      "border":"3px solid #ccc",
      "background":"#fff",
      "width":"200px",
      "position":"absolute",
      "height" : "auto",
      "z-index": "999"
    });
  }else{
    jQuery(input).text("More");
    jQuery('.showdiv').hide();
    jQuery('#styling'+dy+mnth).css({
      "border":"1px solid #404755",
      "background-color":"trasparent",
      "width": basewidth,
      "position":"none",
      "height": "auto",
      "margin-left":"0",
      "padding":"1px",
      "margin-top":"3px",
      "z-index": ""
    });
  }
}

function list_view_change(a){
  var link = jQuery(a);
  var selecttag;
  var image = jQuery(a).children();

  if(image.attr("id") == "mattertoggle"){
    selecttag = link.prev();
  }else{
    selecttag = link.prev("span").children("select");
  }

  if(image.attr("alt") == "Icon_small_minus"){
    image.attr({
      "src": "/images/icon_small_plus.png",
      "alt": "Icon_small_plus"
    });

    selecttag.removeAttr("multiple");
    selecttag.removeAttr("size");

    if(image.attr("id") == "peopletoggle"){
      jQuery("#oppeople").val(true);
    }else{
      jQuery("#opmtr").val(true);
    }
    if(selecttag.children("option[value='']").length == 0){
      selecttag.children("option:first").before("<option value=''>Please Select</option>");
    }
  }else{
    image.attr({
      "src": "/images/icon_small_minus.png",
      "alt": "Icon_small_minus"
    });

    selecttag.attr({
      "multiple":"multiple",
      "size":5
    });

    if(image.attr("id") == "peopletoggle"){
      jQuery("#oppeople").val(false);
    }else{
      jQuery("#opmtr").val(false);
    }

    if(selecttag.children("option[value='']").length > 0){
      selecttag.children("option[value='']").remove();
    }
  }
}

function uncheck_the_checkbox(id){
  jQuery("#mark_as_done"+id).removeAttr("checked");
}

//function search_for_selected() - Removed.
function validate_start_end_date(input){
  var enddate = new Date(jQuery("#end_date").val());
  var startdate = new Date(jQuery("#start_date").val());
  if(enddate != "" && startdate != ""){
    if(enddate < startdate){
      alert("End Date should be greater than Start Date");
      input.value = ""
    }
  }
}

function update_view(action){    
  window.location.href = action;
}

function editSeriesInstance(name, link){   
  jQuery.ajax({
    type: 'GET',
    url: link,
    beforeSend: function(){
      jQuery('#loader1').show();
    },
    success: function(transport){
      jQuery('#TB_ajaxWindowTitle').text(name);
      jQuery('#TB_window').css({
        "width":850,
        "height":390,
        "margin-left":"-425px",
        "margin-top":"-200px"
      });
      jQuery('#TB_ajaxContent').css({
        "width":800,
        "height":390,
        "overflow":"auto"
      });
      jQuery('#activityForm').html(transport);
      jQuery('#loader1').hide();
    }
  });
}

function deleteSeriesInstance(name, link, request_type){
  jQuery.ajax({
    type: request_type,
    url: link,
    beforeSend: function(){
      jQuery('#loader1').show();
    },
    success: function(){
      jQuery('#loader1').hide();
      window.location.reload();
    }
  });
}

function thickboxInstance(link){
  tb_show('Open Recurring Item', link, '');
}

function check_matterssel(action){    
  if(action == "calendar_by_people"){
    var people = jQuery('#peopleselect select').val();
    if(people == null){
      jQuery("#mttrsel").val(true);
    }else{
      jQuery("#mttrsel").val(false);
    }
  }else{
    var matters = jQuery('#mattersselect select').val();
    if(matters == null){
      jQuery("#mttrsel").val(true);
    }else{
      jQuery("#mttrsel").val(false);
    }
  }
}

//function toggle_image_div(link, appid) - Removed.
function set_display_of_searchbox(link){
  jQuery('#search_optionsdiv').show();
  jQuery('#opsearch').val(true);
  jQuery(link).hide();
}