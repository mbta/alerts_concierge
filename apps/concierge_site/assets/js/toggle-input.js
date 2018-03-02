import selectRoute from "./select-route";

export default function($) {
  $ = $ || window.jQuery;

  var toggle = toggleFn($);

  $("input:radio[data-toggle='controller']").click(toggle);
  toggle.call($("input:radio:checked[data-toggle='controller']"));
}

function toggleFn($) {
  return function () {
    var input = $(":input[data-toggle='input']")

    if ($(this).val() === "true") {
      input.prop("disabled", false)
      input.prop("required", true)
    } else {
      input.prop("disabled", true)
      input.prop("required", false)
    }
  }
}
