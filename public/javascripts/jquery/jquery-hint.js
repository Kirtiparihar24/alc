/**
* jQuery Hint Box for search input [contacts, accounts, campaign, opportunity etc.]
*/
(function ($) {

$.fn.hint = function (blurClass) {
  if (!blurClass) {    
    blurClass = 'blursearchbox';
  }

  return this.each(function () {
    // get jQuery version of 'this'
    var $input = $(this),
    
    // capture the rest of the variable to allow for reuse
      title = $input.attr('title'),
      $form = $(this.form),      
      $win = $(window);

    function remove() {
      if ($input.val() === title && $input.hasClass(blurClass)) {
        $input.val('').removeClass(blurClass);
      }
    }

    // only apply logic if the element has the attribute
    if (title) {
      // on blur, set value to title attr if text is blank
      $input.blur(function () {
        if (this.value === '') {
          $input.val(title).addClass(blurClass);
          //$input.css({'color':'#999','font-family':'Arial, Helvetica, sans-serif','font-size':'11px','padding':'0','margin':'0'});
        }
      }).focus(remove).blur(); // now change all inputs to title
      $input.mousedown(function(){
         $input.css('color','#000');
      });
      // clear the pre-defined text when form is submitted
      $form.submit(remove);
      $win.unload(remove); // handles Firefox's autocomplete
    }
  });
};

})(jQuery);
