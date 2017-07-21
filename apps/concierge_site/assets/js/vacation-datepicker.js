const flatpickr = require("flatpickr");

export default function($) {
  $ = $ || window.jQuery;

  $("#user_vacation_start").after("<div class='vacation-start-display'></div>");
  $("#user_vacation_start").css("display", "none");
  $("#user_vacation_end").after("<div class='vacation-end-display'></div>");
  $("#user_vacation_end").css("display", "none");

  const setVacationDates = function(selectedDates, dateStr, instance) {
    $("#user_vacation_start").val(selectedDates[0].toISOString());
    $(".vacation-start-display").text(selectedDates[0].toLocaleDateString());
    if (selectedDates[1]) {
      $("#user_vacation_end").val(selectedDates[1].toISOString());
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
