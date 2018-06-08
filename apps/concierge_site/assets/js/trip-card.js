export default $ => {
  $ = $ || window.jQuery;

  // make entire trip card clickable
  $("div[data-trip-card='link']").on("click", function(e) {
    // bail out if the delete modal link is clicked
    const isModal = $(e.target).data("toggle") == "modal" ? true : false;
    if (isModal) {
      return;
    }

    const $targetEl = $(e.target);
    const $parentEl = $($targetEl).parents("div[data-trip-card='link']");
    const linkType = $parentEl.data("link-type");
    const tripId = $parentEl.data("trip-id");
    if (!tripId) {
      return;
    }
    const urlBase = (linkType == "accessibility") ? "/accessibility_trips" : "/trips";
    window.location = `${urlBase}/${tripId}/edit`;
  });
};
