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
    selectableEntities: [],
    selectedEntities: [],
    selectedSuggestionIndex: 0,
  };

  if ($(".trip-info-form.multi-select-form").length) {
    setSelectedEntities();
    attachSuggestionInput();

    document.onkeydown = function(event){
      onKeyDownOverridesAmenity(event, state, chooseSuggestion, removeStation, $);
    }
  } else {
    return;
  }

  function setSelectedEntities() {
    const selectedStops = $(".selected-subscription-entities").val();
    const selectedStopIds = selectedStops.split(",");
    const className = "select.subscription-select";
    const entities = generateStationList(className, $);

    if (selectedStops) {
      state.selectedEntities = entities.filter((entity) => selectedStopIds.includes(entity.id));
    }

    state.selectableEntities = entities.filter((entity) => !selectedStopIds.includes(entity.id));
  }

  function attachSuggestionInput() {
    const inputEntityType = $(".subscription-select").data("entity-type");

    $(".entity-select-sub-label").after(renderStationInput(inputEntityType, "subscription-select-entity-input", ""));
  }

  function renderRouteSuggestion(route, index) {
    return `
      <div class="station-suggestion bus-route ${selectedSuggestionClass(state.selectedSuggestionIndex, index)}">
        <span class="entity-name">${route}</span>
        ${renderBusIcon()}</span>
      </div>
    `
  }

  function renderBusIcon() {
    return `
      <span class="route-logo" style="padding-right: 10px;">
        <svg aria-hidden="false" class="icon icon-with-circle icon-bus " version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 42 42" data-toggle="tooltip" title="" preserveAspectRatio="xMidYMid meet" data-original-title="Bus">
          <circle r="20" cx="20" cy="20" class="icon-circle icon-bus-circle" fill="#ffce0c" transform="translate(1,1)"></circle>
          <g fill-rule="evenodd" class="icon-image icon-bus-image" style="fill: #000;" transform="translate(4,5) scale(1.4)">
            <path d="M15.0000409,19 L8.99995829,19 C8.99503143,19.5531447 8.55421988,20 8.00104344,20 L6.99895656,20 C6.45028851,20 6.00493267,19.5615199 6.00004069,18.9999777 C5.44710715,18.996349 5,18.5507824 5,17.9975592 L5,17.5024408 C5,16.948808 5,16.0551184 5,15.4982026 L5,5.00179743 C5,4.44851999 5.44994876,4 6.00684547,4 L17.9931545,4 C18.5492199,4 19,4.44488162 19,5.00179743 L19,15.4982026 C19,16.05148 19,16.9469499 19,17.5024408 L19,17.9975592 C19,18.5489355 18.5537115,18.9963398 17.9999585,18.9999777 C17.9950433,19.5531326 17.5542273,20 17.0010434,20 L15.9989566,20 C15.4502958,20 15.0049445,19.5615315 15.0000409,19 Z M13,8 L18,8 L18,14 L13,14 L13,8 Z M6,8 L11,8 L11,14 L6,14 L6,8 Z M8,5 L16,5 L16,7 L8,7 L8,5 Z M16,16 C16,15.4477153 16.4438648,15 17,15 C17.5522847,15 18,15.4438648 18,16 C18,16.5522847 17.5561352,17 17,17 C16.4477153,17 16,16.5561352 16,16 Z M13,16 C13,15.4477153 13.4438648,15 14,15 C14.5522847,15 15,15.4438648 15,16 C15,16.5522847 14.5561352,17 14,17 C13.4477153,17 13,16.5561352 13,16 Z M9,16 C9,15.4477153 9.44386482,15 10,15 C10.5522847,15 11,15.4438648 11,16 C11,16.5522847 10.5561352,17 10,17 C9.44771525,17 9,16.5561352 9,16 Z M6,16 C6,15.4477153 6.44386482,15 7,15 C7.55228475,15 8,15.4438648 8,16 C8,16.5522847 7.55613518,17 7,17 C6.44771525,17 6,16.5561352 6,16 Z">
          </path></g>
        </svg>
      </span>
    `
  }

  function renderEntitySuggestion(entity, index) {
    const form = $(".trip-info-form");
    let svg = "";
    if (form.hasClass("bus")) {
      svg = renderBusIcon()
    }
    return `
      <div class="entity-suggestion ${selectedSuggestionClass(state.selectedSuggestionIndex, index)}">
        <span class="entity-name">${entity.name}</span>
        ${svg}
      </div>
    `
  }

  function typeahead(event) {
    const query = event.target.value;
    if (query.length > 0) {
      const matchingEntities = filterSuggestions(query, state.selectableEntities, "name");
      const suggestionElements = matchingEntities.map(function(entity, index) {
        return renderEntitySuggestion(entity, index);
      });

      const $suggestionContainer = $('.suggestion-container');
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountStationSuggestions(".entity-suggestion", $);
    }
  }

  function chooseSuggestion() {
    state.selectedSuggestionIndex = 0;
    const $selectedSuggestion = $(".selected-suggestion").first();

    if ($selectedSuggestion.length) {
      const stationName = $selectedSuggestion.text().trim();
      const $stationSelect = $(".subscription-select-entity-input");
      const $stationListContainer = $('.selected-entity-list');
      const station = renderEntity(stationName);
      $stationListContainer.append(station);

      removeStationFromOptions(stationName);
      $stationSelect.val("");
      unmountStationSuggestions(".entity-suggestion", $);
    }
  }

  function assignSuggestion(event) {
    const stationName = event.target.textContent.trim();
    const $stationSelect = $(".subscription-select-entity");
    const $stationListContainer = $('.selected-entity-list');
    const station = renderEntity(stationName);
    $stationListContainer.append(station);

    removeStationFromOptions(stationName);
    $stationSelect.val("");
    unmountStationSuggestions(".entity-suggestion", $);
  }

  function removeStationFromOptions(stationName) {
    const station = state.selectableEntities.splice(state.selectableEntities.map((station) => station.name).indexOf(stationName), 1);

    state.selectedEntities.push(station[0]);
  }

  function removeStationFromSelected(stationName) {
    const station = state.selectedEntities.splice(state.selectedEntities.map((station) => station.name).indexOf(stationName), 1);

    state.selectableEntities.push(station[0]);
  };

  function renderEntity(entityName) {
    return `<button class="btn btn-sm btn-selected-entity" type="button"><span>${entityName}</span>&nbsp;<i class="fa fa-times" aria-hidden="true"></i></button>`
  }

  function removeStation(event) {
    let button = $(event.target).closest("button")
    removeStationFromSelected(button.text().trim());
    button.remove();
  }

  function setStopsValue() {
    const stops = state.selectedEntities.map((station) => station.id).join(',');
    const $stopsInput = $('.selected-subscription-entities')
    $stopsInput.val(stops);
    return true;
  }

  function unmountSuggestions() {
    unmountStationSuggestions(".entity-suggestion", $);
  }

  $(".trip-info-form.multi-select-form").submit(setStopsValue);
  $(document).on(
    "keyup", ".subscription-select-entity-input", {}, typeahead);
  $(document).on(
    "mousedown", ".entity-suggestion", {}, assignSuggestion);
  $(document).on(
    "mousedown", ".btn-selected-entity", {}, removeStation);
  $(document).on(
    "focusout", ".subscription-select-entity-input", {}, unmountSuggestions);
}
