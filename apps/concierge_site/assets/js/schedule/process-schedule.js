import elemDataset from "elem-dataset";
import { checkItem, unCheckItem } from "./handle-trip-change";

const makeDate = timeString => new Date(`1/1/2000 ${timeString}`);

function isMatched(tripTime, startTime, endTime) {
  const tripDate = makeDate(tripTime);
  if (!(tripDate instanceof Date)) {
    return false;
  }
  const startDate = makeDate(startTime);
  const endDate = makeDate(endTime);
  return tripDate >= startDate && tripDate <= endDate;
}

function processTrip(
  tripEl,
  startTime,
  endTime,
  travelStartTime,
  travelEndTime
) {
  const dataset = elemDataset(tripEl);
  const tripTime = dataset.time;
  const matched = isMatched(tripTime, startTime, endTime);
  tripEl.style.display = matched ? "block" : "none";
  tripEl.setAttribute("data-matched", matched ? "true" : "false");
  if (
    travelStartTime &&
    travelEndTime &&
    isMatched(tripTime, travelStartTime, travelEndTime)
  ) {
    checkItem(tripEl);
  }
  // if the user has changes the time such that a time is no longer listed, the checkbox should be cleared
  if (!matched) {
    unCheckItem(tripEl);
  }
  return matched ? 1 : 0;
}

function toggleBlankSlate(scheduleEl, display) {
  const blankSlates = [
    ...scheduleEl.getElementsByClassName("schedules__blankslate")
  ];
  blankSlates.forEach(blankSlate => {
    blankSlate.style.display = display;
  });
  const containers = [
    ...scheduleEl.getElementsByClassName("schedules__trips--container")
  ];
  containers.forEach(container => {
    container.style.display = display === "block" ? "none" : "block";
  });
}

function markLastMatchedTrip(scheduleEl) {
  const legs = [...scheduleEl.getElementsByClassName("schedules__trips--leg")];
  legs.forEach(leg => {
    const matchedTrips = [...leg.querySelectorAll("li[data-matched='true']")];
    if (matchedTrips.length === 0) {
      return;
    }
    matchedTrips.forEach(trip => trip.setAttribute("data-last-match", "false"));
    const lastMatchedTrip = matchedTrips.slice(-1)[0];
    lastMatchedTrip.setAttribute("data-last-match", "true");
  });
}

function setAllVisibleToChecked(trips) {
  trips
    .filter(tripEl => tripEl.getAttribute("data-matched") === "true")
    .forEach(tripEl => checkItem(tripEl));
}

export function processSchedule(scheduleEl, showDefaultTravelTimes) {
  const scheduleDataset = elemDataset(scheduleEl);
  const startTime = document.getElementById(scheduleDataset.start).value;
  const endTime = document.getElementById(scheduleDataset.end).value;
  const legs = [
    ...scheduleEl.querySelectorAll("div[data-type='schedule-leg']")
  ];
  legs.forEach(legEl => {
    const legDataset =
      showDefaultTravelTimes === true ? elemDataset(legEl) : {};
    const trips = [...legEl.getElementsByClassName("schedules__trips--item")];
    trips.forEach((tripEl, index) =>
      tripEl.setAttribute("data-position", index)
    );
    const matchedTrips = trips.reduce((count, tripEl) => {
      return (
        count +
        processTrip(
          tripEl,
          startTime,
          endTime,
          legDataset.travelStartTime,
          legDataset.travelEndTime
        )
      );
    }, 0);
    markLastMatchedTrip(scheduleEl);
    matchedTrips === 0
      ? toggleBlankSlate(legEl, "block")
      : toggleBlankSlate(legEl, "none");
    if (matchedTrips === 1) {
      setAllVisibleToChecked(trips);
    }
  });
}
