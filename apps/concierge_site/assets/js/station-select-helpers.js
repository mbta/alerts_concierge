function renderStationInput(name, className, preselectedValue) {
    return `
      <input type="text" name="${name}" placeholder="Enter a station" autocomplete="off" class="subscription-select ${className}"  value="${preselectedValue}"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
}

function unmountStationSuggestions(className, $) {
  $(className).remove();
}

function generateRouteList(className, $) {
  let routes = {};
  const $optgroups = $(className);

  $optgroups.each(function(_i, group) {
    const options = $("option", group).map(function(i, option) {
      return option.text;
    }).get();

    const routeName = group.label;

    routes[routeName] = options;
  });

  return routes;
}

function generateStationList(className, $) {
  let stations = [];
  const $optgroups = $(className);

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

function onKeyDownOverrides(event, state, $) {
  const visibleSuggestionCount = $(".station-suggestion").length;
  const $target = $(event.target);

  if (event.keyCode === 38 && $target.is(".station-input")) {
    event.preventDefault();
    decrementselectedSuggestionIndex(state, visibleSuggestionCount)

  } else if (event.keyCode === 40 && $target.is(".station-input")) {
    event.preventDefault();
    incrementselectedSuggestionIndex(state, visibleSuggestionCount)
  } else if (event.keyCode === 13 && $target.is(".btn-subscription-next")) {
    return;
  } else if (event.keyCode === 13) {
    event.preventDefault();
    let focusable,
        targetIndex,
        next;

    focusable = $target.parent().parent().find("input,a,select,button").not(".no-js, input[type=hidden]").toArray();
    targetIndex = focusable.indexOf($target[0]);

    if (targetIndex >= focusable.length - 1) {
      next = focusable[0];
    } else {
      next = focusable[targetIndex + 1];
    }

    $target.focusout();
    next.focus();
  }
}

function onKeyDownOverridesAmenity(event, state, chooseSuggestion, removeStation, $) {
  const visibleSuggestionCount = $(".station-suggestion").length;
  const $target = $(event.target);

  if (event.keyCode === 38 && $target.is(".station-input")) {
    event.preventDefault();
    decrementselectedSuggestionIndex(state, visibleSuggestionCount)

  } else if (event.keyCode === 40  && $target.is(".station-input")) {
    event.preventDefault();
    incrementselectedSuggestionIndex(state, visibleSuggestionCount)
  } else if (event.keyCode === 13) {
    if ($target.is("button.btn-amenity-submit")) {
      return;
    } else if ($target.is("button.btn-selected-station")) {
      event.preventDefault();
      removeStation(event);
    } else {
      event.preventDefault();
      chooseSuggestion();
    }
  }
}

function selectedSuggestionClass(selectedSuggestionIndex, index) {
  if (selectedSuggestionIndex === index){
    return "selected-suggestion";
  } else {
    return "";
  }
}

function incrementselectedSuggestionIndex(state, visibleSuggestionCount){
  if (state.selectedSuggestionIndex + 1 < visibleSuggestionCount) {
    state.selectedSuggestionIndex = state.selectedSuggestionIndex + 1;
  }
}

function decrementselectedSuggestionIndex(state, visibleSuggestionCount){
  if (state.selectedSuggestionIndex - 1 >= 0) {
    state.selectedSuggestionIndex = state.selectedSuggestionIndex - 1;
  }
}

export {
  generateRouteList,
  generateStationList,
  onKeyDownOverrides,
  onKeyDownOverridesAmenity,
  renderStationInput,
  selectedSuggestionClass,
  unmountStationSuggestions,
};
