import filterSuggestions from './filter-suggestions';

export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {
    selectableStations: [],
    selectedStations: []
  };

  if ($(".enter-trip-info").length) {
    props.allRoutes = generateRouteList();
    props.allStations = generateStationList();
    props.validStationNames = props.allStations.map(station => station.name);
    state.selectableStations = props.validStationNames;
    attachSuggestionInput();
  }

  function attachSuggestionInput() {
    $("label[for='station']").after(renderRouteInput());
  }

  function renderRouteInput() {
    return `
      <input type="text" name="station" placeholder="Enter a station" class="subscription-select subscription-select-amenity-station station-input" autocomplete="off"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
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
      unmountStationSuggestions();
    }
  }

  function unmountStationSuggestions() {
    $(`.amenity-station`).remove();
  }

  function generateRouteList() {
    let routes = {};
    const $optgroups = $("select.subscription-select-amenity-station optgroup");

    $optgroups.each(function(_i, group) {
      const options = $("option", group).map(function(i, option) {
        return option.text;
      }).get();
      const routeName = group.label;
      routes[routeName] = options;
    });
    return routes;
  }

  function generateStationList() {
    let stations = [];
    const $optgroups = $("select.subscription-select-amenity-station optgroup");

    $optgroups.each(function(_i, group) {
      const $options = $("option", group);
      $options.each(function(_i, option) {
        const alreadyAddedStation = stations.find(function(station) {
          return station.name === option.text;
        });
        if (alreadyAddedStation) {
          alreadyAddedStation.allLineNames.push(group.label)
        } else {
          const station = {
            name: option.text,
            id: option.value,
            allLineNames: [group.label]
          };
          stations.push(station);
        }
      });
    });
    return stations;
  }

  function assignSuggestion(event) {
    const stationName = $(event.target).text().trim();
    const $stationSelect = $(".subscription-select-amenity-station");
    const $stationListContainer = $('.selected-station-list.amenity-station-list');
    const station = renderStation(stationName);
    $stationListContainer.append(station);

    removeStationFromOptions(stationName);
    $stationSelect.val("");
    unmountStationSuggestions();
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

  $(".trip-info-form.amenities").submit(setStopsValue);
  $(document).on(
    "keyup", ".subscription-select-amenity-station", {}, typeahead);
  $(document).on(
    "mousedown", ".amenity-station", {}, assignSuggestion);
  $(document).on(
    "mousedown", ".btn-selected-station", {}, removeStation);
  $(document).on(
    "focusout", ".subscription-select-amenity-station", {}, unmountStationSuggestions);
}
