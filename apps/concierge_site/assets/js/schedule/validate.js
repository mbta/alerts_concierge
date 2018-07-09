export const validateTravelTimeSelected = e => {
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
    [...document.querySelectorAll(`div[data-type="leg-error"]`)][0].focus();
  }
};

const countSelectionsForLeg = legEl => {
  const count = [...legEl.getElementsByClassName("active")].length;
  if (count === 0) {
    legEl.querySelector(`div[data-type="leg-error"]`).style.display = "block";
  }
  return count;
};