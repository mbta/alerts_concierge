const flatpickr = require("flatpickr");

export default function($) {
  $ = $ || window.jQuery;

  const $vacationStartInput = $("#user_vacation_start");
  const $vacationEndInput = $("#user_vacation_end");
  
  $vacationStartInput.after("<div class='vacation-start-display'></div>");
  $vacationStartInput.css("display", "none");
  $vacationEndInput.after("<div class='vacation-end-display'></div>");
  $vacationEndInput.css("display", "none");

  const setVacationDates = function(selectedDates, dateStr, instance) {
    $vacationStartInput.val(selectedDates[0].toISOString());
    $(".vacation-start-display").text(selectedDates[0].toLocaleDateString());
    if (selectedDates[1]) {
      $vacationEndInput.val(selectedDates[1].toISOString());
      $(".vacation-end-display").text(selectedDates[1].toLocaleDateString());
    }
  }

  const flatpickrConfig = {
    dateFormat: "Y-m-dT00:00:00+00:00",
    mode: "range",
    onChange: setVacationDates
  };
  const datePicker = flatpickr(".vacation-datepicker", flatpickrConfig);

  $(document).on("click", ".vacation-date-form-section", function() {
    datePicker.open();
  });
}
