import { handleTripChange } from "./schedule/handle-trip-change";
import { processSchedule } from "./schedule/process-schedule";

export default pubSub => {
  // subscribe to the time change event
  pubSub.subscribe("time-change", e => {
    const scheduleEl = document.getElementById(`schedule_${e.mode}`);
    processSchedule(scheduleEl, false);
  });

  // subscribe to the day change event
  pubSub.subscribe("day-change", e => {
    // reconsider each schedule block
    [...document.querySelectorAll("div[data-type='schedule-viewer']")].forEach(
      scheduleEl => processSchedule(scheduleEl, false)
    )
  });

  // subscribe to checkbox change event
  pubSub.subscribe("checkbox-change", e => handleTripChange(e));

  // show each schedule block
  [...document.querySelectorAll("div[data-type='schedule-viewer']")].forEach(
    scheduleEl => {
      scheduleEl.style.display = "block";
      processSchedule(scheduleEl, true);
    }
  );
};
