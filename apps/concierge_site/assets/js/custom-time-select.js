import { timeToInt, timeFromInt } from "time-number";

const oneHourInSeconds = 3600;
const oneDayInSeconds = 86400;

const timeBaseId = id => id.match(/^.+_time/)[0];
const hourEl = baseId => document.getElementById(`${baseId}_hour`);
const minuteEl = baseId => document.getElementById(`${baseId}_minute`);
const amPmEl = baseId => document.getElementById(`${baseId}_am_pm`);

const parseTime = id => {
  const baseId = timeBaseId(id);
  const hour = hourEl(baseId).value;
  const minute = minuteEl(baseId).value;
  const amPm = amPmEl(baseId).value;

  return timeToInt(`${hour}:${minute} ${amPm}`)
}

const setTime = (id, timeInSeconds) => {
  const baseId = timeBaseId(id);
  const time = timeFromInt(timeInSeconds, {
    format: 12,
    leadingZero: false
  });
  const [_match, hour, minute, amPm] = time.match(/(\d+):(\d+) ([AP]M)/);

  hourEl(baseId).value = parseInt(hour);
  minuteEl(baseId).value = parseInt(minute);
  amPmEl(baseId).value = amPm;
}

// when the user is changing the start time, shift the end time 1 hour forward when the start time is equal to or greater than the end time
const shiftEndTime = e => {
  const startTimeEl = e.changedEl;
  const startTimeElId = startTimeEl.getAttribute("id");
  const isStartTime = startTimeElId.indexOf("_start_time") != -1 ? true : false;
  if (!isStartTime) return;

  const endTimeElId = startTimeElId.replace("_start_time", "_end_time");
  const endTimeEl = document.getElementById(endTimeElId);
  const startTimeInSeconds = parseTime(startTimeElId);
  const endTimeInSeconds = parseTime(endTimeElId);
  if (startTimeInSeconds < endTimeInSeconds) return;

  const newEndTimeInSeconds =
    startTimeInSeconds + oneHourInSeconds > oneDayInSeconds - 1
      ? 0
      : startTimeInSeconds + oneHourInSeconds;
  setTime(endTimeElId, newEndTimeInSeconds);
};

export default pubsub => {
  [...document.querySelectorAll("select[data-type='time']")].forEach(select =>
    select.onchange = event => {
      const changedEl = event.target;
      const mode = (changedEl.id.startsWith("trip_return")) ? "return" : "start";

      pubsub.publishSync("time-change", { changedEl, mode });
    });

  pubsub.subscribe("time-change", shiftEndTime);
};
