import { getStopInstances } from "./select-stop-choices";
import { getRouteInstances } from "./select-route-choices";
import { makeErrorMessageEl } from "./error-message";
import { insertAfterElByQuery, removeElByQuery } from "./dom-utils";
// there is a bug in choices.js where multi-selects are not
// setting their values properly. Before submit, this code
// removes all of the selects and adds hidden inputs
export default () => {
  const formEl = document.querySelector("form");
  if (!formEl) {
    return;
  }

  const formId = formEl.getAttribute("id");
  switch (formId) {
    case "accessibility-form":
      formEl.addEventListener("submit", handleAccessibilityFormSubmit, false);
      break;

    case "new-tripleg-form":
      formEl.addEventListener("submit", handleRouteFormSubmit, false);
      break;

    case "tripleg-form":
      formEl.addEventListener("submit", handleRouteFormSubmit, false);
      break;
  }
};

const handleRouteFormSubmit = e => {
  // delete any existing bus error
  removeElByQuery("#bus-error");

  const existingAlternativeRoutes = JSON.parse(
    decodeURI(document.getElementById("trip_alternate_routes").value)
  );

  const formEl = e.target;

  // determine if the route selected was a bus
  const isBusSelected = document
    .querySelector("label[data-id='bus']")
    .getAttribute("aria-checked");

  // do nothing for all non-bus modes
  if (isBusSelected !== "true") {
    return;
  }

  // show an error message if there are no selections
  const busInstance = getRouteInstances()["trip_route_bus"];
  const routeValues = busInstance.getValue();
  if (routeValues.length === 0) {
    e.preventDefault();
    const errorEl = makeErrorMessageEl(
      "bus-error",
      "Please select at least one bus route."
    );
    insertAfterElByQuery(".route__selector--container", errorEl);
    return;
  }

  // separate the first route from the alternate routes
  const [primaryRoute, ...alternateRoutes] = routeValues;

  // set the primary route to a hidden form field
  formEl.appendChild(makeHiddenInput("trip[route]", primaryRoute.value));

  // parse route key
  const routeKey = primaryRoute.value.split("~~")[0];

  // initialize the value for this primary route within the existing alternate routes
  existingAlternativeRoutes[routeKey] = [];

  // create a list of alternate routes, indexed by primary route
  const updatedAlternateRoutes = alternateRoutes.reduce(
    (accumulator, route) =>
      Object.assign({}, accumulator, {
        [routeKey]: accumulator[routeKey].concat(route.value)
      }),
    existingAlternativeRoutes
  );

  // commit all alternate routes back to the DOM
  document.getElementById("trip_alternate_routes").value = encodeURI(
    JSON.stringify(updatedAlternateRoutes)
  );
};

const handleAccessibilityFormSubmit = e => {
  const formEl = e.target;

  // remove select elements
  const stopInputEl = document.getElementById("trip_stops");
  stopInputEl.parentNode.removeChild(stopInputEl);
  const routeInputEl = document.getElementById("trip_routes");
  routeInputEl.parentNode.removeChild(routeInputEl);

  // get stop and route selections
  const stopInstances = getStopInstances();
  const routeIntances = getRouteInstances();
  const routeValues = routeIntances.trip_routes.getValue();
  const stopValues = stopInstances.trip_stops.getValue();

  // add routes and stops as hidden inputs
  routeValues.forEach(route => {
    formEl.appendChild(makeHiddenInput("trip[routes][]", route.value));
  });
  stopValues.forEach(stop => {
    formEl.appendChild(makeHiddenInput("trip[stops][]", stop.value));
  });
};

const makeHiddenInput = (name, value) => {
  const hiddenInput = document.createElement("input");
  hiddenInput.setAttribute("type", "hidden");
  hiddenInput.setAttribute("name", name);
  hiddenInput.setAttribute("value", value);
  return hiddenInput;
};
