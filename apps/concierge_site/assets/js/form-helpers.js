export default function($) {
  $ = $ || window.jQuery;

  $("input").focus(function(event){
    $(event.target).toggleClass("dirty", true);
  });

  $("form.trip-prefs-form").one("submit", function(event){
    event.preventDefault();
    $("form.trip-prefs-form button").prop("disabled", true);
    $("form.trip-prefs-form input[type=submit]").prop("disabled", true);
    event.target.submit();
  });
}
