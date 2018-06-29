import { getStopInstances } from "./select-stop-choices";
import { getRouteInstances } from "./select-route-choices";

export default () => {
  const formEl = document.getElementById("accessibility-form");
  if (!formEl) {
    return;
  }
  formEl.addEventListener("submit", handleFormSubmit, false);
};

const handleFormSubmit = e => {
  const formEl = e.target;

  // there is a bug in choices.js where multi-selects are not
  // setting their values properly. Before submit, this code
  // removes all of the selects and adds hidden inputs

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
}