export default function($) {
  $ = $ || window.jQuery;

  let props = {};

  function typeahead(event) {
    const query = event.target.value;
    const originDestination = event.data.originDestination;
    const $suggestionContainer =
      $(`.subscription-select-${originDestination} + .suggestion-container`);

    if (query.length > 0) {
      const queryRegExp = new RegExp(query, "i");
      const matchingStations = props.allStations.filter(function(station) {
        return station.name.match(queryRegExp);
      })

      const suggestionElements = matchingStations.map(function(station) {
        return renderStationOption(originDestination, station);
      });

      $suggestionContainer.html(suggestionElements);
    } else {
      $(`.${originDestination}-station-suggestion`).remove();
    }
  }

  function assignSuggestion(event) {
    const originDestination = event.data.originDestination;
    const stationName = $(".station-name", $(this)).text();
    const $stationInput = $(`.subscription-select-${originDestination}`);

    $stationInput.val(stationName);

    $( `.${originDestination}-station-suggestion` ).remove();
  }

  function pickFirstSuggestion(event) {
    const originDestination = event.data.originDestination;
    const $stationInput = $(`.subscription-select-${originDestination}`);
    const $firstSuggestion =
      $(`.${originDestination}-station-suggestion`).first();

    if ($firstSuggestion.length) {
      const stationName = $(".station-name", $firstSuggestion).text();
      $stationInput.val(stationName);
    }

    $(`.${originDestination}-station-suggestion`).remove();
  }

  function generateStationList() {
    let stations = [];
    const optgroups =
      document.querySelectorAll("select.subscription-select-origin optgroup");

    optgroups.forEach(function(group) {
      const options = group.querySelectorAll("option");

      options.forEach(function(option) {
        const alreadyAddedStation = stations.find(function(station) {
          return station.name === option.innerText;
        });

        if (alreadyAddedStation) {
          alreadyAddedStation.allLineNames.push(group.label)
        } else {
          const station = {
            name: option.innerText,
            code: option.value,
            allLineNames: [group.label]
          };

          stations.push(station);
        }
      });
    });

    return stations;
  }

  function attachSuggestionInputs() {
    $("label[for='origin']").after(renderStationInput("origin"));
    $("label[for='destination']").after(renderStationInput("destination"));
  }

  function renderStationInput(originDestination) {
    return `
      <input type="text" name="${originDestination}" placeholder="Enter a station" class="subscription-select-${originDestination} station-input" />
      <div class="suggestion-container"></div>
    `
  }

  function renderStationOption(originDestination, station) {
    const stationClass = `${originDestination}-station-suggestion`;
    const lineNames = compactLineNames(station.allLineNames);
    const circleIcons = lineNames.map(renderCircleIcon).join("");

    return `
      <div class="${stationClass} station-suggestion">
        <div class="station-name">${station.name}</div>
        <div class="station-lines">
          ${circleIcons}
        </div>
      </div>
    `
  }

  function renderCircleIcon(lineName) {
    return `
      <svg class="icon-with-circle" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 42 42" title="${lineName}" preserveAspectRatio="xMidYMid meet">
        <circle r="20" cx="20" cy="20" class="icon-${lineName.toLowerCase()}-line-circle" transform="translate(1,1)"></circle>
        <g fill-rule="evenodd" class="icon-image" transform="translate(8,11) scale(1)">
          <path d="M0,0 l0,7 l9,0 l0,15.5 l7,0 l0,-15.5 l9,0 l0,-7 Z">
        </path></g>
      </svg>
      <div class="line-name">${lineName}</div>
    `
  }

  function compactLineNames(lineNames) {
    let lines = [];

    lineNames.forEach(function(name) {
      const displayName = name.split("-")[0]

      if (!lines.includes(displayName)) {
        lines.push(displayName);
      }
    });

    return lines;
  }

  $(document).ready(function() {
    if ($(".enter-trip-info").length) {
      attachSuggestionInputs();
      props.allStations = generateStationList();
    }
  });

  $(document).on(
    "keyup", ".subscription-select-origin", { originDestination: "origin" }, typeahead);
  $(document).on(
    "keyup", ".subscription-select-destination", { originDestination: "destination" }, typeahead);
  $(document).on(
    "focusout", ".subscription-select-origin", { originDestination: "origin" }, pickFirstSuggestion);
  $(document).on(
    "focusout", ".subscription-select-destination", { originDestination: "destination" }, pickFirstSuggestion);
  $(document).on(
    "mousedown", ".origin-station-suggestion", { originDestination: "origin" }, assignSuggestion);
  $(document).on(
    "mousedown", ".destination-station-suggestion", { originDestination: "destination" }, assignSuggestion);
}
