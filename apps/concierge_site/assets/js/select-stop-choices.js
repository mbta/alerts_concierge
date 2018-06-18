import Choices from "choices.js";
import getIcon from "./route-icons";
import { say } from "./speak-to-screenreader";

let instances = {};
let stopData = {};
let stopChoices = {};

export default () => {
  // wait for DOM to load
  document.addEventListener("DOMContentLoaded", () => {
    const stopSelectEls = [
      ...document.querySelectorAll("[data-type='stop-choices']")
    ];

    // apply the choices to all stop selectors
    stopSelectEls.forEach(stopSelectEl => {
      const optionEls = [...stopSelectEl.querySelectorAll("option")];
      cacheStopData(optionEls);
      stopChoices[stopSelectEl.getAttribute("id")] = getStopChoices(optionEls);
      applyChoicesJSToStop(stopSelectEl);
    });
  });
};

const cacheStopData = optionEls => {
  optionEls.forEach(optionEl => {
    const stopId = optionEl.getAttribute("value");
    if (!stopId) {
      return;
    }
    stopData[stopId] = Object.keys(Object.assign({}, optionEl.dataset));
  });
};

const applyChoicesJSToStop = el => {
  const id = el.getAttribute("id");

  // create a new instance of choices
  instances[id] = new Choices(el, {
    position: "bottom",
    shouldSort: false,
    classNames: {
      containerOuter:
        "choices choices__bootstrap--theme choices__bootstrap--stop-theme"
    },
    searchPlaceholderValue: `Type here to search for your stop`,
    callbackOnCreateTemplates: template => ({
      item: itemTemplate(id, template),
      choice: choiceTemplate(id, template)
    })
  });

  // cause options to be spoken when highlighted
  el.addEventListener("highlightChoice", handleHighlightChoice, false);

  // callback to trigger any events for when a choice is made
  el.addEventListener("choice", handleChoice, false);
};

const getStopChoices = optionEls =>
  optionEls.map(optionEl => ({
    value: optionEl.value,
    label: optionEl.innerHTML.trim()
  }));

const renderIcons = stopId =>
  stopData[stopId].reduce(
    (accumulator, iconId) =>
      `${accumulator}${getIcon(iconId)("float-right route__select--icon")}`,
    ""
  );

const itemTemplate = (_id, template) => (classNames, data) => {
  return template(`
  <div class="${classNames.item} ${
    data.highlighted ? classNames.highlightedState : classNames.itemSelectable
  }" data-item data-id="${data.id}" data-value="${data.value}" ${
    data.active ? 'aria-selected="true"' : ""
  } ${data.disabled ? 'aria-disabled="true"' : ""}>
    ${data.value ? renderIcons(data.value) : ""}
    ${data.label}
  </div>
`);
};

const choiceTemplate = (_id, template) => (classNames, data) => {
  return template(`
  <div class="${classNames.item} ${classNames.itemChoice} ${
    data.disabled ? classNames.itemDisabled : classNames.itemSelectable
  }" data-choice ${
    data.disabled
      ? 'data-choice-disabled aria-disabled="true"'
      : "data-choice-selectable"
  } data-id="${data.id}" data-value="${data.value}" ${
    data.groupId > 0 ? 'role="treeitem"' : 'role="option"'
  }>
    ${data.value ? renderIcons(data.value) : ""}
    <span data-id="name">${data.label}</span>
  </div>
`);
};

const handleHighlightChoice = event => {
  const stopName = event.detail.el
    .querySelector("[data-id='name']")
    .innerHTML.trim();
  say(stopName);
};

const handleChoice = event => {
  const selectEl = event.target;
  const selectId = selectEl.getAttribute("id");
  const otherSelectId = flipId(selectId);
  const selectData = Object.assign({}, selectEl.dataset);
  const selectedStopId = event.detail.choice.value || null;
  let availableChoices;

  // prevent origin and destination from being the same
  availableChoices = filterOptionsByStop(otherSelectId, selectedStopId);

  // prevent green line stops on different branches
  if (selectData.route === "Green" && selectedStopId) {
    availableChoices = filterOptionsByBranches(
      getBranchesFromData(stopData[selectedStopId]),
      availableChoices
    );
  }

  // prevent red line stops on different shapes
  if (selectData.route === "Red" && selectedStopId) {
    availableChoices = filterOptionsByShapes(
      getShapesFromData(stopData[selectedStopId]),
      availableChoices
    );
  }

  // set the affected select to whatever the remaining values are
  instances[otherSelectId].setChoices(availableChoices, "value", "label", true);

  // set smart defaults for commuter rail
  if (selectData.mode === "cr" && selectId == "trip_origin") {
    smartDefaultForCommuterRail(otherSelectId, availableChoices);
  }
};

const flipId = selectId =>
  selectId == "trip_origin" ? "trip_destination" : "trip_origin";

const getBranchesFromData = data =>
  data.filter(
    value => ["greenB", "greenC", "greenD", "greenE"].indexOf(value) !== -1
  );

const getShapesFromData = data =>
  data.filter(value => ["red-1", "red-2"].indexOf(value) !== -1);

const filterOptionsByStop = (selectId, disabledStopId) =>
  !disabledStopId
    ? stopChoices[selectId]
    : stopChoices[selectId].filter(stop => stop.value != disabledStopId);

const intersects = (left, right) =>
  left.filter(value => -1 !== right.indexOf(value)).length > 0 ? true : false;

const filterOptionsByBranches = (branches, previousChoices) =>
  !branches || branches.length == 0
    ? previousChoices
    : previousChoices.filter(
        stop =>
          !stopData[stop.value]
            ? true
            : intersects(stopData[stop.value] || [], branches)
      );

const filterOptionsByShapes = (shapes, previousChoices) =>
  !shapes || shapes.length == 0
    ? previousChoices
    : previousChoices.filter(
        stop =>
          !stopData[stop.value]
            ? true
            : intersects(stopData[stop.value] || [], shapes)
      );

const smartDefaultForCommuterRail = (selectId, availableChoices) => {
  const defaultStops = availableChoices.filter(
    stop => stop.value === "place-north" || stop.value === "place-sstat"
  );
  if (defaultStops.length === 0) {
    return;
  }
  instances[selectId].setChoiceByValue(defaultStops[0].value);
};
