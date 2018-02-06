const flatpickr = require("flatpickr");
const moment = require("moment");
const objectAssign = require('object-assign');

export default function($) {
  $ = $ || window.jQuery;

  const flatpickrBaseConfig = {
    allowInput: true,
    altFormat: "m/d/Y",
    altInput: true,
    dateFormat: "m/d/Y"
  };

  const now = moment().format("MM/DD/Y");

  const vacationStartConfig = objectAssign({}, flatpickrBaseConfig, {
    defaultDate: now,
    minDate: now
  });

  const vacationEndConfig = objectAssign({}, flatpickrBaseConfig, {
    defaultDate: moment().add(7, "days").format("MM/DD/Y"),
    minDate: now
  });

  const vacationStartDatepicker =
    flatpickr("#user_vacation_start", vacationStartConfig);
  const vacationEndDatepicker =
    flatpickr("#user_vacation_end", vacationEndConfig);

  function openDatepicker() {
    const datepickerId = $(this).data("datepicker");
    const datepicker = $(datepickerId)[0]._flatpickr;
    datepicker.open();
  }

  $(document).on("click", "[data-datepicker]", openDatepicker)
}
