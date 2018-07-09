import { validateTravelTimeSelected } from "./schedule/validate";

export default () => {
  const commuteEditFormEl = document.getElementById("commute-edit-form");
  if (commuteEditFormEl) {
    commuteEditFormEl.addEventListener("submit", handleTimeFormSubmit, false);
  }
};

const handleTimeFormSubmit = e => {
  validateTravelTimeSelected(e);
};