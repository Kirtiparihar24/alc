var exact_location = window.location.href.toString() /* make the location as a string */
var loc_split = exact_location.split("/") /* split the location */
var controller = loc_split[3] /* find controller name */
var site = loc_split[2] /* find site name */
var keycount = 0

jQuery(document).ready(function(){
  if(jQuery("ul.navigation_list li.active").length > 0){
    jQuery("ul.navigation_list li.active").addClass('active_current');
  }
  if(jQuery("ul.tabs-nav li.tabs-selected").length > 0){
    jQuery("ul.tabs-nav li.tabs-selected").addClass('activesub_current');
  }
});

jQuery(document).keydown(function(e){
  /* -ctrl+backspace for history need to remove as there is already same function available for browsers- */
  /* -ctrl+esc for cancel- */
  if(e.ctrlKey && e.which == 27) {
    history.back();
    return false;
  }
  /* -ctrl+h for home/root_path- */
  if(e.ctrlKey && e.which == 72){
    window.location = "/";
    return false;
  }
  /* -ctrl+l for livian instructions- */
  if(e.ctrlKey && e.which == 76){
    jQuery('.new_instructions_facebox').click();
    return false;
  }
  /* ctrl+o */
  if( e.ctrlKey && e.which == 79 ){
    /* if shift */
    if(e.shiftKey){
      window.location = "/opportunities/";
    }else{
      window.location = "/logout";
    }
    return false;
  }
  /* ctrl + shift + a for accounts */
  if(e.ctrlKey && e.shiftKey && e.which == 65) {
    window.location = "/accounts/";
    return false;
  }
  /* ctrl + shift + c for contacts */
  if(e.ctrlKey && e.shiftKey && e.which == 66){
    window.location = "/contacts/";
    return false;
  }
        
  var navigation_list_ul = jQuery("ul.navigation_list")
  var list_li = jQuery("ul.navigation_list li")
  var active_list_li = jQuery("ul.navigation_list li.active")
  /* ctrl + enter for going to the location of selected tab  */
  if(e.ctrlKey && e.which == 13){
    /* if the tabs-nav ul is available on the page, which is the sub menus available specially in edit pages */
    if(jQuery("#TB_window").length>0 && jQuery("#TB_window").css("display", "block")){}else{
      if(jQuery("ul.tabs-nav").length>0){
        if(navigation_list_ul.hasClass("demo")){
          actual_link = jQuery("ul.navigation_list li.active a").attr("href")
          create_href_for_link(actual_link); /* line no 245 */
          return false;
        }else{
          actual_link = jQuery("ul.tabs-nav li.tabs-selected a").attr("href")
          /* if link consist "fragment" string then just show related div else go to the link */
          if(actual_link.search("fragment")==1){
            jQuery("ul.tabs-nav>li:not(.tabs-selected) a").each(function(idx, item){
              var link = jQuery(item).attr("href")
              jQuery(link).hide();
            });
            jQuery(actual_link).show();
            jQuery("ul.tabs-nav li.activesub_current").removeClass('activesub_current');
            jQuery("ul.tabs-nav li.tabs-selected").addClass('activesub_current');
          }else{
            create_href_for_link(actual_link); /* line no 245 */
          }
        }
      }else{
        actual_link = jQuery("ul.navigation_list li.active a").attr("href")
        create_href_for_link(actual_link); /* line no 245 */
        return false;
      }
    }
  }
  var htmlTag = jQuery('html, body')
  /* if the tabs-nav ul is available on the page, which is the sub menus available specially in edit pages */
  if(jQuery("div.main_containt ul.tabs-nav").length>0){
    if(jQuery("#TB_window").length>0 && jQuery("#TB_window").css("display", "block")){}else{
      var subtab_selected_li = jQuery("ul.tabs-nav li.tabs-selected")
      var tabs_nav_li = jQuery("ul.tabs-nav li")
      /* ctrl + right arrow for navigating through the header main/sub navigation - flow right */
      if(e.ctrlKey && e.which == 39){
        if(tabs_nav_li.hasClass("tabs-selected")){
          subtab_selected_li.next().addClass("tabs-selected");
          jQuery("ul.tabs-nav li.tabs-selected:first").removeClass("tabs-selected");
          keycount++;
          if(controller=="physical" && keycount==1){
            htmlTag.animate({
              scrollTop: jQuery(document).height()
            }, 800);
          }
          calculate_submenu_time();
        }else{
          if(navigation_list_ul.hasClass("demo")){
            right_navigation_list(); /* line no 205 */
          }else{
            jQuery("ul.tabs-nav li:first").addClass("tabs-selected");
          }
        }
        return false;
      }
      /* ctrl + left arrow for navigating through the header main/sub navigation - flow left */
      if(e.ctrlKey && e.which == 37){
        if(tabs_nav_li.hasClass("tabs-selected")){
          subtab_selected_li.prev().addClass("tabs-selected");
          jQuery("ul.tabs-nav li.tabs-selected:last").removeClass("tabs-selected");
          keycount++;
          if(controller=="physical" && keycount==1){
            htmlTag.animate({
              scrollTop: jQuery(document).height()
            }, 800);
          }
          calculate_submenu_time();
        }else{
          if(navigation_list_ul.hasClass("demo")){
            left_navigation_list(); /* line no 215 */
          }else{
            jQuery("ul.tabs-nav li:last").addClass("tabs-selected");
          }
        }
        return false;
      }
      /* ctrl + up arrow for navigating the main header navigation */
      if(e.ctrlKey && e.which == 38){
        subtab_selected_li.removeClass("tabs-selected");
        navigation_list_ul.addClass("demo");
        if(controller=="physical"){
          htmlTag.animate({
            scrollTop: '0px'
          }, 800);
        }
      }
      /* ctrl + down arrow for navigating the sub header navigation */
      if(e.ctrlKey && e.which == 40){
        jQuery("ul.tabs-nav li:first").addClass("tabs-selected");
        navigation_list_ul.removeClass("demo");
        if(controller=="physical"){
          htmlTag.animate({
            scrollTop: jQuery(document).height()
          }, 800);
        }
      }
    }
  }else{
    if(jQuery("#TB_window").length>0 && jQuery("#TB_window").css("display", "block")){}else{
      /* ctrl + right arrow for navigating through the header main navigation - flow right */
      if(e.ctrlKey && e.which == 39){
        right_navigation_list(); /* line no 205 */
        return false;
      }
      /* ctrl + left arrow for navigating through the header main navigation - flow left */
      if(e.ctrlKey && e.which == 37){
        left_navigation_list(); /* line no 215 */
        return false;
      }
    }
  }
        
  if(controller=="physical"){
  /* do nothing just run the default and browser shortcuts */
  }else{
    if(jQuery("#TB_window").length>0 && jQuery("#TB_window").css("display", "block")){}else{
      /* control s & t will work only for new and edit actions, as it gives error for other pages */
      if(loc_split.length>4){
        var actioname
        if(loc_split[5]){
          var Actioname = loc_split[5].split("?")
          actioname = Actioname[0]
        }else{
          actioname = loc_split[4]
        }
        if(actioname=="new" || actioname=="edit"){
          /* -ctrl+s for save- */
          if(e.ctrlKey && e.which == 83){
            jQuery("div.main_containt form input[name='save']").click();
            return false;
          }
          /* -ctrl+t for save & exit- */
          if(e.ctrlKey && e.which == 84){
            jQuery("div.main_containt form input[name='save_exit']").click();
            return false;
          }
        }
      }
      /* -ctrl + n for new action still need to work- */
      if(e.ctrlKey && e.which == 78) {
        if(loc_split.length>4){
          if(actioname=="new"){
            alert("You are already on this page");
            return false;
          }else if(actioname=="edit"){
            var response = confirm("Are you sure you want to navigate away from this page? The changes you made will be lost if you navigate away from this page. Press OK to continue, or Cancel to stay on the current page.");
            if(response){
              controllerwise_new_action(); /* line no 224 */
              return false;
            }else{
              return false;
            }
          }else{
            controllerwise_new_action(); /* line no 224 */
            return false;
          }
        }else{
          controllerwise_new_action(); /* line no 224 */
          return false;
        }
      }
      /* following is for selecting record for editing where ever the grid is available */
      /* shift + down arrow for navigating through the grid data - flow downside */
      if(jQuery('div.main_containt div.tabular_listing').length>0){
        if(e.shiftKey && e.which == 40){
          if(jQuery('tr').hasClass('with_focus')){
            jQuery('tr.with_focus').next().addClass('with_focus');
            jQuery('tr.with_focus:first').removeClass('with_focus');
          }else{
            jQuery('.main_containt .p5 .tabular_listing table:first tr:first').next().addClass('with_focus');
            htmlTag.animate({
              scrollTop: '0px'
            }, 800);
          }
          return false;
        }
        /* shift + up arrow for navigating through the grid data - flow upside */
        if(e.shiftKey && e.which == 38){
          if(jQuery('tr').hasClass('with_focus')){
            jQuery('tr.with_focus').prev().addClass('with_focus');
            jQuery('tr.with_focus:last').removeClass('with_focus');
          }else{
            var ele = jQuery('.main_containt .p5 .tabular_listing table:first tr:last');
            var maintr = ele.parent().parent().parent().parent().parent();
            maintr.addClass('with_focus');
            htmlTag.animate({
              scrollTop: jQuery(document).height()
            }, 800);
          }
          return false;
        }
        /* shift + enter for going to the highlighted address from grid */
        if(e.shiftKey && e.which == 13){
          if(jQuery('tr').hasClass('with_focus')){
            if(controller=="contacts"){
              location.href = jQuery('tr.with_focus').children('td:first').next().children().children().attr('href');
              return false;
            }else if(controller=="matters"){
              location.href = jQuery('tr.with_focus').children('td:first').next().next().children().children().attr('href');
            }else{
              location.href = jQuery('tr.with_focus td:first a').attr('href');
              return false;
            }
            return false;
          }else{}
        }
      }
    }
  }
    
  /* top naviation selection through right key - this is called in both if and else for diff purpose */
  function right_navigation_list(){
    if(list_li.hasClass("active")){
      active_list_li.next().addClass("active");
      jQuery("ul.navigation_list li.active:first").removeClass("active");
    }else{
      jQuery("ul.navigation_list li:first").addClass("active");
    }
    calculate_time();
  }

  /* top naviation selection through left key - this is called in both if and else for diff purpose */
  function left_navigation_list(){
    if(list_li.hasClass("active")){
      active_list_li.prev().addClass("active");
      jQuery("ul.navigation_list li.active:last").removeClass("active");
    }else{
      jQuery("ul.navigation_list li:last").addClass("active");
    }
    calculate_time();
  }

  function controllerwise_new_action(){
    var subcontroller = controller.split("?");
    /* the location which will be genrated, is based on the current controller */
    if(controller=="repositories"){
      jQuery('#repository_upload_document').click();
    }else if(controller=="matters"){
      var new_location = "/"+loc_split[3]+"/"+loc_split[4]
      if(loc_split[5]=="matter_issues" || loc_split[5]=="matter_risks" || loc_split[5]=="matter_facts" || loc_split[5]=="document_homes" || loc_split[5]=="matter_researches"){
        jQuery("a.link_blue").click();
      }else if(loc_split[5]=="matter_tasks"){
        window.location = new_location+"/matter_tasks/new";
      }else{
        window.location = "/"+subcontroller[0]+"/new"
      }
    }else if(controller=="contacts" || controller=="accounts" || controller=="opportunities" || controller=="campaigns"){
      window.location = "/"+subcontroller[0]+"/new"
    }
  }

  function create_href_for_link(actual_link){
    /* location for link will get created and will send the user to that location */
    href = actual_link.split("/")
    if(href[2] == site){
      link_location = "/"+href[3]
    }else{
      link_location = actual_link
    }
    window.location = link_location
  }
});

/* calculating the time for main menu which is not actually a current page */
function calculate_time(){    
  window.setTimeout(function(){
    if(jQuery("ul.navigation_list li.active").hasClass('active_current')){
    }else{
      jQuery("ul.navigation_list li.active").removeClass('active');
      jQuery("ul.navigation_list li.active_current").addClass('active');
    }
  }, 6000);
}

/* calculating the time for sub menu which is not actually a current page */
function calculate_submenu_time(){
  window.setTimeout(function(){
    if(jQuery("ul.tabs-nav li.tabs-selected").hasClass('activesub_current')){
    }else{
      jQuery("ul.tabs-nav li.tabs-selected").removeClass('tabs-selected');
      jQuery("ul.tabs-nav li.activesub_current").addClass('tabs-selected');
    }
  }, 6000);
}