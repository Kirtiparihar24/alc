/*  
 * Subject :: Move the list for list items as the the user sets up the index
 * Depends on :: Jquery
 * Author :: Supriya Surve
 * Created On :: Tue May 3, 07:59 AM 
 * TODO: need to add options for <ul><li> and <select><option>
 * For now these functions can only handle <table> and sorts from 2nd tr and 1st is considered to be holding <th>.
 * This will be handled in future as checkIfobject variable is already defined to check the tag name.
 */

/*
* fetch_data function will get the id name of the table and convert it in to jquery object.
* This will also call build_html function by passing object created, model type(which model to be called), company id and divid separately.
*/
function fetch_data( modelType, companyID, divID ){
  var obj = jQuery(divID);
  build_html( obj, modelType, companyID, divID );
}

/*
* This function is only called through the fetch_data().
* build_html will first check the object's tag name by jquery function .is() and based on this checkIfobject will be assigned a value.
* This assigned value will be used for sorting <td> OR <li> OR <option>.
* After checking the html tag the objects width is changed to fit the buttons on the right side.
* At the end loopingList() is called
*/
function build_html( obj, modelType, companyID, divID ){
  var checkIfobject;
    
  if(obj.is("table")){
    checkIfobject = "TaBle"
  }else if(obj.is("ul")){
    checkIfobject = "UL"
  }else if(obj.is("select")){
    checkIfobject = "SelEct"
  }
  var trheight = jQuery(obj).children().children('tr.bg1').height()
  var tdheight = (parseInt(trheight) * (jQuery(obj).children().children('tr').length-1)) + jQuery(obj).children().children('tr:first').height()
  jQuery(obj).after("<table id='setter' style='float:left' cellspacing='0' cellpadding='0'><tr><th align='center' valign='middle' style='height:"+tdheight+"px'><input name='upbutton' id='upbutton' type='button' value=' &uarr; ' /> <br /> <input name='downbutton' id='downbutton' type='button' value=' &darr; ' /> <br /> <input name='setbutton' id='setbutton' type='button' onClick='sendRequest( \""+checkIfobject+"\", \""+modelType+"\", \""+companyID+"\", \""+divID+"\" )' value='Set' disabled='disabled' style='color:grey'/> </th></tr></table>")
  var setterwidth = ( 100 * parseFloat(jQuery('#setter').css('width')) / parseFloat(jQuery('#setter').parent().css('width')) );
  var tblewidth = (99.7-setterwidth)
  jQuery(obj).css({
    "width" : tblewidth+"%",
    "float" : "left"
  });
  loopingList( obj, checkIfobject );
}

/*
* This function will actually add the hidden field which will be used for indexing the data
*/
function loopingList( obj, checkIfobject ){
  var list;

  switch( checkIfobject ){
    case "TaBle":
      list = obj.children().children('tr');      
      break;

    case "UL":
      list = obj.children('li');
      break;

    case "SelEct":
      list = obj.children('option');
      break;
  }
    
  list.each(function( index ) {
    var listitem = this;
    var jListitem = jQuery(listitem);
        
    jListitem.attr('onClick', "updateList(this)");
    jListitem.children('td:first').append("<input type='hidden' id='hidden_"+index+"' value='"+index+"' class='supportField'/>");
  });
}

jQuery(".update-list").live("click",function(){
  updateList(this);
});

/*
* To add or remove selected/ clicked item's class.
* Need to pass the class name, list array, the clicked item and whether the class exists or not (true/ false)
*/
function updateList( listitem ){
  var jListitem = jQuery(listitem);
  var className = "selected_listitem"
  jQuery("tr").removeClass(className)
  if(jListitem.hasClass(className)){
    jListitem.removeClass(className);
  }else{
    jListitem.addClass(className);
  }
}

/*
* This function handles the up and down sorting button clicks on which the actual sorting takes place.
*/
jQuery('#upbutton').live("click",function(){
  var jListitem = jQuery(".selected_listitem");
       
  if( jListitem.length > 0 ){
    jQuery("#setbutton").removeAttr("disabled");
    jQuery("#setbutton").removeAttr("style");
    var prevlistitem = jListitem.prev();
            
    var prevlistitemIndex = prevlistitem.children("td:first").children("input.supportField").val();
    var jListitemIndex = jListitem.children("td:first").children("input.supportField").val();

    if( jListitemIndex == 1 ){
    }else{
      var innerhmtl = prevlistitem.html();
                
      prevlistitem.remove();
      jListitem.after("<tr class='bg1 update-list' onclick='updateList(this)'>"+innerhmtl+"</tr>");
      jListitem.children("td:first").children("input.supportField").val(prevlistitemIndex);
      jListitem.next().children("td:first").children("input.supportField").val(jListitemIndex);
    }
  }else{
    alert("Select Record for sorting");
  }
});


jQuery('#downbutton').live("click",function(){
  var jListitem = jQuery(".selected_listitem");
  var mxLength = jQuery(".update-list").length-1;
  if( jListitem.length > 0 ){
    jQuery("#setbutton").removeAttr("disabled");
    jQuery("#setbutton").removeAttr("style");
    var nextlistitem = jListitem.next();
    var nextlistitemIndex = nextlistitem.children("td:first").children("input.supportField").val();
    var jListitemIndex = jListitem.children("td:first").children("input.supportField").val();

    if( jListitemIndex == mxLength ){
    }else{
      var innerhmtl = nextlistitem.html();

      nextlistitem.remove();
      jListitem.before("<tr class='bg1 update-list' onclick='updateList(this)'>"+innerhmtl+"</tr>");
      jListitem.children("td:first").children("input.supportField").val(nextlistitemIndex);
      jListitem.prev().children("td:first").children("input.supportField").val(jListitemIndex);
    }
  }else{
    alert("Select Record for Sorting");
  }
});

function sendRequest( checkIfobject, modelType, companyID, divID){
  var jListitem = jQuery(".selected_listitem");
  if( jListitem.length > 0 ){
    var list = jQuery(divID).children().children('tr');    
    var sequences = []
    
    list.each(function(){
      var listitem = this;
      var jListitem = jQuery(listitem);
      var indNum = list.index(listitem);
        
      if( indNum > 0 ){
        var id = jListitem.children("td:first").children("input.supportFieldID").val();
        var sequence = jListitem.children("td:first").children("input.supportField").val();
        sequences.push([id,sequence]);
      }
    });    
    
    jQuery.ajax({
      type: 'get',
      url: '/reset_sequence',
      data:{
        'sequences[]' : sequences,
        "model_type" : modelType,
        "company_id" : companyID
      },
      success: function(){
        window.location.href = "/manage_company_utilities/"+modelType;
      }
    });
  }else{
    alert("Select Record for Sorting");
  }
}