import flatpickr from "flatpickr";

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

      document
        .getElementById(instance.element.id)
        .setAttribute("value", dateStr);

      pubsub.publishSync("time-change", {
        mode: mode
      });
    }
  };

  [...document.querySelectorAll("input[data-type='time']")].forEach(input => {
    flatpickr(input, config);
  });
};
