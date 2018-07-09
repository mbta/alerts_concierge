import { validateTravelTimeSelected } from "./schedule/validate";

export default () => {
  const tripLegFormEl = document.getElementById("tripleg-form");
  if (tripLegFormEl) {
    tripLegFormEl.addEventListener("submit", handleLegFormSubmit, false);
  }

  const tripTimeFormEl = document.getElementById("triptime-form");
  if (tripTimeFormEl) {
    tripTimeFormEl.addEventListener("submit", handleTimeFormSubmit, false);
  }
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
      destinationErrorEl.innerHTML = errorMessage(
        "Destination is a required field."
      );
    }
  }
};

const handleTimeFormSubmit = e => {
  validateTravelTimeSelected(e);
};

const errorMessage = message => {
  return `<div class="error-block-container">
    <span class="error-block">${message}</span>
  </div>`;
};
