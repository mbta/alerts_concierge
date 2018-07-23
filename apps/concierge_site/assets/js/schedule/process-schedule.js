import elemDataset from "elem-dataset";
import { checkItem, unCheckItem } from "./handle-trip-change";

const makeDate = timeString => new Date(`1/1/2000 ${timeString}`);

function isTimeMatched(tripTime, startTime, endTime) {
  const tripDate = makeDate(tripTime);
  if (!(tripDate instanceof Date)) {
    return false;
  }
  const startDate = makeDate(startTime);
  const endDate = makeDate(endTime);
  return tripDate >= startDate && tripDate <= endDate;
}

function isDayMatched(dayType, weekday, weekend) {
  if (weekday && weekend) {
    // any day
    return true;
  } else if (!weekday && !weekend) {
    // no days selected
    return false;
  } else if (weekday && dayType === "weekday") {
    // weekdays
    return true;
  } else if (weekend && dayType === "weekend") {
    // weekend
    return true;
  } else {
    return false;
  }
}

function processTrip(
  tripEl,
  startTime,
  endTime,
  weekday,
  weekend,
  travelStartTime,
  travelEndTime
) {
  const dataset = elemDataset(tripEl);
  const tripTime = dataset.time;
  const dayType = dataset.weekend === "true" ? "weekend" : "weekday";
  const matched =
    isTimeMatched(tripTime, startTime, endTime) &&
    isDayMatched(dayType, weekday, weekend);
  tripEl.style.display = matched ? "block" : "none";
  tripEl.setAttribute("data-matched", matched ? "true" : "false");
  if (
    travelStartTime &&
    travelEndTime &&
    isTimeMatched(tripTime, travelStartTime, travelEndTime)
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

function markFirstAndLastMatchedTrip(legEl) {
  const matchedTrips = [...legEl.querySelectorAll("li[data-matched='true']")];
  if (matchedTrips.length === 0) {
    return;
  }
  matchedTrips.forEach(trip => trip.setAttribute("data-last-match", "false"));
  const lastMatchedTrip = matchedTrips.slice(-1)[0];
  lastMatchedTrip.setAttribute("data-last-match", "true");

  const firstMatchedTrip = matchedTrips.slice(0, 1)[0];
  firstMatchedTrip.setAttribute("data-first-match", "true");
}

function setAllVisibleToChecked(trips) {
  trips
    .filter(tripEl => tripEl.getAttribute("data-matched") === "true")
    .forEach(tripEl => checkItem(tripEl));
}

const weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday"];
const weekends = ["saturday", "sunday"];

const checkdDays = days =>
  days.reduce(
    (accumulator, day) =>
      accumulator === true
        ? true
        : document.querySelector(`input[value='${day}']`).checked,
    false
  );

const timeForTrip = (tripType) => {
  const hour = document.getElementById(`${tripType}_hour`).value;
  const minute = document.getElementById(`${tripType}_minute`).value;
  const amPm = document.getElementById(`${tripType}_am_pm`).value;

  return `${hour}:${minute} ${amPm}`;
};

export function processSchedule(scheduleEl, showDefaultTravelTimes) {
  const weekdaySelected = checkdDays(weekdays);
  const weekendSelected = checkdDays(weekends);
  const scheduleDataset = elemDataset(scheduleEl);
  const startTime = timeForTrip(scheduleDataset.start);
  const endTime = timeForTrip(scheduleDataset.end);
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
          weekdaySelected,
          weekendSelected,
          legDataset.travelStartTime,
          legDataset.travelEndTime
        )
      );
    }, 0);
    markFirstAndLastMatchedTrip(legEl);
    matchedTrips === 0
      ? toggleBlankSlate(legEl, "block")
      : toggleBlankSlate(legEl, "none");
    if (matchedTrips === 1) {
      setAllVisibleToChecked(trips);
    }
  });
}
