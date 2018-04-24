export default function($) {
  $ = $ || window.jQuery;

  const toggle = toggleFn($);

  $("input:radio[data-toggle='controller']").click(toggle);
  toggle.call($("input:radio:checked[data-toggle='controller']"));
}

function toggleFn($) {
  return function() {
    const input = $(":input[data-toggle='input']");
    const label = $("label[data-toggle='label']");

    if ($(this).val() === "true") {
      input.prop("disabled", false);
      input.prop("required", true);
      label.removeClass("form__label--disabled");
    } else {
      input.prop("disabled", true);
      input.prop("required", false);
      label.addClass("form__label--disabled");
    }
  };
}
