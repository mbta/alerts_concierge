import filterSuggestions from './filter-suggestions';
import {generateRouteList, generateStationList, renderStationInput, unmountStationSuggestions} from './station-select-helpers';

export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {
    selectableStations: [],
    selectedStations: []
  };

  if ($(".enter-trip-info").length) {
    const className = "select.subscription-select-amenity-station";
    props.allRoutes = generateRouteList(className, $);
    props.allStations = generateStationList(className, $);
    props.validStationNames = props.allStations.map(station => station.name);
    state.selectableStations = props.validStationNames;
    attachSuggestionInput();
  }

  function attachSuggestionInput() {
    $("label[for='station']").after(renderStationInput("station", "subscription-select-amenity-station station-input"));
  }

  function renderRouteSuggestion(route) {
    return `
      <div class="station-suggestion amenity-station">
        <span class="station-name">${route}</span>
      </div>
    `
  }

  function typeahead(event) {
    const query = event.target.value;
    if (query.length > 0) {
      const matchingRoutes = filterSuggestions(query, state.selectableStations);
      const suggestionElements = matchingRoutes.map(function(route) {
        return renderRouteSuggestion(route);
      });

      const $suggestionContainer = $('.suggestion-container');
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountStationSuggestions(".amenity-station", $);
    }
  }

  function assignSuggestion(event) {
    const stationName = $(event.target).text().trim();
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
    state.selectedStations
    .splice(state.selectableStations.indexOf(stationName), 1);

    state.selectableStations.push(stationName);
  };

  function renderStation(stationName) {
    return `<button class="btn btn-primary btn-selected-station" type="button">${stationName}</button>`
  }

  function removeStation(event) {
    const stationName = event.target.textContent;
    removeStationFromSelected(stationName);
    event.currentTarget.remove();
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
