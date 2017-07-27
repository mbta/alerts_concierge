export default function($) {
  $ = $ || window.jQuery;

  $("input").focus(function(event){
    $(event.target).toggleClass("dirty", true);
  });

  $("form.single-submit-form").one("submit", function(event){
    event.preventDefault();
    $("button", event.target).prop("disabled", true);
    $("input[type=submit]", event.target).prop("disabled", true);
    event.target.submit();
  });
}
