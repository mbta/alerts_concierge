export default function($) {
  $ = $ || window.jQuery;

  $("input").focus(function(event){
    $(event.target).toggleClass("dirty", true);
  });

  $("form.sub-creation-form").one("submit", function(event){
    event.preventDefault();
    $("form.sub-creation-form button").prop("disabled", true);
    $("form.sub-creation-form input[type=submit]").prop("disabled", true);
    event.target.submit();
  });
}
