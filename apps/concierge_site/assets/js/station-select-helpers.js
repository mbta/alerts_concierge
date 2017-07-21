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

export {
  generateRouteList,
  generateStationList,
  renderStationInput,
  unmountStationSuggestions
};
