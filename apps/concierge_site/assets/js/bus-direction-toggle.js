
export const toggleBusDirection = direction => {
  const legInputEl = document.getElementById("trip_saved_leg");
  const [route, _direction] = legInputEl.value.split(" - ", 2);
  legInputEl.value = `${route} - ${direction}`;
};