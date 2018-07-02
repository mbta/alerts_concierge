import elemDataset from 'elem-dataset';

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
  tripEl.setAttribute("data-matched", matched ? "true" : "false");
  return matched ? 1 : 0;
}

function toggleBlankSlate(scheduleEl, display) {
  const blankSlates = [... scheduleEl.getElementsByClassName("schedules__blankslate")];
  blankSlates.forEach(blankSlate => {
    blankSlate.style.display = display;
  });
}

function markLastMatchedTrip(scheduleEl) {
  const legs = [... scheduleEl.getElementsByClassName("schedules__trips--leg")];
  legs.forEach(leg => {
    const matchedTrips = [... leg.querySelectorAll("li[data-matched='true']")];
    if (matchedTrips.length === 0) {
      return;
    }
    matchedTrips.forEach(trip => trip.setAttribute("data-last-match", "false"));
    const lastMatchedTrip = matchedTrips.slice(-1)[0];
    lastMatchedTrip.setAttribute("data-last-match", "true");
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
  markLastMatchedTrip(scheduleEl);
  matchedTrips == 0 ? toggleBlankSlate(scheduleEl, "block") : toggleBlankSlate(scheduleEl, "none");
}

export default (pubSub) => {
  pubSub.subscribe("time-change", e => {
    const scheduleEl = document.getElementById(`schedule_${e.mode}`);
    processSchedule(scheduleEl);
  });

  const scheduleWidgets = [... document.querySelectorAll("div[data-type='schedule-viewer']")];
  scheduleWidgets.forEach((scheduleEl) => {
    scheduleEl.style.display = "block";
    processSchedule(scheduleEl);
  });
};
