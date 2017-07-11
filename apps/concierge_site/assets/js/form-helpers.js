export default function($) {
  $ = $ || window.jQuery;

  $("input").focus(function(event){
    $(event.target).toggleClass("dirty", true);
  });
}
