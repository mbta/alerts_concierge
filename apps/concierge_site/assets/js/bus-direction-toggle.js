export const toggleBusDirection = direction => {
  const legInputEl = document.getElementById("trip_saved_leg");
  const [route, _direction] = legInputEl.value.split(" - ", 2);
  const updatedRoute = `${route} - ${direction}`;
  updateAlternateRoutes(legInputEl.value, updatedRoute, direction);
  legInputEl.value = updatedRoute;
};

// when the user changes their bus direction, update alternative routes to match
const updateAlternateRoutes = (before, after, direction) => {
  // read existing alternate routes from DOM
  const alternativeRoutes = JSON.parse(
    decodeURI(document.getElementById("trip_alternate_routes").value)
  );

  // return if their are no alternative routes specified
  if (Object.keys(alternativeRoutes).length === 0) {
    return;
  }

  // loop over alternate routes, updating the key and values
  // for example, {"a - 1": ["b - 1~~~Route b~~bus"]} -> {"a - 0": ["b - 0~~~Route b~~bus"]}
  const updatedAlternateRoutes = Object.keys(alternativeRoutes).reduce(
    (accumulator, primaryRoute) =>
      primaryRoute === before
        ? // update the route that has been changed
          Object.assign({}, accumulator, {
            [after]: alternativeRoutes[primaryRoute].map(alternativeRoute => {
              // replace the direction on nested alternate routes
              const [route, suffix] = alternativeRoute.split(" - ", 2);
              return `${route} - ${direction}${suffix.substring(1)}`;
            })
          })
        : // otherwise, return original key and value
          Object.assign({}, accumulator, {
            [`${primaryRoute}`]: alternativeRoutes[primaryRoute]
          }),
    {}
  );

  // commit all alternate routes back to the DOM
  document.getElementById("trip_alternate_routes").value = encodeURI(
    JSON.stringify(updatedAlternateRoutes)
  );
};
