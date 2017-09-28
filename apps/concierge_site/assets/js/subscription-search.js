export default function($) {
  $ = $ || window.jQuery;

  $(".diagnostic-result-toggle").on("click", function (event) {
    let target = event.currentTarget;
    let id = target.attributes['data-target-sub-id'].value;

    $(`#${id}`).toggleClass("hidden");
    $(`.diagnostic-toggle-text.${id}`).toggleClass("hidden");
  })
}
