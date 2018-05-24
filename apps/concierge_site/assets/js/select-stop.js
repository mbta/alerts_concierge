import getIcon from "./route-icons";

const select2Options = {
  templateResult: formatStop,
  templateSelection: formatStop,
  theme: "bootstrap4",
  placeholder: "Select a stop"
};

const NORTH_STATION = "place-sstat";
const SOUTH_STATION = "place-north";

const greenLines = ["green-b", "green-c", "green-d", "green-e"];
const redShapes = ["red-1", "red-2"];

export default function($) {
  $ = $ || window.jQuery;
  $("select[data-type='stop']").each(function() {
    $(this).select2(select2Options);
    addValidation($(this));
  });
};

function formatStop(stop) {
  const $el = $(stop.element);
  const className = "float-right";
  const accessible = $el.data("accessible") ? getIcon("accessible")(className) : "";
  const red = $el.data("red") ? getIcon("red")(className) : "";
  const orange = $el.data("orange") ? getIcon("orange")(className) : "";
  const blue = $el.data("blue") ? getIcon("blue")(className) : "";
  const greenB = $el.data("green-b") ? getIcon("green-b")(className) : ""
  const greenC = $el.data("green-c") ? getIcon("green-c")(className) : "";
  const greenD = $el.data("green-d") ? getIcon("green-d")(className) : "";
  const greenE = $el.data("green-e") ? getIcon("green-e")(className) : "";
  const mattapan = $el.data("mattapan") ? getIcon("mattapan")(className) : "";
  const cr = $el.data("cr") ? getIcon("cr")(className) : "";
  const bus = $el.data("bus") ? getIcon("bus")(className) : "";
  const ferry = $el.data("ferry") ? getIcon("ferry")(className) : "";
  return $(`<span>${stop.text}${accessible}${ferry}${cr}${bus}${mattapan}${blue}${greenE}${greenD}${greenC}${greenB}${orange}${red}</span>`);
};

function addValidation(selectStopComponent) {
  if (isTripLegForm()) {
    selectStopComponent.on("select2:select", removeDestinationIfSameAsOrigin);
    selectStopComponent.on("select2:select", greenEnforceSameRoute);
    selectStopComponent.on("select2:select", redEnforceSameShape);
    selectStopComponent.on("select2:select", commuterRailSmartDestination);
  }
}

function isTripLegForm() {
  return $("#tripleg-form").length > 0;
}

function isDefaultOptionSelected($el) {
  return $el.find(":selected").html() == "Select a stop";
}

function getSelectedOption($el) {
  return $el.find(":selected")[0];
}

function commuterRailSmartDestination(select2) {
  const $originSelectEl = $("#trip_origin");
  const $destinationSelectEl = $("#trip_destination");
  const originSelectedOption = getSelectedOption($originSelectEl);

  // only perform for commuter rail
  if (select2.target.getAttribute("data-mode") != "cr") {
    return;
  }

  // only perform this operation when the origin changes
  if (select2.target.getAttribute("id") != "trip_origin") {
    return;
  }

  // skip if north / south station already selected
  if (originSelectedOption.value == SOUTH_STATION || originSelectedOption.value == NORTH_STATION) {
    return;
  }

  // skip if there is already an existing destination selection
  if (!isDefaultOptionSelected($destinationSelectEl)) {
    return;
  }

  [...$destinationSelectEl.children()].forEach(optionEl => {
    if (optionEl.value == SOUTH_STATION || optionEl.value == NORTH_STATION) {
      $destinationSelectEl.val(optionEl.value);
      $destinationSelectEl.trigger('change');
    }
  });
}

function removeDestinationIfSameAsOrigin(select2) {
  const $originSelectEl = $("#trip_origin");
  const $destinationSelectEl = $("#trip_destination");
  const originSelectedOption = getSelectedOption($originSelectEl);
  const destinationSelectedOption = getSelectedOption($destinationSelectEl);

  // only perform this operation when the origin changes
  if (select2.target.getAttribute("id") != "trip_origin") {
    return;
  }

  [...$destinationSelectEl.children()].forEach(optionEl => {
    if (optionEl.value == originSelectedOption.value) {
      optionEl.setAttribute("disabled", "disabled");
    } else {
      optionEl.removeAttribute("disabled");
    }
  });

  rebuildSelect2($destinationSelectEl, destinationSelectedOption.value);
}

function greenEnforceSameRoute(select2) {
  const $originSelectEl = $("#trip_origin");
  const $destinationSelectEl = $("#trip_destination");

  // only perform this operation when the origin changes
  if (select2.target.getAttribute("id") != "trip_origin") {
    return;
  }

  // only perform this operation if the line is Green
  if ($originSelectEl.attr("data-route") != "Green") {
    return;
  }
  const originSelectedOption = $originSelectEl.find(":selected")[0];
  const selectedOriginRoutes = greenLines.filter(route => (originSelectedOption.getAttribute(`data-${route}`) == "true"));
  [...$destinationSelectEl.children()].forEach(optionEl => {
    if (stopMatch(selectedOriginRoutes, optionEl)) {
      optionEl.removeAttribute("disabled");
    } else {
      optionEl.setAttribute("disabled", "disabled");
    }
  });

  rebuildSelect2($destinationSelectEl);
}

const rebuildSelect2 = ($select2El, selectedValue) => {
  $select2El.val(null).trigger('change');

  $select2El.select2("destroy");
  $select2El.select2(select2Options);

  if (selectedValue) {
    $select2El.val(selectedValue);
    $select2El.trigger('change');
  }
};

const stopMatch = (options, optionEl) => 
  options.reduce((accumulator, value) => (
    accumulator == true
    ? true
    : optionEl.getAttribute(`data-${value}`) == "true"
      ? true
      : false
  ), false);
  
function redEnforceSameShape(select2) {
  const $originSelectEl = $("#trip_origin");
  const $destinationSelectEl = $("#trip_destination");

  // only perform this operation when the origin changes
  if (select2.target.getAttribute("id") != "trip_origin") {
    return;
  }

  // only perform this operation if the line is Green
  if ($originSelectEl.attr("data-route") != "Red") {
    return;
  }
  const originSelectedOption = $originSelectEl.find(":selected")[0];
  const selectedOriginShapes = redShapes.filter(shape => (originSelectedOption.getAttribute(`data-${shape}`) == "true"));
  [...$destinationSelectEl.children()].forEach(optionEl => {
    if (stopMatch(selectedOriginShapes, optionEl)) {
      optionEl.removeAttribute("disabled");
    } else {
      optionEl.setAttribute("disabled", "disabled");
    }
  });

  rebuildSelect2($destinationSelectEl);
}
