import flatpickr from "flatpickr";

const config = {
  enableTime: true,
  noCalendar: true,
  dateFormat: "h:i K",
  time_24hr: false,
  minuteIncrement: 15
};

export default () => {
  [...document.querySelectorAll("input[data-type='time']")].forEach(input => {
    flatpickr(input, config);
  })
};