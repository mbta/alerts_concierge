export default () => {
  const tripLegFormEl = document.getElementById("tripleg-form");
  if (!tripLegFormEl) {
    return;
  }
  tripLegFormEl.addEventListener("submit", handleLegFormSubmit, false);
};

const handleLegFormSubmit = e => {
  const originInputEl = document.getElementById("trip_origin");
  const destinationInputEl = document.getElementById("trip_destination");
  const originErrorEl = document.getElementById("trip_origin_error");
  const destinationErrorEl = document.getElementById("trip_destination_error");

  originErrorEl.innerHTML = "";
  destinationErrorEl.innerHTML = "";

  if (!originInputEl.value || !destinationInputEl.value) {
    e.preventDefault();
    if (!originInputEl.value) {
      originErrorEl.innerHTML = errorMessage("Origin is a required field.");
    }
    if (!destinationInputEl.value) {
      destinationErrorEl.innerHTML = errorMessage("Destination is a required field.");
    }
  }
};

const errorMessage = message => {
  return `<div class="error-block-container">
    <span class="error-block">${message}</span>
  </div>`;
};
