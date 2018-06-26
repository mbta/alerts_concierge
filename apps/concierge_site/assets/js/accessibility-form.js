export default () => {
  const formEl = document.getElementById("accessibility-form");
  if (!formEl) {
    return;
  }
  formEl.addEventListener("submit", handleFormSubmit, false);
};

const handleFormSubmit = e => {
  const stopInputEl = document.getElementById("trip_stops");
  const stopOptions = [...stopInputEl.querySelectorAll("option")];
  stopOptions.forEach(option => {option.selected = true});
  
  const routeInputEl = document.getElementById("trip_routes");
  const routeOptions = [...routeInputEl.querySelectorAll("option")];
  routeOptions.forEach(option => {option.selected = true});
};