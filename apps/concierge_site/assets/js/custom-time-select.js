import flatpickr from "flatpickr";
import { timeToInt, timeFromInt } from "time-number";

const oneHourInSeconds = 3600;
const oneDayInSeconds = 86400;

// when the user is changing the start time, shift the end time 1 hour forward when the times are the same
const shiftEndTime = e => {
  const startTimeEl = e.changedEl;
  const startTimeElId = startTimeEl.getAttribute("id");
  const isStartTime = startTimeElId.indexOf("_start_time") != -1 ? true : false;
  if (!isStartTime) {
    return;
  }

  const endTimeElId = startTimeElId.replace("_start_time", "_end_time");
  const endTimeEl = document.getElementById(endTimeElId);
  const startTime = startTimeEl.value.trim();
  const endTime = endTimeEl.value.trim();

  if (startTime != endTime) {
    return;
  }

  const startTimeInSeconds = timeToInt(startTime);
  const newEndTimeInSeconds =
    startTimeInSeconds + oneHourInSeconds > oneDayInSeconds - 1
      ? 0
      : startTimeInSeconds + oneHourInSeconds;
  endTimeEl.value = timeFromInt(newEndTimeInSeconds, {
    format: 12,
    leadingZero: false
  });
};

export default pubsub => {
  const config = {
    enableTime: true,
    noCalendar: true,
    dateFormat: "h:i K",
    time_24hr: false,
    minuteIncrement: 15,
    onChange: (selectedDates, dateStr, instance) => {
      const mode =
        instance.element.id == "trip_return_start_time" ||
        instance.element.id == "trip_return_end_time"
          ? "return"
          : "start";

      const changedEl = document.getElementById(instance.element.id);

      pubsub.publishSync("time-change", {
        mode: mode,
        changedEl: changedEl
      });
    }
  };

  pubsub.subscribe("time-change", shiftEndTime);

  [...document.querySelectorAll("input[data-type='time']")].forEach(input => {
    flatpickr(input, Object.assign({}, config, {appendTo: input.parentNode}));
  });
};
