export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {};

  if ($(".enter-trip-info").length) {
    props.allStations = generateStationList();
    props.validStationNames = props.allStations.map(station => station.name);
    attachSuggestionInputs();
  }

  function typeahead(event) {
    const query = event.target.value;
    const originDestination = event.data.originDestination;

    if (query.length > 0) {
      const queryRegExp = new RegExp(query, "i");
      const matchingStations = props.allStations.filter(function(station) {
        return station.name.match(queryRegExp);
      })

      const suggestionElements = matchingStations.map(function(station) {
        return renderStationSuggestion(originDestination, station);
      });

      const $suggestionContainer =
        $(`.${subscriptionSelectClass(originDestination)} + .suggestion-container`);
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountStationSuggestions(originDestination);
    }
  }

  function validateStationInput(event) {
    const inputText = event.target.value;
    const originDestination = event.data.originDestination;
    const $stationInput = $(`.${subscriptionSelectClass(originDestination)}`);

    if (props.validStationNames.includes(event.target.value)) {
      $stationInput.attr("data-valid", true);
      setSelectedStation(originDestination, inputText, associatedLines(inputText))
    } else {
      $stationInput.attr("data-valid", false);
      clearSelectedStation(originDestination);
    }
  }

  function assignSuggestion(event) {
    const originDestination = event.data.originDestination;
    const stationName = $(".station-name", $(this)).text();
    const $stationInput = $(`.${subscriptionSelectClass(originDestination)}`);

    $stationInput.val(stationName);
    $stationInput.attr("data-valid", true);
    setSelectedStation(originDestination, stationName, $(this).attr("data-lines"));
    unmountStationSuggestions(originDestination);
  }

  function pickFirstSuggestion(event) {
    const originDestination = event.data.originDestination;
    const $stationInput = $(`.${subscriptionSelectClass(originDestination)}`);
    const $firstSuggestion =
      $(`.${originDestination}-station-suggestion`).first();

    if ($firstSuggestion.length) {
      const stationName = $(".station-name", $firstSuggestion).text();
      $stationInput.val(stationName);
      $stationInput.attr("data-valid", true);
      setSelectedStation(originDestination, stationName, $firstSuggestion.attr("data-lines"));
    }

    unmountStationSuggestions(originDestination);
  }

  function generateStationList() {
    let stations = [];
    const $optgroups = $("select.subscription-select-origin optgroup");

    $optgroups.each(function(_i, group) {
      const $options = $("option", group);

      $options.each(function(_i, option) {
        const alreadyAddedStation = stations.find(function(station) {
          return station.name === option.innerText;
        });

        if (alreadyAddedStation) {
          alreadyAddedStation.allLineNames.push(group.label)
        } else {
          const station = {
            name: option.text,
            code: option.value,
            allLineNames: [group.label]
          };

          stations.push(station);
        }
      });
    });
    return stations;
  }

  function unmountStationSuggestions(classPrefix) {
    $(`.${classPrefix}-station-suggestion`).remove();
  }

  function attachSuggestionInputs() {
    $("label[for='origin']").after(renderStationInput("origin"));
    $("label[for='destination']").after(renderStationInput("destination"));
  }

  function renderStationInput(originDestination) {
    return `
      <input type="text" name="${originDestination}" placeholder="Enter a station" class="${stationInputClass(originDestination)}"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
  }

  function renderStationSuggestion(originDestination, station) {
    const lineNames = compactLineNames(station.allLineNames);
    const circleIcons = lineNames.map(renderCircleIcon).join("");

    return `
      <div class="${stationSuggestionClass(originDestination)}" data-lines="${station.allLineNames.join(",")}">
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
        <circle r="20" cx="20" cy="20" class="${circleIconClass(lineName)}" transform="translate(1,1)"></circle>
        <g fill-rule="evenodd" class="icon-image" transform="translate(8,11) scale(1)">
          <path d="M0,0 l0,7 l9,0 l0,15.5 l7,0 l0,-15.5 l9,0 l0,-7 Z">
        </path></g>
      </svg>
      <div class="line-name">${lineName}</div>
    `
  }

  function stationInputClass(originDestination) {
    return `${subscriptionSelectClass(originDestination)} station-input`;
  }

  function subscriptionSelectClass(originDestination) {
    return `subscription-select-${originDestination}`
  }

  function stationSuggestionClass(originDestination) {
    return `${originDestination}-station-suggestion station-suggestion`
  }

  function circleIconClass(lineName) {
    const lineColor = lineName.toLowerCase().split(" ")[0]
    return `icon-${lineColor}-line-circle`
  }

  function setSelectedStation(originDestination, stationName, lines) {
    state[`${originDestination}SelectedName`] = stationName;
    state[`${originDestination}SelectedLines`] = lines;
  }

  function clearSelectedStation(originDestination) {
    state[`${originDestination}SelectedName`] = null;
    state[`${originDestination}SelectedLines`] = null;
  }

  function compactLineNames(lineNames) {
    let lines = [];

    lineNames.forEach(function(name) {
      const displayName = name.split(" ").slice(0, 2).join(" ");

      if (!lines.includes(displayName)) {
        lines.push(displayName);
      }
    });

    return lines;
  }

  function associatedLines(name) {
    const station = props.allStations.find(function(station) {
      return station.name == name;
    });

    return station.allLineNames.join(",");
  }

  $(document).on(
    "keyup", ".subscription-select-origin", { originDestination: "origin" }, typeahead);
  $(document).on(
    "keyup", ".subscription-select-destination", { originDestination: "destination" }, typeahead);
  $(document).on(
    "keyup", ".subscription-select-origin", { originDestination: "origin" }, validateStationInput);
  $(document).on(
    "keyup", ".subscription-select-destination", { originDestination: "destination" }, validateStationInput);
  $(document).on(
    "focusout", ".subscription-select-origin", { originDestination: "origin" }, pickFirstSuggestion);
  $(document).on(
    "focusout", ".subscription-select-destination", { originDestination: "destination" }, pickFirstSuggestion);
  $(document).on(
    "mousedown", ".origin-station-suggestion", { originDestination: "origin" }, assignSuggestion);
  $(document).on(
    "mousedown", ".destination-station-suggestion", { originDestination: "destination" }, assignSuggestion);
}
