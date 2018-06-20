import Choices from "choices.js";
import elemDataset from 'elem-dataset';
import getIcon from "./route-icons";
import { say } from "./speak-to-screenreader";

// global-to-this-module variables for tracking instances, icons and the speaker element
let instances = {};
let icons = {};

export default () => {
  // wait for DOM to load
  document.addEventListener("DOMContentLoaded", () => {
    const routeSelectEls = document.querySelectorAll(
      "[data-type='route-choices']"
    );
    if (routeSelectEls.length < 1) {
      return;
    }

    // apply the chouices to the first element found
    applyChoicesJSToRoute(routeSelectEls.item(0), { keepClosed: true });
  });
};

// destroys any instance of the route select component and remove event listeners
const destroyChoicesJSForRoute = el => {
  const id = el.getAttribute("id");
  if (instances[id]) {
    el.removeEventListener("choice", handleChoice, false);
    el.removeEventListener("showDropdown", handleShowDropdown, false);
    instances[id].destroy();
  }
};

const applyChoicesJSToRoute = (el, options = {}) => {
  const id = el.getAttribute("id");

  // if the element was already create, re-initialize it
  // this is a bit hacky, but without this it was causing major errors
  if (instances[id]) {
    instances[id].destroy();
    instances[id] = false;
    setTimeout(() => {
      applyChoicesJSToRoute(el, options);
    }, 100);
    return;
  }

  // populate icons for select
  if (!icons[id]) {
    icons[id] = getIconMap(el);
  }

  // create a new instance of choices
  instances[id] = new Choices(el, {
    position: "bottom",
    shouldSort: false,
    classNames: {
      containerOuter: `choices choices__bootstrap--theme ${searchOptionClass(
        id
      )}`
    },
    searchPlaceholderValue: `Type here to search for your ${modeNameFromId(
      id
    )} route`,
    callbackOnCreateTemplates: template => ({
      item: itemTemplate(id, template),
      choice: choiceTemplate(id, template)
    })
  });

  // immediately show the dropdown
  if (options.keepClosed != true) {
    instances[id].showDropdown();
  }

  // cause options to be spoken when highlighted
  el.addEventListener("highlightChoice", handleHighlightChoice, false);

  // allows focus to be applied to the component instead of search input when search input is hidden
  if (options.focus === true) {
    el.addEventListener("showDropdown", handleShowDropdown, false);
  }

  // callback to make the component appear closed when a selection is made
  el.addEventListener("choice", handleChoice, false);
};

const modeNameFromId = id =>
  id == "trip_route_cr" ? "commuter rail" : id.replace(/trip_route_/, "");

const searchOptionClass = id =>
  id == "trip_route_subway" || id == "trip_route_ferry" ? "no-search" : "";

const itemTemplate = (id, template) => (classNames, data) => {
  return template(`
  <div class="${classNames.item} ${
    data.highlighted ? classNames.highlightedState : classNames.itemSelectable
  }" data-item data-id="${data.id}" data-value="${data.value}" ${
    data.active ? 'aria-selected="true"' : ""
  } ${data.disabled ? 'aria-disabled="true"' : ""}>
    ${
      data.value
        ? getIcon(icons[id][data.value])("float-left route__select--icon")
        : ""
    }
    ${data.label}
  </div>
`);
};

const choiceTemplate = (id, template) => (classNames, data) => {
  return template(`
  <div class="${classNames.item} ${classNames.itemChoice} ${
    data.disabled ? classNames.itemDisabled : classNames.itemSelectable
  }" data-select-text="Press to select" data-choice ${
    data.disabled
      ? 'data-choice-disabled aria-disabled="true"'
      : "data-choice-selectable"
  } data-id="${data.id}" data-value="${data.value}" ${
    data.groupId > 0 ? 'role="treeitem"' : 'role="option"'
  }">
    ${
      data.value
        ? getIcon(icons[id][data.value])("float-left route__select--icon")
        : ""
    }
    <span data-id="name">${data.label}</span>
  </div>
`);
};

const getContainerFromEventPath = eventPath =>
  eventPath
    .filter(
      node =>
        node.classList && node.classList.contains("choices__bootstrap--theme")
    )
    .shift();

const handleShowDropdown = event => {
  const container = getContainerFromEventPath(event.path);
  if (container.classList.contains("no-search")) {
    container.focus();
  }
};

const handleChoice = event => {
  // remove the classes that make the component appear in an open state
  const container = getContainerFromEventPath(event.path);
  container.classList.remove("is-active");
  container.classList.remove("is-open");
  container
    .querySelector(".choices__list--dropdown")
    .classList.remove("is-active");
};

const handleHighlightChoice = event => {
  // assign reference to speaker element
  const routeName = event.detail.el
    .querySelector("[data-id='name']")
    .innerHTML.trim();
  say(routeName);
};

// read icons from select form data and puts them in dictionary object
const getIconMap = el => {
  return [...el.querySelectorAll("option")].reduce((accumulator, option) => {
    const id = option.getAttribute("value");
    const dataset = elemDataset(option);
    const icon = dataset.icon;
    if (id && icon) {
      accumulator[id] = icon;
    }
    return accumulator;
  }, {});
};

// function used by radio button component to hide/show different related selects
export const toggleVisibleSelector = inputValue => {
  [...document.querySelectorAll("[data-type='mode-select']")].forEach(el => {
    const selectEl = el.querySelector("select");
    const dataset = elemDataset(el);
    if (dataset.id == inputValue) {
      el.classList.remove("d-none");
      selectEl.setAttribute("name", "trip[route]");
      applyChoicesJSToRoute(selectEl, { focus: true });
    } else {
      destroyChoicesJSForRoute(selectEl);
      el.classList.add("d-none");
      selectEl.setAttribute("name", "route-hidden");
    }
  });
};
