import { complement } from "set-manipulator";

const determineExistingSelections = listEl =>
  [...listEl.childNodes]
    .filter(itemEl => itemEl.getAttribute("data-selected") === "true")
    .map(itemEl => parseInt(itemEl.getAttribute("data-position")));

const isContigouos = positions =>
  positions.reduce(
    (accumulator, position) =>
      accumulator.isContigouos === false
        ? { isContigouos: false }
        : accumulator.lastPosition === position - 1
          ? { isContigouos: true, lastPosition: position }
          : { isContigouos: false },
    {
      isContigouos: true,
      lastPosition: positions.slice(0, 1) - 1
    }
  )["isContigouos"];

const firstPosition = postitions => postitions.slice(0, 1)[0];

const lastPosition = positions => positions.slice(-1)[0];

const makeRange = (length, from) =>
  Array(length)
    .fill(from)
    .map((x, y) => x + y);

const determinePositionGaps = positions =>
  complement(
    makeRange(
      lastPosition(positions) - firstPosition(positions),
      firstPosition(positions)
    ),
    positions
  );

const checkItem = itemEl => {
  itemEl.setAttribute("data-selected", "true");
  itemEl
    .querySelector("input[type='checkbox']")
    .setAttribute("checked", "checked");
  itemEl.querySelector("label").setAttribute("aria-checked", "true");
  itemEl.querySelector("label").classList.add("active");
};

const unCheckItem = itemEl => {
  itemEl.setAttribute("data-selected", "false");
  itemEl.querySelector("input[type='checkbox']").removeAttribute("checked");
  itemEl.querySelector("label").setAttribute("aria-checked", "false");
  itemEl.querySelector("label").classList.remove("active");
};

const checkPositions = (listEl, positions) =>
  [...listEl.childNodes]
    .filter(
      itemEl =>
        positions.indexOf(parseInt(itemEl.getAttribute("data-position"))) !== -1
    )
    .forEach(itemEl => checkItem(itemEl));

const fillSelectionGaps = (listEl, positions) =>
  checkPositions(listEl, determinePositionGaps(positions));

const clearSelections = listEl =>
  [...listEl.childNodes].forEach(itemEl => unCheckItem(itemEl));

const handleTripChecked = (listEl, positions) =>
  isContigouos(positions) ? null : fillSelectionGaps(listEl, positions);

const handleTripUnchecked = (listEl, positions) =>
  isContigouos(positions) ? null : clearSelections(listEl);

const handleTrip = (changedItemEl, isChecked) => {
  changedItemEl.setAttribute("data-selected", isChecked ? "true" : "false");
  const changedListEl = changedItemEl.parentNode;
  const selectedPositions = determineExistingSelections(changedListEl);

  isChecked
    ? handleTripChecked(changedListEl, selectedPositions)
    : handleTripUnchecked(changedListEl, selectedPositions);
};

export const handleTripChange = (e) => {
  const changedLabelEl = e.changedEl[0]; // because changeEl is a jQuery object
  const changedItemEl = changedLabelEl.parentNode;
  const tripTime = changedItemEl.getAttribute("data-time") || false;
  tripTime ? handleTrip(changedItemEl, e.isChecked) : null;
}