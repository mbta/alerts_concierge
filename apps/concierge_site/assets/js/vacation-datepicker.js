const flatpickr = require("flatpickr");
const moment = require("moment");

export default function($) {
  $ = $ || window.jQuery;

  const flatpickrBaseConfig = {
    allowInput: true,
    altFormat: "m/d/Y",
    altInput: true,
    dateFormat: "m/d/Y"
  };

  const now = moment().format("MM/DD/Y");

  const vacationStartConfig = Object.assign({}, flatpickrBaseConfig, {
    defaultDate: now
  });

  const vacationEndConfig = Object.assign({}, flatpickrBaseConfig, {
    defaultDate: moment().add(7, "days").format("MM/DD/Y"),
    minDate: now
  });

  flatpickr("#user_vacation_start", vacationStartConfig);
  flatpickr("#user_vacation_end", vacationEndConfig);
}
