const flatpickr = require("flatpickr");
const moment = require("moment");

export default function($) {
  $ = $ || window.jQuery;

  const flatpickrBaseConfig = {
    altInput: true,
    dateFormat: "Y-m-dT00:00:00+00:00"
  };

  const now = moment().format();
  const vacationStartConfig = Object.assign({}, flatpickrBaseConfig, {
    defaultDate: now
  });

  const vacationEndConfig = Object.assign({}, flatpickrBaseConfig, {
    defaultDate: moment().add(7, "days").format(),
    minDate: now
  });

  flatpickr("#user_vacation_start", vacationStartConfig);
  flatpickr("#user_vacation_end", vacationEndConfig);

}
