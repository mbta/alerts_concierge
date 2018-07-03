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

const validateTravelTimeSelected = e => {
  // get all legs
  const scheduleLegs = [
    ...document.querySelectorAll("div[data-type='schedule-leg']")
  ];

  // if there are no legs, there is nothing to validate
  if (scheduleLegs.length === 0) {
    return;
  }

  // remove any prior error notifications
  [...document.querySelectorAll(`div[data-type="leg-error"]`)].forEach(
    el => (el.style.display = "none")
  );

  // check if each leg has a selection
  const eachLegHasSelection = scheduleLegs.reduce((accumulator, legEl) => {
    const count = countSelectionsForLeg(legEl);
    return accumulator === false ? false : count > 0;
  }, true);

  // if any leg is missing a selection, prevent the form submission
  if (!eachLegHasSelection) {
    e.preventDefault();
  }
};

const countSelectionsForLeg = legEl => {
  const count = [...legEl.getElementsByClassName("active")].length;
  if (count === 0) {
    legEl.querySelector(`div[data-type="leg-error"]`).style.display = "block";
  }
  return count;
};

const errorMessage = message => {
  return `<div class="error-block-container">
    <span class="error-block">${message}</span>
  </div>`;
};
