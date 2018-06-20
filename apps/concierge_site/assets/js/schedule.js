import elemDataset from 'elem-dataset';
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
  const dataset = elemDataset(tripEl); 
  const tripTime = dataset.time;
  const matched = isMatched(tripTime, startTime, endTime);
  tripEl.style.display = matched ? "block" : "none";
  return matched ? 1 : 0;
}

function toggleBlankSlate(scheduleEl, display) {
  const blankSlates = [... scheduleEl.getElementsByClassName("schedules__blankslate")];
  blankSlates.forEach(blankSlate => {
    blankSlate.style.display = display;
  });
}

function processSchedule(scheduleEl) {
  const dataset = elemDataset(scheduleEl);
  const startTime = document.getElementById(dataset.start).value;
  const endTime = document.getElementById(dataset.end).value;
  const trips = [... scheduleEl.getElementsByClassName("schedules__trips--item")];
  const matchedTrips = trips.reduce((count, tripEl) => {
    return count + processTrip(tripEl, startTime, endTime);
  }, 0);
  matchedTrips == 0 ? toggleBlankSlate(scheduleEl, "block") : toggleBlankSlate(scheduleEl, "none");
}

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
  const dataset = elemDataset(legEl);
  const expanded = !JSON.parse(dataset.expanded || "false");
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

export default (pubSub) => {
  pubSub.subscribe("time-change", e => {
    const scheduleEl = document.getElementById(`schedule_${e.mode}`);
    expandAndProcessSchedule(scheduleEl);
  });

  const scheduleWidgets = [... document.querySelectorAll("div[data-type='schedule-viewer']")];
  scheduleWidgets.forEach((scheduleEl) => {
    scheduleEl.style.display = "block";
    processSchedule(scheduleEl);
    enableToggle(scheduleEl);
  });
};
