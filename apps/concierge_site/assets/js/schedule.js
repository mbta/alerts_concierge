const toggleDownClasses = "fa fa-caret-down schedules__toggle";
const toggleUpClasses = "fa fa-caret-up schedules__toggle";

const makeDate = timeString => new Date(`1/1/2000 ${timeString}`);

function isMatched(tripTime, startTime, endTime) {
  const tripDate = makeDate(tripTime);
  if (!(tripDate instanceof Date)) {
    return false;
  }
  const startDate = makeDate(startTime);
  const endDate = makeDate(endTime);
  return (tripDate >= startDate) && (tripDate <= endDate);
}

function processTrip(tripEl, startTime, endTime) {
  const tripTime = tripEl.dataset.time;
  tripEl.style.display = isMatched(tripTime, startTime, endTime) ? "block" : "none";
}

function processSchedule(scheduleEl) {
  const startTime = document.getElementById(scheduleEl.dataset.start).value;
  const endTime = document.getElementById(scheduleEl.dataset.end).value;
  const trips = [... scheduleEl.getElementsByClassName("schedules__trips--item")];
  trips.forEach(tripEl => processTrip(tripEl, startTime, endTime));
}

function handleTimeChange(scheduleEl) {
  const startInputEl = document.getElementById(scheduleEl.dataset.start);
  const endInputEl = document.getElementById(scheduleEl.dataset.end);
  ['keyup', 'click'].forEach((eventType) => {
    startInputEl.addEventListener(eventType, () => expandAndProcessSchedule(scheduleEl));
    endInputEl.addEventListener(eventType, () => expandAndProcessSchedule(scheduleEl));
  });
};

function expandAndProcessSchedule(scheduleEl) {
  const legs = [... scheduleEl.querySelectorAll(".schedules__trips--leg")];
  legs.forEach((legEl) => {
    const toggleEl = legEl.querySelector(".schedules__toggle");
    doToggle(legEl, toggleEl, true);
  });
  processSchedule(scheduleEl);
}

function handleToggle(e, legEl, toggleEl, scheduleEl) {
  e.preventDefault();
  const expanded = !JSON.parse(legEl.dataset.expanded || "false");
  doToggle(legEl, toggleEl, expanded);
}

function doToggle(legEl, toggleEl, expanded) {
  legEl.setAttribute("data-expanded", expanded);
  if (toggleEl) {
    toggleEl.className = (expanded) ? toggleUpClasses : toggleDownClasses;
  }
}

function enableToggle(scheduleEl) {
  const legs = [... scheduleEl.querySelectorAll(".schedules__trips--leg")];
  legs.forEach((legEl) => {
    const toggleEl = document.createElement("A");
    const headerEl = legEl.querySelector(".schedules__header");
    toggleEl.className = toggleDownClasses;
    toggleEl.setAttribute("href", "#");
    legEl.appendChild(toggleEl);
    ['keypress', 'click'].forEach((eventType) => {
      toggleEl.addEventListener(eventType, (e) => handleToggle(e, legEl, toggleEl, scheduleEl));
      headerEl.addEventListener(eventType, (e) => handleToggle(e, legEl, toggleEl, scheduleEl));
    });
  });
}

export default () => {
  const scheduleWidgets = [... document.querySelectorAll("div[data-type='schedule-viewer']")];
  scheduleWidgets.forEach((scheduleEl) => {
    scheduleEl.style.display = "block";
    processSchedule(scheduleEl);
    enableToggle(scheduleEl);
    handleTimeChange(scheduleEl);
  });
};
