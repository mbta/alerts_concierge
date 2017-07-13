import filterSuggestions from './filter-suggestions';
import {generateRouteList, generateStationList} from './station-select-helpers';

export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {
    origin: {},
    destination: {}
  };

  if ($(".enter-trip-info").length) {
    const className = "select.subscription-select-origin";
    props.allRoutes = generateRouteList(className, $);
    props.allStations = generateStationList(className, $);
    props.validStationNames = props.allStations.map(station => station.name);
    attachSuggestionInputs();
    validateInputs();
  }

  function typeahead(event) {
    const query = event.target.value;
    const originDestination = event.data.originDestination;

    if (query.length > 0) {
      const matchingStations = filter(originDestination, query, props.allStations, state);
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

    validateInputText(inputText, originDestination);
  }

  function validateInputText(inputText, originDestination){
    const $stationInput = $(`.${subscriptionSelectClass(originDestination)}`);
    if (props.validStationNames.includes(inputText)) {
      $stationInput.attr("data-valid", true);
      $stationInput.attr("data-station-id", stationIdFromStationName(inputText));
      setSelectedStation(originDestination, inputText, associatedLines(inputText));
    } else {
      $stationInput.attr("data-valid", false);
      $stationInput.attr("data-station-id", null);
      clearSelectedStation(originDestination);
    }
  }

  function validateInputs(){
    validateInputText(fetchPreselectedValue("origin"), "origin");
    validateInputText(fetchPreselectedValue("destination"), "destination");
  }

  function assignSuggestion(event) {
    const originDestination = event.data.originDestination;
    const stationName = $(".station-name", $(this)).text();
    const $stationInput = $(`.${subscriptionSelectClass(originDestination)}`);

    $stationInput.val(stationName);
    $stationInput.attr("data-valid", true);
    $stationInput.attr("data-station-id", $(this).attr("data-station-id"));
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
      $stationInput.attr("data-station-id",  $firstSuggestion.attr("data-station-id"));
      setSelectedStation(originDestination, stationName, $firstSuggestion.attr("data-lines"));
    } else if (!props.validStationNames.includes($stationInput.val())) {
      $stationInput.val(null);
    }

    unmountStationSuggestions(originDestination);
  }

  function filter(originDestination, query) {
    let matchingStations = filterSuggestions(query, props.allStations, 'name');

    if (otherStationHasValidSelection(originDestination)) {
      const otherStation = oppositeStation(originDestination);
      matchingStations = matchingStations.filter(function(station) {
        return (
          state[otherStation].selectedName != station.name &&
          stationsOnSelectedLines(originDestination).includes(station.name)
        );
      });
    }

    return matchingStations;
  }

  function stationsOnSelectedLines(originDestination) {
    const otherStation = oppositeStation(originDestination);
    const selectedLines = state[otherStation]["selectedLines"].split(",");
    let stations = [];

    selectedLines.forEach(function(line) {
      stations = stations.concat(props.allRoutes[line])
    });

    return stations;
  }

  function handleSubmit() {
    updateHiddenStationInputs();
    return true;
  }

  function updateHiddenStationInputs() {
    const origin = $(".subscription-select-origin").attr("data-station-id");
    const destination = $(".subscription-select-destination").attr("data-station-id");

    $("input[name='subscription[origin]']").val(origin);
    $("input[name='subscription[destination]']").val(destination);
  }

  function unmountStationSuggestions(classPrefix) {
    $(`.${classPrefix}-station-suggestion`).remove();
  }

  function attachSuggestionInputs() {
    $("label[for='origin']").after(renderStationInput("origin"));
    $("label[for='destination']").after(renderStationInput("destination"));
    $(".trip-info-footer").before(renderHiddenStationInputs());
  }

  function renderStationInput(originDestination) {
    const preselectedValue = fetchPreselectedValue(originDestination);
    return `
      <input type="text" name="${originDestination}" placeholder="Enter a station" class="subscription-select ${stationInputClass(originDestination)}" value="${preselectedValue}"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
  }

  function fetchPreselectedValue(originDestination) {
    return $(`select[name="subscription[${originDestination}]"]`).find("option:selected").first().text();
  }

  function renderHiddenStationInputs() {
    return `
      <input type="hidden" name="subscription[origin]" />
      <input type="hidden" name="subscription[destination]" />
    `
  }

  function renderStationSuggestion(originDestination, station) {
    const form = $(".trip-info-form");
    let svg = "";

    if (form.hasClass("subway")) {
      const lineNames = compactLineNames(station.allLineNames);
      svg = lineNames.map(renderSubwayIcon).join("");
    } else if (form.hasClass("commuter-rail")) {
      svg = renderCommuterRailIcon(station.allLineNames);
    } else if (form.hasClass("ferry")) {
      svg = renderFerryIcon(station.allLineNames);
    }

    return renderSuggestionIcons(svg, originDestination, station)
  }

  function renderSuggestionIcons(svg, originDestination, station) {
    return `
      <div class="${stationSuggestionClass(originDestination)}" data-lines="${station.allLineNames.join(",")}" data-station-id="${station.id}">
        <div class="station-name">${station.name}</div>
        <div class="station-lines">
          ${svg}
        </div>
      </div>
    `
  }

  function renderSubwayIcon(lineName) {
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

  function renderCommuterRailIcon(lineNames) {
    let lineHelperText = ""
    if (lineNames.length > 1) {
      lineHelperText = "Multiple Lines";
    } else {
      lineHelperText = lineNames[0];
    }
    return `
      <div class="commuter-rail-icon circle-icon">
        <svg width="24" height="24" viewBox="-2 -2 26 26" xmlns="http://www.w3.org/2000/svg">
          <title>rail-icon</title>
          <g fill="#FFF" class="icon-image" fill-rule="evenodd">
            <path d="M7.077 22l.578-1h8.69l.578 1H7.077zM6.5 23l-.567.982-.866-.5L6.5 21H3.993C3.445 21 3 20.556 3 20v-1h18v1c0 .552-.445 1-.993 1H17.5l1.433 2.482-.866.5L17.5 23h-11zM21 6.6V3.817c0-.565-.424-1.144-.946-1.318L12.946.13c-.512-.17-1.37-.175-1.892 0L3.946 2.5C3.434 2.67 3 3.262 3 3.816V6.6L2 7v10.004c0 .55.444.996.992.996h18.016c.537 0 .992-.446.992-.996V7l-1-.4zM20 5c0-.553-.438-1.125-.96-1.274L13 2v3l7 2V5zM4 5c0-.553.438-1.125.96-1.274L11 2v3L4 7V5zm15.5 11c.828 0 1.5-.672 1.5-1.5s-.672-1.5-1.5-1.5-1.5.672-1.5 1.5.672 1.5 1.5 1.5zm-15 0c.828 0 1.5-.672 1.5-1.5S5.328 13 4.5 13 3 13.672 3 14.5 3.672 16 4.5 16zm7.5-3c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm0-.264c-1.51 0-2.736-1.225-2.736-2.736 0-1.51 1.225-2.736 2.736-2.736 1.51 0 2.736 1.225 2.736 2.736 0 1.51-1.225 2.736-2.736 2.736zM10.02 8.53h3.96v.915h-1.47v2.448h-1.014V9.445h-1.47l-.006-.915z"/>
          </g>
        </svg>
      </div>
      <div class="line-name">${lineHelperText}</div>
    `
  }

  function renderFerryIcon(lineNames) {
    let lineHelperText = ""
    if (lineNames.length > 1) {
      lineHelperText = "Multiple Routes";
    } else {
      lineHelperText = lineNames[0];
    }
    return `
      <div class="ferry-icon circle-icon">
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <title>ferry-icon</title>
          <g fill="#FFF" class="icon-image" fill-rule="evenodd">
            <path d="M17.234 19.167c.843-2.41 3.304-5.86 5.762-7.497L24 11l-4-1.667V5l-4-2V2l-4-2-4 2v1L4 5v4.333L0 11l1.004.67c2.494 1.662 4.922 4.862 5.777 7.5l.088.027 1.264.42c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l1.264-.42.102-.03zM19 8.917V6l-6-3v3l5 2.5 1 .417zm-14 0V6l6-3v3L6 8.5l-1 .417zM12 13c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zm0-.176c-1.007 0-1.824-.817-1.824-1.824 0-1.007.817-1.824 1.824-1.824 1.007 0 1.824.817 1.824 1.824 0 1.007-.817 1.824-1.824 1.824zm-1.32-2.804h2.64v.61h-.98v1.632h-.676V10.63h-.98l-.004-.61zM24 20.908l-2.132.71c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0L0 20.908v-1l2.132.71c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l2.132-.71v1zM24 22.908l-2.132.71c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0l-1.264-.42c-.48-.16-1.26-.16-1.736 0l-1.264.42c-.48.16-1.26.16-1.736 0L0 22.908v-1l2.132.71c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l1.264-.42c.48-.16 1.26-.16 1.736 0l1.264.42c.48.16 1.26.16 1.736 0l2.132-.71v1z"/>
          </g>
        </svg>
      </div>
      <div class="line-name">${lineHelperText}</div>
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

  function otherStationHasValidSelection(originDestination) {
    const otherStation = oppositeStation(originDestination);
    return (state[otherStation].selectedName && state[otherStation].selectedLines);
  }

  function setSelectedStation(originDestination, stationName, lines) {
    state[originDestination] = {
      selectedName: stationName,
      selectedLines: lines
    };
  }

  function clearSelectedStation(originDestination) {
    state[originDestination] = {
      selectedName: null,
      selectedLines: null
    };
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

  function stationIdFromStationName(stationName) {
    const station = props.allStations.find(station => station.name == stationName);
    return station.id;
  }

  function oppositeStation(originDestination) {
    return originDestination == "origin" ? "destination" : "origin"
  }

  function validateDropdown(event) {
    event.target.dataset.valid = true;
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
  $(document).on("focus", ".relevant-days-select", validateDropdown);
  $(document).on("focus", ".travel-time-select", validateDropdown);
  $(document).on("submit", ".trip-info-form", handleSubmit);
}
