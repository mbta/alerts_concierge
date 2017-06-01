export default function($) {
  $ = $ || window.jQuery;

  function typeahead(event) {
    const query = event.target.value;
    const station = event.data.station;
    const $suggestions = $(`.${station}-station-suggestion`)

    $suggestions.addClass("hidden");

    if (query.length > 0) {
      const queryRegExp = new RegExp(query, "i");
      const stationElements = $suggestions.get();
      const matchingStations = Array.prototype.filter.call(
        stationElements,
        function(stationElement) {
          return stationElement.innerText.match(queryRegExp);
        }
      );

      $(matchingStations).removeClass("hidden");
    }
  }

  function assignSuggestion() {
    const stationName = $(".station-name", $(this)).text();
    const $stationInput = $(".station-input", $(this).parent()).first();

    $stationInput.val(stationName);

    $( ".station-suggestion" ).addClass("hidden");
  }

  function pickFirstSuggestion(event) {
    const station = event.data.station;
    const $stationInput = $(`.subscription-select-${station}`);
    const $firstSuggestion = $(`.${station}-station-suggestion:visible`).first();

    if ($firstSuggestion.length) {
      const stationName = $(".station-name", $firstSuggestion).text();
      $stationInput.val(stationName);
    }

    $( ".station-suggestion" ).addClass("hidden");
  }

  $(document).on(
    "keyup", ".subscription-select-origin", { station: "origin" }, typeahead);
  $(document).on(
    "keyup", ".subscription-select-destination", { station: "destination" }, typeahead);
  $(document).on(
    "focusout", ".subscription-select-origin", { station: "origin" }, pickFirstSuggestion);
  $(document).on(
    "focusout", ".subscription-select-destination", { station: "destination" }, pickFirstSuggestion);
  $(document).on("mousedown", ".station-suggestion", assignSuggestion);
}
