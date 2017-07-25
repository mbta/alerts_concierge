const flatpickr = require("flatpickr");

export default function($) {
  $ = $ || window.jQuery;

  const flatpickrConfig = {
    dateFormat: "Y-m-dT00:00:00+00:00",
    altInput: true
  };

  flatpickr("#user_vacation_start", flatpickrConfig);
  flatpickr("#user_vacation_end", flatpickrConfig);
}
