import $ from "jquery";

export default () => {
  // add contextual trip data to delete modal
  $("#deleteModal").on("show.bs.modal", function(e) {
    // when the modal opens, read the trip-id if it is available
    const tripId = $(e.relatedTarget).data("trip-id");
    const token = $(e.relatedTarget).data("token");
    if (!tripId) {
      // The confirmation button has already been set up in the _delete_modal partial
      return;
    }

    // delete any existing link
    $("#deleteModal")
      .find("a[data-modal='temp-button']")
      .remove();

    // append a fresh link
    $("#deleteModal")
      .find("div[data-modal='action_container']")
      .append(
        `<a class="btn btn-primary" data-modal="temp-button" data-csrf="${token}" data-method="delete" data-to="/trips/${tripId}" href="#" rel="nofollow">Yes, delete</a>`
      );
  });

  // make delete modal / links accessible
  $("a[data-toggle='modal']").on("keypress", triggerClick());

  function triggerClick() {
    return function(e) {
      e.preventDefault();
      e.stopPropagation();
      $(e.target).click();
    };
  }
};
