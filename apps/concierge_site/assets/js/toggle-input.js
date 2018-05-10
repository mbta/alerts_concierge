export default function($) {
  $ = $ || window.jQuery;

  const toggle = toggleFn($);

  $("input:radio[data-toggle='controller']").click(toggle);
  toggle.call($("input:radio:checked[data-toggle='controller']"));
}

function toggleFn($) {
  return function() {
    const $inputEl = $(":input[data-toggle='input']");
    const $containerEl = $("div[data-type='connection']");

    if ($(this).val() === "true") {
      $inputEl.prop("required", true);
      $containerEl.removeClass("d-none");
    } else {
      $inputEl.prop("required", false);
      $containerEl.addClass("d-none");
    }
  };
}
