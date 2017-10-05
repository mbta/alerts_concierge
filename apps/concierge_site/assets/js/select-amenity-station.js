import filterSuggestions from './filter-suggestions';
import {
  generateStationList,
  onKeyDownOverridesAmenity,
  renderStationInput,
  selectedSuggestionClass,
  unmountStationSuggestions
} from './station-select-helpers';

export default function($) {
  $ = $ || window.jQuery;

  let state = {
    selectableStations: [],
    selectedStations: [],
    selectedSuggestionIndex: 0,
  };

  if ($(".trip-info-form.amenities").length) {
    setSelectedStations();
    attachSuggestionInput();

    document.onkeydown = function(event){
      onKeyDownOverridesAmenity(event, state, chooseSuggestion, removeStation, $);
    }
  } else {
    return;
  }

  function setSelectedStations() {
    const selectedStops = $(".subscription-amenities-stops").val();
    if (selectedStops) {
      state.selectedStations = selectedStops.split(",");
    }

    const className = "select.subscription-select-amenity-station";
    const stations = generateStationList(className, $).map(station => station.name);
    state.selectableStations = stations
      .slice(1, stations.length)
      .filter(stationName => !state.selectedStations.includes(stationName));
  }

  function attachSuggestionInput() {
    $(".amenity-station-select-sub-label").after(renderStationInput("station", "subscription-select-amenity-station station-input", ""));
  }

  function renderRouteSuggestion(route, index) {
    return `
      <div class="station-suggestion amenity-station ${selectedSuggestionClass(state.selectedSuggestionIndex, index)}">
        <span class="station-name">${route}</span>
      </div>
    `
  }

  function typeahead(event) {
    const query = event.target.value;
    if (query.length > 0) {
      const matchingRoutes = filterSuggestions(query, state.selectableStations);
      const suggestionElements = matchingRoutes.map(function(route, index) {
        return renderRouteSuggestion(route, index);
      });

      const $suggestionContainer = $('.suggestion-container');
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountStationSuggestions(".amenity-station", $);
    }
  }

  function chooseSuggestion() {
    state.selectedSuggestionIndex = 0;
    const $routeInput = $('.subscription-select-route');
    const $selectedSuggestion = $(".selected-suggestion").first();

    if ($selectedSuggestion.length) {
      const stationName = $selectedSuggestion.text().trim();
      const $stationSelect = $(".subscription-select-amenity-station");
      const $stationListContainer = $('.selected-station-list.amenity-station-list');
      const station = renderStation(stationName);
      $stationListContainer.append(station);

      removeStationFromOptions(stationName);
      $stationSelect.val("");
      unmountStationSuggestions(".amenity-station", $);
    }
  }

  function assignSuggestion(event) {
    const stationName = event.target.textContent.trim();
    const $stationSelect = $(".subscription-select-amenity-station");
    const $stationListContainer = $('.selected-station-list.amenity-station-list');
    const station = renderStation(stationName);
    $stationListContainer.append(station);

    removeStationFromOptions(stationName);
    $stationSelect.val("");
    unmountStationSuggestions(".amenity-station", $);
  }

  function removeStationFromOptions(stationName) {
    state.selectableStations
    .splice(state.selectableStations.indexOf(stationName), 1);

    state.selectedStations.push(stationName);
  }

  function removeStationFromSelected(stationName) {
    state.selectedStations.splice(state.selectedStations.indexOf(stationName), 1);
    state.selectableStations.push(stationName);
  };

  function renderStation(stationName) {
    return `<button class="btn btn-sm btn-selected-station" type="button"><span>${stationName}</span>&nbsp;<i class="fa fa-times" aria-hidden="true"></i></button>`
  }

  function removeStation(event) {
    let button = $(event.target).closest("button")
    removeStationFromSelected(button.text().trim());
    button.remove();
  }

  function setStopsValue() {
    const stops = state.selectedStations.join(',');
    const $stopsInput = $('.subscription-amenities-stops')
    $stopsInput.val(stops);
    return true;
  }

  function unmountSuggestions() {
    unmountStationSuggestions(".amenity-station", $);
  }

  $(".trip-info-form.amenities").submit(setStopsValue);
  $(document).on(
    "keyup", ".subscription-select-amenity-station", {}, typeahead);
  $(document).on(
    "mousedown", ".amenity-station", {}, assignSuggestion);
  $(document).on(
    "mousedown", ".btn-selected-station", {}, removeStation);
  $(document).on(
    "focusout", ".subscription-select-amenity-station", {ha: "ha"}, unmountSuggestions);
}
