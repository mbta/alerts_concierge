import getIcon from "./route-icons";

const select2Options = {
  templateResult: formatStop,
  templateSelection: formatStop,
  theme: "bootstrap4",
  placeholder: "Select a stop"
};

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
    selectStopComponent.on("select2:select", disableSubmitButtonIfSameStops);
    selectStopComponent.on("select2:select", greenEnforceSameRoute);
    selectStopComponent.on("select2:select", redEnforceSameShape);
  }
}

function isTripLegForm() {
  return $("#tripleg-form").length > 0;
}

function disableSubmitButtonIfSameStops() {
  const origin = $("#select2-trip_origin-container").attr("title");
  const destination = $("#select2-trip_destination-container").attr("title");
  if (origin == destination) {
    $("button[type='submit']").attr("disabled", "disabled");
  } else {
    $("button[type='submit']").removeAttr("disabled");
  }
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

const rebuildSelect2 = ($select2El) => {
  $select2El.val(null).trigger('change');

  $select2El.select2("destroy");
  $select2El.select2(select2Options);
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
