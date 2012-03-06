//=====Resolution Script Created by Sanjay, Khushboo on 29 April 2010======================================//
function LoadResolutionCss(){
  var href = window.location.href.toString();
  var split_string = href.split("/")
  var width = "100%"
  if(split_string.length > 5){
    if(split_string[5].match(/document_homes/)){
      width = "84%"
      if(split_string[6]=="new" || split_string[7]=="edit"){
        width = "100%"
      }
    }
  }
  var winwidth = (screen.width || document.client.width);
  if (winwidth <= 1400){
    document.body.style.fontSize = "68.8%";
    jQuery('#doc').css({
      "width" : "1200px"
    });
    jQuery('#foot').css({
      "width" : "1200px"
    });
    if(split_string.length > 5){
      if(split_string[5]=="document_homes"){
        if(split_string[6]=="new" || split_string[7]=="edit"){
          jQuery('.column_right_tabs').css({
            "width" : width
          });
        }
      }
    }
  }else{
    document.body.style.fontSize = "75%";
    jQuery('#doc').css({
      "width" : "1580px"
    });
    jQuery('#foot').css({
      "width" : "1580px"
    });
    jQuery('.column_left').css({
      "width" : "235px"
    });
    jQuery('.section_left').css({
      "width" : "235px"
    });
    jQuery('.column_fav').css({
      "width" : "235px"
    });
    jQuery('.column_right').css({
      "width" : "84%"
    });
    jQuery('.column_right_tabs').css({
      "width" : width
    });
    jQuery('.dashbard_left').css({
      "width" : "84%"
    });
  }
}
window.onload = LoadResolutionCss;