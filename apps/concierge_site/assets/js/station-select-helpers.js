function renderStationInput(name, className, preselectedValue) {
    return `
    <input type="text" name="${name}" placeholder="Enter a ${name}" autocomplete="off" class="${className}" value="${preselectedValue}"/>
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
      } else if (option.value) {
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
  const visibleSuggestionCount = $(".entity-suggestion").length;
  const $target = $(event.target);

  if (event.keyCode === 38 && $target.hasClass("subscription-select-entity-input")) {
    event.preventDefault();
    decrementselectedSuggestionIndex(state, visibleSuggestionCount)

  } else if (event.keyCode === 40 && $target.hasClass("subscription-select-entity-input")) {
    event.preventDefault();
    incrementselectedSuggestionIndex(state, visibleSuggestionCount)
  } else if (event.keyCode === 13 && $target.hasClass("btn-subscription-next")) {
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
  const visibleSuggestionCount = $(".entity-suggestion").length;
  const $target = $(event.target);

  if (event.keyCode === 38 && $target.hasClass("subscription-select-entity-input")) {
    event.preventDefault();
    decrementselectedSuggestionIndex(state, visibleSuggestionCount)

  } else if (event.keyCode === 40  && $target.hasClass("subscription-select-entity-input")) {
    event.preventDefault();
    incrementselectedSuggestionIndex(state, visibleSuggestionCount)
  } else if (event.keyCode === 13) {
    if ($target.hasClass("btn-subscription-next")) {
      return;
    } else if ($target.hasClass("btn-selected-entity")) {
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
