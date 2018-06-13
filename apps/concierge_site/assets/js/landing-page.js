export default $ => {
  $ = $ || window.jQuery;

  // Keep track of whether input elements have content
  $("body.landing-page input.form-control").on("blur", function(e) {
    const $targetEl = $(e.target);
    if ($targetEl.val()) {
      $targetEl.addClass("has-content");
    } else {
      $targetEl.removeClass("has-content");
    }
  });
};
