jQuery(document).ready(function(){
  jQuery('#matter_task_list1').hide();
  jQuery('#matter_task_list2').hide();
  jQuery('#matter_task_list3').hide();
  jQuery('#matter_task_list4').hide();
  jQuery('#matter_task_list5').hide();

  jQuery('#linkToggle1').click(function(){
    jQuery('#matter_task_list1').slideToggle(500);
    return false;
  });

  jQuery('#linkToggle2').click(function(){
    jQuery('#matter_task_list2').slideToggle(500);
    return false;
  });

  jQuery('#linkToggle3').click(function(){
    jQuery('#matter_task_list3').slideToggle(500);
    return false;
  });

  jQuery('#linkToggle4').click(function(){
    jQuery('#matter_task_list4').slideToggle(500);
    return false;
  });

  jQuery('#linkToggle5').click(function(){
    jQuery('#matter_task_list5').slideToggle(500);
    return false;
  });

  vtip();

  //ActionPad
  ShowActionOnOver();
  jQuery(".hidden_action",this).hide(); // hide all
  //Due to this fade out file is not working because it work on body content
  jQuery(function(){
    LiviaTooltipAP();
  })

  jQuery('.body_container').click(function(){
    jQuery('.tooltip').fadeOut(100);
  });
});

function LiviaTooltipAP(){
  jQuery("td").delegate('.icon_action','click',function(e){
    jQuery('.tooltip').fadeOut(100);
    var div = jQuery(this).next();
    var div_height = div.height();
    div.css({
      "margin-left": "-340px",
      "margin-top": "-" + div_height/2 + "px",
      "position": "absolute"
    });
    div.fadeIn(300);
    e.stopPropagation();
  });
}

function calltooltip( title, link ){
  /* specially created for those links which are not showing tooltip by default adding class - currently using for 1st n last pagination links */
  jQuery('body').append( '<p id="vtip">' + title + '</p>' );
  linkoffset = link.offset();
  jQuery('p#vtip').css("top", (linkoffset.top+22)+"px").css("left", (linkoffset.left-8)+"px").fadeIn("fast");
  return false;
}

function hidetooltip(){
  jQuery("p#vtip").fadeOut("fast").remove();
  return false;
}

this.vtip = function(){
  this.xOffset = -12; // x distance from mouse
  this.yOffset = 20; // y distance from mouse
  jQuery(".vtip").unbind().hover(
    function(e){
      this.t = this.title;
      this.title = '';
      this.top = (e.pageY + yOffset);
      this.left = (e.pageX + xOffset);
      jQuery('body').append( '<p id="vtip">' + this.t + '</p>' );
      jQuery('p#vtip').css("top", this.top+"px").css("left", this.left+"px").fadeIn("fast");
    },
    function(){
      this.title = this.t;
      jQuery("p#vtip").fadeOut("fast").remove();
    }
    ).mousemove(
    function(e){
      this.top = (e.pageY + yOffset);
      this.left = (e.pageX + xOffset);			 
      jQuery("p#vtip").css("top", this.top+"px").css("left", this.left+"px");
    }).click(
    function(){
      jQuery("p#vtip").fadeOut("fast").remove();
    });
};

function ShowActionOnOver(){
  jQuery(".action_div").hover(function(){
    jQuery(".hidden_action",this).show();
  },
  function(){
    jQuery(".hidden_action",this).hide();
  });
}

function vertical_tabs_toggle(){
  var verttabs = jQuery("#verticaltabs > ul > li");
  verttabs.click(function(){
    verttabs.removeClass('selected');
    jQuery(this).addClass('selected');
    var ind = verttabs.index(jQuery(this));
    jQuery('#verticaltabs > div').hide().eq(ind).show();
  }).eq(0).click();
}

//function TimeExpenseTooltipAP() - Removed

function formatSequenceOnChange(){
  if(jQuery("#matter_id_flag").val()=="false"){
    jQuery("#matter_id").val("");
    var d = new Date();
    var curr_date = d.getDate();
    var curr_month =d.getMonth()+1;
    var curr_year = d.getFullYear();
    var current_month=curr_month.toString();
    var current_day=curr_date.toString();
    if(current_month.length == 1){
      current_month="0"+current_month;
    }

    if(current_day.length == 1){
      current_day="0"+current_day;
    }
    var current_year=curr_year.toString().substring(2,4);
    var current_date= current_month+"/"+current_day+"/"+current_year
    var numforamt="";
    var numSeperator=jQuery('#sequence_seperator_id').val();
    var company_sequence=jQuery('#sequence_no_used_id').val();
    var myselected_array=jQuery('#format_id').val().split(",");
    if( company_sequence != "" ){
      for(i=0;i<myselected_array.length;i++){
        if(myselected_array[i]=="N"){
          if(company_sequence.length==1){
            company_sequence="000"+company_sequence
          }
          if( company_sequence.length == 2 ){
            company_sequence="00"+company_sequence
          }
          if( company_sequence.length == 3 ){
            company_sequence="0"+company_sequence
          }
          numforamt=company_sequence+""+numSeperator;
          jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
        }
        if( myselected_array[i] == "AC" ){
          if( jQuery("#_accconname").val() != "" ){
            numforamt=jQuery("#_accconname").val()+""+numSeperator;
            jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
          }
        }
        if( myselected_array[i] == "CY" ){
          numforamt=curr_year+""+numSeperator;
          jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
        }
        if( myselected_array[i] == "CD" ){
          numforamt=current_date+""+numSeperator;
          jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
        }
        if( myselected_array[i] == "MT" ){
          if( jQuery("#matter_matter_category_nonlitigation").is(":checked") ){
            numforamt=jQuery("#matter_matter_type_nonliti option:selected").text()+""+numSeperator;
            jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
          }
          if( jQuery("#matter_matter_category_litigation").is(":checked") ){
            numforamt=jQuery("#matter_matter_type_liti option:selected").text()+""+numSeperator;
            jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
          }
        }

        if( myselected_array[i] == "MN" ){
          if( jQuery("#matter_name").val() != "" ){
            numforamt=jQuery("#matter_name").val()+""+numSeperator;
            jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
          }
        }

        if( myselected_array[i] == "M" ){
          numforamt= current_month+""+numSeperator;
          jQuery("#matter_id").val(jQuery("#matter_id").val()+numforamt);
        }
      }
      var numindex=numforamt.indexOf(numSeperator);
      if( numindex > 0 ){
        numforamt=jQuery("#matter_id").val().substring(0,jQuery("#matter_id").val().length-1);
      }else{
        numforamt=jQuery("#matter_id").val().substring(0,jQuery("#matter_id").val().length);
      }
      jQuery("#matter_id").val(numforamt);
    }
  }
}

function onMatterIdChange(){
  jQuery("#matter_id_flag").val("true");
}