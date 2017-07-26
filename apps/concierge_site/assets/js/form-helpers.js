export default function($) {
  $ = $ || window.jQuery;

  $("input").focus(function(event){
    $(event.target).toggleClass("dirty", true);
  });

  $("form.single-submit-form").one("submit", function(event){
    event.preventDefault();
    $("form.single-submit-form button").prop("disabled", true);
    $("form.single-submit-form input[type=submit]").prop("disabled", true);
    event.target.submit();
  });
}
