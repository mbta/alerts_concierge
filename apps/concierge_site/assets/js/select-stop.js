import getIcon from "./route-icons";

const select2Options = {
  templateResult: formatStop,
  templateSelection: formatStop,
  theme: "bootstrap4",
  placeholder: "Select a stop"
};

const greenLines = ["green-b", "green-c", "green-d", "green-e"];

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
  [...$destinationSelectEl.children()].forEach(option => {
    if (stopRouteMatch(selectedOriginRoutes, option)) {
      option.removeAttribute("disabled");
    } else {
      option.setAttribute("disabled", "disabled");
    }
  });

  // always clear the destination because it may have an incompatible value
  $destinationSelectEl.val(null).trigger('change');

  // select2 needs to be re-initialized or it doesn't see the changes
  $destinationSelectEl.select2("destroy");
  $destinationSelectEl.select2(select2Options);
}

const stopRouteMatch = (routes, option) => 
  routes.reduce((accumulator, route) => (
    accumulator == true
    ? true
    : option.getAttribute(`data-${route}`) == "true"
      ? true
      : false
  ), false);
  