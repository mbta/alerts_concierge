export default $ => {
  $ = $ || window.jQuery;

  // add contextual trip data to delete modal
  $("#deleteModal").on("show.bs.modal", function(e) {
    // when the modal opens, read the trip-id if it is available
    const tripId = $(e.relatedTarget).data("trip-id");
    const token = $(e.relatedTarget).data("token");
    if (!tripId) {
      return;
    }

    // delete any existing link
    $("#deleteModal")
      .find("a[data-modal='temp-button']")
      .remove();

    // append a fresh link
    $("#deleteModal")
      .find("div[data-modal='action_container']")
      .prepend(
        `<a class="btn btn-primary" data-modal="temp-button" data-csrf="${token}" data-method="delete" data-to="/trips/${tripId}" href="#" rel="nofollow">Yes, delete</a>`
      );
  });

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

  // make delete modal / links accessible
  $("a[data-toggle='modal']").on("keypress", triggerClick());
};

function triggerClick() {
  return function (e) {
    e.preventDefault();
    e.stopPropagation();
    $(e.target).click();
  };
}